# Planeta de fundo: nasce acima da tela, desce devagar e some ao sair por baixo.
extends Node2D

@export var velocidade = 40.0
const alt = 256

@onready var sprite = $Sprite2D

# y_real guarda a posição com fração; o nó usa floor() para ficar alinhado ao pixel
var y_real = 0.0

func _ready():
	y_real = -sprite.texture.get_height()
	position.y = y_real
	$voo.play()

func _process(delta):
	y_real += velocidade * delta
	position.y = floor(y_real)
	if position.y > alt:
		queue_free()
