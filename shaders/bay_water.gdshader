shader_type canvas_item;
// Moves the bay part of the backdrop painting in whole-pixel ripples, with a few
// sparse moonlit glints. The town, sky and lighthouse above the horizon stay still.

uniform float horizon = 0.52;
uniform float shore = 0.965;
uniform vec2 texture_size = vec2(640.0, 198.0);

void fragment() {
	vec2 px = floor(UV * texture_size);
	float in_bay = smoothstep(horizon, horizon + 0.05, UV.y) * step(UV.y, shore);
	float depth = clamp((UV.y - horizon) / (shore - horizon), 0.0, 1.0);
	float wave = sin(px.y * 0.9 - TIME * 1.7 + sin(px.x * 0.035 + TIME * 0.6) * 2.0);
	float shift = floor(wave * mix(0.6, 2.4, depth) * in_bay + 0.5);
	vec4 color = texture(TEXTURE, (px + vec2(shift, 0.0) + 0.5) / texture_size);
	float glint = sin(px.x * 0.21 + TIME * 1.3 + px.y * 1.7) * sin(px.y * 0.5 - TIME * 2.1 + px.x * 0.05);
	color.rgb += vec3(0.05, 0.09, 0.11) * step(0.93, glint) * in_bay;
	COLOR = color;
}
