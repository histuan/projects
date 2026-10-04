// Flash de sprite: pinta o sprite com cor_flash na proporção 'intensidade'
// (0 = normal, 1 = cor chapada), mantendo o alfa e o modulate do sprite
shader_type canvas_item;

uniform vec4 cor_flash : source_color = vec4(1.0);
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, cor_flash.rgb, intensidade), c.a);
}
