export default defineEventHandler(async (event) => {
  const query = getQuery(event).q as string
  if (!query) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Missing required query parameter "q"'
    })
  }

  const yahooUrl = `https://query2.finance.yahoo.com/v1/finance/search?q=${encodeURIComponent(query)}&quotesCount=8`
  try {
    const res = await fetch(yahooUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept': 'application/json'
      }
    })

    if (!res.ok) {
      throw new Error(`Yahoo Search HTTP Error: ${res.status}`)
    }

    const data: any = await res.json()
    const quotes = (data?.quotes || []).map((q: any) => ({
      symbol: q.symbol,
      name: q.shortname || q.longname || q.name || q.symbol,
      exchange: q.exchange,
      type: q.typeDisp || q.quoteType || 'Unknown'
    }))

    return { success: true, results: quotes }
  } catch (e: any) {
    console.error('[Yahoo Search Error]:', e)
    throw createError({
      statusCode: 502,
      statusMessage: 'Failed to search asset from Yahoo: ' + e.message
    })
  }
})
