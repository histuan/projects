# Rastro de cópias de um sprite (teleporte, esquiva): cada cópia fica parada no mundo,
# pintada com a cor, e desbota até sumir. Deixe este nó ANTES do Sprite2D na árvore,
# para as cópias serem desenhadas atrás do corpo.
class_name Afterimage
extends Node

## O Sprite2D que vai ser copiado
@export var sprite: NodePath

# Sobe a cada parar(): um soltar() que estava esperando não solta mais cópias
var geracao = 0

# Solta 'copias' cópias, uma a cada 'intervalo' segundos (tempo real)
func soltar(copias, intervalo, vida, cor, alfa):
	var minha = geracao
	for i in range(copias):
		if minha != geracao:
			return
		copiar(vida, cor, alfa)
		if i < copias - 1:
			await get_tree().create_timer(intervalo, false, false, true).timeout

# Interrompe um soltar() em andamento e apaga as cópias que ainda estão na tela
func parar():
	geracao += 1
	for copia in get_children():
		copia.queue_free()

# Copia o quadro atual no lugar atual; a cópia desbota até 0 em 'vida' segundos
func copiar(vida, cor, alfa):
	var alvo: Sprite2D = get_node(sprite)
	var copia = Sprite2D.new()
	copia.texture = alvo.texture
	copia.hframes = alvo.hframes
	copia.vframes = alvo.vframes
	copia.frame = alvo.frame
	copia.flip_h = alvo.flip_h
	copia.flip_v = alvo.flip_v
	copia.centered = alvo.centered
	copia.offset = alvo.offset
	copia.modulate = Color(cor.r, cor.g, cor.b, alfa)
	add_child(copia)
	copia.global_position = alvo.global_position
	copia.global_rotation = alvo.global_rotation
	copia.global_scale = alvo.global_scale
	var tween = copia.create_tween().set_ignore_time_scale()
	tween.tween_property(copia, "modulate:a", 0.0, vida)
	tween.tween_callback(copia.queue_free)
