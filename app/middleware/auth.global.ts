export default defineNuxtRouteMiddleware((to) => {
  // Ignore API routes
  if (to.path.startsWith('/api/')) {
    return
  }

  const authStore = useAuthStore()

  console.log(`[Auth Middleware] Path: ${to.path}, isLoggedIn: ${authStore.isLoggedIn}, token: ${authStore.token}`)

  // Prevent accessing protected pages if not logged in
  if (!authStore.isLoggedIn && to.path !== '/login') {
    console.log(`[Auth Middleware] Unauthorized access to ${to.path}, redirecting to /login`)
    return navigateTo('/login')
  }

  // Prevent accessing login page if already logged in
  if (authStore.isLoggedIn && to.path === '/login') {
    console.log(`[Auth Middleware] Already logged in, redirecting from /login to /`)
    return navigateTo('/')
  }
})

