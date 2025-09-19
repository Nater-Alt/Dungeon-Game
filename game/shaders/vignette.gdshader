shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.6;

void fragment() {
    vec2 centered = UV * 2.0 - 1.0;
    float dist = length(centered);
    float vignette = smoothstep(0.4, 0.9, dist);
    COLOR = vec4(vec3(0.0), vignette * intensity);
}
