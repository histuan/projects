# Intro em vídeo: vai para o menu quando o vídeo acaba ou com Espaço/Enter.
extends Node2D

const CENA_MENU = "res://cenas/geral/start.tscn"

@onready var video: VideoStreamPlayer = $Video

var saindo: bool = false
const ESPERA_PULAR = 1.5
var pode_pular: bool = false

func _ready():
	video.finished.connect(ir_menu)
	video.play()

	# Carrega o menu em segundo plano enquanto o vídeo toca
	ResourceLoader.load_threaded_request(CENA_MENU)
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

	var cena_pronta = ResourceLoader.load_threaded_get(CENA_MENU)

	get_tree().change_scene_to_packed(cena_pronta)
