# Item da motosserra: cai piscando e ativa o power-up ao encostar no player.
extends Area2D

var velocidade = 70
var pego = false

func _ready():
	$AnimationPlayer.play("moto")
	piscar()

func piscar():
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(self, "modulate:a", 0.2, 0.25)
		tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _process(delta):
	position.y += velocidade * delta
	if global_position.y > 260:
		queue_free()

# "pego" evita ativar duas vezes
func _on_body_entered(body):
	if pego:
		return
	if body.is_in_group("tanque"):
		pego = true
		body.ativar_moto()
		queue_free()
