import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Task 1.5: Secure environment variables
const VERTEX_AI_PROJECT_ID = Deno.env.get('VERTEX_AI_PROJECT_ID') || '';
const VERTEX_AI_LOCATION = Deno.env.get('VERTEX_AI_LOCATION') || 'us-central1';
const VERTEX_AI_MODEL = Deno.env.get('VERTEX_AI_MODEL') || 'gemini-1.5-flash';
const GOOGLE_CLOUD_API_KEY = Deno.env.get('GOOGLE_CLOUD_API_KEY') || '';
const CHAT_RATE_LIMIT_PER_MINUTE = parseInt(Deno.env.get('CHAT_RATE_LIMIT_PER_MINUTE') || '10');
const CHAT_TIMEOUT_MS = parseInt(Deno.env.get('CHAT_TIMEOUT_MS') || '30000');

// API Contract Interfaces

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
  attachments?: ChatAttachment[];
}

interface ChatAttachment {
  type: 'image';
  url: string;
  filename: string;
  size: number;
  mime_type: string;
}

interface ChatRequest {
  messages: ChatMessage[];
  attachments?: ChatAttachment[];
  settings?: {
    personalization_enabled?: boolean;
    stream?: boolean;
  };
  conversation_id?: string;
}

interface ChatStreamChunk {
  type: 'chunk' | 'done' | 'error';
  content?: string;
  conversation_id?: string;
  message_id?: string;
  error?: string;
}

interface ChatResponse {
  message: ChatMessage;
  conversation_id: string;
  message_id: string;
  moderation_passed: boolean;
  tokens_used?: number;
}

interface ErrorResponse {
  error: string;
  code: string;
  details?: any;
}

// Moderation categories
interface ModerationResult {
  passed: boolean;
  categories: string[];
  confidence: number;
  blocked_reason?: string;
}

// Moderation utility functions
async function moderateMessage(content: string): Promise<ModerationResult> {
  // Simple heuristic-based moderation for MVP
  // TODO: Integrate with Google Safety API or similar service
  
  const lowerContent = content.toLowerCase();
  const blockedCategories: string[] = [];
  
  // Check for inappropriate content patterns
  const inappropriatePatterns = [
    /\b(suicide|self.?harm|kill.?myself)\b/i,
    /\b(drug.?abuse|illegal.?drugs)\b/i,
    /\b(violence|harm.?others)\b/i,
    /\b(hate.?speech|discrimination)\b/i
  ];
  
  const medicalAdvicePatterns = [
    /\b(diagnose|diagnosis|prescription|medication|treatment)\b/i,
    /\b(doctor|physician|medical.?advice)\b/i
  ];
  
  for (const pattern of inappropriatePatterns) {
    if (pattern.test(content)) {
      blockedCategories.push('inappropriate_content');
      break;
    }
  }
  
  for (const pattern of medicalAdvicePatterns) {
    if (pattern.test(content)) {
      blockedCategories.push('medical_advice_request');
      break;
    }
  }
  
  return {
    passed: blockedCategories.length === 0,
    categories: blockedCategories,
    confidence: blockedCategories.length > 0 ? 0.8 : 0.1,
    blocked_reason: blockedCategories.length > 0 ? 'heuristic_filter' : undefined
  };
}

function getSafeResponse(categories: string[]): string {
  if (categories.includes('inappropriate_content')) {
    return "I understand you might be going through a difficult time. I'm here to help with skincare questions, but for serious concerns, please reach out to a mental health professional or crisis helpline. Is there something specific about your skincare routine I can help you with instead?";
  }
  
  if (categories.includes('medical_advice_request')) {
    return "I can't provide medical diagnoses or treatment advice. For skin conditions that concern you, it's best to consult with a dermatologist or healthcare provider. However, I'm happy to discuss general skincare routines, product information, or help you track your skin health journey. What would you like to know?";
  }
  
  return "I want to keep our conversation focused on helpful skincare guidance. Let me know how I can assist you with your skincare routine, product questions, or tracking your skin health progress.";
}

