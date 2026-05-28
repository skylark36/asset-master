import type { Portfolio, Asset } from '~/server/types'

export default defineEventHandler(async (event) => {
  const portfolioId = getRouterParam(event, 'id')
  if (!portfolioId) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Portfolio ID is required'
    })
  }

  const query = getQuery(event)
  const brokerParam = query.broker as string

  const userId = getUserId(event)
  const db = useDB(event)

  // 1. Verify portfolio exists and belongs to user
  const portfolio = await db.prepare(
    'SELECT * FROM portfolios WHERE id = ? AND user_id = ?'
  ).bind(portfolioId, userId).first<Portfolio>()

  if (!portfolio) {
    throw createError({
      statusCode: 404,
      statusMessage: 'Portfolio not found or unauthorized'
    })
  }

  const baseCurrency = portfolio.currency || 'USD'

  // 2. Generate date range for the last 30 days
  const days = 30
  const dates: string[] = []
  const now = new Date()
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000)
    dates.push(d.toISOString().split('T')[0])
  }

  // 3. Fetch all assets inside the portfolio (filtered by broker if requested)
  let queryStr = 'SELECT * FROM assets WHERE portfolio_id = ?'
  const queryParams: any[] = [portfolioId]

  if (brokerParam && brokerParam !== 'All') {
    queryStr += ' AND broker = ?'
    queryParams.push(brokerParam)
  }

  queryStr += ' ORDER BY purchase_date ASC'

  const { results: assets } = await db.prepare(queryStr)
    .bind(...queryParams)
    .all<Asset>()

  if (!assets || assets.length === 0) {
    // Empty portfolio: return trend with 0 values
    const trend = dates.map(d => ({ date: d, value: 0 }))
    return { success: true, trend }
  }

  // 4. Fetch real-time stock prices to get their currencies
  const distinctSymbols = Array.from(new Set(assets.map(a => a.symbol)))
  const stockPrices = await fetchStockPrices(event, distinctSymbols)

  // Find required FX conversion pairs
  const conversionPairs: string[] = []
  const symbolCurrencyMap: Record<string, string> = {}

  for (const symbol of distinctSymbols) {
    const liveData = stockPrices[symbol]
    const assetCurrency = liveData?.currency || 'USD'
    symbolCurrencyMap[symbol] = assetCurrency
    if (assetCurrency !== baseCurrency) {
      conversionPairs.push(`${assetCurrency}${baseCurrency}=X`.toUpperCase())
    }
  }

  // 5. Fetch historical prices for assets and FX conversion pairs in parallel
  const symbolPricesMap: Record<string, Record<string, number>> = {}
  const allQuerySymbols = [...distinctSymbols, ...Array.from(new Set(conversionPairs))]

  const promises = allQuerySymbols.map(async (symbol) => {
    const prices = await getHistoricalPrices(event, symbol, dates)
    symbolPricesMap[symbol] = prices
  })
  await Promise.all(promises)

  // 6. Aggregate valuation for each date
  const trend = dates.map((dateStr) => {
    const endOfDayTimestamp = new Date(dateStr + 'T23:59:59.999Z').getTime()
    let dailyValuation = 0
    const isToday = dateStr === dates[dates.length - 1]

    for (const asset of assets) {
      // Count asset only if it was purchased on or before this day
      if (asset.purchase_date <= endOfDayTimestamp) {
        const symbolPrices = symbolPricesMap[asset.symbol] || {}

        // If it's today, prioritize the live/real-time stock price from fetchStockPrices
        let price = symbolPrices[dateStr]
        if (isToday) {
          const liveData = stockPrices[asset.symbol]
          if (liveData?.price !== undefined) {
            price = liveData.price
          }
        }
        if (price === undefined || price === null) {
          price = asset.purchase_price
        }

        // Convert price to portfolio base currency if necessary
        const assetCurrency = symbolCurrencyMap[asset.symbol] || 'USD'
        let priceInBase = price
        if (assetCurrency !== baseCurrency) {
          const pair = `${assetCurrency}${baseCurrency}=X`.toUpperCase()

          // If it's today, prioritize the live exchange rate
          let rate = symbolPricesMap[pair]?.[dateStr]
          if (isToday) {
            const liveRateData = stockPrices[pair]
            if (liveRateData?.price !== undefined) {
              rate = liveRateData.price
            }
          }
          if (rate === undefined || rate === null) {
            rate = 1.0
          }

          priceInBase = price * rate
        }

        dailyValuation += asset.quantity * priceInBase
      }
    }

    return {
      date: dateStr,
      value: Number(dailyValuation.toFixed(2))
    }
  })

  return { success: true, trend }
})
