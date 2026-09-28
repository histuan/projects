# Tela inicial: animações do título, splash, Lorax e trúfulas; Enter começa o jogo.
extends Node2D

@onready var titulo = $CanvasLayer/VBoxContainer/LabelTitulo

const MAIN = preload("res://cenas/geral/main.tscn")

# Frases do splash (uma é sorteada cada vez que a tela abre)
const FRASES = [
	"AGORA COM MOTOSSERRA!",
	"100% ORGANICO",
	"NENHUMA ARVORE FOI MACHUCADA",
	"SERA A A QUE EU SOU RUIM...",
	"FEITO COM ARVORES REAIS",
	"I HAVE NO MOUTH AND I MUST TALK!"
]

@onready var label_enter = $CanvasLayer/VBoxContainer/LabelEnter
@onready var splash = $CanvasLayer/Splash
@onready var lorax = $CanvasLayer/sprites/Lorax
@onready var flash = $CanvasLayer/Flash

# tempo: relógio das animações · saindo: trava a tela após o Enter · base_y: altura original de cada trúfula
var tempo = 0.0
var saindo = false
var escala_lorax: Vector2
var base_y = {}

# Guarda os valores originais para animar a partir deles
func _ready():
	escala_lorax = lorax.scale
	splash.text = FRASES.pick_random()
	for s in $CanvasLayer/sprites.get_children():
		if s != lorax:
			base_y[s] = round(s.position.y)

# Anima tudo com senos do tempo
func _process(delta):
	tempo += delta
	if saindo:
		return

	# PRESS ENTER pisca (modulate e não visible, para o VBox não reorganizar o título)
	label_enter.modulate.a = 1.0 if fmod(tempo, 1.0) < 0.6 else 0.0
	# Título pulsa e balança em torno do centro
	titulo.pivot_offset = titulo.size / 2
	var escala_titulo = 1.0 + 0.1 * sin(tempo * 3.0)
	titulo.scale = Vector2(escala_titulo, escala_titulo)
	titulo.rotation = deg_to_rad(4.0 * sin(tempo * 1.7))

	# Splash pulsa rápido
	var pulso = 1.0 + 0.08 * sin(tempo * 8.0)
	splash.pivot_offset = splash.size / 2
	splash.scale = Vector2(pulso, pulso)

	# Lorax "respira"
	lorax.scale = escala_lorax * (1.0 + 0.03 * sin(tempo * 4.0))

	# Trúfulas balançam, cada uma defasada
	var i = 0
	for s in base_y:
		s.position.y = base_y[s] + round(sin(tempo * 2.0 + i) * 1.5)
		i += 1

	if Input.is_action_just_pressed("ui_accept"):
		comecar()

# Som de start (continua tocando na troca de cena), zoom no Lorax, flash,
# música abaixa e, no fim, troca para o jogo
func comecar():
	saindo = true
	label_enter.modulate.a = 1.0
	var t = create_tween().set_parallel()
	var som = $sons/start
	som.reparent(get_tree().root)
	som.play()
	som.finished.connect(som.queue_free)
	t.tween_property(lorax, "scale", escala_lorax * 1.4, 0.15)
	t.tween_property(flash, "color:a", 1.0, 0.6)
	t.tween_property($sons/musga, "volume_db", -40.0, 0.6)
	t.chain().tween_callback(func(): get_tree().change_scene_to_packed(MAIN))
