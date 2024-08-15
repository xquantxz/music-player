<template>
    <div id="player-bar">
        <PlayerBarInfo :title="title" :artist="artist" :picture="picture"/>
        <PlayerBarControl :play-state="playState"/>
    </div>
</template>

<style scoped>

#player-bar {
    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    align-items: center;
    width: 100%;
    height: 100%;
    overflow: hidden;
    background-color: rgb(0, 0, 0);
    color: rgb(255,255,255);
}

#player-bar > * {
    flex-basis: auto;
    flex-grow: 1;
}
</style>

<script setup lang="ts">
import { ref, defineProps } from "vue";
import PlayerBarControl from "./PlayerBarControl.vue";
import PlayerBarInfo from "./PlayerBarInfo.vue";

const props = defineProps<{ title: string, artist: string|null, picture: any, playState: any }>();
</script>