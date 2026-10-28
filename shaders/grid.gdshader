shader_type canvas_item;

uniform vec2 cells = vec2(90.0, 60.0);
uniform vec4 base_color : source_color = vec4(0.06, 0.07, 0.11, 1.0);
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.06);

void fragment() {
	vec2 g = UV * cells;
	// Per-tile brightness jitter so the ground reads as rough terrain.
	float h = fract(sin(dot(floor(g), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 base = base_color.rgb + vec3(h * 0.018);
	// Distance to the nearest grid line, in screen pixels.
	vec2 d = abs(fract(g - 0.5) - 0.5) / fwidth(g);
	float line = 1.0 - clamp(min(d.x, d.y), 0.0, 1.0);
	COLOR = vec4(mix(base, line_color.rgb, line * line_color.a), 1.0);
}
