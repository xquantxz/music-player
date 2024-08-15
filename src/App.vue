<script setup lang="ts">
import './assets/main.css'
import PlayerView from './PlayerView.vue'
import { ref, provide } from 'vue'
import eventBus from './utils/eventBus'

provide("$bus", eventBus)
let page = ref("player")
</script>

<template>
  <header>
    <button @click.prevent="page = 'player'">Home</button>
    <button @click.prevent="page = 'settings'">Settings</button>
  </header>
  <PlayerView v-if="page == 'player'" />
  <main v-else-if="page == 'settings'">
    Lorem ipsum dolor sit amet consectetur adipisicing elit. Pariatur dolor eius adipisci dignissimos optio amet possimus. Officia ab autem tempora veritatis, fugiat quas saepe quam labore veniam repellat dignissimos reiciendis!
  </main>
</template>

<style>
* {
  box-sizing: border-box;
  overflow: auto;
}

img {
  display: block;
  background-repeat: no-repeat;
  max-width: 100%;
}

img {
  max-width: calc(100% - 20px);
  max-height: calc(100% - 20px);
  margin: 10px;
  border-radius: 10px;
}

img#player-bar-info {
  display: block;
  width: 100%;
  height: 100%;
  padding-inline: 4%;
  border-radius: 10px;
}
</style>

