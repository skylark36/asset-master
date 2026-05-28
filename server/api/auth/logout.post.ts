export default defineEventHandler((event) => {
  deleteSessionToken(event)
  return {
    success: true,
    message: 'Logged out successfully'
  }
})
