import type { Asset } from '~/server/types'

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
  let queryStr = 'SELECT * FROM assets WHERE portfolio_id = ?'
  const queryParams: any[] = [portfolioId]

  if (brokerParam && brokerParam !== 'All') {
    queryStr += ' AND broker = ?'
    queryParams.push(brokerParam)
  }

  queryStr += ' ORDER BY purchase_date DESC'

  const { results } = await db.prepare(queryStr)
    .bind(...queryParams)
    .all<Asset>()

  return { success: true, assets: results || [] }
})
