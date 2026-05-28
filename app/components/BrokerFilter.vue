<template>
  <t-card class="broker-filter-card" bordered>
    <div class="section-title">Broker Filtering</div>
    
    <!-- Select Broker Filter -->
    <div class="filter-group">
      <label class="field-label">Active Broker Filter</label>
      <t-select
        v-model="portfolioStore.selectedBroker"
        placeholder="Select Broker"
        @change="handleBrokerChange"
      >
        <t-option
          v-for="broker in portfolioStore.availableBrokers"
          :key="broker"
          :value="broker"
          :label="broker"
        />
      </t-select>
    </div>

    <!-- Manage Custom Brokers -->
    <div class="manage-group">
      <label class="field-label">Manage Custom Brokers</label>
      <t-space wrap size="small" class="broker-tags">
        <t-tag
          v-for="broker in portfolioStore.customBrokers"
          :key="broker"
          theme="primary"
          variant="light"
          closable
          @close="removeBroker(broker)"
        >
          {{ broker }}
        </t-tag>
        <span v-if="portfolioStore.customBrokers.length === 0" class="no-custom">No custom brokers added.</span>
      </t-space>
      
      <div class="add-broker-input">
        <t-input
          v-model="newBrokerName"
          placeholder="New broker name..."
          @enter="addBroker"
        >
          <template #suffix>
            <t-button variant="text" shape="square" @click="addBroker">
              <template #icon><add-icon /></template>
            </t-button>
          </template>
        </t-input>
      </div>
    </div>
  </t-card>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { AddIcon } from 'tdesign-icons-vue-next'
import { usePortfolioStore } from '~/stores/portfolio'

const portfolioStore = usePortfolioStore()
const newBrokerName = ref('')

onMounted(() => {
  portfolioStore.initBrokers()
})

function handleBrokerChange(val: any) {
  portfolioStore.selectBroker(val as string)
}

function addBroker() {
  const name = newBrokerName.value.trim()
  if (name) {
    portfolioStore.addCustomBroker(name)
    newBrokerName.value = ''
  }
}

function removeBroker(name: string) {
  portfolioStore.removeCustomBroker(name)
}
</script>

<style scoped>
.broker-filter-card {
  height: 350px;
  display: flex;
  flex-direction: column;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--td-text-color-primary);
  margin-bottom: 16px;
}

.filter-group, .manage-group {
  margin-bottom: 16px;
}

.field-label {
  display: block;
  font-size: 12px;
  color: var(--td-text-color-secondary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}

.broker-tags {
  min-height: 32px;
  margin-bottom: 12px;
  display: block;
}

.no-custom {
  font-size: 13px;
  color: var(--td-text-color-placeholder);
}

.add-broker-input {
  margin-top: 8px;
}
</style>
