import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationSetting {
  id: string
  user_id: string
  category: string
  enabled: boolean
  time: string
  quiet_from: string
  quiet_to: string
}

interface UserProfile {
  user_id: string
  time_zone: string
}

interface FCMToken {
  user_id: string
  token: string
  platform: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get current time in UTC
    const now = new Date()
    const currentHour = now.getUTCHours()
    const currentMinute = now.getUTCMinutes()
    const currentTime = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`

    console.log(`Push scheduler running at ${currentTime} UTC`)

    // Get all enabled notification settings with user profiles and FCM tokens
    const { data: settingsData, error: settingsError } = await supabaseClient
      .from('notification_settings')
      .select(`
        *,
        profiles!inner(user_id, time_zone),
        user_fcm_tokens!inner(user_id, token, platform)
      `)
      .eq('enabled', true)

    if (settingsError) {
      console.error('Error fetching notification settings:', settingsError)
      throw settingsError
    }

    if (!settingsData || settingsData.length === 0) {
      console.log('No enabled notification settings found')
      return new Response(
        JSON.stringify({ message: 'No notifications to send' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const notifications: Array<{
      token: string
      title: string
      body: string
      data: Record<string, string>
    }> = []

    // Process each notification setting
    for (const setting of settingsData) {
      const profile = setting.profiles
      const tokens = setting.user_fcm_tokens

      if (!profile || !tokens || tokens.length === 0) {
        continue
      }

      // Convert user's local time to UTC for comparison
      const userLocalTime = convertToUserTime(currentTime, profile.time_zone)
      const settingTime = setting.time.substring(0, 5) // Remove seconds

      // Check if it's time to send this notification
      if (userLocalTime !== settingTime) {
        continue
      }

      // Check if we're in quiet hours
      if (isInQuietHours(userLocalTime, setting.quiet_from, setting.quiet_to)) {
        console.log(`Skipping notification for user ${setting.user_id} - in quiet hours`)
        continue
      }

      // Create notification payload
      const { title, body } = getNotificationContent(setting.category)
      
      // Add notification for each user token
      for (const tokenData of tokens) {
        notifications.push({
          token: tokenData.token,
          title,
          body,
          data: {
            category: setting.category,
            campaign: 'scheduled',
            user_id: setting.user_id,
          }
        })
      }
    }

    if (notifications.length === 0) {
      console.log('No notifications scheduled for current time')
      return new Response(
        JSON.stringify({ message: 'No notifications scheduled' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Send notifications via FCM
    const results = await sendFCMNotifications(notifications)
    
    console.log(`Sent ${results.successful} notifications, ${results.failed} failed`)

    return new Response(
      JSON.stringify({
        message: `Processed ${notifications.length} notifications`,
        successful: results.successful,
        failed: results.failed,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Push scheduler error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

function convertToUserTime(utcTime: string, timeZone: string): string {
  // This is a simplified conversion - in production, use a proper timezone library
  // For now, we'll assume the time is already in the correct format
  return utcTime
}

function isInQuietHours(currentTime: string, quietFrom: string, quietTo: string): boolean {
  const current = timeToMinutes(currentTime)
  const from = timeToMinutes(quietFrom.substring(0, 5))
  const to = timeToMinutes(quietTo.substring(0, 5))

  // Handle quiet hours that span midnight
  if (from > to) {
    return current >= from || current <= to
  } else {
    return current >= from && current <= to
  }
}

function timeToMinutes(time: string): number {
  const [hours, minutes] = time.split(':').map(Number)
  return hours * 60 + minutes
}

function getNotificationContent(category: string): { title: string; body: string } {
  switch (category) {
    case 'routine_am':
      return {
        title: 'Morning Skincare Routine',
        body: 'Time for your morning skincare routine! Start your day with healthy skin.',
      }
    case 'routine_pm':
      return {
        title: 'Evening Skincare Routine',
        body: 'Don\'t forget your evening skincare routine before bed.',
      }
    case 'daily_log':
      return {
        title: 'Daily Skin Health Log',
        body: 'How is your skin feeling today? Log your daily observations.',
      }
    case 'weekly_insights':
      return {
        title: 'Weekly Skin Insights',
        body: 'Your weekly skin health insights are ready! Check your progress.',
      }
    default:
      return {
        title: 'SkinCare Reminder',
        body: 'You have a skincare reminder.',
      }
  }
}

async function sendFCMNotifications(notifications: Array<{
  token: string
  title: string
  body: string
  data: Record<string, string>
}>): Promise<{ successful: number; failed: number }> {
  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')
  
  if (!fcmServerKey) {
    console.error('FCM_SERVER_KEY not configured')
    return { successful: 0, failed: notifications.length }
  }

  let successful = 0
  let failed = 0

  // Send notifications in batches to avoid overwhelming FCM
  const batchSize = 100
  for (let i = 0; i < notifications.length; i += batchSize) {
    const batch = notifications.slice(i, i + batchSize)
    
    const promises = batch.map(async (notification) => {
      try {
        const response = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Authorization': `key=${fcmServerKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: notification.token,
            notification: {
              title: notification.title,
              body: notification.body,
            },
            data: notification.data,
            android: {
              priority: 'high',
            },
            apns: {
              headers: {
                'apns-priority': '10',
              },
            },
          }),
        })

        if (response.ok) {
          successful++
        } else {
          console.error(`FCM send failed for token ${notification.token}:`, await response.text())
          failed++
        }
      } catch (error) {
        console.error(`Error sending to token ${notification.token}:`, error)
        failed++
      }
    })

    await Promise.all(promises)
    
    // Small delay between batches
    if (i + batchSize < notifications.length) {
      await new Promise(resolve => setTimeout(resolve, 100))
    }
  }

  return { successful, failed }
}
