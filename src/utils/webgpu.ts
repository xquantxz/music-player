// @ts-nocheck

export async function getWebGPUDevice() {
    if (!navigator.gpu) {
        console.log("WebGPU not supported");
        return null;
    }
    
    const adapter = await navigator.gpu.requestAdapter();

    // checks if gpu meets the requirements
    if (!adapter) {
        console.log("Failed to get GPUAdapter");
        return null;
    }
    
    return await adapter.requestDevice();
}
// @ts-ignore
export function updateUniform(device, data, buffer) {
    device.queue.writeBuffer(buffer, 0, data);
    return;
}