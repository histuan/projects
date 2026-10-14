# Reações do corpo do boss pedidas pelos momentos (passo SINAL) e pela fase (inclinar,
# deslocar): mexem só no Sprite2D, nunca na colisão. O Momentos acha este nó no alvo, como
# faz com FlashSprite e Afterimage. Fica como filho do corpo (ou aponte 'sprite' para o Sprite2D).
# PIVÔ NOS PÉS: no _ready o sprite passa a ter offset (0, -pes) e o nó dele desce para a linha
# dos pés (o desenho não muda de lugar); assim escala (squash) e rotação giram em torno do pé.
# Inclinar = girar o sprite (o shader do FlashSprite suaviza a borda dos texels); o lean em
# fileiras inteiras fica como alternativa (inclinar_lean).
class_name ReacoesCorpo
extends Node

## O Sprite2D que reage
@export var sprite: NodePath = ^"../Sprite2D"
## Px do centro do sprite até a linha dos pés (linha 28 do quadro de 32 px = 12)
@export var pes := 12.0

var alvo: Sprite2D
var posicao_base := Vector2.ZERO
# O que cada reação faz agora; aplicar() junta tudo no sprite
var escala := Vector2.ONE
var graus := 0.0
# Px que o topo desloca agora no lean (o shader arredonda por fileira)
var lean := 0.0
var recuo := 0.0
var lado := 0.0
var tween_squash: Tween = null
var tween_recuo: Tween = null
var tween_inclinar: Tween = null
var tween_lado: Tween = null

# Põe o pivô do sprite nos pés (sem mudar o desenho de lugar) e guarda onde ele fica parado
func _ready():
	alvo = get_node(sprite)
	alvo.offset += Vector2(0, -pes)
	alvo.position += Vector2(0, pes)
	posicao_base = alvo.position

# Faz a reação 'nome' com os números do passo; os outros nomes são de outros ouvintes (hud...)
func reagir(nome, parametros):
	match nome:
		&"squash":
			squash(parametros.get("escala", Vector2.ONE), parametros.get("duracao", 0.0))
		&"recuo":
			recuar(parametros.get("px", 0.0), parametros.get("tempos", Vector2.ZERO))

# Achata na hora e volta a (1, 1) em 'duracao' s com um repique, presos pelos pés
func squash(nova_escala, duracao):
	if duracao <= 0:
		push_error("ReacoesCorpo: squash sem duracao")
		return
	if tween_squash != null:
		tween_squash.kill()
	tween_squash = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_squash.tween_method(definir_escala, nova_escala, Vector2.ONE, duracao)

# Sobe 'px' em tempos.x segundos e volta em tempos.y
func recuar(px, tempos):
	if px <= 0 or tempos.x <= 0 or tempos.y <= 0:
		push_error("ReacoesCorpo: recuo sem px ou tempos")
		return
	if tween_recuo != null:
		tween_recuo.kill()
	tween_recuo = create_tween()
	tween_recuo.tween_method(definir_recuo, 0.0, -px, tempos.x)
	tween_recuo.tween_method(definir_recuo, -px, 0.0, tempos.y)

# Gira até 'novos_graus' (negativo = esquerda; 0 = de pé) em 'tempo' s, em torno dos pés; com
# o sprite girado o shader suaviza a borda dos texels
func inclinar(novos_graus, tempo):
	if tween_inclinar != null:
		tween_inclinar.kill()
	tween_inclinar = create_tween()
	tween_inclinar.tween_method(definir_graus, graus, novos_graus, maxf(tempo, 0.001))

# Põe a rotação em 'novos_graus' na hora (o vai e vem progressivo chama a cada quadro); só
# mexe no sprite quando o ângulo muda
func definir_inclinacao(novos_graus):
	if tween_inclinar != null:
		tween_inclinar.kill()
		tween_inclinar = null
	if novos_graus != graus:
		definir_graus(novos_graus)

# Alternativa à rotação: o topo desloca 'px' (negativo = esquerda; 0 = de pé) em 'tempo' s,
# em degraus inteiros pelo shader. Sem FlashSprite no sprite, não faz nada
func inclinar_lean(px, tempo):
	var flash = flash_do_sprite()
	if flash == null:
		return
	flash.definir_lean(lean, ceilf(maxf(absf(px), absf(lean))), pes)
	if tween_inclinar != null:
		tween_inclinar.kill()
	tween_inclinar = create_tween()
	tween_inclinar.tween_method(definir_lean.bind(flash), lean, px, maxf(tempo, 0.001))

# Alternativa à inclinação: desloca 'px' para o lado em 'tempo' s (0 = no lugar)
func deslocar(px, tempo):
	if tween_lado != null:
		tween_lado.kill()
	tween_lado = create_tween()
	tween_lado.tween_method(definir_lado, lado, px, maxf(tempo, 0.001))

# Escala do squash (o tween chama a cada quadro)
func definir_escala(valor):
	escala = valor
	aplicar()

# Px do recuo (negativo = para cima)
func definir_recuo(valor):
	recuo = valor
	aplicar()

# Graus da rotação; a borda suavizada liga só com o sprite girado (de pé fica o nearest de sempre)
func definir_graus(valor):
	graus = valor
	aplicar()
	var flash = flash_do_sprite()
	if flash != null:
		flash.definir_suavizar(graus != 0.0)

# Px do lean no topo (o tween chama a cada quadro); a margem do quad (px inteiros, para não
# desalinhar os texels) acompanha o maior valor
func definir_lean(valor, flash):
	lean = valor
	flash.definir_lean(lean, ceilf(maxf(flash.margem_lean, absf(lean))), pes)

# O FlashSprite filho do sprite (dono do material), ou null
func flash_do_sprite():
	for filho in alvo.get_children():
		if filho is FlashSprite:
			return filho
	return null

# Px do deslocamento para o lado
func definir_lado(valor):
	lado = valor
	aplicar()

# Escala, rotação e posição do sprite (o pivô já está nos pés); recuo e lado somam em px inteiros
func aplicar():
	alvo.scale = escala
	alvo.rotation = deg_to_rad(graus)
	alvo.position = posicao_base + Vector2(lado, recuo).round()

# Corta qualquer reação e devolve o sprite ao normal
func parar():
	for tween in [tween_squash, tween_recuo, tween_inclinar, tween_lado]:
		if tween != null:
			tween.kill()
	escala = Vector2.ONE
	graus = 0.0
	recuo = 0.0
	lado = 0.0
	if alvo != null:
		aplicar()
	var flash = flash_do_sprite() if alvo != null else null
	if flash != null:
		flash.definir_suavizar(false)
		if lean != 0.0:
			flash.definir_lean(0.0, 0.0, pes)
	lean = 0.0
