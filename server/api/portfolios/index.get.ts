import type { Portfolio } from '~/server/types'

export default defineEventHandler(async (event) => {
  const userId = getUserId(event)
  const db = useDB(event)

  const { results } = await db.prepare(
    'SELECT * FROM portfolios WHERE user_id = ? ORDER BY name ASC'
  ).bind(userId).all<Portfolio>()

  return { success: true, portfolios: results || [] }
})
