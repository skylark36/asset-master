import type { Portfolio } from '~/server/types'

export default defineEventHandler(async (event) => {
  const portfolioId = getRouterParam(event, 'id')
  if (!portfolioId) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Portfolio ID is required'
    })
  }

  const body = await readBody(event).catch(() => ({}))
  const { name, description, currency } = body

  const userId = getUserId(event)
  const db = useDB(event)

  // Verify the portfolio exists and belongs to the user
  const existing = await db.prepare(
    'SELECT * FROM portfolios WHERE id = ? AND user_id = ?'
  ).bind(portfolioId, userId).first<Portfolio>()

  if (!existing) {
    throw createError({
      statusCode: 404,
      statusMessage: 'Portfolio not found or unauthorized'
    })
  }

  const newName = name || existing.name
  const newDesc = description !== undefined ? description : existing.description
  const newCurrency = currency || existing.currency

  await db.prepare(
    'UPDATE portfolios SET name = ?, description = ?, currency = ? WHERE id = ?'
  ).bind(newName, newDesc, newCurrency.toUpperCase(), portfolioId).run()

  return {
    success: true,
    portfolio: {
      id: portfolioId,
      user_id: userId,
      name: newName,
      description: newDesc,
      currency: newCurrency.toUpperCase(),
      created_at: existing.created_at
    }
  }
})
