<script setup lang="ts">
import { defineComponent } from 'vue'
import ThemeLayout from './theme-layout.vue'

const components = defineComponent({ ThemeLayout })
const props = defineProps<{
  image?: string
}>();
</script>

<template>
  <theme-layout layout-class="relative">
      <div class="content my-auto col-span-10 py-0 col-start-2">
        <slot />

        <div class="col-span-12 my-auto h-full w-full grid grid-cols-12">
          <div v-if="image" class="my-auto manual-shadow col-span-10 col-start-2">
            <img :src="image" />
          </div>
        </div>
      </div>s
  </theme-layout>
</template>
