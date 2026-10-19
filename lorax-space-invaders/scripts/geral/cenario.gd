# Cenário da partida: bases, chão e paredes somem e voltam juntos (a AreaGameOver fica sempre).
# Escondidos, ficam sem colisão (process_mode DISABLED tira os corpos do espaço físico).
extends Node

const GRUPOS = [&"bases", &"chao", &"paredes"]
const EFEITOS = preload("res://recursos/boss/efeitos_boss.tres")

# Fade do sumir() em andamento (mostrar() o mata)
var tween_sumir: Tween

# Mostra (ou esconde) bases, chão e paredes na hora, desfazendo um sumir() no meio
func mostrar(ligado):
	if tween_sumir != null:
		tween_sumir.kill()
		tween_sumir = null
	for nome in GRUPOS:
		var grupo = get_node(NodePath(nome))
		grupo.set_deferred(&"process_mode", Node.PROCESS_MODE_INHERIT if ligado else Node.PROCESS_MODE_DISABLED)
		for filho in grupo.get_children():
			if filho is CanvasItem:
				filho.visible = ligado
				filho.modulate.a = 1.0

# Some com bases, chão e paredes: a colisão sai na hora; o desenho some na hora (fade 0) ou em 'fade' s
func sumir(fade = 0.0):
	if fade <= 0.0:
		mostrar(false)
		return
	if tween_sumir != null:
		tween_sumir.kill()
	tween_sumir = create_tween().set_parallel()
	for nome in GRUPOS:
		var grupo = get_node(NodePath(nome))
		grupo.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
		for filho in grupo.get_children():
			if filho is CanvasItem and filho.visible:
				tween_sumir.tween_property(filho, "modulate:a", 0.0, fade)
	tween_sumir.chain().tween_callback(mostrar.bind(false))

# Pico do pilar: some na hora, debaixo do flash branco; com "reduzir efeitos" o flash é fraco e o
# corte apareceria, então some com fade
func sumir_sob_flash():
	sumir(EFEITOS.fade_bases_reduzido if Configuracoes.reduzir_efeitos else 0.0)
