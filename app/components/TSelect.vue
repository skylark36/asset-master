<template>
  <div class="t-select-wrapper" ref="selectRef">
    <div class="t-select-trigger" @click="toggleDropdown">
      <t-input
        :model-value="localInputVal"
        :placeholder="placeholder"
        :disabled="disabled"
        :readonly="!filterable"
        @focus="handleFocus"
        @blur="handleBlur"
        @update:model-value="handleInput"
        class="t-select-input-inner"
      >
        <template #suffix>
          <div class="suffix-icons">
            <span v-if="loading" class="t-select-loading-icon">
              <span class="spinner-mini"></span>
            </span>
            <chevron-down-icon 
              v-else 
              class="t-select-arrow" 
              :class="{ 'is-open': isOpen }" 
            />
          </div>
        </template>
      </t-input>
    </div>

    <!-- Dropdown overlay showing the slot directly -->
    <div v-show="isOpen" class="t-select-dropdown">
      <div v-if="loading" class="t-select-dropdown-loading">
        <span class="spinner"></span>
        <span>Searching...</span>
      </div>
      <div v-else-if="registeredOptions.length === 0" class="t-select-dropdown-empty">
        No results
      </div>
      <div v-else class="t-select-options-list">
        <slot />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, provide, onMounted, onUnmounted } from 'vue'
import { ChevronDownIcon } from 'tdesign-icons-vue-next'

const props = withDefaults(
  defineProps<{
    modelValue?: any
    value?: any
    placeholder?: string
    filterable?: boolean
    disabled?: boolean
    loading?: boolean
  }>(),
  {
    placeholder: '',
    filterable: false,
    disabled: false,
    loading: false
  }
)

const emit = defineEmits([
  'update:modelValue',
  'update:value',
  'change',
  'search',
  'focus',
  'blur'
])

const selectRef = ref<HTMLElement | null>(null)
const isOpen = ref(false)
const isFocused = ref(false)
const searchQuery = ref('')
const localInputVal = ref('')

const registeredOptions = ref<{ value: any; label: string }[]>([])

const selectedValue = computed(() => {
  return props.modelValue !== undefined ? props.modelValue : props.value
})

// Sync display input value based on selected value and registered options
function updateLocalInput() {
  if (isFocused.value && props.filterable) {
    return
  }
  const matched = registeredOptions.value.find(opt => opt.value === selectedValue.value)
  localInputVal.value = matched ? matched.label : (selectedValue.value || '')
}

watch(selectedValue, () => {
  updateLocalInput()
})

watch(registeredOptions, () => {
  updateLocalInput()
}, { deep: true })

// Registration APIs for TOption children
function registerOption(opt: { value: any; label: string }) {
  const idx = registeredOptions.value.findIndex(o => o.value === opt.value)
  if (idx !== -1) {
    registeredOptions.value[idx] = opt
  } else {
    registeredOptions.value.push(opt)
  }
}

function unregisterOption(value: any) {
  const idx = registeredOptions.value.findIndex(o => o.value === value)
  if (idx !== -1) {
    registeredOptions.value.splice(idx, 1)
  }
}

function updateOption(value: any, updates: Partial<{ label: string }>) {
  const idx = registeredOptions.value.findIndex(o => o.value === value)
  if (idx !== -1) {
    registeredOptions.value[idx] = { ...registeredOptions.value[idx], ...updates }
  }
}

function selectOption(option: { value: any; label: string }) {
  emit('update:modelValue', option.value)
  emit('update:value', option.value)
  emit('change', option.value)
  isOpen.value = false
  isFocused.value = false
  localInputVal.value = option.label
}

provide('t-select-context', {
  selectedValue,
  registerOption,
  unregisterOption,
  updateOption,
  selectOption
})

function toggleDropdown() {
  if (props.disabled) return
  if (!props.filterable) {
    isOpen.value = !isOpen.value
  } else {
    isOpen.value = true
  }
}

function handleFocus(e: any) {
  if (props.disabled) return
  isFocused.value = true
  isOpen.value = true
  emit('focus', e)
  if (props.filterable) {
    searchQuery.value = ''
    emit('search', '')
  }
}

function handleBlur(e: any) {
  emit('blur', e)
}

function handleInput(val: any) {
  // Safe extraction of the typed text
  const cleanVal = (val && typeof val === 'object' && 'target' in val) ? val.target.value : val
  if (!props.filterable) return
  localInputVal.value = cleanVal
  searchQuery.value = cleanVal
  emit('search', cleanVal)
  isOpen.value = true
}

// Click outside handling to close dropdown
function handleClickOutside(e: MouseEvent) {
  if (selectRef.value && !selectRef.value.contains(e.target as Node)) {
    isOpen.value = false
    isFocused.value = false
    updateLocalInput()
  }
}

onMounted(() => {
  window.addEventListener('click', handleClickOutside)
  updateLocalInput()
})

onUnmounted(() => {
  window.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.t-select-wrapper {
  position: relative;
  width: 100%;
}

.t-select-trigger {
  width: 100%;
  cursor: pointer;
}

.t-select-input-inner {
  width: 100%;
}

.suffix-icons {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.t-select-arrow {
  font-size: 16px;
  color: var(--td-text-color-placeholder, #888888);
  transition: transform 0.3s ease;
  cursor: pointer;
}

.t-select-arrow.is-open {
  transform: rotate(180deg);
}

.t-select-loading-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 4px;
}

/* Floating Dropdown Styles */
.t-select-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 1000;
  margin-top: 4px;
  max-height: 250px;
  overflow-y: auto;
  background: var(--td-bg-color-container, #ffffff);
  border: 1px solid var(--td-border-level-1-color, rgba(0, 0, 0, 0.15));
  border-radius: 8px;
  box-shadow: var(--td-shadow-2, 0 4px 20px rgba(0, 0, 0, 0.08));
  transition: background 0.3s, border-color 0.3s;
}

/* Premium Dark Mode Glassmorphism Override */
[theme-mode='dark'] .t-select-dropdown {
  background: rgba(15, 20, 35, 0.95);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-color: rgba(255, 255, 255, 0.08);
  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.5);
}

.t-select-dropdown-loading,
.t-select-dropdown-empty {
  padding: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: var(--td-text-color-secondary, #888888);
  font-size: 14px;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid var(--td-border-level-1-color, rgba(255, 255, 255, 0.1));
  border-top-color: var(--td-brand-color, #0052d9);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.spinner-mini {
  width: 14px;
  height: 14px;
  border: 1.5px solid var(--td-border-level-1-color, rgba(255, 255, 255, 0.1));
  border-top-color: var(--td-brand-color, #0052d9);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
