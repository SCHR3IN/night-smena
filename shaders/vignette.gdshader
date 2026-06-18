shader_type canvas_item;

// Виньетка для офиса — тёмные края, создающие клаустрофобию
uniform float intensity : hint_range(0.0, 2.0) = 0.6;
uniform float radius : hint_range(0.0, 1.0) = 0.7;
uniform float softness : hint_range(0.0, 1.0) = 0.4;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.02, 1.0);

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec2 center = UV - 0.5;
    float dist = length(center);
    float vig = smoothstep(radius, radius - softness, dist);
    col.rgb = mix(vignette_color.rgb, col.rgb, vig * (1.0 - intensity) + intensity * vig);
    COLOR = col;
}
