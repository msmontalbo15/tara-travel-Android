import { serve } from 'std/http/server.ts'
import { createClient } from '@supabase/supabase-js'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PushPayload {
  userId?: string
  topic?: string
  title: string
  body: string
  data?: Record<string, any>
  targetScreen?: string
  targetItemId?: string
  tripId?: string
  priority?: 'high' | 'normal'
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')

    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const payload: PushPayload = await req.json()
    const { userId, topic, title, body, data = {}, targetScreen, targetItemId, tripId, priority = 'high' } = payload

    if (!title || !body || (!userId && !topic)) {
      return new Response(
        JSON.stringify({ error: 'Missing required push fields (title, body, and either userId or topic)' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let registrationToken: string | null = null

    if (userId) {
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('id', userId)
        .maybeSingle()

      if (userError || !user?.fcm_token) {
        console.warn(`[push-relay] No active FCM registration token for user: ${userId}`)
        // Fall back to storing in-app notification record anyway
      } else {
        registrationToken = user.fcm_token
      }
    }

    // Standardized payload matching Tara Travel's NotificationPayload
    const formattedData: Record<string, string> = {
      title,
      body,
      trip_id: tripId || data.tripId || data.trip_id || '',
      target_screen: targetScreen || data.targetScreen || data.target_screen || 'notifications',
      target_item_id: targetItemId || data.targetItemId || data.target_item_id || '',
      priority,
      timestamp: new Date().toISOString(),
    }

    // Include extra metadata
    for (const [k, v] of Object.entries(data)) {
      if (typeof v === 'string') {
        formattedData[k] = v
      } else if (v !== null && v !== undefined) {
        formattedData[k] = JSON.stringify(v)
      }
    }

    let fcmResponse: any = null

    // Send via FCM if server key is configured
    if (fcmServerKey && (registrationToken || topic)) {
      const fcmMessage = {
        to: topic ? `/topics/${topic}` : registrationToken,
        priority: priority === 'high' ? 'high' : 'normal',
        notification: {
          title,
          body,
          sound: 'default',
          channel_id: 'tara_travel_high_priority',
        },
        data: formattedData,
      }

      const res = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `key=${fcmServerKey}`,
        },
        body: JSON.stringify(fcmMessage),
      })

      fcmResponse = await res.json()
      console.log('[push-relay] FCM dispatch status:', res.status, fcmResponse)
    }

    // Persist to notifications table for user notification center history
    if (userId) {
      await supabase.from('notifications').insert({
        user_id: userId,
        trip_id: tripId,
        type: targetScreen || 'general',
        title,
        body,
        data: formattedData,
        read: false,
      })
    }

    return new Response(
      JSON.stringify({
        success: true,
        dispatchedToFcm: Boolean(fcmServerKey && (registrationToken || topic)),
        fcmResponse,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (err: unknown) {
    console.error('[push-relay] Unexpected error:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
