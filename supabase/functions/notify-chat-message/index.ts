// Supabase Edge Function: notify-chat-message
// Triggered by Database Webhook on INSERT into chat_messages
// Sends FCM push notification to recipient via Firebase Cloud Messaging v1 API

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL          = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const FCM_PROJECT_ID        = Deno.env.get('FCM_PROJECT_ID') ?? ''
// Full service account JSON string stored as secret
const FCM_SERVICE_ACCOUNT   = Deno.env.get('FCM_SERVICE_ACCOUNT') ?? ''

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

// ── JWT helpers for Google OAuth2 ────────────────────────────────────────────

function base64urlEncode(data: string): string {
  return btoa(data).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function base64urlEncodeBytes(bytes: ArrayBuffer): string {
  const arr = new Uint8Array(bytes)
  let str = ''
  arr.forEach(b => str += String.fromCharCode(b))
  return base64urlEncode(str)
}

async function getGoogleAccessToken(): Promise<string> {
  const sa = JSON.parse(FCM_SERVICE_ACCOUNT)
  const now = Math.floor(Date.now() / 1000)

  const header  = base64urlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = base64urlEncode(JSON.stringify({
    iss:   sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud:   'https://oauth2.googleapis.com/token',
    iat:   now,
    exp:   now + 3600,
  }))

  const signingInput = `${header}.${payload}`

  // Import RSA private key
  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  const keyBytes = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  )

  const jwt = `${signingInput}.${base64urlEncodeBytes(signature)}`

  // Exchange JWT for access token
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenRes.json()
  if (!tokenData.access_token) throw new Error(`Token error: ${JSON.stringify(tokenData)}`)
  return tokenData.access_token
}

// ── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  try {
    const body   = await req.json()
    const record = body.record as {
      id: string
      chat_id: string
      sender_id: string
      text: string
      image_url: string | null
    }

    if (!record?.chat_id || !record?.sender_id) {
      return new Response('Missing fields', { status: 400 })
    }

    // 1. Fetch chat participants
    const { data: chat, error: chatErr } = await supabase
      .from('chats')
      .select('buyer_id, seller_id, listing_id')
      .eq('id', record.chat_id)
      .single()

    if (chatErr || !chat) return new Response('Chat not found', { status: 404 })

    const recipientId = record.sender_id === chat.buyer_id
      ? chat.seller_id
      : chat.buyer_id

    // 2. Fetch sender + recipient profiles
    const { data: profiles, error: profileErr } = await supabase
      .from('profiles')
      .select('id, fcm_token, name, is_chat_banned')
      .in('id', [record.sender_id, recipientId])

    if (profileErr || !profiles) return new Response('Profiles not found', { status: 404 })

    const sender    = profiles.find((p: any) => p.id === record.sender_id)
    const recipient = profiles.find((p: any) => p.id === recipientId)

    if (!recipient?.fcm_token) {
      return new Response('No FCM token', { status: 200 })
    }

    // Don't notify if sender is banned
    if (sender?.is_chat_banned) {
      return new Response('Sender is banned', { status: 200 })
    }

    // 3. Fetch listing title
    const { data: listing } = await supabase
      .from('listings')
      .select('title')
      .eq('id', chat.listing_id)
      .single()

    const senderName   = sender?.name ?? 'Someone'
    const msgPreview   = record.image_url ? '📷 Photo' : (record.text?.slice(0, 100) ?? '')
    const listingTitle = listing?.title ?? 'a listing'

    // 4. Get Google OAuth2 token
    const accessToken = await getGoogleAccessToken()

    // 5. Send FCM v1 notification
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type':  'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: recipient.fcm_token,
            notification: {
              title: `${senderName} — ${listingTitle}`,
              body:  msgPreview,
            },
            data: {
              chat_id: record.chat_id,
              type:    'chat_message',
            },
            android: {
              priority: 'high',
              notification: {
                channel_id: 'chat_messages',
              },
            },
            apns: {
              payload: {
                aps: { badge: 1, sound: 'default' },
              },
            },
          },
        }),
      },
    )

    const result = await fcmRes.json()

    // If token is invalid/unregistered, clear it to force refresh on next app open.
    const fcmErrorCode =
      result?.error?.details?.[0]?.errorCode ??
      result?.error?.details?.find?.((d: any) => d?.errorCode)?.errorCode
    if (fcmErrorCode === 'UNREGISTERED') {
      await supabase
        .from('profiles')
        .update({ fcm_token: null })
        .eq('id', recipientId)
      return new Response(
        JSON.stringify({
          status: 'stale_token_cleared',
          recipient_id: recipientId,
          fcm_error: 'UNREGISTERED',
        }),
        { status: 200 },
      )
    }

    return new Response(JSON.stringify(result), { status: 200 })

  } catch (err) {
    return new Response(`Error: ${err}`, { status: 500 })
  }
})
