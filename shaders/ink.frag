// Ink Mode: grayscale on warm gray paper. Whites are paper, not OLED white.

#version 300 es
precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

const float CONTRAST = 0.88;
const float PAPER = 0.90;
const float LIFT = 0.04;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
const vec3 WARM = vec3(1.03, 1.00, 0.92);

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float y = dot(pix.rgb, LUMA);
    y = (y - 0.5) * CONTRAST + 0.5;
    y = clamp(y * PAPER + LIFT, 0.0, 1.0);
    fragColor = vec4(vec3(y) * WARM, pix.a);
}
