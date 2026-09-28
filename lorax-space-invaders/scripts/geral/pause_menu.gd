# Menu de pausa (Esc/P). Pausa a árvore toda; este nó continua ativo
# porque o process_mode é ALWAYS.
extends CanvasLayer

@onready var botao_continuar = $VBoxContainer/Continuar
var COR_DESTAQUE = Color.from_rgba8(253, 208, 23)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	for b in $VBoxContainer.get_children():
		if b is Button:
			preparar_botao(b)

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
	
# Tira as caixas do tema e faz mouse e teclado usarem o mesmo destaque (o foco)
func preparar_botao(b):
	b.flat = true
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for estado in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(estado, Color.WHITE)
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(destacar.bind(b, true))
	b.focus_exited.connect(destacar.bind(b, false))

# Pinta o texto de amarelo quando o botão tem foco e volta ao branco quando perde
func destacar(b, ligado):
	if ligado:
		b.modulate = COR_DESTAQUE
	else:
		b.modulate = Color.WHITE
