import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

serve(async (req) => {
  try {
    // Get the database payload from the webhook
    const payload = await req.json()
    const record = payload.record // The updated report row

    // Check if the status was changed to 'Resolved' and the user provided an email
    if (payload.type === 'UPDATE' && record.status === 'Resolved' && record.email) {
      
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`
        },
        body: JSON.stringify({
          from: 'Lumina Lanka <onboarding@resend.dev>', // Use your verified domain here later
          to: record.email,
          subject: 'Update: Your Streetlight Report is Resolved!',
          html: `
            <div style="font-family: sans-serif; color: #333;">
              <h2>Good news, ${record.name}!</h2>
              <p>The streetlight issue you reported (<strong>${record.issue_type}</strong>) has been successfully resolved by our maintenance team.</p>
              <p>Thank you for helping us keep Maharagama bright and safe.</p>
              <br/>
              <p>Best regards,<br/><strong>Maharagama Urban Council</strong></p>
            </div>
          `
        })
      })

      const data = await res.json()
      return new Response(JSON.stringify(data), { status: 200 })
    }

    return new Response("Ignored: Not a resolution or no email provided.", { status: 200 })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
