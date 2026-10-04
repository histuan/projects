// Distorção da tela inteira: onda de choque (anel que empurra a imagem para fora) e
// aberração cromática (vermelho e azul separados). Os dois ficam num shader só porque
// dois retângulos lendo a tela no mesmo CanvasLayer leem a mesma cópia: um apagaria o outro.
shader_type canvas_item;

uniform sampler2D tela : hint_screen_texture, filter_nearest;
// Tamanho da tela em px, para medir o anel em pixels
uniform vec2 tamanho = vec2(254.0, 256.0);
// Onda: centro e raio em px, largura do anel em px, força = deslocamento (fração da tela)
uniform vec2 centro = vec2(0.0);
uniform float raio = 0.0;
uniform float largura = 12.0;
uniform float forca = 0.0;
// Aberração: quantos px o vermelho e o azul se separam
uniform float aberracao_px = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 direcao = uv * tamanho - centro;
	float distancia = length(direcao);
	float no_anel = 1.0 - clamp(abs(distancia - raio) / (largura * 0.5), 0.0, 1.0);
	if (distancia > 0.0) {
		uv -= normalize(direcao) * forca * no_anel;
	}
	vec2 desvio = vec2(aberracao_px, 0.0) / tamanho;
	float vermelho = texture(tela, uv + desvio).r;
	float verde = texture(tela, uv).g;
	float azul = texture(tela, uv - desvio).b;
	COLOR = vec4(vermelho, verde, azul, 1.0);
}
