// @ts-ignore: Deno import
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// @ts-ignore: Deno import
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

serve(async (req: Request) => {
  try {
    const { record } = await req.json()
    
    // record is the new message row inserted in chat_messages table
    const senderId = record.sender_id
    const threadId = record.thread_id
    const messageType = record.message_type
    const content = record.content

    const supabaseUrl = (globalThis as any).Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceRoleKey = (globalThis as any).Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const firebaseServiceAccount = JSON.parse((globalThis as any).Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}')

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

    // 1. Get thread members to find the recipient
    const { data: thread } = await supabase
      .from('chat_threads')
      .select('user1_id, user2_id')
      .eq('id', threadId)
      .single()

    if (!thread) throw new Error('Thread not found')

    const recipientId = thread.user1_id === senderId ? thread.user2_id : thread.user1_id

    // 2. Get recipient's FCM token and profile
    const { data: recipientProfile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', recipientId)
      .single()

    const fcmToken = recipientProfile?.fcm_token
    if (!fcmToken) {
      console.log('Recipient has no FCM token registered')
      return new Response(JSON.stringify({ status: 'no_token' }), { status: 200 })
    }

    // 3. Get sender's name and avatar
    const { data: senderProfile } = await supabase
      .from('profiles')
      .select('first_name, last_name, avatar_url')
      .eq('id', senderId)
      .single()

    const firstName = senderProfile?.first_name ?? ''
    const lastName = senderProfile?.last_name ?? ''
    const senderName = `${firstName} ${lastName}`.trim() || 'Someone'
    const senderAvatar = senderProfile?.avatar_url ?? ''

    // 4. Construct body text
    let bodyText = ''
    if (messageType === 'text') {
      bodyText = content
    } else if (messageType === 'audio') {
      bodyText = '🎙️ Voice Message'
    } else if (messageType === 'image') {
      bodyText = '📷 Photo'
    } else {
      bodyText = 'Sent a message'
    }

    // 5. Send FCM Notification using Firebase v1 REST API
    const accessToken = await getAccessToken(firebaseServiceAccount)
    
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: senderName,
          body: bodyText,
        },
        data: {
          threadId: threadId,
        },
        apns: {
          payload: {
            aps: {
              "mutable-content": 1,
              alert: {
                title: senderName,
                body: bodyText,
              },
              sound: "default",
            },
          },
          fcm_options: {
            image: senderAvatar,
          },
        },
      },
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${firebaseServiceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      }
    )

    const responseData = await response.json()
    console.log('FCM Response:', responseData)

    return new Response(JSON.stringify({ success: true, response: responseData }), { status: 200 })
  } catch (error) {
    console.error('Error sending notification:', error)
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: errorMessage }), { status: 500 })
  }
})

// Helper to get Google OAuth2 Access Token using Service Account JWT
async function getAccessToken(serviceAccount: any): Promise<string> {
  const jwtHeader = { alg: 'RS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  
  const jwtClaim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  // Helper to base64url encode
  const encodeB64 = (obj: any) => {
    const json = JSON.stringify(obj)
    const binString = new TextEncoder().encode(json)
    return btoa(String.fromCharCode(...binString))
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
  }

  const headerEncoded = encodeB64(jwtHeader)
  const claimEncoded = encodeB64(jwtClaim)
  const stringToSign = `${headerEncoded}.${claimEncoded}`

  // Sign JWT using Web Crypto API and the private key
  const pem = serviceAccount.private_key
  const pemHeader = "-----BEGIN PRIVATE KEY-----"
  const pemFooter = "-----END PRIVATE KEY-----"
  const pemBody = pem
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "")
  
  const binaryDerString = atob(pemBody)
  const binaryDer = new Uint8Array(binaryDerString.length)
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i)
  }

  const key = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(stringToSign)
  )

  const signatureArray = new Uint8Array(signatureBuffer)
  const signatureEncoded = btoa(String.fromCharCode(...signatureArray))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')

  const jwt = `${stringToSign}.${signatureEncoded}`

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const data = await response.json()
  return data.access_token
}
