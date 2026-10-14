# Reações do corpo do boss pedidas pelos momentos (passo SINAL): mexem só no Sprite2D, nunca
# na colisão. O Momentos acha este nó no alvo, como faz com FlashSprite e Afterimage.
# Fica como filho do corpo (ou aponte 'sprite' para o Sprite2D).
class_name ReacoesCorpo
extends Node

## O Sprite2D que reage
@export var sprite: NodePath = ^"../Sprite2D"
## Px do centro do sprite até a linha dos pés (linha 28 do quadro de 32 px = 12)
@export var pes := 12.0

var alvo: Sprite2D
var posicao_base := Vector2.ZERO
var tween_squash: Tween = null

# Guarda onde o sprite fica parado (a volta de toda reação)
func _ready():
	alvo = get_node(sprite)
	posicao_base = alvo.position

# Faz a reação 'nome' com os números do passo; os outros nomes são de outros ouvintes (hud...)
func reagir(nome, parametros):
	match nome:
		&"squash":
			squash(parametros.get("escala", Vector2.ONE), parametros.get("duracao", 0.0))

# Achata na hora e volta a (1, 1) em 'duracao' s com um repique, presos pelos pés
func squash(escala, duracao):
	if duracao <= 0:
		push_error("ReacoesCorpo: squash sem duracao")
		return
	if tween_squash != null:
		tween_squash.kill()
	tween_squash = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_squash.tween_method(definir_escala, escala, Vector2.ONE, duracao)

# Escala o sprite mantendo os pés na mesma linha
func definir_escala(escala):
	alvo.scale = escala
	alvo.position = posicao_base + Vector2(0, pes * (1.0 - escala.y))

# Corta qualquer reação e devolve o sprite ao normal
func parar():
	if tween_squash != null:
		tween_squash.kill()
		tween_squash = null
	if alvo != null:
		definir_escala(Vector2.ONE)
