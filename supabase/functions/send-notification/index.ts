import { serve } from 'std/http/server.ts'
import { createClient } from '@supabase/supabase-js'

const EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const payload = await req.json()
    const { userId, title, body, data = {}, type = 'general', tripId = null } = payload

    if (!userId || !title || !body) {
      return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400 })
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('push_token')
      .eq('id', userId)
      .single()

    if (error || !user?.push_token) {
      return new Response(JSON.stringify({ error: 'No push token found' }), { status: 404 })
    }

    const pushRes = await fetch(EXPO_PUSH_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        to: user.push_token,
        title,
        body,
        data: { ...data, type, tripId },
        sound: 'default',
        priority: type === 'navigation' ? 'high' : 'default',
      }),
    })

    const pushJson = await pushRes.json()

    if (!pushRes.ok) {
      console.error('Push error:', pushJson)
    }

    await supabase.from('notifications').insert({
      user_id: userId,
      trip_id: tripId,
      type,
      title,
      body,
      data,
      read: false,
    })

    return new Response(JSON.stringify({ success: true, pushJson }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err: unknown) {
    console.error(err)
    const errorMessage = err instanceof Error ? err.message : 'Unknown error'
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: corsHeaders,
    })
  }
})