// sRGB Mode: standard BT.709 color space, faithful reproduction.
// Matrix is the sRGB→XYZ inverse baked in, gamma 2.2.

#version 300 es
precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

const mat3 M = mat3(
    3.24096994, -1.53738318, -0.49861076,
   -0.96924364,  1.87596750,  0.04155506,
    0.05563008, -0.20397696,  1.05697151
);
const float GAMMA = 2.2;
const float CONTRAST = 0.95;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

vec3 srgbToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

vec3 linearToSrgb(vec3 c) {
    return mix(c * 12.92, pow(clamp(c, 0.0, 1.0), vec3(1.0 / 2.4)) * 1.055 - 0.055, step(0.0031308, c));
}

void main() {
    vec4 pix = texture(tex, v_texcoord);
    vec3 lin = srgbToLinear(pix.rgb);
    vec3 color = M * lin;
    float y = dot(color, LUMA);
    color = (color - 0.5) * CONTRAST + 0.5;
    color = linearToSrgb(color);
    fragColor = vec4(color, pix.a);
}
