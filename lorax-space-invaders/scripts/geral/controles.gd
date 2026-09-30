# Barra de controles: cada tecla afunda enquanto o jogador a aperta.
extends Node2D

@onready var tecla_a = $teclaA
@onready var tecla_d = $teclaD
@onready var tecla_espaco = $teclaEspaco
@onready var tecla_p = $teclaP
@onready var tecla_esc = $teclaEsc


# Atualiza as teclas a cada quadro
func _process(_delta):
	animar_teclas()

# Afunda cada tecla (quadro 1) enquanto o jogador estiver apertando
func animar_teclas():
	tecla_a.frame = int(Input.is_action_pressed("esquerda"))
	tecla_d.frame = int(Input.is_action_pressed("direita"))
	tecla_espaco.frame = int(Input.is_action_pressed("shoot"))
	tecla_p.frame = int(Input.is_physical_key_pressed(KEY_P))
	tecla_esc.frame = int(Input.is_physical_key_pressed(KEY_ESCAPE))
