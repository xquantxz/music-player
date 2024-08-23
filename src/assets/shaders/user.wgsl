fn getRotationMatrix(a: f32) -> mat2x2<f32> {
    let rotationMatrix = mat2x2(cos(a), sin(a), -sin(a), cos(a));
    return rotationMatrix;
}

fn function(uv: vec2f) -> vec3f {
    let factor = max((freqBass/20),10)- (0.5-pow(abs(uv.x), 2)-pow(abs(uv.y), 2))*freqBass/50-2*kickDetected;
    let y = uv.y*factor;
    let x = uv.x*factor;

    let dist = length(vec2f(fract(y)-0.5 , fract(x)-0.5)) - 0.4;
    if (dist < 0) {
        return vec3f(0,0.5,0.3);
    }
    return vec3f(0,0.0,0.0);
}

fn pulseEffect(color: vec3f) -> vec3f {
    let b = freqBass/600*kickDetected; 
    return b * vec3f(0,0.9,0.2) + (1-b) * color;
}

@fragment
fn fragmentMain(@builtin(position) coord: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = (coord.xy / resolution.xy) * 2 - 1;
    var color = function(getRotationMatrix(sin(time)/2) * uv);
    color = uv.y * vec3f(uv,0.0) + (1-uv.y) * color;
    color = pulseEffect(color);
    return vec4f(color,1);
}
