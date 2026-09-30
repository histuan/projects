# Intro em vídeo: vai para o menu quando o vídeo acaba ou com Espaço/Enter.
extends Node2D

const CENA_MENU = "res://cenas/geral/start.tscn"

@onready var video: VideoStreamPlayer = $Video
@onready var dica: Label = $dicaPular

var saindo: bool = false
const ESPERA_PULAR = 3
const DICA_ESPERA = 3.0
const DICA_VISIVEL = 3.0
const DICA_FADE = 0.5
var pode_pular: bool = false

func _ready():
	video.finished.connect(ir_menu)
	video.play()
	
	mostrar_dica()

	await get_tree().create_timer(ESPERA_PULAR).timeout
	pode_pular = true

func _process(_delta):
	if not pode_pular:
		return
	if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("ui_accept"):
		ir_menu()

# "saindo" impede trocar de cena duas vezes (vídeo acabou + tecla no mesmo instante)
func ir_menu():
	if saindo:
		return
	saindo = true
	video.stop()
	await get_tree().process_frame

	get_tree().change_scene_to_file(CENA_MENU)
	
# Dica invisível no começo: aparece com fade após DICA_ESPERA, fica DICA_VISIVEL e some com fade
func mostrar_dica():
	dica.modulate.a = 0.0
	var t = create_tween()
	t.tween_interval(DICA_ESPERA)
	t.tween_property(dica, "modulate:a", 1.0, DICA_FADE)
	t.tween_interval(DICA_VISIVEL)
	t.tween_property(dica, "modulate:a", 0.0, DICA_FADE)
