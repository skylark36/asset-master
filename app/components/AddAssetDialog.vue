<template>
  <t-dialog
    v-model:visible="localVisible"
    :header="isEdit ? 'Edit Asset Holding' : 'Add Asset Holding'"
    :confirm-btn="isEdit ? 'Save Changes' : 'Add Asset'"
    cancel-btn="Cancel"
    @confirm="handleSubmit"
    destroy-on-close
    width="500px"
  >
    <t-form :model="form" :rules="rules" ref="formRef" label-align="top">
      <!-- Search Symbol -->
      <t-form-item label="Symbol / Ticker" name="symbol">
        <t-select
          v-model="form.symbol"
          placeholder="Search ticker (e.g. AAPL, BTC-USD)"
          filterable
          :filter="() => true"
          :loading="searchLoading"
          @search="handleSearch"
          @change="handleSelectAsset"
          :disabled="isEdit"
        >
          <t-option
            v-for="item in searchResults"
            :key="item.symbol"
            :value="item.symbol"
            :label="`${item.symbol} - ${item.name} (${item.exchange})`"
          />
        </t-select>
      </t-form-item>

      <!-- Asset Name -->
      <t-form-item label="Asset Name" name="name">
        <t-input v-model="form.name" placeholder="Enter asset name" />
      </t-form-item>

      <!-- Quantity & Purchase Price side-by-side -->
      <div class="row-flex">
        <t-form-item label="Quantity" name="quantity" class="flex-child">
          <t-input-number v-model="form.quantity" :min="0.0001" :step="1" placeholder="0.0" style="width: 100%" />
        </t-form-item>
        <t-form-item label="Purchase Price (Local)" name="purchasePrice" class="flex-child">
          <t-input-number v-model="form.purchasePrice" :min="0.01" :step="0.01" placeholder="0.00" style="width: 100%" />
        </t-form-item>
      </div>

      <!-- Broker & Purchase Date side-by-side -->
      <div class="row-flex">
        <t-form-item label="Broker" name="broker" class="flex-child">
          <t-select v-model="form.broker" placeholder="Select Broker">
            <t-option
              v-for="broker in filteredBrokers"
              :key="broker"
              :value="broker"
              :label="broker"
            />
          </t-select>
        </t-form-item>
        <t-form-item label="Purchase Date" name="purchaseDate" class="flex-child">
          <t-date-picker v-model="form.purchaseDate" placeholder="Select date" style="width: 100%" />
        </t-form-item>
      </div>
    </t-form>
  </t-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { MessagePlugin } from 'tdesign-vue-next'
import type { FormInstanceFunctions } from 'tdesign-vue-next'
import { usePortfolioStore } from '~/stores/portfolio'
import { useAssetSearch } from '~/composables/useAssetSearch'

const props = defineProps<{
  visible: boolean
  asset: any | null // Existing asset for editing, or null for creating
}>()

const emit = defineEmits(['update:visible', 'saved'])

const portfolioStore = usePortfolioStore()
const formRef = ref<FormInstanceFunctions | null>(null)

const localVisible = computed({
  get: () => props.visible,
  set: (val) => emit('update:visible', val)
})

const isEdit = computed(() => !!props.asset)

const form = ref({
  symbol: '',
  name: '',
  quantity: 1,
  purchasePrice: 0,
  broker: 'Other',
  purchaseDate: ''
})

const rules = {
  symbol: [{ required: true, message: 'Symbol is required', trigger: 'blur' }],
  name: [{ required: true, message: 'Name is required', trigger: 'blur' }],
  quantity: [{ required: true, message: 'Quantity is required', trigger: 'blur' }],
  purchasePrice: [{ required: true, message: 'Purchase price is required', trigger: 'blur' }],
  broker: [{ required: true, message: 'Broker is required', trigger: 'change' }]
}

// Select only preset & custom brokers, filter out 'All'
const filteredBrokers = computed(() => {
  return portfolioStore.availableBrokers.filter(b => b !== 'All')
})

// Search hook
const { results: searchResults, loading: searchLoading, search: runSearch } = useAssetSearch()

function handleSearch(query: string) {
  runSearch(query)
}

async function handleSelectAsset(symbolVal: any) {
  const selected = searchResults.value.find(s => s.symbol === symbolVal)
  if (selected) {
    form.value.name = selected.name
    
    // Fetch live market quote to pre-populate the purchase price (Live Cost-Basis Sync)
    try {
      const data = await $fetch<{ success: boolean; prices: Record<string, any> }>('/api/stocks', {
        query: { symbols: symbolVal }
      })
      if (data.success && data.prices[symbolVal]) {
        form.value.purchasePrice = Number(data.prices[symbolVal].price.toFixed(2))
      }
    } catch (e) {
      console.error('[Live Price Sync Error]', e)
    }
  }
}

// Watch dialog visibility or asset prop change
watch(() => props.visible, (val) => {
  if (val) {
    if (props.asset) {
      // Load edit data
      form.value = {
        symbol: props.asset.symbol,
        name: props.asset.name,
        quantity: props.asset.quantity,
        purchasePrice: props.asset.purchasePrice || props.asset.purchase_price,
        broker: props.asset.broker,
        purchaseDate: props.asset.purchaseDate ? new Date(props.asset.purchaseDate).toISOString().split('T')[0] : ''
      }
    } else {
      // Clear for new holding
      form.value = {
        symbol: '',
        name: '',
        quantity: 1,
        purchasePrice: 0,
        broker: 'Other',
        purchaseDate: new Date().toISOString().split('T')[0]
      }
    }
  }
})

async function handleSubmit() {
  const validateResult = await formRef.value?.validate()
  if (validateResult !== true) {
    return
  }

  const payload = {
    symbol: form.value.symbol,
    name: form.value.name,
    quantity: Number(form.value.quantity),
    purchasePrice: Number(form.value.purchasePrice),
    broker: form.value.broker,
    purchaseDate: form.value.purchaseDate ? new Date(form.value.purchaseDate).getTime() : Date.now()
  }

  let success = false
  if (isEdit.value && props.asset) {
    success = await portfolioStore.editAssetHolding({
      assetId: props.asset.id,
      ...payload
    })
  } else {
    success = await portfolioStore.addAssetHolding(payload)
  }

  if (success) {
    MessagePlugin.success(isEdit.value ? 'Holding updated' : 'Holding added successfully')
    localVisible.value = false
    emit('saved')
  } else {
    MessagePlugin.error(portfolioStore.errorMessage || 'Failed to save holding')
  }
}
</script>

<style scoped>
.row-flex {
  display: flex;
  gap: 16px;
  width: 100%;
}
.flex-child {
  flex: 1;
}
</style>
