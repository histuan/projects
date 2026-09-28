# Intro em vídeo: vai para o menu quando o vídeo acaba ou com Espaço/Enter.
extends Node2D

const CENA_MENU = "res://cenas/geral/start.tscn"

@onready var video: VideoStreamPlayer = $Video

var saindo: bool = false

func _ready():
	video.finished.connect(ir_menu)
	video.play()

	# Carrega o menu em segundo plano enquanto o vídeo toca
	ResourceLoader.load_threaded_request(CENA_MENU)

func _process(_delta):
	if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("ui_accept"):
		ir_menu()

# "saindo" impede trocar de cena duas vezes (vídeo acabou + tecla no mesmo instante)
func ir_menu():
	if saindo:
		return
	saindo = true

	var cena_pronta = ResourceLoader.load_threaded_get(CENA_MENU)

	get_tree().change_scene_to_packed(cena_pronta)
