<template>
    <canvas id="shader-canvas" :onload="loadWebGPU" width="300px" height="300px"></canvas>
</template>

<script setup lang="ts">
    // @ts-nocheck
    
    import { inject, onMounted, onUnmounted } from 'vue';
    import fragmentShaderSource from '../assets/shaders/user.wgsl?raw';
    import { getWebGPUDevice, updateUniform } from '@/utils/webgpu';
    import { appWindow } from "@tauri-apps/api/window";

    let keepRendering = true;
    let device;
    let resolutionBuffer;

    function onWindowResize() {
        const canvas = document.getElementById("shader-canvas") as HTMLCanvasElement;
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        console.log("updated")
        updateUniform(device, new Float32Array([canvas.width, canvas.height]), resolutionBuffer);
    }
    
    window.addEventListener('resize', onWindowResize);


    async function loadWebGPU() {
        let analyserNode = inject("analyserNode");
        let audioContext = inject("audioContext");
        device = await getWebGPUDevice();
        if (!device) {
            return;
        }
        
        const canvas = document.getElementById("shader-canvas") as HTMLCanvasElement;
        canvas.width = window.innerWidth;
        canvas.height =  window.innerHeight;
        const ctx = canvas.getContext("webgpu");
        const preferredFormat = navigator.gpu.getPreferredCanvasFormat();
        
        ctx.configure({
            device,
            format: preferredFormat
        });
        
        const vertices = new Float32Array([
            -1, -1,
            1, -1,
            1,  1,
            -1, -1,
            1,  1,
            -1,  1,
        ]);

        const vertexBuffer = device.createBuffer({
            label: "viewport vertices",
            size: vertices.byteLength,
            usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
        });

        device.queue.writeBuffer(vertexBuffer, 0, vertices);
        const vertexBufferLayout = {
            arrayStride: 8,
            attributes: [{
                format: "float32x2",
                offset: 0,
                shaderLocation: 0,
            }],
        }

        const shaderModule = device.createShaderModule({
            label: "player shader",
            code: `
                @group(0) @binding(0) var<uniform> time: f32;
                @group(0) @binding(1) var<uniform> resolution: vec2f;
                @group(0) @binding(2) var<uniform> freqBass: f32;
                @group(0) @binding(3) var<uniform> kickDetected: f32; // use as bool

                struct VertexOutput {
                    @builtin(position) pos: vec4f,
                    @location(0) fragPos: vec2f,
                    @location(1) data: vec2f,
                }

                @vertex fn vertexMain(@location(0) pos: vec2f) -> VertexOutput {
                    let a0 = freqBass;
                    let a1 = time;
                    let a2 = kickDetected;
                    var output: VertexOutput;
                    output.pos = vec4f(pos,0,1);
                    output.fragPos = (pos+1)/2 * resolution;
                    output.data = pos;
                    return output;
                }
            
            ` + fragmentShaderSource
        });

        const pipeline = device.createRenderPipeline({
            label: "pipeline",
            layout: "auto",
            vertex: {
                module: shaderModule,
                entryPoint: "vertexMain",
                buffers: [vertexBufferLayout]
            },
            fragment: {
                module: shaderModule,
                entryPoint: "fragmentMain",
                targets: [{
                    format: preferredFormat
                }]
            }
        });

        let t = 0;
        const timeData = new Float32Array([t]);
        const timeBuffer = device.createBuffer({
            label: "time uniform buffer",
            size: timeData.byteLength,
            usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
        });
        device.queue.writeBuffer(timeBuffer, 0, timeData);

        const resolutionData = new Float32Array([canvas.width, canvas.height]);
        resolutionBuffer = device.createBuffer({
            label: "resolution uniform buffer",
            size: resolutionData.byteLength,
            usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
        });

        device.queue.writeBuffer(resolutionBuffer, 0, resolutionData);

        let freqData = new Uint8Array(analyserNode.frequencyBinCount)
        analyserNode.getByteFrequencyData(freqData);

        const freqBassData = new Float32Array([freqData[21]]);
        const freqBassBuffer = device.createBuffer({
            label: "freq bass uniform buffer",
            size: freqData.byteLength,
            usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
        });

        device.queue.writeBuffer(freqBassBuffer, 0, freqBassData);

        const kickDataBuffer = device.createBuffer({
            size: 4,
            usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
        });

        const generalBindGroup = device.createBindGroup({
            label: "general info bind group",
            layout: pipeline.getBindGroupLayout(0),
            entries: [{
                binding: 0,
                resource: { buffer: timeBuffer }
            },
            {
                binding: 1,
                resource: { buffer: resolutionBuffer }
            },
            {
                binding: 2,
                resource: { buffer: freqBassBuffer }
            },
            {
                binding: 3,
                resource: { buffer: kickDataBuffer }
            }],
        });

        function calculateFrequencyAverage(min, max) {
            const frequencyRange = {
                minIndex: Math.floor(min / (audioContext.sampleRate / 2) * freqData.length),
                maxIndex: Math.ceil(max / (audioContext.sampleRate / 2) * freqData.length),
            };

            let sum = 0;
            let count = 0;
            for (let i = frequencyRange.minIndex; i <= frequencyRange.maxIndex; i++) {
                sum += freqData[i];
                count++;
            }
            const freqBass = sum / count;
            return freqBass;
        }

        function calculateFreqBass() {
            return calculateFrequencyAverage(20, 250);
        }

        function render() {
            analyserNode.getByteFrequencyData(freqData);

            let bassAmp = calculateFrequencyAverage(20, 150)
            if (bassAmp > 230) {
                updateUniform(device, new Float32Array([1]), kickDataBuffer)
            } else {
                updateUniform(device, new Float32Array([0]), kickDataBuffer)
            }

            updateUniform(device, new Float32Array([calculateFreqBass()]), freqBassBuffer);
            const encoder = device.createCommandEncoder();
            
            const pass = encoder.beginRenderPass({
                colorAttachments: [{
                    view: ctx.getCurrentTexture().createView(),
                    loadOp: "clear",
                    storeOp: "store",
                }]
            });
            pass.setPipeline(pipeline);
            pass.setVertexBuffer(0, vertexBuffer);
            pass.setBindGroup(0, generalBindGroup);
            pass.draw(6);

            pass.end();

            // let boost = freqData[13]/16 > 3 ? freqData[8]/64 : 1
            t+=0.008;
             
            updateUniform(device, new Float32Array([t]), timeBuffer);

            device.queue.submit([encoder.finish()]);
            if (keepRendering)
                requestAnimationFrame(render);
        }
        requestAnimationFrame(render);
    }

    onMounted(loadWebGPU)
    onUnmounted(() => {
        keepRendering = false;
    })
</script>