<template>
  <t-config-provider :global-config="globalConfig">
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </t-config-provider>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from '~/stores/auth'
import { useDarkMode } from '~/composables/useDarkMode'

const globalConfig = {
  // Optional TDesign configurations
}

const { init } = useDarkMode()
const authStore = useAuthStore()

onMounted(() => {
  // Clear any old/stale service workers from previous projects on localhost
  if (import.meta.client && navigator.serviceWorker) {
    navigator.serviceWorker.getRegistrations().then((registrations) => {
      for (const registration of registrations) {
        registration.unregister().then((success) => {
          if (success) {
            console.log('[ServiceWorker] Unregistered stale service worker successfully')
            window.location.reload()
          }
        })
      }
    })
  }

  // Initialize theme-mode attribute
  init()
  // Restore user session from cookie
  authStore.initAuth()
})
</script>
