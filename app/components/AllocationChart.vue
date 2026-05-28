<template>
  <t-card class="chart-card" bordered>
    <div class="chart-header">Asset Allocation</div>
    <div class="chart-container">
      <ClientOnly>
        <v-chart v-if="chartData.length > 0" class="chart" :option="option" autoresize />
        <div v-else class="empty-state">No holdings to display.</div>
      </ClientOnly>
    </div>
  </t-card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { HoldingValuation } from '~/server/types'

const props = defineProps<{
  holdings: HoldingValuation[]
}>()

const chartData = computed(() => {
  return props.holdings.map(h => ({
    name: h.symbol,
    value: Number(h.currentValue.toFixed(2))
  })).sort((a, b) => b.value - a.value)
})

const option = computed(() => {
  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      backgroundColor: 'var(--td-bg-color-container)',
      borderColor: 'var(--td-border-level-1-color)',
      borderWidth: 1,
      textStyle: {
        color: 'var(--td-text-color-primary)',
        fontFamily: 'Outfit'
      },
      formatter: '{b}: <b>{c}</b> ({d}%)'
    },
    legend: {
      type: 'scroll',
      orient: 'vertical',
      right: '5%',
      top: 'center',
      textStyle: {
        color: 'var(--td-text-color-secondary)',
        fontFamily: 'Outfit',
        fontSize: 12
      },
      pageIconColor: 'var(--td-brand-color)',
      pageIconInactiveColor: 'var(--td-text-color-placeholder)',
      pageTextStyle: {
        color: 'var(--td-text-color-secondary)'
      }
    },
    color: [
      '#6366F1', // Indigo
      '#06B6D4', // Cyan
      '#10B981', // Emerald Green
      '#8B5CF6', // Purple
      '#F59E0B', // Amber
      '#EC4899', // Pink
      '#3B82F6', // Blue
      '#F97316'  // Orange
    ],
    series: [
      {
        name: 'Allocation',
        type: 'pie',
        radius: ['50%', '75%'],
        center: ['40%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 8,
          borderColor: 'var(--td-bg-color-container)',
          borderWidth: 2
        },
        label: {
          show: false,
          position: 'center'
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 16,
            fontWeight: 'bold',
            color: 'var(--td-text-color-primary)',
            fontFamily: 'Outfit',
            formatter: '{b}\n{d}%'
          }
        },
        labelLine: {
          show: false
        },
        data: chartData.value
      }
    ]
  }
})
</script>

<style scoped>
.chart-card {
  height: 350px;
  display: flex;
  flex-direction: column;
}

.chart-header {
  font-size: 16px;
  font-weight: 600;
  color: var(--td-text-color-primary);
  margin-bottom: 16px;
}

.chart-container {
  flex: 1;
  position: relative;
}

.chart {
  width: 100%;
  height: 100%;
}

.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--td-text-color-placeholder);
  font-size: 14px;
}
</style>
