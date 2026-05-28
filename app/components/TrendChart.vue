<template>
  <t-card class="chart-card" bordered>
    <div class="chart-header">
      <div class="title">Valuation Trend (30D)</div>
      <div class="subtitle">Historical portfolio value over time</div>
    </div>
    <div class="chart-container">
      <ClientOnly>
        <v-chart v-if="trendData.length > 0" class="chart" :option="option" autoresize />
        <div v-else class="empty-state">No historical data available.</div>
      </ClientOnly>
    </div>
  </t-card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { TrendDataPoint } from '~/server/types'

const props = defineProps<{
  trendData: TrendDataPoint[]
  currency: string
}>()

const option = computed(() => {
  const xAxisData = props.trendData.map(d => d.date)
  const yAxisData = props.trendData.map(d => d.value)

  return {
    backgroundColor: 'transparent',
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '8%',
      containLabel: true
    },
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'var(--td-bg-color-container)',
      borderColor: 'var(--td-border-level-1-color)',
      borderWidth: 1,
      textStyle: {
        color: 'var(--td-text-color-primary)',
        fontFamily: 'Outfit'
      },
      formatter: (params: any) => {
        const item = params[0]
        const val = new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: props.currency || 'USD'
        }).format(item.value)
        return `${item.name}<br/>Value: <b>${val}</b>`
      }
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: xAxisData,
      axisLine: {
        lineStyle: {
          color: 'var(--td-border-level-1-color)'
        }
      },
      axisLabel: {
        color: 'var(--td-text-color-secondary)',
        fontFamily: 'Outfit',
        formatter: (val: string) => {
          const parts = val.split('-')
          if (parts.length === 3) {
            return `${parts[1]}/${parts[2]}`
          }
          return val
        }
      }
    },
    yAxis: {
      type: 'value',
      axisLine: {
        show: false
      },
      splitLine: {
        lineStyle: {
          color: 'var(--td-border-level-1-color)'
        }
      },
      axisLabel: {
        color: 'var(--td-text-color-secondary)',
        fontFamily: 'Outfit',
        formatter: (val: number) => {
          if (val >= 1e6) return `${(val / 1e6).toFixed(1)}M`
          if (val >= 1e3) return `${(val / 1e3).toFixed(0)}k`
          return val.toString()
        }
      }
    },
    series: [
      {
        name: 'Portfolio Value',
        type: 'line',
        data: yAxisData,
        smooth: true,
        showSymbol: false,
        lineStyle: {
          width: 3,
          color: 'var(--td-brand-color)'
        },
        itemStyle: {
          color: 'var(--td-brand-color)'
        },
        areaStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [
              { offset: 0, color: 'rgba(99, 102, 241, 0.4)' },
              { offset: 1, color: 'rgba(99, 102, 241, 0.0)' }
            ]
          }
        }
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
  margin-bottom: 16px;
}

.title {
  font-size: 16px;
  font-weight: 600;
  color: var(--td-text-color-primary);
}

.subtitle {
  font-size: 12px;
  color: var(--td-text-color-placeholder);
  margin-top: 4px;
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
