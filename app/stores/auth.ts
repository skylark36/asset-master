import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

interface User {
  id: string
  email: string
  name?: string
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(null)

  // Sync token value from cookie during store initialization
  const cookie = useCookie<string | null>('session-token')
  token.value = cookie.value

  const isLoggedIn = computed(() => !!token.value)

  async function login(email: string, password: string) {
    console.log(`[AuthStore] login called for email: ${email}`)
    try {
      const data = await $fetch<{ success: boolean; token: string; user: User }>('/api/auth/login', {
        method: 'POST',
        body: { email, password }
      })
      console.log(`[AuthStore] login response:`, data)
      if (data.success) {
        user.value = data.user
        token.value = data.token
        const sessionCookie = useCookie<string | null>('session-token')
        sessionCookie.value = data.token
        console.log(`[AuthStore] login success: set user to ${JSON.stringify(user.value)}, token to ${token.value}`)
        return true
      }
    } catch (e: any) {
      console.error('[AuthStore] Login API error:', e)
      throw e
    }
    return false
  }

  async function register(email: string, name: string, password: string) {
    try {
      const data = await $fetch<{ success: boolean; token: string; user: User }>('/api/auth/register', {
        method: 'POST',
        body: { email, name, password }
      })
      if (data.success) {
        user.value = data.user
        token.value = data.token
        const sessionCookie = useCookie<string | null>('session-token')
        sessionCookie.value = data.token
        return true
      }
    } catch (e: any) {
      console.error('Registration error:', e)
      throw e
    }
    return false
  }

  async function logout() {
    try {
      await $fetch('/api/auth/logout', { method: 'POST' })
    } catch (e) {
      console.error('Logout API error:', e)
    } finally {
      user.value = null
      token.value = null
      const sessionCookie = useCookie<string | null>('session-token')
      sessionCookie.value = null
      // Redirect to login page
      navigateTo('/login')
    }
  }

  function initAuth() {
    const sessionCookie = useCookie<string | null>('session-token')
    token.value = sessionCookie.value
    console.log(`[AuthStore] initAuth called: token.value = ${token.value}, user.value = ${user.value ? JSON.stringify(user.value) : 'null'}`)
    if (token.value && !user.value) {
      user.value = {
        id: token.value,
        email: 'demo@assetmaster.app',
        name: 'Chien'
      }
      console.log(`[AuthStore] initAuth hydrated user from token:`, user.value)
    }
  }


  return {
    user,
    token,
    isLoggedIn,
    login,
    register,
    logout,
    initAuth
  }
})
