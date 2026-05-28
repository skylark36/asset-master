<template>
  <div class="dashboard-page">
    <!-- Top Stats Cards -->
    <ValuationCards :valuation="portfolioStore.valuation" :currency="portfolioStore.selectedPortfolio?.currency || 'USD'" />


        <AssetTable
          :holdings="portfolioStore.assets"
          :base-currency="portfolioStore.selectedPortfolio?.currency || 'USD'"
          @add-asset="openAddAsset"
          @edit-asset="openEditAsset"
          @delete-asset="handleDeleteAsset"
        />

    <!-- Add/Edit Asset Dialog -->
    <AddAssetDialog
      v-model:visible="dialogVisible"
      :asset="selectedAsset"
      @saved="refreshDashboard"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { MessagePlugin } from 'tdesign-mobile-vue'
import { usePortfolioStore } from '~/stores/portfolio'

const portfolioStore = usePortfolioStore()
const dialogVisible = ref(false)
const selectedAsset = ref<any | null>(null)

function openAddAsset() {
  selectedAsset.value = null
  dialogVisible.value = true
}

function openEditAsset(asset: any) {
  selectedAsset.value = asset
  dialogVisible.value = true
}

async function handleDeleteAsset(assetId: string) {
  const success = await portfolioStore.deleteAssetHolding(assetId)
  if (success) {
    MessagePlugin.success('Holding deleted successfully')
  } else {
    MessagePlugin.error(portfolioStore.errorMessage || 'Failed to delete holding')
  }
}

function refreshDashboard() {
  if (portfolioStore.selectedPortfolio) {
    portfolioStore.loadPortfolioDetails(portfolioStore.selectedPortfolio.id)
  }
}

onMounted(() => {
  portfolioStore.loadPortfolios()
})
</script>

<style scoped>
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 24px;
}

.grid-left {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.grid-right {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

@media (max-width: 1024px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
}
</style>
