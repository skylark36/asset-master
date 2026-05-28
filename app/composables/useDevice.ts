import { ref } from 'vue'

export function useDevice() {
  const isMobile = ref(false)

  const checkDevice = () => {
    if (import.meta.server) {
      const headers = useRequestHeaders(['user-agent'])
      const ua = headers['user-agent'] || ''
      isMobile.value = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(ua)
    } else {
      isMobile.value = window.innerWidth <= 768 || /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
    }
  }

  checkDevice()

  return {
    isMobile
  }
}
