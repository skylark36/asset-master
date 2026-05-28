<template>
  <!-- Mobile Platform Layout using tdesign-mobile-vue -->
  <div v-if="authStore.isLoggedIn && isMobile" class="mobile-layout">
    <!-- Mobile NavBar -->
    <m-navbar :title="pageTitle" class="mobile-header">
      <template #right>
        <theme-toggle />
      </template>
    </m-navbar>

    <!-- Mobile Content Body -->
    <div class="mobile-content">
      <slot />
    </div>

    <!-- Mobile Bottom TabBar -->
    <m-tab-bar v-model="mobileActiveTab" @change="handleMobileTabChange" class="mobile-tab-bar">
      <m-tab-bar-item value="dashboard" label="Dashboard">
        <template #icon><dashboard-icon /></template>
      </m-tab-bar-item>
      <m-tab-bar-item value="settings" label="Settings">
        <template #icon><setting-icon /></template>
      </m-tab-bar-item>
    </m-tab-bar>
  </div>

  <!-- Desktop Layout using tdesign-vue-next -->
  <t-layout class="app-layout" v-else-if="authStore.isLoggedIn && !isMobile">
    <!-- Sidebar -->
    <t-aside class="sidebar-aside">
      <t-menu theme="dark" :value="activeMenu" class="sidebar-menu">
        <template #logo>
          <div class="logo-area">
            <span class="brand-gradient-text brand-name">ASSET MASTER</span>
          </div>
        </template>
        
        <!-- Menu Items -->
        <t-menu-item value="dashboard" @click="navigateTo('/')">
          <template #icon><dashboard-icon /></template>
          Dashboard
        </t-menu-item>
        <t-menu-item value="settings" @click="navigateTo('/profile')">
          <template #icon><setting-icon /></template>
          Settings
        </t-menu-item>

        <!-- Dynamic Portfolio List inside sidebar menu -->
        <div class="portfolio-switcher-section">
          <div class="switcher-title">Portfolios</div>
          <t-select
            v-model="activePortfolioId"
            placeholder="Select Portfolio"
            size="small"
            class="port-selector"
            @change="handlePortfolioChange"
          >
            <t-option
              v-for="p in portfolioStore.portfolios"
              :key="p.id"
              :value="p.id"
              :label="p.name"
            />
          </t-select>
        </div>
      </t-menu>
    </t-aside>

    <!-- Main Content Area -->
    <t-layout class="main-layout">
      <t-header class="app-header">
        <div class="header-left">
          <h2 class="page-title">{{ pageTitle }}</h2>
        </div>
        <div class="header-right">
          <t-space size="medium" align="center">
            <!-- Theme Toggle -->
            <theme-toggle />
            
            <!-- User Dropdown -->
            <t-dropdown :options="dropdownOptions" @click="handleDropdownClick">
              <t-button variant="text" class="user-profile-btn">
                <template #icon><user-icon /></template>
                {{ authStore.user?.name || 'User' }}
              </t-button>
            </t-dropdown>
          </t-space>
        </div>
      </t-header>

      <!-- Page Content -->
      <t-content class="app-content">
        <slot />
      </t-content>
    </t-layout>
  </t-layout>

  <!-- Render slot directly for login/register pages without layout wrapper -->
  <div v-else class="auth-layout-container">
    <slot />
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, watch, h } from 'vue'
import { useRoute } from 'vue-router'
import {
  DashboardIcon,
  SettingIcon,
  UserIcon,
  LogoutIcon
} from 'tdesign-icons-vue-next'
import { TabBar as MTabBar, TabBarItem as MTabBarItem, Navbar as MNavbar } from 'tdesign-mobile-vue'
import { useAuthStore } from '~/stores/auth'
import { usePortfolioStore } from '~/stores/portfolio'
import { useDevice } from '~/composables/useDevice'

const route = useRoute()
const authStore = useAuthStore()
const portfolioStore = usePortfolioStore()
const { isMobile } = useDevice()

// Sync selected portfolio to select dropdown
const activePortfolioId = computed({
  get: () => portfolioStore.selectedPortfolio?.id || '',
  set: (val) => {
    const found = portfolioStore.portfolios.find(p => p.id === val)
    if (found) {
      portfolioStore.selectPortfolio(found)
    }
  }
})

const activeMenu = computed(() => {
  if (route.path === '/profile') return 'settings'
  return 'dashboard'
})

const mobileActiveTab = ref(activeMenu.value)

watch(activeMenu, (newVal) => {
  mobileActiveTab.value = newVal
})

const pageTitle = computed(() => {
  if (route.path === '/profile') return 'Profile & Settings'
  return portfolioStore.selectedPortfolio?.name || 'Dashboard'
})

const dropdownOptions = [
  { content: 'Profile & Settings', value: 'profile', prefixIcon: () => h(SettingIcon) },
  { content: 'Log Out', value: 'logout', theme: 'danger', prefixIcon: () => h(LogoutIcon) }
]

function handleDropdownClick(option: any) {
  if (option.value === 'profile') {
    navigateTo('/profile')
  } else if (option.value === 'logout') {
    authStore.logout()
  }
}

function handlePortfolioChange(val: any) {
  const found = portfolioStore.portfolios.find(p => p.id === val)
  if (found) {
    portfolioStore.selectPortfolio(found)
  }
}

function handleMobileTabChange(value: any) {
  if (value === 'dashboard') {
    navigateTo('/')
  } else if (value === 'settings') {
    navigateTo('/profile')
  }
}

onMounted(() => {
  if (authStore.isLoggedIn) {
    portfolioStore.loadPortfolios()
  }
})
</script>

<style scoped>
/* Desktop layout styles */
.app-layout {
  height: 100vh;
  overflow: hidden;
  background-color: var(--td-bg-color-page);
}

.sidebar-aside {
  width: 240px !important;
  border-right: 1px solid var(--td-border-level-1-color);
}

.sidebar-menu {
  height: 100%;
}

.logo-area {
  padding: 16px 24px;
  display: flex;
  align-items: center;
}

.brand-name {
  font-size: 20px;
  letter-spacing: 0.1em;
  font-weight: 800;
}

.portfolio-switcher-section {
  padding: 16px 20px;
  margin-top: 24px;
  border-top: 1px solid var(--td-border-level-1-color);
}

.switcher-title {
  font-size: 11px;
  color: var(--td-text-color-placeholder);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}

.port-selector {
  width: 100%;
}

.main-layout {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  height: 64px;
  padding: 0 32px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--td-border-level-1-color);
  background: var(--td-bg-color-container);
}

.page-title {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: var(--td-text-color-primary);
}

.user-profile-btn {
  color: var(--td-text-color-primary);
}

.app-content {
  flex: 1;
  padding: 32px;
  overflow-y: auto;
}

.auth-layout-container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--td-bg-color-page);
}

/* Mobile layout styles */
.mobile-layout {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: var(--td-bg-color-page);
}

.mobile-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--td-bg-color-container) !important;
  border-bottom: 1px solid var(--td-border-level-1-color);
}

.mobile-content {
  flex: 1;
  padding: 16px;
  overflow-y: auto;
  padding-bottom: 80px; /* space for tab-bar */
}

.mobile-tab-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 100;
  border-top: 1px solid var(--td-border-level-1-color);
  background: var(--td-bg-color-container) !important;
}
</style>
