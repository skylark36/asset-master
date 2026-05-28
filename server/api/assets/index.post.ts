export default defineEventHandler(async (event) => {
  const body = await readBody(event).catch(() => ({}))
  const { portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker } = body

  if (!portfolio_id || !symbol || !name || quantity === undefined || purchase_price === undefined) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Missing required fields: portfolio_id, symbol, name, quantity, purchase_price'
    })
  }

  const db = useDB(event)
  const id = crypto.randomUUID()
  const date = purchase_date || Date.now()
  const brokerVal = broker || 'Other'

  await db.prepare(
    `INSERT INTO assets (id, portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker) 
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(id, portfolio_id, symbol.toUpperCase(), name, Number(quantity), Number(purchase_price), date, brokerVal).run()

  return {
    success: true,
    asset: { id, portfolio_id, symbol: symbol.toUpperCase(), name, quantity: Number(quantity), purchase_price: Number(purchase_price), purchase_date: date, broker: brokerVal }
  }
})
