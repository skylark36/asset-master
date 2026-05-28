export default defineEventHandler(async (event) => {
  const body = await readBody(event).catch(() => ({}))
  const { email, name, password } = body

  if (!email || !name || !password) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Missing required fields: email, name, password'
    })
  }

  const db = useDB(event)
  const emailLower = email.toLowerCase().trim()

  // Check if user already exists
  const existingUser = await db.prepare(
    'SELECT * FROM users WHERE email = ?'
  ).bind(emailLower).first()

  if (existingUser) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Email is already registered'
    })
  }

  const userId = crypto.randomUUID()
  const passwordHash = await hashPassword(password)
  const createdAt = Date.now()

  // Insert new user
  await db.prepare(
    'INSERT INTO users (id, email, name, password_hash, created_at) VALUES (?, ?, ?, ?, ?)'
  ).bind(userId, emailLower, name.trim(), passwordHash, createdAt).run()

  // Auto-create a starting default portfolio for visual completeness
  const portfolioId = crypto.randomUUID()
  await db.prepare(
    'INSERT INTO portfolios (id, user_id, name, description, currency, created_at) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(portfolioId, userId, 'My Wealth', 'Core stock and crypto ledger', 'USD', createdAt).run()

  // Set session cookie
  setSessionToken(event, userId)

  return {
    success: true,
    token: userId,
    user: { id: userId, email: emailLower, name: name.trim() }
  }
})
