<template>
  <div class="profile-page">
    <div class="profile-grid">
      <!-- Left side: Portfolio management -->
      <div class="grid-col">
        <!-- Active Portfolio Info & Currency Update -->
        <t-card class="section-card" title="Portfolio Settings" bordered>
          <t-form label-align="top" class="form-spacing">
            <t-form-item label="Active Portfolio">
              <t-input :value="portfolioStore.selectedPortfolio?.name" disabled />
            </t-form-item>
            <t-form-item label="Base Currency">
              <t-select
                v-model="portfolioCurrency"
                placeholder="Select Currency"
                @change="handleCurrencyChange"
                :loading="portfolioStore.isValuationLoading"
              >
                <t-option value="USD" label="USD - US Dollar" />
                <t-option value="EUR" label="EUR - Euro" />
                <t-option value="GBP" label="GBP - British Pound" />
                <t-option value="JPY" label="JPY - Japanese Yen" />
                <t-option value="HKD" label="HKD - Hong Kong Dollar" />
                <t-option value="SGD" label="SGD - Singapore Dollar" />
              </t-select>
            </t-form-item>
          </t-form>
        </t-card>

        <!-- Create Portfolio -->
        <t-card class="section-card" title="Create New Portfolio" bordered>
          <t-form :model="newPort" :rules="newPortRules" ref="newPortForm" @submit="handleCreatePortfolio" label-align="top">
            <t-form-item label="Portfolio Name" name="name">
              <t-input v-model="newPort.name" placeholder="e.g. Crypto Ledger" />
            </t-form-item>
            <t-form-item label="Description" name="description">
              <t-input v-model="newPort.description" placeholder="e.g. Cold storage tokens" />
            </t-form-item>
            <t-form-item label="Initial Base Currency" name="currency">
              <t-select v-model="newPort.currency" placeholder="Select Currency">
                <t-option value="USD" label="USD - US Dollar" />
                <t-option value="EUR" label="EUR - Euro" />
                <t-option value="GBP" label="GBP - British Pound" />
                <t-option value="JPY" label="JPY - Japanese Yen" />
              </t-select>
            </t-form-item>
            <div class="submit-container">
              <t-button theme="primary" type="submit" :loading="portfolioStore.isLoading">
                Create Portfolio
              </t-button>
            </div>
          </t-form>
        </t-card>
      </div>

      <!-- Right side: Feedback Form -->
      <div class="grid-col">
        <t-card class="section-card" title="Submit Feedback" subtitle="Report bugs or request new features. Feedback is synced to Cloudflare D1." bordered>
          <t-alert 
            v-if="portfolioStore.feedbackSubmittedSuccess" 
            theme="success" 
            message="Feedback submitted successfully! Thank you." 
            class="feedback-alert"
          />

          <t-form label-align="top" @submit="handleFeedbackSubmit">
            <t-form-item label="Category">
              <t-select v-model="portfolioStore.feedbackCategory">
                <t-option value="Bug Report" label="Bug Report" />
                <t-option value="Feature Request" label="Feature Request" />
                <t-option value="UI Suggestion" label="UI/UX Suggestion" />
                <t-option value="Other" label="Other" />
              </t-select>
            </t-form-item>

            <t-form-item label="Rating">
              <t-rate v-model="portfolioStore.feedbackRating" />
            </t-form-item>

            <t-form-item label="Description">
              <t-textarea 
                v-model="portfolioStore.feedbackText" 
                placeholder="Write your feedback here..." 
                :autosize="{ minRows: 4, maxRows: 8 }"
              />
            </t-form-item>

            <div class="submit-container">
              <t-button 
                theme="primary" 
                type="submit" 
                :loading="portfolioStore.isFeedbackSubmitting"
                :disabled="!portfolioStore.feedbackText.trim()"
              >
                Send Feedback
              </t-button>
            </div>
          </t-form>
        </t-card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, watch } from 'vue'
import { MessagePlugin } from 'tdesign-vue-next'
import type { SubmitContext } from 'tdesign-vue-next'
import { usePortfolioStore } from '~/stores/portfolio'

const portfolioStore = usePortfolioStore()

const portfolioCurrency = ref(portfolioStore.selectedPortfolio?.currency || 'USD')

watch(() => portfolioStore.selectedPortfolio?.currency, (newVal) => {
  if (newVal) {
    portfolioCurrency.value = newVal
  }
})

const newPort = reactive({
  name: '',
  description: '',
  currency: 'USD'
})

const newPortRules = {
  name: [{ required: true, message: 'Portfolio name is required', trigger: 'blur' }],
  currency: [{ required: true, message: 'Base currency is required', trigger: 'change' }]
}

async function handleCurrencyChange(val: any) {
  const success = await portfolioStore.updateSelectedPortfolioCurrency(val as string)
  if (success) {
    MessagePlugin.success(`Base currency updated to ${val}`)
  } else {
    MessagePlugin.error('Failed to update base currency')
  }
}

async function handleCreatePortfolio({ validateResult, e }: SubmitContext) {
  if (e) {
    e.preventDefault()
  }
  if (validateResult !== true) return

  const success = await portfolioStore.createPortfolio(newPort.name, newPort.description, newPort.currency)
  if (success) {
    MessagePlugin.success(`Portfolio "${newPort.name}" created!`)
    newPort.name = ''
    newPort.description = ''
  } else {
    MessagePlugin.error(portfolioStore.errorMessage || 'Failed to create portfolio')
  }
}

async function handleFeedbackSubmit(e: any) {
  if (e) e.preventDefault()
  if (!portfolioStore.feedbackText.trim()) return

  await portfolioStore.submitFeedback()
  if (portfolioStore.feedbackSubmittedSuccess) {
    MessagePlugin.success('Feedback sent!')
  }
}
</script>

<style scoped>
.profile-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.grid-col {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.form-spacing {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.submit-container {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

.feedback-alert {
  margin-bottom: 16px;
}

@media (max-width: 768px) {
  .profile-grid {
    grid-template-columns: 1fr;
  }
}
</style>
