<template>
    <div id="player-bar-info">
        <p>{{ props.title }} {{ artist ? `- ${props.artist}` : '' }}</p>
    </div>
</template>

<style scoped>

div {
    height: 100%;
    overflow: hidden;
}

</style>

<script setup lang="ts">
    import { ref, defineProps, watch } from "vue";
    
    const props = defineProps<{ title: string, artist: string|null, picture: any }>();

    watch(props, (_, newProps) => {
        if (newProps.picture) {
            let container = document.getElementById("player-bar-info")

            let img = document.getElementById("player-bar-info-image") as HTMLImageElement
            if (img) {
                img.remove();
            }

            img = document.createElement("img");
            img.id = "player-bar-info-image";
            const blob = new Blob([newProps.picture.data], {type: newProps.picture.format});
            img.src = URL.createObjectURL(blob);
            img.style.float = "left"

            if (container?.firstChild) {
                container.insertBefore(img, container.firstChild)
            } else {
                container?.appendChild(img)
            }
        }
    })
</script>