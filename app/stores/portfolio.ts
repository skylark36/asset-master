import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Portfolio, Asset, PortfolioValuation, TrendDataPoint } from '~/server/types'

export const usePortfolioStore = defineStore('portfolio', () => {
  // State
  const portfolios = ref<Portfolio[]>([])
  const selectedPortfolio = ref<Portfolio | null>(null)
  const assets = ref<Asset[]>([])
  const valuation = ref<PortfolioValuation | null>(null)
  const trendData = ref<TrendDataPoint[]>([])

  const isLoading = ref(false)
  const isValuationLoading = ref(false)
  const isTrendLoading = ref(false)
  const errorMessage = ref<string | null>(null)

  const selectedBroker = ref('All')
  const presetBrokers = ['IBKR', 'Charles Schwab', 'HSBC']
  const customBrokers = ref<string[]>([])

  // Feedback State
  const feedbackText = ref('')
  const feedbackRating = ref(5)
  const feedbackCategory = ref('Feature Request')
  const isFeedbackSubmitting = ref(false)
  const feedbackSubmittedSuccess = ref(false)

  // Computed
  const availableBrokers = computed(() => {
    return ['All', ...presetBrokers, ...customBrokers.value, 'Other']
  })

  // Initialize custom brokers from localStorage client-side
  function initBrokers() {
    if (import.meta.client) {
      const saved = localStorage.getItem('custom_brokers')
      if (saved) {
        try {
          customBrokers.value = JSON.parse(saved)
        } catch (e) {
          console.error('[PortfolioStore Init Custom Brokers Error]', e)
        }
      }
    }
  }

  function addCustomBroker(name: string) {
    const cleanName = name.trim()
    if (!cleanName) return
    const isDuplicate = presetBrokers.some(b => b.toLowerCase() === cleanName.toLowerCase()) ||
      customBrokers.value.some(b => b.toLowerCase() === cleanName.toLowerCase())
    if (isDuplicate) return

    customBrokers.value.push(cleanName)
    if (import.meta.client) {
      localStorage.setItem('custom_brokers', JSON.stringify(customBrokers.value))
    }
  }

  function removeCustomBroker(name: string) {
    customBrokers.value = customBrokers.value.filter(b => b !== name)
    if (import.meta.client) {
      localStorage.setItem('custom_brokers', JSON.stringify(customBrokers.value))
    }
    if (selectedBroker.value === name) {
      selectBroker('All')
    }
  }

  async function loadPortfolios() {
    isLoading.value = true
    errorMessage.value = null
    try {
      const data = await $fetch<{ success: boolean; portfolios: Portfolio[] }>('/api/portfolios')
      if (data.success) {
        portfolios.value = data.portfolios
        if (data.portfolios.length > 0) {
          if (!selectedPortfolio.value) {
            selectPortfolio(data.portfolios[0])
          } else {
            const exists = data.portfolios.find(p => p.id === selectedPortfolio.value!.id)
            if (exists) {
              selectedPortfolio.value = exists
              await loadPortfolioDetails(exists.id)
            } else {
              selectPortfolio(data.portfolios[0])
            }
          }
        } else {
          // Auto create a portfolio if none exists
          const success = await createPortfolio('My Wealth', 'Core stock and crypto ledger', 'USD')
          if (!success) {
            selectedPortfolio.value = null
            assets.value = []
            valuation.value = null
          }
        }
      }
    } catch (e: any) {
      errorMessage.value = 'Failed to load portfolios. Is the server running?'
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  async function createPortfolio(name: string, description: string, currency = 'USD') {
    isLoading.value = true
    errorMessage.value = null
    try {
      const data = await $fetch<{ success: boolean; portfolio: Portfolio }>('/api/portfolios', {
        method: 'POST',
        body: { name, description, currency }
      })
      if (data.success) {
        portfolios.value.push(data.portfolio)
        selectPortfolio(data.portfolio)
        return true
      }
    } catch (e: any) {
      errorMessage.value = `Failed to create portfolio: ${e.message}`
      console.error(e)
    } finally {
      isLoading.value = false
    }
    return false
  }

  async function updateSelectedPortfolioCurrency(currency: string) {
    if (!selectedPortfolio.value) return false
    isValuationLoading.value = true
    errorMessage.value = null
    try {
      const data = await $fetch<{ success: boolean; portfolio: Portfolio }>(`/api/portfolios/${selectedPortfolio.value.id}`, {
        method: 'PUT',
        body: { currency }
      })
      if (data.success) {
        const index = portfolios.value.findIndex(p => p.id === selectedPortfolio.value!.id)
        if (index !== -1) {
          portfolios.value[index] = data.portfolio
        }
        selectedPortfolio.value = data.portfolio
        await loadPortfolioDetails(data.portfolio.id)
        return true
      }
    } catch (e: any) {
      errorMessage.value = `Failed to update currency: ${e.message}`
      console.error(e)
    } finally {
      isValuationLoading.value = false
    }
    return false
  }

  function selectPortfolio(portfolio: Portfolio) {
    selectedPortfolio.value = portfolio
    loadPortfolioDetails(portfolio.id)
  }

  async function loadPortfolioDetails(portfolioId: string) {
    isValuationLoading.value = true
    errorMessage.value = null
    try {
      const broker = selectedBroker.value
      // Run concurrent requests
      const [assetsData, valuationData] = await Promise.all([
        $fetch<{ success: boolean; assets: Asset[] }>(`/api/portfolios/${portfolioId}/assets`, { query: { broker } }),
        $fetch<{ success: boolean; valuation: PortfolioValuation }>(`/api/portfolios/${portfolioId}/valuation`, { query: { broker } })
      ])

      if (assetsData.success) {
        assets.value = assetsData.assets
      }
      if (valuationData.success) {
        valuation.value = valuationData.valuation
      }
    } catch (e: any) {
      errorMessage.value = 'Failed to fetch details for this portfolio.'
      console.error(e)
      assets.value = []
      valuation.value = {
        portfolioId,
        currency: selectedPortfolio.value?.currency || 'USD',
        totalCostBasis: 0,
        totalCurrentValue: 0,
        totalProfitLoss: 0,
        totalProfitLossPercentage: 0,
        holdings: []
      }
    } finally {
      isValuationLoading.value = false
    }

    loadTrendData(portfolioId)
  }

  async function loadTrendData(portfolioId: string) {
    isTrendLoading.value = true
    try {
      const broker = selectedBroker.value
      const data = await $fetch<{ success: boolean; trend: TrendDataPoint[] }>(`/api/portfolios/${portfolioId}/trend`, { query: { broker } })
      if (data.success) {
        trendData.value = data.trend
      }
    } catch (e: any) {
      console.error('[Trend Data Loading Error]', e)
      trendData.value = []
    } finally {
      isTrendLoading.value = false
    }
  }

  function selectBroker(broker: string) {
    selectedBroker.value = broker
    if (selectedPortfolio.value) {
      loadPortfolioDetails(selectedPortfolio.value.id)
    }
  }

  async function addAssetHolding(holding: {
    symbol: string
    name: string
    quantity: number
    purchasePrice: number
    broker: string
    purchaseDate?: number
  }) {
    if (!selectedPortfolio.value) return false
    isValuationLoading.value = true
    try {
      const data = await $fetch<{ success: boolean; asset: Asset }>('/api/assets', {
        method: 'POST',
        body: {
          portfolio_id: selectedPortfolio.value.id,
          ...holding
        }
      })
      if (data.success) {
        await loadPortfolioDetails(selectedPortfolio.value.id)
        return true
      }
    } catch (e: any) {
      errorMessage.value = `Failed to add holding: ${e.message}`
      console.error(e)
    } finally {
      isValuationLoading.value = false
    }
    return false
  }

  async function editAssetHolding(holding: {
    assetId: string
    symbol: string
    name: string
    quantity: number
    purchasePrice: number
    broker: string
    purchaseDate?: number
  }) {
    if (!selectedPortfolio.value) return false
    isValuationLoading.value = true
    try {
      const data = await $fetch<{ success: boolean; asset: Asset }>(`/api/assets/${holding.assetId}`, {
        method: 'PUT',
        body: {
          portfolio_id: selectedPortfolio.value.id,
          ...holding
        }
      })
      if (data.success) {
        await loadPortfolioDetails(selectedPortfolio.value.id)
        return true
      }
    } catch (e: any) {
      errorMessage.value = `Failed to edit holding: ${e.message}`
      console.error(e)
    } finally {
      isValuationLoading.value = false
    }
    return false
  }

  async function deleteAssetHolding(assetId: string) {
    if (!selectedPortfolio.value) return false
    isValuationLoading.value = true
    try {
      const data = await $fetch<{ success: boolean }>(`/api/assets/${assetId}`, {
        method: 'DELETE'
      })
      if (data.success) {
        await loadPortfolioDetails(selectedPortfolio.value.id)
        return true
      }
    } catch (e: any) {
      errorMessage.value = `Failed to delete asset: ${e.message}`
      console.error(e)
    } finally {
      isValuationLoading.value = false
    }
    return false
  }

  async function refreshActivePortfolio() {
    if (selectedPortfolio.value) {
      await loadPortfolioDetails(selectedPortfolio.value.id)
    } else {
      await loadPortfolios()
    }
  }

  async function submitFeedback() {
    isFeedbackSubmitting.value = true
    errorMessage.value = null
    try {
      // Simulate real-world network latency (Edge Node feedback sync)
      await new Promise(resolve => setTimeout(resolve, 1200))

      feedbackSubmittedSuccess.value = true
      feedbackText.value = ''
      feedbackRating.value = 5
      feedbackCategory.value = 'Feature Request'

      setTimeout(() => {
        feedbackSubmittedSuccess.value = false
      }, 4000)
    } catch (e: any) {
      errorMessage.value = `Failed to submit feedback: ${e.message}`
    } finally {
      isFeedbackSubmitting.value = false
    }
  }

  return {
    portfolios,
    selectedPortfolio,
    assets,
    valuation,
    trendData,
    isLoading,
    isValuationLoading,
    isTrendLoading,
    errorMessage,
    selectedBroker,
    presetBrokers,
    customBrokers,
    availableBrokers,
    feedbackText,
    feedbackRating,
    feedbackCategory,
    isFeedbackSubmitting,
    feedbackSubmittedSuccess,
    initBrokers,
    addCustomBroker,
    removeCustomBroker,
    loadPortfolios,
    createPortfolio,
    updateSelectedPortfolioCurrency,
    selectPortfolio,
    loadPortfolioDetails,
    loadTrendData,
    selectBroker,
    addAssetHolding,
    editAssetHolding,
    deleteAssetHolding,
    refreshActivePortfolio,
    submitFeedback
  }
})
