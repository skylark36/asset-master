<template>
  <div
    class="custom-card"
    :class="{ 'custom-card--bordered': bordered }"
  >
    <!-- Card Header: only render if title, subtitle, actions slot, or title/subtitle slots are present -->
    <div v-if="hasHeader" class="custom-card__header">
      <div class="custom-card__header-text">
        <slot name="title">
          <div v-if="title" class="custom-card__title">{{ title }}</div>
        </slot>
        <slot name="subtitle">
          <div v-if="subtitle" class="custom-card__subtitle">{{ subtitle }}</div>
        </slot>
      </div>
      <div v-if="$slots.actions" class="custom-card__actions">
        <slot name="actions" />
      </div>
    </div>
    <!-- Card Body -->
    <div class="custom-card__body">
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, useSlots } from 'vue'

const props = withDefaults(
  defineProps<{
    title?: string
    subtitle?: string
    bordered?: boolean
  }>(),
  {
    bordered: true
  }
)

const slots = useSlots()

const hasHeader = computed(() => {
  return !!(props.title || props.subtitle || slots.title || slots.subtitle || slots.actions)
})
</script>

<style scoped>
.custom-card {
  background: var(--td-bg-color-container, #ffffff);
  border-radius: var(--td-radius-large, 12px);
  box-shadow: var(--td-shadow-1, 0 1px 10px rgba(0, 0, 0, 0.05));
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  overflow: hidden;
  transition: transform 0.3s cubic-bezier(0.25, 0.8, 0.25, 1), 
              box-shadow 0.3s cubic-bezier(0.25, 0.8, 0.25, 1),
              border-color 0.3s cubic-bezier(0.25, 0.8, 0.25, 1),
              background 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

/* Subtle hover interaction to make UI feel alive and premium */
.custom-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--td-shadow-2, 0 4px 20px rgba(0, 0, 0, 0.08));
}

/* Premium Dark Mode Glassmorphism Override */
[theme-mode='dark'] .custom-card {
  background: rgba(9, 13, 26, 0.45);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
  border-color: rgba(255, 255, 255, 0.08);
}

[theme-mode='dark'] .custom-card:hover {
  background: rgba(9, 13, 26, 0.55);
  border-color: rgba(255, 255, 255, 0.15);
  box-shadow: 0 12px 40px 0 rgba(0, 0, 0, 0.5);
}

.custom-card--bordered {
  border: 1px solid var(--td-border-level-1-color, rgba(255, 255, 255, 0.08));
}

.custom-card__header {
  padding: 16px 20px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  border-bottom: 1px solid var(--td-border-level-1-color, rgba(255, 255, 255, 0.05));
  gap: 16px;
}

.custom-card__header-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}

.custom-card__title {
  font-size: 16px;
  font-weight: 600;
  color: var(--td-text-color-primary, #ffffff);
}

.custom-card__subtitle {
  font-size: 12px;
  color: var(--td-text-color-placeholder, #888888);
}

.custom-card__actions {
  display: flex;
  align-items: center;
}

.custom-card__body {
  padding: 20px;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.custom-card__body:empty {
  display: none;
}
</style>
