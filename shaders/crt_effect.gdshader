shader_type canvas_item;

// CRT-эффект для камер наблюдения
uniform float scan_line_amount : hint_range(0.0, 1.0) = 0.3;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.15;
uniform float distortion : hint_range(0.0, 0.1) = 0.003;
uniform float roll_speed : hint_range(0.0, 5.0) = 0.5;
uniform float flicker : hint_range(0.0, 0.1) = 0.02;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform vec4 tint_color : source_color = vec4(0.7, 0.9, 0.7, 1.0);

float random(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Barrel distortion
    vec2 center = uv - 0.5;
    float dist = dot(center, center);
    uv += center * dist * distortion;

    // Rolling effect
    float roll = sin(uv.y * 20.0 + TIME * roll_speed) * 0.001;
    uv.x += roll;

    // Get base color
    vec4 col = texture(TEXTURE, uv);

    // Apply green-ish tint
    col.rgb *= tint_color.rgb;

    // Scan lines
    float scan = sin(uv.y * 360.0 * 3.14159) * 0.5 + 0.5;
    col.rgb -= scan_line_amount * scan * 0.3;

    // Noise
    float n = random(uv + vec2(TIME * 0.1)) * noise_amount;
    col.rgb += vec3(n) - noise_amount * 0.5;

    // Flicker
    float f = 1.0 - flicker * random(vec2(TIME, 0.0));
    col.rgb *= f;

    // Vignette
    float vig = 1.0 - dist * vignette_intensity * 4.0;
    col.rgb *= vig;

    COLOR = col;
}
