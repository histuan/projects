# Planeta de fundo: nasce acima da tela, desce devagar e some ao sair por baixo.
extends Node2D

@export var velocidade = 40.0
## Segundos do fade quando a wave do boss manda sumir
@export var fade_saida := 1.0
const alt = 256

@onready var sprite = $Sprite2D

# y_real guarda a posição com fração; o nó usa floor() para ficar alinhado ao pixel
var y_real = 0.0

func _ready():
	add_to_group(&"planetas")
	y_real = -sprite.texture.get_height()
	position.y = y_real
	$voo.play()

func _process(delta):
	y_real += velocidade * delta
	position.y = floor(y_real)
	if position.y > alt:
		queue_free()

# Some com fade (imagem e som do voo) em vez de terminar de passar
func sumir():
	if is_in_group(&"sumindo"):
		return
	add_to_group(&"sumindo")
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, fade_saida)
	tween.tween_property($voo, "volume_db", -80.0, fade_saida)
	tween.chain().tween_callback(queue_free)
