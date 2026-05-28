import type { H3Event } from 'h3'

export async function hashPassword(password: string): Promise<string> {
  const msgBuffer = new TextEncoder().encode(password)
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

export function getUserId(event: H3Event): string {
  // Try session-token cookie first (SSR-compatible)
  const cookieToken = getCookie(event, 'session-token')
  if (cookieToken) {
    return cookieToken
  }

  // Fallback to Bearer token header (REST API compatibility)
  const authHeader = getRequestHeader(event, 'authorization')
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.substring(7)
  }

  // Default fallback for demo/unauthenticated requests (matching original behavior)
  return 'demo-user-123'
}

export function setSessionToken(event: H3Event, userId: string) {
  setCookie(event, 'session-token', userId, {
    httpOnly: false, // Allow client-side Nuxt/JS to read session status
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 30 * 24 * 60 * 60, // 30 days
    path: '/'
  })
}

export function deleteSessionToken(event: H3Event) {
  deleteCookie(event, 'session-token', {
    path: '/'
  })
}
