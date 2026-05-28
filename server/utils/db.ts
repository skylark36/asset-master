import type { H3Event } from 'h3'

export function useDB(event: H3Event) {
  // Under Cloudflare Workers / Pages, Nitro binds the cloudflare env to event.context.cloudflare
  const db = event.context.cloudflare?.env?.DB
  if (!db) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Cloudflare D1 Database binding "DB" is not available.'
    })
  }
  return db
}
