# Pilar de luz alto (8_pilar_alto) que sobe atrás do corpo do boss junto com o 3_pilar. Fica antes do
# LoraxFinal na árvore para desenhar atrás dele. Escondido fora da animação: some sozinho quando ela acaba.
extends Node2D

## Pés do quadro: px do centro do quadro até a linha dos pés (mesma conta do ReacoesCorpo.pes)
@export var pes := 0.0

# Começa escondido, com o desenho apoiado na linha dos pés
func _ready():
	visible = false
	$Sprite2D.offset = Vector2(0, -pes)
	$AnimationPlayer.animation_finished.connect(_on_animacao_terminou)

# Troca o conjunto de animações (lista de AnimacaoDados)
func carregar_animacoes(lista):
	var anim = $AnimationPlayer
	anim.stop()
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", AnimacaoDados.criar_biblioteca(lista))

# Aparece com os pés em 'ponto_pes' e toca 'nome' do começo
func tocar(nome, ponto_pes: Vector2):
	global_position = ponto_pes
	visible = true
	$AnimationPlayer.play(nome)
	$AnimationPlayer.seek(0.0, true)

# Para no meio e some (a transformação parou)
func parar():
	$AnimationPlayer.stop()
	visible = false

# A animação acabou: some
func _on_animacao_terminou(_nome):
	visible = false
