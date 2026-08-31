// Lighten Mode: subtle desaturation between Normal and Color Ink.
// Slightly muted colors, closer to normal than Color Ink.

#version 300 es
precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

const float SATURATION = 0.75;
const float CONTRAST = 0.95;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float y = dot(pix.rgb, LUMA);
    vec3 color = mix(vec3(y), pix.rgb, SATURATION);
    color = (color - 0.5) * CONTRAST + 0.5;
    color.b *= mix(1.0, 0.97, smoothstep(0.45, 0.95, y));
    fragColor = vec4(color, pix.a);
}