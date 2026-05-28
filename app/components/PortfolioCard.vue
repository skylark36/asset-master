<template>
  <Card class="portfolio-detail-card" :title="portfolio?.name" :subtitle="portfolio?.description" bordered>
    <template #actions>
      <t-tag theme="primary" variant="light">{{ portfolio?.currency }}</t-tag>
    </template>
    <div class="card-content">
      <div class="port-meta">
        <span class="meta-label">Created on:</span>
        <span class="meta-val font-outfit">{{ formatDate(portfolio?.created_at) }}</span>
      </div>
      <div class="port-meta">
        <span class="meta-label">Holdings Count:</span>
        <span class="meta-val font-outfit">{{ assetCount }}</span>
      </div>
    </div>
  </Card>
</template>

<script setup lang="ts">
import type { Portfolio } from '~/server/types'

defineProps<{
  portfolio: Portfolio | null
  assetCount: number
}>()

function formatDate(ts?: number) {
  if (!ts) return ''
  return new Date(ts).toLocaleDateString()
}
</script>

<style scoped>
.portfolio-detail-card {
  margin-bottom: 24px;
}
.card-content {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.port-meta {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
}
.meta-label {
  color: var(--td-text-color-secondary);
}
.meta-val {
  color: var(--td-text-color-primary);
  font-weight: 500;
}
</style>
