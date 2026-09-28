# Menu de pausa (Esc/P). Pausa a árvore toda; este nó continua ativo
# porque o process_mode é ALWAYS.
extends CanvasLayer

@onready var botao_continuar = $VBoxContainer/Continuar

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		alternar()
		# Marca a tecla como usada para nenhum outro nó reagir a ela
		get_viewport().set_input_as_handled()

# Liga/desliga a pausa e mostra/esconde o menu
func alternar():
	var pausar = not get_tree().paused
	get_tree().paused = pausar
	visible = pausar
	if pausar:
		botao_continuar.grab_focus()

func _on_continuar_pressed():
	alternar()

# Reiniciar e Menu despausam ANTES de trocar de cena (senão a nova começaria pausada)
func _on_reiniciar_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

# change_scene_to_file (sem preload) evita referência circular: o start.gd já faz preload da main
func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://cenas/geral/start.tscn")

func _on_sair_pressed():
	get_tree().quit()
