<template>
  <t-button
    variant="text"
    shape="square"
    :aria-label="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
    @click="toggle"
    class="theme-toggle"
  >
    <template #icon>
      <sunny-icon v-if="isDark" />
      <moon-icon v-else />
    </template>
  </t-button>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { SunnyIcon, MoonIcon } from 'tdesign-icons-vue-next'

const { isDark, toggle, init } = useDarkMode()

onMounted(() => {
  init()
})
</script>

<style scoped>
.theme-toggle {
  color: var(--td-text-color-primary);
}
</style>
