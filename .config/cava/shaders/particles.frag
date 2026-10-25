#version 330

in vec2 fragCoord;
out vec4 fragColor;

// bar values. defaults to left channels first (low to high), then right (high to low).
uniform float bars[512];

uniform int bars_count;    // number of bars (left + right) (configurable)
uniform int bar_width;     // bar width (configurable), not used here
uniform int bar_spacing;   // space between bars (configurable), not used here
uniform float shader_time; // shader execution time s

uniform vec3 u_resolution; // window resolution

// colors, configurable in cava config file (r,g,b) (0.0 - 1.0)
uniform vec3 bg_color; // background color
uniform vec3 fg_color; // foreground color

uniform int gradient_count;
uniform vec3 gradient_colors[8]; // gradient colors

const int PARTICLES_PER_BAR = 6;

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec3 gradient_color(float t) {
    if (gradient_count < 2) {
        return fg_color;
    }
    t = clamp(t, 0.0, 1.0);
    float scaled = t * float(gradient_count - 1);
    int idx = int(scaled);
    idx = clamp(idx, 0, gradient_count - 2);
    float frac = scaled - float(idx);
    return mix(gradient_colors[idx], gradient_colors[idx + 1], frac);
}

void main() {
    vec3 col = bg_color;

    int bar = int(float(bars_count) * fragCoord.x);
    bar = clamp(bar, 0, bars_count - 1);

    float bar_size = 1.0 / float(bars_count);
    float cell_left = float(bar) * bar_size;

    float amp = bars[bar];
    if (amp * u_resolution.y < 1.0) {
        amp = 1.0 / u_resolution.y;
    }

    float aspect = u_resolution.x / u_resolution.y;
    float signal = smoothstep(0.0, 0.08, amp);

    for (int p = 0; p < PARTICLES_PER_BAR; p++) {
        float seed = float(bar) * 97.13 + float(p) * 13.37;

        // horizontal offset within this bar's cell
        float offset_x = (hash11(seed) * 0.7 + 0.15) * bar_size;
        float speed = 0.18 + hash11(seed + 1.0) * 0.35;
        float phase = hash11(seed + 2.0);
        float size = (0.0035 + hash11(seed + 3.0) * 0.0065) * (0.6 + 0.4 * amp);

        // particle rises through the current bar height, then loops back to the bottom
        float rise = fract(phase + shader_time * speed);
        float py = rise * amp * 1.1;

        float alpha = (1.0 - smoothstep(0.55, 1.0, rise)) * signal;

        vec2 delta = vec2((fragCoord.x - (cell_left + offset_x)) * aspect,
                           fragCoord.y - py);
        float d = length(delta);

        float glow = smoothstep(size, 0.0, d);
        vec3 pc = gradient_color(rise);

        col += pc * glow * alpha;
    }

    fragColor = vec4(col, 1.0);
}
