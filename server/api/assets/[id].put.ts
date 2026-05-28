export default defineEventHandler(async (event) => {
  const assetId = getRouterParam(event, 'id')
  if (!assetId) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Asset ID is required'
    })
  }

  const body = await readBody(event).catch(() => ({}))
  const { portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker } = body

  if (!symbol || !name || quantity === undefined || purchase_price === undefined) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Missing required fields: symbol, name, quantity, purchase_price'
    })
  }

  const db = useDB(event)
  const date = purchase_date || Date.now()
  const brokerVal = broker || 'Other'

  const result = await db.prepare(
    `UPDATE assets SET symbol = ?, name = ?, quantity = ?, purchase_price = ?, purchase_date = ?, broker = ? 
     WHERE id = ?`
  ).bind(symbol.toUpperCase(), name, Number(quantity), Number(purchase_price), date, brokerVal, assetId).run()

  if (result.meta.changes === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'Asset holding not found'
    })
  }

  return {
    success: true,
    asset: { id: assetId, portfolio_id, symbol: symbol.toUpperCase(), name, quantity: Number(quantity), purchase_price: Number(purchase_price), purchase_date: date, broker: brokerVal }
  }
})
