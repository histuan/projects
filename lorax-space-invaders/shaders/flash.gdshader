// Material do corpo do boss: inclinação (rotação com anti-alias na borda dos texels) e o
// flash de cor.
// Flash: pinta o sprite com cor_flash na proporção 'intensidade' (0 = normal, 1 = cor chapada),
// mantendo o alfa e o modulate do sprite.
// suavizar_borda (sprite girado): "sharp bilinear" feito à mão com 4 texels lidos em nearest; o
// miolo de cada texel fica nítido e só a faixa de ~1 pixel da tela entre dois texels é
// misturada. Texel fora do quadro conta como transparente (nunca o quadro vizinho da folha) e a
// mistura é pré-multiplicada (sem halo escuro).
// O quad é alargado em margem_px para nada ser cortado. Supõe o sprite centrado (com offset_px).
shader_type canvas_item;

uniform vec4 cor_flash : source_color = vec4(1.0);
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
// Rotação com anti-alias na borda dos texels
uniform bool suavizar_borda = false;
// Px a mais de cada lado do quad (x, y)
uniform vec2 margem_px = vec2(0.0);
// O offset do Sprite2D (o quadro fica centrado nele)
uniform vec2 offset_px = vec2(0.0);

// Posição (px) a partir do centro do quadro, metade do quadro e a cor do vértice (modulate)
varying vec2 local;
varying vec2 metade;
varying vec4 cor_vertice;

void vertex() {
	vec2 v = VERTEX - offset_px;
	metade = abs(v);
	vec2 lado = sign(v);
	v += lado * margem_px;
	UV += lado * margem_px * TEXTURE_PIXEL_SIZE;
	VERTEX = v + offset_px;
	local = v;
	cor_vertice = COLOR;
}

// A cor 'c' lida no texel 'q' do quadro, com o alfa pré-multiplicado; fora do quadro = transparente
vec4 pre_multiplicar(vec4 c, vec2 q, vec2 tamanho) {
	if (q.x < 0.0 || q.y < 0.0 || q.x >= tamanho.x || q.y >= tamanho.y) {
		return vec4(0.0);
	}
	return vec4(c.rgb * c.a, c.a);
}

// Lê o texel 'q' do quadro atual (o TEXTURE embutido não pode ir como argumento de função)
#define TEXEL(q) pre_multiplicar(texture(TEXTURE, origem + ((q) + 0.5) * TEXTURE_PIXEL_SIZE), (q), tamanho)

void fragment() {
	vec4 c = COLOR;
	// A metade chega interpolada (ex.: 15,9999): volta ao inteiro exato
	vec2 m = floor(metade + 0.5);
	vec2 tamanho = 2.0 * m;
	// Coordenada em texels dentro do quadro (0 no canto de cima/esquerda) e a origem do quadro na folha
	vec2 t = local + m;
	vec2 origem = UV - t * TEXTURE_PIXEL_SIZE;
	if (suavizar_borda) {
		vec2 w = fwidth(t);
		vec4 s;
		if (w.x >= 1.0 || w.y >= 1.0 || w.x <= 0.0 || w.y <= 0.0) {
			s = TEXEL(floor(t));
		} else {
			// Ponto de leitura: o centro do texel no miolo; só perto da borda anda até ela
			vec2 f = fract(t) - 0.5;
			vec2 b = 0.5 - w * 0.5;
			vec2 a = floor(t) + 0.5 + (f - clamp(f, -b, b)) / w;
			// Bilinear à mão entre os 4 texels em volta do ponto
			vec2 g = a - 0.5;
			vec2 i0 = floor(g);
			vec2 k = g - i0;
			vec4 c00 = TEXEL(i0);
			vec4 c10 = TEXEL(i0 + vec2(1.0, 0.0));
			vec4 c01 = TEXEL(i0 + vec2(0.0, 1.0));
			vec4 c11 = TEXEL(i0 + vec2(1.0, 1.0));
			s = mix(mix(c00, c10, k.x), mix(c01, c11, k.x), k.y);
		}
		c = s.a > 0.0 ? vec4(s.rgb / s.a, s.a) * cor_vertice : vec4(0.0);
	}
	COLOR = vec4(mix(c.rgb, cor_flash.rgb, intensidade), c.a);
}
