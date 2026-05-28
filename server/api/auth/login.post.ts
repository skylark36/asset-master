export default defineEventHandler(async (event) => {
  const body = await readBody(event).catch(() => ({}))
  const { email, password } = body
  console.log('pass', email, password)

  if (!email || !password) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Missing email or password'
    })
  }

  const db = useDB(event)
  const emailLower = email.toLowerCase().trim()

  const user: any = await db.prepare(
    'SELECT * FROM users WHERE email = ?'
  ).bind(emailLower).first()

  if (!user) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid email or password'
    })
  }

  const inputHash = await hashPassword(password)
  if (user.password_hash !== inputHash) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid email or password'
    })
  }

  // Set session cookie
  setSessionToken(event, user.id)

  return {
    success: true,
    token: user.id,
    user: { id: user.id, email: user.email, name: user.name }
  }
})
