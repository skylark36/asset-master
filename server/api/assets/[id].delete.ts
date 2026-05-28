export default defineEventHandler(async (event) => {
  const assetId = getRouterParam(event, 'id')
  if (!assetId) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Asset ID is required'
    })
  }

  const db = useDB(event)
  const result = await db.prepare(
    'DELETE FROM assets WHERE id = ?'
  ).bind(assetId).run()

  if (result.meta.changes === 0) {
    throw createError({
      statusCode: 404,
      statusMessage: 'Asset holding not found'
    })
  }

  return { success: true, message: 'Asset successfully deleted' }
})
