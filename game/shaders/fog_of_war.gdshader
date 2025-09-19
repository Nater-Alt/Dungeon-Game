shader_type canvas_item;

uniform vec2 player_pos = vec2(0.5, 0.5);
uniform float light_radius = 0.35;
uniform int revealed_count = 0;
uniform vec2 revealed_points[32];
uniform float shadow_strength = 0.85;

void fragment() {
    vec2 uv = UV;
    float dist = distance(uv, player_pos);
    float main_visibility = smoothstep(light_radius, light_radius * 0.2, dist);
    float memory_visibility = 0.0;
    for (int i = 0; i < revealed_count; i++) {
        float d = distance(uv, revealed_points[i]);
        memory_visibility = max(memory_visibility, smoothstep(light_radius * 1.4, light_radius * 0.4, d));
    }
    float visibility = clamp(max(1.0 - main_visibility, memory_visibility * 0.5), 0.0, 1.0);
    float fog = mix(shadow_strength, 0.0, visibility);
    COLOR = vec4(vec3(0.0), fog);
}
