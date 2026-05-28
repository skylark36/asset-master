export default defineEventHandler(async (event) => {
  const body = await readBody(event).catch(() => ({}))
  const { name, description, currency } = body

  if (!name) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Portfolio name is required'
    })
  }

  const userId = getUserId(event)
  const db = useDB(event)
  const id = crypto.randomUUID()
  const createdAt = Date.now()
  const portCurrency = currency || 'USD'

  await db.prepare(
    'INSERT INTO portfolios (id, user_id, name, description, currency, created_at) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(id, userId, name, description || '', portCurrency, createdAt).run()

  return {
    success: true,
    portfolio: { id, user_id: userId, name, description, currency: portCurrency, created_at: createdAt }
  }
})
