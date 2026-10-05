# Lista de etapas do cheat code: mostra as opções e avisa qual foi escolhida.
extends CanvasLayer

signal etapa_escolhida(etapa)
signal cancelado

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
const COR_DESTAQUE = Color(253 / 255.0, 208 / 255.0, 23 / 255.0)

var opcoes = []
var labels = []
var indice = 0

# Fica acima de tudo na tela inicial e só aparece quando abrir() é chamada
func _ready():
	layer = 10
	hide()

# opcoes: lista de {"nome": texto, "etapa": valor}
func abrir(lista_opcoes):
	opcoes = lista_opcoes
	indice = 0
	montar()
	show()

# Fundo escuro, título e um Label por opção
func montar():
	for f in get_children():
		f.queue_free()
	labels.clear()
	var fundo = ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.85)
	fundo.size = Vector2(254, 256)
	add_child(fundo)
	var caixa = VBoxContainer.new()
	caixa.size = Vector2(254, 0)
	caixa.position = Vector2(0, 70)
	caixa.add_theme_constant_override("separation", 10)
	add_child(caixa)
	caixa.add_child(criar_label("CHEAT", 16, Color.WHITE))
	for o in opcoes:
		var l = criar_label(o["nome"], 10, Color.WHITE)
		caixa.add_child(l)
		labels.append(l)
	destacar()

# Label centralizado com a fonte do jogo
func criar_label(texto, tamanho, cor):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l

# Pinta de amarelo só a opção selecionada
func destacar():
	for i in labels.size():
		labels[i].add_theme_color_override("font_color", COR_DESTAQUE if i == indice else Color.WHITE)

# Navega com as setas, escolhe com Enter/Espaço, cancela com Esc
func _unhandled_input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_down"):
		indice = (indice + 1) % opcoes.size()
		Sons.tocar(&"menu_navega")
		destacar()
	elif event.is_action_pressed("ui_up"):
		indice = (indice - 1 + opcoes.size()) % opcoes.size()
		Sons.tocar(&"menu_navega")
		destacar()
	elif event.is_action_pressed("ui_accept"):
		Sons.tocar(&"menu_escolhe")
		hide()
		etapa_escolhida.emit(opcoes[indice]["etapa"])
	elif event.is_action_pressed("ui_cancel"):
		hide()
		cancelado.emit()
	get_viewport().set_input_as_handled()
