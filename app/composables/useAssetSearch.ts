import { ref } from 'vue'

export function useAssetSearch() {
  const results = ref<any[]>([])
  const loading = ref(false)
  let timer: any = null

  const search = (query: string) => {
    if (timer) clearTimeout(timer)
    
    const cleanQuery = query.trim()
    if (!cleanQuery) {
      results.value = []
      loading.value = false
      return
    }

    loading.value = true
    timer = setTimeout(async () => {
      try {
        const data = await $fetch<{ success: boolean; results: any[] }>('/api/stocks/search', {
          query: { q: cleanQuery }
        })
        if (data.success) {
          results.value = data.results
        }
      } catch (e) {
        console.error('[Asset Search Error]', e)
        results.value = []
      } finally {
        loading.value = false
      }
    }, 300) // Debounce 300ms
  }

  return {
    results,
    loading,
    search
  }
}
