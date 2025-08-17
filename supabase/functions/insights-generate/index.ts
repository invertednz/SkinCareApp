import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// JSON Schema for insights output
interface InsightsSummary {
  overall_assessment: string;
  key_trends: string[];
  data_quality_note?: string;
}

interface InsightsRecommendation {
  category: 'continue' | 'start' | 'stop';
  title: string;
  rationale: string;
  confidence_level: 'high' | 'medium' | 'low';
  priority: number; // 1-5, 1 being highest priority
}

interface InsightsActionPlan {
  immediate_actions: string[];
  weekly_goals: string[];
  monitoring_focus: string[];
}

interface InsightsResponse {
  summary: InsightsSummary;
  recommendations: InsightsRecommendation[];
  action_plan: InsightsActionPlan;
  generated_at: string;
  data_period: {
    start_date: string;
    end_date: string;
    days_analyzed: number;
  };
  disclaimer: string;
  debug_info?: {
    user_data_summary: any;
    prompt_used: string;
    model_response_raw: string;
  };
}

// Error response interface
interface ErrorResponse {
  error: string;
  code: string;
  details?: any;
}

serve(async (req) => {
  try {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }

    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders })
    }

    // Validate request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed', code: 'METHOD_NOT_ALLOWED' } as ErrorResponse),
        { 
          status: 405, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header', code: 'UNAUTHORIZED' } as ErrorResponse),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Get user from JWT
    const jwt = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(jwt)
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token', code: 'UNAUTHORIZED', details: authError } as ErrorResponse),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Parse request body
    const requestBody = await req.json()
    const { force_refresh = false, debug = false } = requestBody

    // Check for existing recent insights (cooldown logic)
    if (!force_refresh) {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()
      const { data: recentInsights } = await supabase
        .from('insights')
        .select('generated_at')
        .eq('user_id', user.id)
        .gte('generated_at', oneHourAgo)
        .order('generated_at', { ascending: false })
        .limit(1)

      if (recentInsights && recentInsights.length > 0) {
        return new Response(
          JSON.stringify({ 
            error: 'Insights generated recently. Please wait before requesting again.', 
            code: 'RATE_LIMITED',
            details: { last_generated: recentInsights[0].generated_at }
          } as ErrorResponse),
          { 
            status: 429, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
    }

    // Task 1.2: Query last 14 days of logs/photos from Supabase with proper RLS
    const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    const today = new Date().toISOString().split('T')[0]

    // Fetch user data with RLS automatically applied
    const [
      skinHealthData,
      symptomData,
      dietData,
      supplementData,
      routineData,
      photoData,
      profileData
    ] = await Promise.all([
      // Skin health entries
      supabase
        .from('skin_health_entries')
        .select('*')
        .eq('user_id', user.id)
        .gte('entry_date', fourteenDaysAgo)
        .lte('entry_date', today)
        .is('deleted_at', null)
        .order('entry_date', { ascending: false }),
      
      // Symptom entries
      supabase
        .from('symptom_entries')
        .select('*')
        .eq('user_id', user.id)
        .gte('entry_date', fourteenDaysAgo)
        .lte('entry_date', today)
        .is('deleted_at', null)
        .order('entry_date', { ascending: false }),
      
      // Diet entries
      supabase
        .from('diet_entries')
        .select('*')
        .eq('user_id', user.id)
        .gte('entry_date', fourteenDaysAgo)
        .lte('entry_date', today)
        .is('deleted_at', null)
        .order('entry_date', { ascending: false }),
      
      // Supplement entries
      supabase
        .from('supplement_entries')
        .select('*')
        .eq('user_id', user.id)
        .gte('entry_date', fourteenDaysAgo)
        .lte('entry_date', today)
        .is('deleted_at', null)
        .order('entry_date', { ascending: false }),
      
      // Routine entries
      supabase
        .from('routine_entries')
        .select('*')
        .eq('user_id', user.id)
        .gte('entry_date', fourteenDaysAgo)
        .lte('entry_date', today)
        .is('deleted_at', null)
        .order('entry_date', { ascending: false }),
      
      // Photos (linked to entries in the date range)
      supabase
        .from('photos')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', fourteenDaysAgo + 'T00:00:00.000Z')
        .lte('created_at', today + 'T23:59:59.999Z')
        .order('created_at', { ascending: false }),
      
      // User profile for context
      supabase
        .from('profiles')
        .select('*')
        .eq('user_id', user.id)
        .single()
    ])

    // Check for data fetching errors
    const dataErrors = [
      skinHealthData.error,
      symptomData.error,
      dietData.error,
      supplementData.error,
      routineData.error,
      photoData.error,
      profileData.error
    ].filter(Boolean)

    if (dataErrors.length > 0) {
      console.error('Data fetching errors:', dataErrors)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch user data', 
          code: 'DATA_FETCH_ERROR',
          details: dataErrors
        } as ErrorResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Compile user data summary
    const userDataSummary = {
      profile: profileData.data,
      data_period: {
        start_date: fourteenDaysAgo,
        end_date: today,
        days_analyzed: 14
      },
      skin_health: {
        entries: skinHealthData.data || [],
        count: skinHealthData.data?.length || 0
      },
      symptoms: {
        entries: symptomData.data || [],
        count: symptomData.data?.length || 0
      },
      diet: {
        entries: dietData.data || [],
        count: dietData.data?.length || 0
      },
      supplements: {
        entries: supplementData.data || [],
        count: supplementData.data?.length || 0
      },
      routine: {
        entries: routineData.data || [],
        count: routineData.data?.length || 0
      },
      photos: {
        entries: photoData.data || [],
        count: photoData.data?.length || 0
      }
    }

    // Check if we have sufficient data for meaningful insights
    const totalEntries = userDataSummary.skin_health.count + 
                        userDataSummary.symptoms.count + 
                        userDataSummary.diet.count + 
                        userDataSummary.supplements.count + 
                        userDataSummary.routine.count

    if (totalEntries < 3) {
      return new Response(
        JSON.stringify({ 
          error: 'Insufficient data for insights generation. Please log more entries and try again.', 
          code: 'INSUFFICIENT_DATA',
          details: { total_entries: totalEntries, minimum_required: 3 }
        } as ErrorResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Task 1.3: Engineer prompt with guardrails and disclaimers
    const systemPrompt = `You are a skincare insights AI assistant that analyzes user data to provide helpful, evidence-based suggestions. You must follow these strict guidelines:

CRITICAL SAFETY GUIDELINES:
- You are NOT a medical professional and cannot provide medical advice
- Always include disclaimers about consulting healthcare professionals
- Never diagnose skin conditions or recommend prescription treatments
- Focus on general skincare habits and routine optimization
- Be conservative with recommendations and acknowledge limitations

ANALYSIS APPROACH:
- Analyze patterns in the provided data objectively
- Look for correlations between routine adherence, diet, and skin health
- Identify trends over the 14-day period
- Consider data quality and completeness in your confidence levels
- Provide actionable, specific suggestions when possible

OUTPUT REQUIREMENTS:
- Respond ONLY with valid JSON matching the exact schema provided
- Use confidence levels: 'high' (strong data support), 'medium' (some evidence), 'low' (limited data)
- Prioritize recommendations: 1 (most important) to 5 (least important)
- Keep rationales concise but informative
- Include appropriate disclaimers`

    const userDataPrompt = `
USER DATA SUMMARY (Last 14 days):
${JSON.stringify(userDataSummary, null, 2)}

ANALYSIS INSTRUCTIONS:
1. Analyze skin health trends (ratings, patterns)
2. Identify correlations between diet, supplements, routine adherence and skin health
3. Look for symptom patterns and potential triggers
4. Assess routine consistency and effectiveness
5. Consider photo data if available for visual progress

Generate insights following this exact JSON schema:
{
  "summary": {
    "overall_assessment": "Brief overall assessment of skin health trends",
    "key_trends": ["Array of 2-4 key observations from the data"],
    "data_quality_note": "Note about data completeness/quality if relevant"
  },
  "recommendations": [
    {
      "category": "continue|start|stop",
      "title": "Specific recommendation title",
      "rationale": "Evidence-based explanation",
      "confidence_level": "high|medium|low",
      "priority": 1-5
    }
  ],
  "action_plan": {
    "immediate_actions": ["2-3 specific actions to take this week"],
    "weekly_goals": ["2-3 goals for the coming week"],
    "monitoring_focus": ["2-3 things to track closely"]
  }
}

Remember: Focus on patterns in the actual data provided. If data is limited, acknowledge this and provide general guidance. Always maintain a helpful but cautious tone.`

    const fullPrompt = systemPrompt + "\n\n" + userDataPrompt

    // Task 1.4: Call Vertex AI (model selection per PRD), handle timeouts/retries
    const vertexAiApiKey = Deno.env.get('VERTEX_AI_API_KEY')
    const vertexAiProjectId = Deno.env.get('VERTEX_AI_PROJECT_ID')
    const vertexAiLocation = Deno.env.get('VERTEX_AI_LOCATION') || 'us-central1'
    
    if (!vertexAiApiKey || !vertexAiProjectId) {
      console.error('Missing Vertex AI configuration')
      return new Response(
        JSON.stringify({ 
          error: 'AI service configuration error', 
          code: 'AI_CONFIG_ERROR'
        } as ErrorResponse),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Vertex AI API call with retry logic
    async function callVertexAI(prompt: string, maxRetries = 3): Promise<string> {
      const url = `https://${vertexAiLocation}-aiplatform.googleapis.com/v1/projects/${vertexAiProjectId}/locations/${vertexAiLocation}/publishers/google/models/gemini-1.5-flash:generateContent`
      
      const requestBody = {
        contents: [{
          role: 'user',
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.1,
          topK: 1,
          topP: 0.8,
          maxOutputTokens: 2048,
        },
        safetySettings: [
          {
            category: 'HARM_CATEGORY_HARASSMENT',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            category: 'HARM_CATEGORY_HATE_SPEECH',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      }

      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          const controller = new AbortController()
          const timeoutId = setTimeout(() => controller.abort(), 30000) // 30 second timeout

          const response = await fetch(url, {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${vertexAiApiKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody),
            signal: controller.signal
          })

          clearTimeout(timeoutId)

          if (!response.ok) {
            const errorText = await response.text()
            throw new Error(`Vertex AI API error: ${response.status} - ${errorText}`)
          }

          const result = await response.json()
          
          if (!result.candidates || result.candidates.length === 0) {
            throw new Error('No response generated from Vertex AI')
          }

          const content = result.candidates[0]?.content?.parts?.[0]?.text
          if (!content) {
            throw new Error('Empty response from Vertex AI')
          }

          return content

        } catch (error) {
          console.error(`Vertex AI call attempt ${attempt} failed:`, error)
          
          if (attempt === maxRetries) {
            throw error
          }
          
          // Exponential backoff: wait 2^attempt seconds
          await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000))
        }
      }
      
      throw new Error('Max retries exceeded')
    }

    let aiResponse: string
    let rawModelResponse = ''
    
    try {
      console.log('Calling Vertex AI for insights generation...')
      aiResponse = await callVertexAI(fullPrompt)
      rawModelResponse = aiResponse
      console.log('Vertex AI response received')
    } catch (error) {
      console.error('Vertex AI call failed:', error)
      return new Response(
        JSON.stringify({ 
          error: 'AI service unavailable', 
          code: 'AI_SERVICE_ERROR',
          details: error.message
        } as ErrorResponse),
        { 
          status: 503, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Task 1.5: Map model response to JSON schema with validation and safe defaults
    let parsedInsights: any
    
    try {
      // Try to extract JSON from the response (in case it's wrapped in markdown or other text)
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/)
      const jsonString = jsonMatch ? jsonMatch[0] : aiResponse
      
      parsedInsights = JSON.parse(jsonString)
    } catch (error) {
      console.error('Failed to parse AI response as JSON:', error)
      
      // Fallback to structured mock response if parsing fails
      parsedInsights = {
        summary: {
          overall_assessment: "Unable to generate detailed insights due to data processing error. Please try again later.",
          key_trends: ["Data analysis temporarily unavailable"],
          data_quality_note: "AI response parsing failed"
        },
        recommendations: [{
          category: 'continue',
          title: 'Maintain consistent logging',
          rationale: 'Continue tracking your skin health data for better insights.',
          confidence_level: 'low',
          priority: 1
        }],
        action_plan: {
          immediate_actions: ["Continue current routine", "Keep logging daily data"],
          weekly_goals: ["Maintain consistency in data entry"],
          monitoring_focus: ["Overall skin health trends"]
        }
      }
    }

    // Validate and apply safe defaults to the parsed response
    const validatedResponse: InsightsResponse = {
      summary: {
        overall_assessment: parsedInsights.summary?.overall_assessment || "Analysis completed with limited data.",
        key_trends: Array.isArray(parsedInsights.summary?.key_trends) ? 
                   parsedInsights.summary.key_trends.slice(0, 5) : 
                   ["Insufficient data for trend analysis"],
        data_quality_note: parsedInsights.summary?.data_quality_note
      },
      recommendations: Array.isArray(parsedInsights.recommendations) ? 
                      parsedInsights.recommendations.slice(0, 10).map((rec: any) => ({
                        category: ['continue', 'start', 'stop'].includes(rec.category) ? rec.category : 'continue',
                        title: rec.title || 'General recommendation',
                        rationale: rec.rationale || 'Based on available data patterns',
                        confidence_level: ['high', 'medium', 'low'].includes(rec.confidence_level) ? 
                                        rec.confidence_level : 'low',
                        priority: typeof rec.priority === 'number' && rec.priority >= 1 && rec.priority <= 5 ? 
                                rec.priority : 3
                      })) : 
                      [{
                        category: 'continue' as const,
                        title: 'Maintain current routine',
                        rationale: 'Continue with your current skincare approach',
                        confidence_level: 'low' as const,
                        priority: 1
                      }],
      action_plan: {
        immediate_actions: Array.isArray(parsedInsights.action_plan?.immediate_actions) ? 
                          parsedInsights.action_plan.immediate_actions.slice(0, 5) : 
                          ["Continue current skincare routine"],
        weekly_goals: Array.isArray(parsedInsights.action_plan?.weekly_goals) ? 
                     parsedInsights.action_plan.weekly_goals.slice(0, 5) : 
                     ["Maintain consistent data logging"],
        monitoring_focus: Array.isArray(parsedInsights.action_plan?.monitoring_focus) ? 
                         parsedInsights.action_plan.monitoring_focus.slice(0, 5) : 
                         ["Overall skin health"]
      },
      generated_at: new Date().toISOString(),
      data_period: {
        start_date: fourteenDaysAgo,
        end_date: today,
        days_analyzed: Math.min(14, totalEntries)
      },
      disclaimer: "These insights are AI-generated suggestions based on your logged data and should not replace professional medical advice. Always consult with a dermatologist for serious skin concerns.",
      ...(debug && {
        debug_info: {
          user_data_summary: userDataSummary,
          prompt_used: fullPrompt,
          model_response_raw: rawModelResponse
        }
      })
    }

    // Cache the insights in the database
    try {
      await supabase
        .from('insights')
        .insert({
          user_id: user.id,
          summary: validatedResponse.summary,
          recommendations: validatedResponse.recommendations,
          action_plan: validatedResponse.action_plan,
          data_period: validatedResponse.data_period,
          generated_at: validatedResponse.generated_at,
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24 hour expiry
        })
    } catch (cacheError) {
      console.error('Failed to cache insights:', cacheError)
      // Continue without caching - don't fail the request
    }

    // Return the validated response
    return new Response(
      JSON.stringify(validatedResponse),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Insights generation error:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        code: 'INTERNAL_ERROR',
        details: error.message 
      } as ErrorResponse),
      { 
        status: 500, 
        headers: { 
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json' 
        } 
      }
    )
  }
})
