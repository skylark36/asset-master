<template>
  <div class="login-wrapper">
    <Card class="login-card" bordered>
      <div class="card-header">
        <h1 class="logo-title font-outfit">ASSET MASTER</h1>
        <p class="subtitle">Wealth & Portfolio Ledger</p>
      </div>

      <t-tabs v-model="activeTab" class="login-tabs">
        <!-- Login Tab -->
        <t-tab-panel value="login" label="Log In">
          <t-form :model="loginForm" label-align="top">
            <t-form-item label="Email Address" name="email">
              <t-input v-model="loginForm.email" placeholder="Enter your email" clearable>
                <template #prefix-icon>
                  <mail-icon />
                </template>
              </t-input>
            </t-form-item>
            <t-form-item label="Password" name="password">
              <t-input v-model="loginForm.password" type="password" placeholder="Enter your password" clearable>
                <template #prefix-icon>
                  <lock-on-icon />
                </template>
              </t-input>
            </t-form-item>
            <div class="submit-btn-container">
              <t-button theme="primary" @click="handleLogin" block :loading="loading">
                Sign In
              </t-button>
            </div>
          </t-form>
        </t-tab-panel>

        <!-- Register Tab -->
        <t-tab-panel value="register" label="Register">
          <t-form :model="registerForm" :rules="registerRules" ref="registerFormRef" @submit="handleRegister" label-align="top">
            <t-form-item label="Full Name" name="name">
              <t-input v-model="registerForm.name" placeholder="Enter your name" clearable>
                <template #prefix-icon>
                  <user-icon />
                </template>
              </t-input>
            </t-form-item>
            <t-form-item label="Email Address" name="email">
              <t-input v-model="registerForm.email" placeholder="Enter your email" clearable>
                <template #prefix-icon>
                  <mail-icon />
                </template>
              </t-input>
            </t-form-item>
            <t-form-item label="Password" name="password">
              <t-input v-model="registerForm.password" type="password" placeholder="Create a password" clearable>
                <template #prefix-icon>
                  <lock-on-icon />
                </template>
              </t-input>
            </t-form-item>
            <div class="submit-btn-container">
              <t-button theme="primary" type="submit" block :loading="loading">
                Create Account
              </t-button>
            </div>
          </t-form>
        </t-tab-panel>
      </t-tabs>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { MessagePlugin } from 'tdesign-mobile-vue'
import { MailIcon, LockOnIcon, UserIcon } from 'tdesign-icons-vue-next'
import type { SubmitContext } from 'tdesign-mobile-vue'
import { useAuthStore } from '~/stores/auth'

definePageMeta({
  layout: false // Do not wrap in default layout
})

const authStore = useAuthStore()
const activeTab = ref('login')
const loading = ref(false)

const loginForm = reactive({
  email: '',
  password: ''
})

const registerForm = reactive({
  name: '',
  email: '',
  password: ''
})

const loginRules = {
  email: [
    { required: true, message: 'Email is required', trigger: 'blur' },
    { email: true, message: 'Please enter a valid email', trigger: 'blur' }
  ],
  password: [{ required: true, message: 'Password is required', trigger: 'blur' }]
}

const registerRules = {
  name: [{ required: true, message: 'Name is required', trigger: 'blur' }],
  email: [
    { required: true, message: 'Email is required', trigger: 'blur' },
    { email: true, message: 'Please enter a valid email', trigger: 'blur' }
  ],
  password: [
    { required: true, message: 'Password is required', trigger: 'blur' },
    { min: 6, message: 'Password must be at least 6 characters', trigger: 'blur' }
  ]
}

async function handleLogin() {

  console.log('login test', loginForm.email, loginForm.password)
  loading.value = true
  try {
    const success = await authStore.login(loginForm.email, loginForm.password)
    if (success) {
      MessagePlugin.success('Signed in successfully!')
      navigateTo('/')
    }
  } catch (err: any) {
    MessagePlugin.error(err.statusMessage || err.message || 'Invalid email or password')
  } finally {
    loading.value = false
  }
}

async function handleRegister({ validateResult, e }: SubmitContext) {
  if (e) {
    e.preventDefault()
  }
  if (validateResult !== true) return

  loading.value = true
  try {
    const success = await authStore.register(registerForm.email, registerForm.name, registerForm.password)
    if (success) {
      MessagePlugin.success('Account created successfully!')
      navigateTo('/')
    }
  } catch (err: any) {
    MessagePlugin.error(err.statusMessage || err.message || 'Registration failed')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  width: 100vw;
  padding: 20px;
  background-color: var(--td-bg-color-page);
}

.login-card {
  width: 100%;
  max-width: 440px;
}

.card-header {
  text-align: center;
  margin-bottom: 24px;
}

.logo-title {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
  letter-spacing: 0.05em;
  color: var(--td-brand-color);
}

.subtitle {
  margin: 4px 0 0 0;
  font-size: 14px;
  color: var(--td-text-color-secondary);
}

.login-tabs {
  margin-top: 16px;
}

.submit-btn-container {
  margin-top: 24px;
}

:deep(.t-tabs__nav) {
  margin-bottom: 24px;
}
</style>
