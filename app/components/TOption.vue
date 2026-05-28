<template>
  <div
    class="t-select-option"
    :class="{ 'is-selected': isSelected, 'is-disabled': disabled }"
    @click.stop="handleSelect"
  >
    <span class="option-text">
      <slot>{{ label }}</slot>
    </span>
    <check-icon v-if="isSelected" class="t-select-check" />
  </div>
</template>

<script setup lang="ts">
import { inject, computed, onMounted, onUnmounted, watch } from 'vue'
import { CheckIcon } from 'tdesign-icons-vue-next'

const props = withDefaults(
  defineProps<{
    value: any
    label: string
    disabled?: boolean
  }>(),
  {
    disabled: false
  }
)

const selectContext = inject<any>('t-select-context', null)

const isSelected = computed(() => {
  if (!selectContext) return false
  return selectContext.selectedValue.value === props.value
})

function handleSelect() {
  if (props.disabled) return
  if (selectContext) {
    selectContext.selectOption({
      value: props.value,
      label: props.label
    })
  }
}

// Register option to select context so TSelect knows the label for the trigger text
if (selectContext) {
  onMounted(() => {
    selectContext.registerOption({
      value: props.value,
      label: props.label
    })
  })

  onUnmounted(() => {
    selectContext.unregisterOption(props.value)
  })

  watch(() => props.label, (newLabel) => {
    selectContext.updateOption(props.value, { label: newLabel })
  })

  watch(() => props.value, (newValue, oldValue) => {
    selectContext.unregisterOption(oldValue)
    selectContext.registerOption({
      value: newValue,
      label: props.label
    })
  })
}
</script>

<style scoped>
.t-select-option {
  padding: 12px 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  color: var(--td-text-color-primary, #ffffff);
  transition: background-color 0.2s, color 0.2s;
  font-size: 14px;
}

.t-select-option:hover {
  background-color: var(--td-bg-color-hover, rgba(0, 0, 0, 0.05));
}

[theme-mode='dark'] .t-select-option:hover {
  background-color: rgba(255, 255, 255, 0.08);
}

.t-select-option.is-selected {
  color: var(--td-brand-color, #0052d9);
  font-weight: 500;
}

.t-select-option.is-disabled {
  color: var(--td-text-color-disabled, rgba(0, 0, 0, 0.25));
  cursor: not-allowed;
  opacity: 0.6;
}

.t-select-check {
  color: var(--td-brand-color, #0052d9);
  width: 16px;
  height: 16px;
  flex-shrink: 0;
}

.option-text {
  flex: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-right: 8px;
}
</style>
