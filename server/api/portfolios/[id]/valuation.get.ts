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

  const db = useDB(event)

  // 1. Fetch portfolio to get base currency
  const portfolio = await db.prepare(
    'SELECT * FROM portfolios WHERE id = ?'
  ).bind(portfolioId).first<Portfolio>()

  const baseCurrency = portfolio?.currency || 'USD'

  // 2. Fetch assets in portfolio
  let queryStr = 'SELECT * FROM assets WHERE portfolio_id = ?'
  const queryParams: any[] = [portfolioId]

  if (brokerParam && brokerParam !== 'All') {
    queryStr += ' AND broker = ?'
    queryParams.push(brokerParam)
  }

  const { results: assets } = await db.prepare(queryStr)
    .bind(...queryParams)
    .all<Asset>()

  if (!assets || assets.length === 0) {
    return {
      success: true,
      valuation: {
        portfolioId,
        currency: baseCurrency,
        totalCostBasis: 0,
        totalCurrentValue: 0,
        totalProfitLoss: 0,
        totalProfitLossPercentage: 0,
        holdings: []
      }
    }
  }

  // 3. Fetch live stock prices for all distinct tickers
  const distinctSymbols = Array.from(new Set(assets.map(a => a.symbol)))
  const stockPrices = await fetchStockPrices(event, distinctSymbols)

  // Check if any asset requires currency conversion
  const conversionPairs: string[] = []
  for (const asset of assets) {
    const liveData = stockPrices[asset.symbol]
    const assetCurrency = liveData?.currency || 'USD'
    if (assetCurrency !== baseCurrency) {
      conversionPairs.push(`${assetCurrency}${baseCurrency}=X`.toUpperCase())
    }
  }

  // Fetch currency conversion FX rates in parallel
  if (conversionPairs.length > 0) {
    const distinctPairs = Array.from(new Set(conversionPairs))
    const fxRates = await fetchStockPrices(event, distinctPairs)
    Object.assign(stockPrices, fxRates)
  }

  // 4. Compute dynamic valuations grouped by broker and symbol
  let totalCostBasis = 0
  let totalCurrentValue = 0

  const groupedMap = new Map<string, {
    broker: string;
    symbol: string;
    name: string;
    quantity: number;
    totalCostBasisInBase: number;
    totalCostBasisInLocal: number;
    latestPurchaseDate: number;
  }>()

  for (const asset of assets) {
    const livePriceData = stockPrices[asset.symbol]
    const assetCurrency = livePriceData?.currency || 'USD'

    let rate = 1.0
    if (assetCurrency !== baseCurrency) {
      const pair = `${assetCurrency}${baseCurrency}=X`.toUpperCase()
      rate = stockPrices[pair]?.price || 1.0
    }

    const localPurchasePrice = asset.purchase_price
    const convertedPurchasePrice = localPurchasePrice * rate
    const costBasisInBase = asset.quantity * convertedPurchasePrice

    const key = `${asset.broker}_${asset.symbol}`

    if (!groupedMap.has(key)) {
      groupedMap.set(key, {
        broker: asset.broker,
        symbol: asset.symbol,
        name: asset.name,
        quantity: asset.quantity,
        totalCostBasisInBase: costBasisInBase,
        totalCostBasisInLocal: asset.quantity * localPurchasePrice,
        latestPurchaseDate: asset.purchase_date,
      })
    } else {
      const existing = groupedMap.get(key)!
      existing.quantity += asset.quantity
      existing.totalCostBasisInBase += costBasisInBase
      existing.totalCostBasisInLocal += asset.quantity * localPurchasePrice
      if (asset.purchase_date > existing.latestPurchaseDate) {
        existing.latestPurchaseDate = asset.purchase_date
      }
    }
  }

  const holdingsList = Array.from(groupedMap.values()).map((group) => {
    const livePriceData = stockPrices[group.symbol]
    const assetCurrency = livePriceData?.currency || 'USD'

    let rate = 1.0
    if (assetCurrency !== baseCurrency) {
      const pair = `${assetCurrency}${baseCurrency}=X`.toUpperCase()
      rate = stockPrices[pair]?.price || 1.0
    }

    const localCurrentPrice = livePriceData ? livePriceData.price : (group.quantity > 0 ? (group.totalCostBasisInLocal / group.quantity) : 0)
    const localPreviousClose = livePriceData?.previousClose || localCurrentPrice

    const convertedCurrentPrice = localCurrentPrice * rate
    const convertedPreviousClose = localPreviousClose * rate

    const costBasis = group.totalCostBasisInBase
    const currentValue = group.quantity * convertedCurrentPrice
    const profitLoss = currentValue - costBasis
    const profitLossPercentage = costBasis > 0 ? (profitLoss / costBasis) * 100 : 0

    // Average purchase price in local currency
    const localAveragePurchasePrice = group.quantity > 0 ? (group.totalCostBasisInLocal / group.quantity) : 0
    const convertedPurchasePrice = localAveragePurchasePrice * rate

    totalCostBasis += costBasis
    totalCurrentValue += currentValue

    return {
      id: `${group.broker}_${group.symbol}`,
      symbol: group.symbol,
      name: group.name,
      quantity: group.quantity,
      purchaseDate: group.latestPurchaseDate,
      purchasePrice: localAveragePurchasePrice,
      convertedPurchasePrice,
      currentPrice: localCurrentPrice,
      convertedCurrentPrice,
      costBasis,
      currentValue,
      profitLoss,
      profitLossPercentage,
      currency: assetCurrency,
      previousClose: localPreviousClose,
      convertedPreviousClose,
      weightPercentage: 0,
      broker: group.broker
    }
  })

  // 5. Calculate total metrics and weights
  const totalProfitLoss = totalCurrentValue - totalCostBasis
  const totalProfitLossPercentage = totalCostBasis > 0 ? (totalProfitLoss / totalCostBasis) * 100 : 0

  const holdingsWithWeights = holdingsList.map(h => ({
    ...h,
    weightPercentage: totalCurrentValue > 0 ? (h.currentValue / totalCurrentValue) * 100 : 0
  }))

  return {
    success: true,
    valuation: {
      portfolioId,
      currency: baseCurrency,
      totalCostBasis,
      totalCurrentValue,
      totalProfitLoss,
      totalProfitLossPercentage,
      holdings: holdingsWithWeights
    }
  }
})
