import { ref, onMounted, onUnmounted } from 'vue'

export type ThemeMode = 'light' | 'dark' | 'auto'

const STORAGE_KEY = 'theme-mode'

const mode = ref<ThemeMode>('dark')
const isDark = ref(true)

export function useDarkMode() {
  let mediaQuery: MediaQueryList | null = null

  const getSystemTheme = (): boolean => {
    if (import.meta.server) return true // Default to dark for SSR
    return window.matchMedia('(prefers-color-scheme: dark)').matches
  }

  const applyTheme = (dark: boolean) => {
    isDark.value = dark
    if (import.meta.client) {
      document.documentElement.setAttribute('theme-mode', dark ? 'dark' : 'light')
    }
  }

  const handleSystemChange = (e: MediaQueryListEvent) => {
    if (mode.value === 'auto') {
      applyTheme(e.matches)
    }
  }

  const setMode = (newMode: ThemeMode) => {
    mode.value = newMode
    if (import.meta.client) {
      localStorage.setItem(STORAGE_KEY, newMode)
      if (newMode === 'auto') {
        applyTheme(getSystemTheme())
      } else {
        applyTheme(newMode === 'dark')
      }
    }
  }

  const toggle = () => {
    if (mode.value === 'auto') {
      setMode(isDark.value ? 'light' : 'dark')
    } else {
      setMode(mode.value === 'dark' ? 'light' : 'dark')
    }
  }

  const init = () => {
    if (import.meta.client) {
      const savedMode = localStorage.getItem(STORAGE_KEY) as ThemeMode | null
      if (savedMode) {
        setMode(savedMode)
      } else {
        setMode('dark') // Default to dark mode for premium Space Blue theme
      }

      mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
      mediaQuery.addEventListener('change', handleSystemChange)
    }
  }

  const cleanup = () => {
    if (import.meta.client && mediaQuery) {
      mediaQuery.removeEventListener('change', handleSystemChange)
    }
  }

  return {
    mode,
    isDark,
    setMode,
    toggle,
    init,
    cleanup
  }
}
