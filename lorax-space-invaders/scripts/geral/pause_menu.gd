# Menu de pausa (Esc/P). Pausa a árvore toda; este nó continua ativo
# porque o process_mode é ALWAYS. O painel OPÇÕES (volumes e "reduzir tremor e flashes")
# é montado por código.
extends CanvasLayer

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
# Sliders de volume: nome em Configuracoes, texto e bus (a prévia toca nele)
const VOLUMES = [
	["geral", "GERAL", &"Master"],
	["musica", "MÚSICA", &"Musica"],
	["efeitos", "EFEITOS", &"Efeitos"],
	["voz", "VOZ", &"Voz"],
]
# Som curto da prévia de volume
const EVENTO_AMOSTRA = &"menu_navega"
const LARGURA_NOME = 64
const LARGURA_SLIDER = 110
const LARGURA_VALOR = 40

@onready var botao_continuar = $VBoxContainer/Continuar
var COR_DESTAQUE = Color.from_rgba8(253, 208, 23)

var painel_opcoes: VBoxContainer
var primeiro_slider: HSlider
var botao_opcoes: Button
# Toca a prévia com o jogo pausado (filho deste nó, então também é ALWAYS)
var amostra: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	criar_botao_opcoes()
	criar_painel_opcoes()
	amostra = AudioStreamPlayer.new()
	add_child(amostra)
	for b in $VBoxContainer.get_children():
		if b is Button:
			preparar_botao(b)

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		# Dentro das OPÇÕES, Esc/P só volta para a lista (não despausa)
		if painel_opcoes.visible:
			fechar_opcoes()
		else:
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

# Botão "OPÇÕES" na lista, logo antes de "SAIR" (preparado junto com os outros no _ready)
func criar_botao_opcoes():
	botao_opcoes = Button.new()
	botao_opcoes.text = "OPÇÕES"
	usar_fonte(botao_opcoes)
	botao_opcoes.pressed.connect(abrir_opcoes)
	$VBoxContainer.add_child(botao_opcoes)
	$VBoxContainer.move_child(botao_opcoes, $VBoxContainer/Sair.get_index())

# Painel escondido: título, um slider por volume, "REDUZIR TREMOR E FLASHES" e "VOLTAR"
func criar_painel_opcoes():
	painel_opcoes = VBoxContainer.new()
	painel_opcoes.add_theme_constant_override("separation", 8)
	painel_opcoes.alignment = BoxContainer.ALIGNMENT_CENTER
	painel_opcoes.hide()
	add_child(painel_opcoes)
	painel_opcoes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var titulo = Label.new()
	titulo.text = "OPÇÕES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FONTE)
	painel_opcoes.add_child(titulo)
	for volume in VOLUMES:
		painel_opcoes.add_child(criar_linha_volume(volume[0], volume[1], volume[2]))
	var reduzir = CheckButton.new()
	reduzir.text = "REDUZIR TREMOR E FLASHES"
	reduzir.button_pressed = Configuracoes.reduzir_efeitos
	reduzir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	usar_fonte(reduzir)
	preparar_botao(reduzir)
	reduzir.toggled.connect(Configuracoes.definir_reduzir_efeitos)
	painel_opcoes.add_child(reduzir)
	var voltar = Button.new()
	voltar.text = "VOLTAR"
	usar_fonte(voltar)
	preparar_botao(voltar)
	voltar.pressed.connect(fechar_opcoes)
	painel_opcoes.add_child(voltar)

# Uma linha "NOME [slider] 100%"; o nome fica amarelo com o slider em foco
func criar_linha_volume(nome, texto, bus):
	var linha = HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	var rotulo = criar_texto(texto, LARGURA_NOME)
	var valor = criar_texto("", LARGURA_VALOR)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.1
	slider.custom_minimum_size.x = LARGURA_SLIDER
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.set_value_no_signal(Configuracoes.get("volume_" + nome))
	mostrar_porcentagem(valor, slider.value)
	slider.value_changed.connect(mudar_volume.bind(nome, bus, valor))
	slider.mouse_entered.connect(slider.grab_focus)
	slider.focus_entered.connect(destacar.bind(rotulo, true))
	slider.focus_exited.connect(destacar.bind(rotulo, false))
	if primeiro_slider == null:
		primeiro_slider = slider
	linha.add_child(rotulo)
	linha.add_child(slider)
	linha.add_child(valor)
	return linha

# Label de largura fixa com a fonte do menu
func criar_texto(texto, largura):
	var label = Label.new()
	label.text = texto
	label.custom_minimum_size.x = largura
	usar_fonte(label)
	return label

# Fonte do jogo no tamanho dos botões
func usar_fonte(controle):
	controle.add_theme_font_override("font", FONTE)
	controle.add_theme_font_size_override("font_size", 8)

# Slider mexeu: salva o volume e, com o jogo pausado, toca a prévia no bus dele
# (a música não precisa: ela toca enquanto as OPÇÕES estão abertas)
func mudar_volume(valor, nome, bus, rotulo_valor):
	Configuracoes.definir_volume(nome, valor)
	mostrar_porcentagem(rotulo_valor, valor)
	if bus != &"Musica" and Sons.preparar_player(EVENTO_AMOSTRA, amostra):
		amostra.bus = bus
		amostra.play()

# "0%" a "100%"
func mostrar_porcentagem(label, valor):
	label.text = "%d%%" % roundi(valor * 100)

# Troca a lista pelo painel OPÇÕES e deixa a música tocar enquanto ele está aberto
func abrir_opcoes():
	$VBoxContainer.hide()
	$controles.hide()
	painel_opcoes.show()
	primeiro_slider.grab_focus()
	Musica.ouvir_na_pausa(true)

# Volta para a lista (com foco no OPÇÕES) e a música pausa de novo
func fechar_opcoes():
	Musica.ouvir_na_pausa(false)
	amostra.stop()
	painel_opcoes.hide()
	$controles.show()
	$VBoxContainer.show()
	botao_opcoes.grab_focus()
