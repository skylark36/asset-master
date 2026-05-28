<template>
  <div class="valuation-cards-grid">
    <!-- Total Value Card -->
    <Card class="val-card" bordered>
      <div class="val-label">Total Value</div>
      <div class="val-amount font-outfit">{{ formatCurrency(valuation?.totalCurrentValue || 0, currency) }}</div>
      <div class="val-sub">Aggregated Current Value</div>
    </Card>

    <!-- Total Cost Basis Card -->
    <Card class="val-card" bordered>
      <div class="val-label">Cost Basis</div>
      <div class="val-amount font-outfit">{{ formatCurrency(valuation?.totalCostBasis || 0, currency) }}</div>
      <div class="val-sub">Total Capital Invested</div>
    </Card>

    <!-- Total P&L Card with Dynamic Borders -->
    <Card 
      class="val-card"
      :class="plStatusClass"
      bordered
    >
      <div class="val-label">Total Profit / Loss</div>
      <div 
        class="val-amount font-outfit"
        :class="plTextClass"
      >
        {{ plSign }}{{ formatCurrency(Math.abs(valuation?.totalProfitLoss || 0), currency) }}
      </div>
      <div 
        class="val-percentage"
        :class="plTextClass"
      >
        <component :is="TrendArrowIcon" v-if="valuation?.totalProfitLoss !== 0" :style="{ marginRight: '4px' }" />
        {{ valuation?.totalProfitLossPercentage !== undefined ? valuation.totalProfitLossPercentage.toFixed(2) : '0.00' }}%
      </div>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ArrowTriangleUpIcon, ArrowTriangleDownIcon } from 'tdesign-icons-vue-next'
import type { PortfolioValuation } from '~/server/types'

const props = defineProps<{
  valuation: PortfolioValuation | null
  currency: string
}>()

const plSign = computed(() => {
  const pl = props.valuation?.totalProfitLoss || 0
  return pl > 0 ? '+' : pl < 0 ? '-' : ''
})

const plTextClass = computed(() => {
  const pl = props.valuation?.totalProfitLoss || 0
  return pl > 0 ? 'text-success' : pl < 0 ? 'text-danger' : ''
})

const plStatusClass = computed(() => {
  const pl = props.valuation?.totalProfitLoss || 0
  return pl > 0 ? 'border-success' : pl < 0 ? 'border-danger' : ''
})

const TrendArrowIcon = computed(() => {
  const pl = props.valuation?.totalProfitLoss || 0
  return pl >= 0 ? ArrowTriangleUpIcon : ArrowTriangleDownIcon
})

function formatCurrency(val: number, curr: string) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: curr || 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(val)
}
</script>

<style scoped>
.valuation-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}

.val-card {
  height: 100%;
}

.val-label {
  font-size: 14px;
  color: var(--td-text-color-secondary);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 12px;
}

.val-amount {
  font-size: 28px;
  font-weight: 700;
  color: var(--td-text-color-primary);
  margin-bottom: 8px;
}

.val-sub {
  font-size: 12px;
  color: var(--td-text-color-placeholder);
}

.val-percentage {
  font-size: 16px;
  font-weight: 600;
  display: flex;
  align-items: center;
  margin-top: 4px;
}

.border-success {
  border: 1px solid var(--td-success-color) !important;
}

.border-danger {
  border: 1px solid var(--td-error-color) !important;
}

.text-success {
  color: var(--td-success-color) !important;
}

.text-danger {
  color: var(--td-error-color) !important;
}
</style>
