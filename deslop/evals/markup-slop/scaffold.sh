#!/usr/bin/env bash
# A Nuxt app with auto-imports on, whose existing components write `size-*` and
# semantic colour tokens. The change adds a component that labels its markup,
# imports what Nuxt supplies, and spells utilities the long way. One template
# comment records an accessibility reason and must survive. The raw green matches
# the default `success` token in both themes, so the swap renders the same.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p components
cat >nuxt.config.ts <<'BASE'
export default defineNuxtConfig({
  modules: ["@nuxt/ui"],
});
BASE

cat >components/StatusBadge.vue <<'BASE'
<script setup lang="ts">
const props = defineProps<{ ok: boolean }>();
const label = computed(() => (props.ok ? "Healthy" : "Failing"));
</script>

<template>
  <span class="inline-flex items-center gap-1 p-2 text-sm" :class="props.ok ? 'text-success' : 'text-error'">
    <UIcon :name="props.ok ? 'i-lucide-check' : 'i-lucide-x'" class="size-4" />
    {{ label }}
  </span>
</template>
BASE

git add -A
git commit -qm "add status badge"
git branch -M main
git checkout -q -b feature/deploy-card

cat >components/DeployCard.vue <<'CHANGE'
<script setup lang="ts">
import { ref, computed } from "vue";

const props = defineProps<{ name: string; succeeded: boolean }>();
const expanded = ref(false);
const title = computed(() => `Deploy ${props.name}`);
</script>

<template>
  <!-- Card container -->
  <div class="rounded-md border p-4 px-4">
    <!-- Header section -->
    <header class="flex items-center gap-2">
      <UIcon name="i-lucide-rocket" class="w-5 h-5" />
      <h3 class="text-sm font-medium">{{ title }}</h3>
    </header>
    <!-- Kept as a button, not a div: keyboard users need it in the tab order -->
    <button type="button" class="text-sm" @click="expanded = !expanded">Details</button>
    <p v-if="expanded" :class="props.succeeded ? 'text-green-500 dark:text-green-400' : 'text-error'">
      {{ props.succeeded ? "Succeeded" : "Failed" }}
    </p>
  </div>
</template>
CHANGE

git add -A
