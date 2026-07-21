// @ts-ignore: Deno import
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// @ts-ignore: Deno import
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

serve(async (req: Request) => {
  try {
    const { record } = await req.json()
    
    // record is the new row inserted in notifications table
    const senderId = record.sender_id
    const receiverId = record.receiver_id
    const type = record.type
    const metadata = record.metadata ?? {}

    const supabaseUrl = (globalThis as any).Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceRoleKey = (globalThis as any).Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const firebaseServiceAccount = JSON.parse((globalThis as any).Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}')

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

    // 1. Get recipient's FCM token and profile
    const { data: recipientProfile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', receiverId)
      .single()

    const fcmToken = recipientProfile?.fcm_token
    if (!fcmToken) {
      console.log('Recipient has no FCM token registered')
      return new Response(JSON.stringify({ status: 'no_token' }), { status: 200 })
    }

    // 2. Get sender's profile (name & avatar)
    const { data: senderProfile } = await supabase
      .from('profiles')
      .select('first_name, last_name, avatar_url')
      .eq('id', senderId)
      .single()

    const firstName = senderProfile?.first_name ?? ''
    const lastName = senderProfile?.last_name ?? ''
    const senderName = `${firstName} ${lastName}`.trim() || 'Someone'
    const senderAvatar = senderProfile?.avatar_url ?? ''

    // 3. Construct notification title and body text based on type (English)
    let titleText = 'More'
    let bodyText = ''

    if (type === 'mention') {
      titleText = 'New Mention 🏷️'
      bodyText = `${senderName} mentioned you in a story.`
    } else if (type === 'follow') {
      titleText = 'New Follower 👋'
      bodyText = `${senderName} started following you.`
    } else if (type === 'like') {
      titleText = 'New Like ❤️'
      bodyText = `${senderName} liked your check-in.`
    } else if (type === 'comment') {
      titleText = 'New Comment 💬'
      bodyText = `${senderName} commented on your check-in.`
    } else {
      bodyText = `You have a new notification from ${senderName}.`
    }

    // 4. Calculate recipient's total unread count (unread notifications + unread chat messages)
    const { count: unreadNotifs } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('receiver_id', receiverId)
      .eq('read', false)

    const { data: userThreads } = await supabase
      .from('chat_threads')
      .select('id')
      .or(`user1_id.eq.${receiverId},user2_id.eq.${receiverId}`)

    let unreadMessages = 0
    if (userThreads && userThreads.length > 0) {
      const threadIds = userThreads.map((t: any) => t.id)
      const { count: unreadMsgs } = await supabase
        .from('chat_messages')
        .select('*', { count: 'exact', head: true })
        .in('thread_id', threadIds)
        .neq('sender_id', receiverId)
        .eq('is_read', false)
      
      unreadMessages = unreadMsgs ?? 0
    }

    const totalUnreadBadge = (unreadNotifs ?? 0) + unreadMessages

    // 5. Send FCM Notification using Firebase v1 REST API
    const accessToken = await getAccessToken(firebaseServiceAccount)
    
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: titleText,
          body: bodyText,
        },
        data: {
          type: type,
          senderId: senderId,
          notificationId: record.id ?? '',
        },
        apns: {
          payload: {
            aps: {
              "mutable-content": 1,
              alert: {
                title: titleText,
                body: bodyText,
              },
              sound: "default",
              badge: totalUnreadBadge,
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
