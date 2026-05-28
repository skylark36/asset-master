<template>
  <Card class="table-card" bordered>
    <div class="card-header">
      <h3 class="card-title">Holdings Ledger</h3>
      <t-button theme="primary" @click="$emit('add-asset')">
        <template #icon><add-icon /></template>
        Add Holding
      </t-button>
    </div>
    <t-table
      row-key="id"
      :data="holdings"
      :columns="columns"
      size="medium"
      hover
      stripe
      responsive
      empty="No holdings found in this portfolio."
    >
      <!-- Custom symbol cell -->
      <template #symbol="{ row }">
        <span class="symbol-tag">{{ row.symbol }}</span>
      </template>

      <!-- Custom name cell with ellipsis -->
      <template #name="{ row }">
        <div class="name-cell" :title="row.name">
          {{ row.name }}
        </div>
      </template>

      <!-- Custom quantity cell -->
      <template #quantity="{ row }">
        {{ row.quantity.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 4 }) }}
      </template>

      <!-- Custom purchasePrice cell -->
      <template #purchasePrice="{ row }">
        {{ formatCurrency(row.purchasePrice, row.currency) }}
      </template>

      <!-- Custom currentPrice cell -->
      <template #currentPrice="{ row }">
        {{ formatCurrency(row.currentPrice, row.currency) }}
      </template>

      <!-- Custom costBasis cell -->
      <template #costBasis="{ row }">
        {{ formatCurrency(row.costBasis, baseCurrency) }}
      </template>

      <!-- Custom currentValue cell -->
      <template #currentValue="{ row }">
        {{ formatCurrency(row.currentValue, baseCurrency) }}
      </template>

      <!-- Custom profitLoss cell -->
      <template #profitLoss="{ row }">
        <span :class="plClass(row.profitLoss)">
          {{ row.profitLoss > 0 ? '+' : '' }}{{ formatCurrency(row.profitLoss, baseCurrency) }}
        </span>
      </template>

      <!-- Custom profitLossPercentage cell -->
      <template #profitLossPercentage="{ row }">
        <span :class="plClass(row.profitLoss)">
          {{ row.profitLoss > 0 ? '+' : '' }}{{ row.profitLossPercentage?.toFixed(2) }}%
        </span>
      </template>

      <!-- Custom weightPercentage cell -->
      <template #weightPercentage="{ row }">
        <t-progress 
          theme="line" 
          :percentage="Number(row.weightPercentage?.toFixed(1))" 
          :label="`${row.weightPercentage?.toFixed(1)}%`"
          size="small"
        />
      </template>

      <!-- Custom broker cell -->
      <template #broker="{ row }">
        <t-tag variant="outline" size="small">{{ row.broker }}</t-tag>
      </template>

      <!-- Custom actions cell -->
      <template #actions="{ row }">
        <t-space size="small">
          <t-button variant="text" theme="primary" shape="circle" @click="$emit('edit-asset', row)">
            <template #icon><edit-icon /></template>
          </t-button>
          <t-popconfirm content="Are you sure you want to delete this holding?" @confirm="$emit('delete-asset', row.id)">
            <t-button variant="text" theme="danger" shape="circle">
              <template #icon><delete-icon /></template>
            </t-button>
          </t-popconfirm>
        </t-space>
      </template>
    </t-table>
  </Card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { AddIcon, EditIcon, DeleteIcon } from 'tdesign-icons-vue-next'
import type { HoldingValuation } from '~/server/types'

const props = defineProps<{
  holdings: HoldingValuation[]
  baseCurrency: string
}>()

defineEmits(['add-asset', 'edit-asset', 'delete-asset'])

const columns = computed(() => [
  { colKey: 'symbol', title: 'Ticker', width: 95, align: 'left' },
  { colKey: 'name', title: 'Name', width: 140, align: 'left', ellipsis: true },
  { colKey: 'quantity', title: 'Qty', width: 90, align: 'right' },
  { colKey: 'purchasePrice', title: 'Cost (Local)', width: 110, align: 'right' },
  { colKey: 'currentPrice', title: 'Price (Local)', width: 110, align: 'right' },
  { colKey: 'costBasis', title: 'Cost Basis', width: 120, align: 'right' },
  { colKey: 'currentValue', title: 'Value', width: 120, align: 'right' },
  { colKey: 'profitLoss', title: 'Profit / Loss', width: 120, align: 'right' },
  { colKey: 'profitLossPercentage', title: 'Return', width: 90, align: 'right' },
  { colKey: 'weightPercentage', title: 'Weight', width: 130, align: 'left' },
  { colKey: 'broker', title: 'Broker', width: 110, align: 'center' },
  { colKey: 'actions', title: 'Actions', width: 100, align: 'center' }
])

function formatCurrency(val: number, curr: string) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: curr || 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(val)
}

function plClass(pl: number) {
  return pl > 0 ? 'text-success' : pl < 0 ? 'text-danger' : 'text-neutral'
}
</script>

<style scoped>
.table-card {
  margin-bottom: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.card-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--td-text-color-primary);
}

.symbol-tag {
  font-family: monospace;
  font-weight: 700;
  color: var(--td-brand-color);
  background: rgba(99, 102, 241, 0.1);
  padding: 2px 6px;
  border-radius: 4px;
}

.name-cell {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 130px;
}

.text-success {
  color: var(--td-success-color);
  font-weight: 600;
}

.text-danger {
  color: var(--td-error-color);
  font-weight: 600;
}

.text-neutral {
  color: var(--td-text-color-secondary);
}
</style>