function generateConversationId(): string {
  return `conv_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

function generateMessageId(): string {
  return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// Task 1.4: Error handling with retries and backoff
async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelayMs: number = 1000
): Promise<T> {
  let lastError: Error;
  
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      
      if (attempt === maxRetries) {
        throw lastError;
      }
      
      // Exponential backoff with jitter
      const delay = baseDelayMs * Math.pow(2, attempt) + Math.random() * 1000;
      console.log(`Attempt ${attempt + 1} failed, retrying in ${delay}ms:`, error);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  throw lastError!;
}

async function withTimeout<T>(
  fn: () => Promise<T>,
  timeoutMs: number = 30000
): Promise<T> {
  return Promise.race([
    fn(),
    new Promise<T>((_, reject) => 
      setTimeout(() => reject(new Error('Operation timed out')), timeoutMs)
    )
  ]);
}

// Mock Vertex AI call with error handling
async function callVertexAI(messages: ChatMessage[], streaming: boolean = false): Promise<string> {
  // TODO: Replace with actual Vertex AI integration
  // This is a mock implementation for now
  
  return withRetry(async () => {
    return withTimeout(async () => {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Simulate occasional failures for testing retry logic
      if (Math.random() < 0.1) {
        throw new Error('Simulated API failure');
      }
      
      return "I'm here to help with your skincare questions! How can I assist you today?";
    }, 15000); // 15 second timeout
  }, 3, 1000); // 3 retries with 1 second base delay
}

// Task 1.3: SSE Streaming implementation
async function handleStreamingRequest(
  messages: ChatMessage[], 
  attachments: ChatAttachment[] | undefined,
  settings: any,
  conversation_id: string | undefined,
  user: any
): Promise<Response> {
  const convId = conversation_id || generateConversationId();
  const msgId = generateMessageId();
  
  // Create readable stream for SSE
  const stream = new ReadableStream({
    async start(controller) {
      try {
        // Send initial heartbeat
        controller.enqueue(new TextEncoder().encode(`data: ${JSON.stringify({
          type: 'chunk',
          content: '',
          conversation_id: convId,
          message_id: msgId
        } as ChatStreamChunk)}\n\n`));

        // Call Vertex AI with error handling
        const aiResponse = await callVertexAI(messages, true);
        
        for (let i = 0; i < aiResponse.length; i += 5) {
          const chunk = aiResponse.slice(i, i + 5);
          
          controller.enqueue(new TextEncoder().encode(`data: ${JSON.stringify({
            type: 'chunk',
            content: chunk,
            conversation_id: convId,
            message_id: msgId
          } as ChatStreamChunk)}\n\n`));
          
          // Small delay to simulate streaming
          await new Promise(resolve => setTimeout(resolve, 50));
        }
        
        // Send completion message
        controller.enqueue(new TextEncoder().encode(`data: ${JSON.stringify({
          type: 'done',
          conversation_id: convId,
          message_id: msgId
        } as ChatStreamChunk)}\n\n`));
        
        controller.close();
      } catch (error) {
        controller.enqueue(new TextEncoder().encode(`data: ${JSON.stringify({
          type: 'error',
          error: 'Stream processing failed',
          conversation_id: convId,
          message_id: msgId
        } as ChatStreamChunk)}\n\n`));
        controller.close();
      }
    }
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }
  });
}

async function handleRegularRequest(
  messages: ChatMessage[], 
  attachments: ChatAttachment[] | undefined,
  settings: any,
  conversation_id: string | undefined,
  user: any
): Promise<Response> {
  const convId = conversation_id || generateConversationId();
  const msgId = generateMessageId();
  
  // Call Vertex AI with error handling
  const aiResponse = await callVertexAI(messages, false);
  
  const response: ChatResponse = {
    message: {
      role: 'assistant',
      content: aiResponse,
      timestamp: new Date().toISOString()
    },
    conversation_id: convId,
    message_id: msgId,
    moderation_passed: true
  };

  return new Response(
    JSON.stringify(response),
    { 
      status: 200, 
      headers: { 
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json' 
      } 
    }
  );
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
    const requestBody: ChatRequest = await req.json()
    const { messages, attachments, settings, conversation_id } = requestBody

    // Validate required fields
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Messages array is required and cannot be empty', code: 'INVALID_REQUEST' } as ErrorResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Task 1.2: Pre-moderation check and safe response path
    const lastUserMessage = messages[messages.length - 1];
    if (lastUserMessage?.role === 'user') {
      const moderationResult = await moderateMessage(lastUserMessage.content);
      
      if (!moderationResult.passed) {
        // Return safe response for blocked content
        const safeResponse: ChatResponse = {
          message: {
            role: 'assistant',
            content: getSafeResponse(moderationResult.categories),
            timestamp: new Date().toISOString()
          },
          conversation_id: conversation_id || generateConversationId(),
          message_id: generateMessageId(),
          moderation_passed: false
        };

        // Track moderation block analytics
        // TODO: Implement analytics tracking
        console.log('Moderation blocked message:', moderationResult);

        return new Response(
          JSON.stringify(safeResponse),
          { 
            status: 200, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        );
      }
    }

    // Task 1.3: Check if streaming is requested
    const isStreaming = settings?.stream !== false; // Default to streaming
    
    if (isStreaming) {
      // Return SSE stream
      return handleStreamingRequest(messages, attachments, settings, conversation_id, user);
    } else {
      // Return regular JSON response
      return handleRegularRequest(messages, attachments, settings, conversation_id, user);
    }

  } catch (error) {
    console.error('Chat proxy error:', error)
    
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
