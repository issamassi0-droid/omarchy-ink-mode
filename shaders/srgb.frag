// sRGB Mode: faithful BT.709 reproduction, softer pass-through.
// Warmth 0.00, slight desaturation, soft contrast, brighter gamma.

#version 300 es
precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

const float WARMTH = 0.0;
const float SATURATION = 0.98;
const float CONTRAST = 0.97;
const float GAMMA = 1.01;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

float srgbToLinear(float c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

float linearToSrgb(float c) {
    c = clamp(c, 0.0, 1.0);
    return c <= 0.0031308 ? c * 12.92 : pow(c, 1.0 / 2.4) * 1.055 - 0.055;
}

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float r = srgbToLinear(pix.r);
    float g = srgbToLinear(pix.g);
    float b = srgbToLinear(pix.b);

    float r2 = r + WARMTH * (r - b);
    float b2 = b + WARMTH * (b - r);
    float g2 = g;

    float y = 0.2126 * r2 + 0.7152 * g2 + 0.0722 * b2;
    r2 = mix(y, r2, SATURATION);
    g2 = mix(y, g2, SATURATION);
    b2 = mix(y, b2, SATURATION);

    r2 = (r2 - 0.5) * CONTRAST + 0.5;
    g2 = (g2 - 0.5) * CONTRAST + 0.5;
    b2 = (b2 - 0.5) * CONTRAST + 0.5;

    r2 = linearToSrgb(pow(clamp(r2, 0.0, 1.0), GAMMA));
    g2 = linearToSrgb(pow(clamp(g2, 0.0, 1.0), GAMMA));
    b2 = linearToSrgb(pow(clamp(b2, 0.0, 1.0), GAMMA));

    fragColor = vec4(r2, g2, b2, pix.a);
}