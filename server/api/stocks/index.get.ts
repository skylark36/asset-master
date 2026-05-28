export default defineEventHandler(async (event) => {
  const symbolsParam = getQuery(event).symbols as string
  if (!symbolsParam) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Missing required query parameter "symbols"'
    })
  }

  const symbols = symbolsParam.split(',').map(s => s.trim()).filter(Boolean)
  if (symbols.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid or empty symbols parameter'
    })
  }

  const prices = await fetchStockPrices(event, symbols)
  return { success: true, prices }
})
