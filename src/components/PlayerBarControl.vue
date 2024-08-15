
<template>
    <div id="player-bar-controls">
        <div>
            <label>
                <IconPrevious />
                <input hidden type="button" value="previous" @click.prevent="previous">
            </label>
            <label>
                <IconPause v-show="isPlaying"/>
                <IconPlay v-show="!isPlaying"/>
                <input hidden type="button" :value="playButtonText" @click.prevent="togglePlay">
            </label>
            <label>
                <IconNext />
                <input hidden type="button" value="next">
            </label>
        </div>
        <div>
            <input id="play-slider" type="range" min="0" max="100" :value="getPlayTime" @input="setTime"/>
            <input id="volume-slider" type="range" min="0" max="100" :value="100" @input="changeVolume"/>
        </div>
    </div>
</template>

<style scoped>
#player-bar-controls {
    flex-grow: 2;
}
</style>

<script setup lang="ts">
    import IconPlay from './icons/IconPlay.vue';
    import IconPause from './icons/IconPause.vue';
    import IconPrevious from './icons/IconPrevious.vue';
    import IconNext from './icons/IconNext.vue';
    import { ref, computed, inject } from "vue";
    let props = defineProps<{playState: any}>()
    let $bus = inject<any>("$bus");

    let isPlaying = ref(true);
    let playButtonText = computed(() => {
        return isPlaying.value ? "pause" : "play"
    });

    let getPlayTime = computed(() => {
        props;
        return Math.round(props.playState.currentTime / props.playState.maxTime * 100)
    })

    function previous() {
        $bus.$emit("setPlayTime", 0);
    }

    function togglePlay() {
        console.log("setPlayState emitted")
        isPlaying.value = !isPlaying.value;
        $bus.$emit("setPlayState", isPlaying.value);
    }

    function changeVolume(e: any) {
        $bus.$emit("setPlayVolume", e.target.value);
    }

    function setTime(e: any) {
        let time = props.playState.maxTime * parseInt(e.target.value)/100
        $bus.$emit("setPlayTime", time)
    }
</script>
