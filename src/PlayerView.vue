<template>
    <input type="button" value="Open File" @click.prevent="openFilePicker"/>
    <div>
        <div id="player-view-main">
            <h2>Player View</h2>
            <p v-if="!title">Loading...</p>
            <p v-if="title">{{ title }}</p>
            <audio id="player-audio" style="display: none;"></audio>
            <hr />
        </div>
        <div id="player-view-bar">
            <PlayerBar :title="title" :artist="artist" :picture="picture" :play-state="playState"/>
        </div>
    </div>
</template>

<style scoped>
#player-view-bar {
    position: absolute;
    bottom: 0;
    height: 80px;
    width: 100%;
}

#player-view-main {
    padding: 1rem;
}
</style>
  
<script setup lang="ts">
    import { ref, watch, defineProps, inject, onUnmounted } from "vue";
    import { parseBuffer } from "music-metadata";
    import { readBinaryFile } from '@tauri-apps/api/fs';
    import PlayerBar from "./components/PlayerBar.vue";
    import { open } from '@tauri-apps/api/dialog';
    import { createNewAudioContext } from "./audio";

    let title = ref("Loading...");
    let artist = ref<string|null>(null);
    let picture = ref<any|null>(null);

    let $bus = inject<any>("$bus");

    let audio: HTMLAudioElement;

    let playState = ref({
      isPlaying: false,
      maxTime: 99999,
      currentTime: 0
    });

    let audioContext = createNewAudioContext();
    let mediaNode: MediaElementAudioSourceNode;
    let gainNode = audioContext.createGain();

    gainNode.gain.setValueAtTime(1, 0);
    gainNode.connect(audioContext.destination);

    $bus.$on("setPlayState", (play: boolean) => {
      console.log("play state changed to " + play)
      if (play) {
          audio?.play()
      } else {
          audio?.pause()
      }
    });

    $bus.$on("setPlayTime", (t: number) => {
        if(audio)
            audio.currentTime = t;
    });

    $bus.$on("setPlayVolume", (vol: number) => {
      gainNode.gain.setValueAtTime(vol/100, audioContext.currentTime);
    });

    onUnmounted(() => {
      $bus.$off("setPlayState");
      $bus.$off("setPlayVolume");
      gainNode.disconnect();
      console.log(audioContext.sampleRate);
    });

    async function openFilePicker() {
      let path = await open({
        multiple: false,
        filters: [{
          name: 'Image',
          extensions: ['mp3', 'wav', 'ogg']
        }]
      });

      if (typeof path === "object" && path) {
            path = path[0];
      }

      if (!path) {
          return;
      }

      let d: any;

      readBinaryFile(path).then((data) => {
          d = data;
          return parseBuffer(data);
      }).then((metadata) => {
          title.value = metadata.common.title || path;

          if (metadata.common.title) {
              artist.value = metadata.common.artist || "Unknown artist";
          } else {
              artist.value = null;
          }

          if (metadata.common.picture) {
              picture.value = {
                  data: metadata.common.picture[0].data,
                  format: metadata.common.picture[0].format
              };
          } else {
              picture.value = null;
          }
          mediaNode?.disconnect();
          let blob = new Blob([d], { type: `audio/${metadata.format.container?.toLowerCase() || "mpeg"}` });
          audio = document.getElementById("player-audio") as HTMLAudioElement;
          audio.src = URL.createObjectURL(blob);
          playState.value.maxTime = metadata.format.duration || 0;
          if (!mediaNode)
              mediaNode = audioContext.createMediaElementSource(audio);
          mediaNode.connect(gainNode);
          audio.addEventListener("timeupdate", (event) => {
              if (!event.target) return;
              let target = event.target as HTMLAudioElement;
              playState.value.currentTime = target.currentTime;
          })

          audio.addEventListener("play", () => playState.value.isPlaying = true)
          audio.addEventListener("pause", () => playState.value.isPlaying = false)
          audio.addEventListener("ended", () => {
            playState.value.isPlaying = false;
          })
      });
    }


</script>
  
  
