# Game over: mostra a pontuação e reinicia pelo botão ou pelo teclado.
extends Node2D

# Espera mínima antes de aceitar o reinício: quem estava apertando Espaço
# ao morrer não pula esta tela sem querer
const ESPERA_MINIMA = 0.8
var pode_reiniciar = false

func _ready():
	$VBoxContainer/LabelScore.text = "SCORE: " + str(Partida.pontos)
	await get_tree().create_timer(ESPERA_MINIMA).timeout
	pode_reiniciar = true
	
# Clique no botão: aumenta o texto como feedback e reinicia
func _on_reiniciar_pressed():
	if not pode_reiniciar:
		return
	$VBoxContainer/reiniciar/reinciarTexto.add_theme_font_size_override("font_size", 18)
	await get_tree().create_timer(0.1).timeout
	reiniciar()
	
# Espaço ou Enter também reiniciam
func _process(_delta):
	if not pode_reiniciar:
		return
	if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("ui_accept"):
		reiniciar()	

func reiniciar():
	get_tree().change_scene_to_file("res://cenas/geral/main.tscn")
