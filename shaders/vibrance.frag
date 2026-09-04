// Vibrance Mode: muted, uniform desaturation with reduced gamma for a softer read.
// VIBRANCE 1.0 = unchanged saturation; GAMMA < 1.0 brightens midtones.

#version 300 es
precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

const float VIBRANCE = 0.65;
const float GAMMA = 1.3;
const float CONTRAST = 0.80;
const float BOOST_THRESHOLD = 0.5;
const float BOOST_FALLOFF = 0.25;
const float BOOST_AMOUNT = 0.95;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float y = dot(pix.rgb, LUMA);

    // Vibrance boost in dark areas
    vec3 boost = mix(pix.rgb, mix(vec3(y), pix.rgb, BOOST_AMOUNT), smoothstep(0.0, BOOST_THRESHOLD, y));

    // Blend boosted darks with original, rising to original as brightness increases
    vec3 saturated = mix(mix(pix.rgb, boost, VIBRANCE), pix.rgb, smoothstep(BOOST_THRESHOLD + BOOST_FALLOFF, 1.0, y));

    // Basic saturation/constrast
    vec3 color = (saturated - 0.5) * CONTRAST + 0.5;

    // Uniform muting: blend all channels equally toward gray
    color = mix(color, vec3(y), 0.15);

    // Roll-off proportional to luminance: darker colors less, brighter colors more
    float rolloff = smoothstep(0.0, 1.0, y) * 0.18;
    color = mix(color, color * 0.82, rolloff);

    // Clamp last and apply gamma
    color = clamp(color, 0.0, 1.0);
    color = pow(color, vec3(GAMMA));

    fragColor = vec4(color, pix.a);
}