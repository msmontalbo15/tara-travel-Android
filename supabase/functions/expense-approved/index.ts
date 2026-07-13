import { serve } from 'std/http/server.ts'
import { createClient } from '@supabase/supabase-js'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const body = await req.json()
    const { record, old_record } = body

    if (!record || !old_record) {
      return new Response('Invalid payload', { status: 400 })
    }

    if (record.status === old_record.status) {
      return new Response('No status change', { status: 200 })
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('push_token, display_name')
      .eq('id', record.paid_by_user_id)
      .single()

    if (error || !user?.push_token) {
      return new Response('No push token', { status: 200 })
    }

    const isApproved = record.status === 'approved'

    const amountFormatted = `₱${Number(record.amount).toFixed(2)}`

    const title = isApproved
      ? '✅ Expense approved!'
      : '❌ Expense rejected'

    const bodyText = isApproved
      ? `${record.description} (${amountFormatted}) was approved.`
      : `${record.description} was rejected. Note: ${record.rejection_note ?? 'No reason given.'}`

    const pushRes = await fetch('https://exp.host/--/api/v2/push/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        to: user.push_token,
        title,
        body: bodyText,
        data: {
          type: 'expense_status',
          expenseId: record.id,
          tripId: record.trip_id,
        },
        sound: 'default',
      }),
    })

    const pushJson = await pushRes.json()

    if (!pushRes.ok) {
      console.error('Push failed:', pushJson)
    }

    await supabase.from('notifications').insert({
      user_id: record.paid_by_user_id,
      trip_id: record.trip_id,
      type: isApproved ? 'expense_approved' : 'expense_rejected',
      title,
      body: bodyText,
      data: { expenseId: record.id },
      read: false,
    })

    return new Response(JSON.stringify({ success: true }), {
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