# Item genérico que cai piscando: aparência e efeito vêm do PowerUp em 'powerup'.
extends Area2D

@export var powerup: PowerUp
var velocidade = 70
var pego = false
var tempo = 0.0

func _ready():
	$Sprite2D.texture = powerup.sprite
	$Sprite2D.hframes = powerup.quadros
	piscar()

func piscar():
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(self, "modulate:a", 0.2, 0.25)
		tween.tween_property(self, "modulate:a", 1.0, 0.25)

# Cai, anima os quadros do spritesheet e some ao passar do fundo da tela
func _process(delta):
	position.y += velocidade * delta
	tempo += delta
	$Sprite2D.frame = int(tempo * powerup.fps) % powerup.quadros
	if global_position.y > 260:
		queue_free()

# "pego" evita ativar duas vezes
func _on_body_entered(body):
	if pego:
		return
	if body.is_in_group("tanque"):
		pego = true
		body.ativar_powerup(powerup)
		queue_free()
