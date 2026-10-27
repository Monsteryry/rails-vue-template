<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { getHealth, type Health } from '@/api/client'

const health = ref<Health | null>(null)
const error = ref<string | null>(null)

onMounted(async () => {
  try {
    health.value = await getHealth()
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e)
  }
})
</script>

<template>
  <main>
    <h2>Backend status</h2>
    <p v-if="health">
      <strong>{{ health.status }}</strong> · Rails {{ health.rails }}<br />
      <small>{{ health.database }}</small
      ><br />
      <small>Redis: {{ health.redis }}</small>
    </p>
    <p v-else-if="error">Could not reach the API: {{ error }}</p>
    <p v-else>Checking…</p>
  </main>
</template>
