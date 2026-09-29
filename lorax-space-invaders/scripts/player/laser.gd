# Laser do player: sobe reto e acerta um único inimigo.
extends Area2D

var velocity = 200
var acertou = false

func _process(delta: float) -> void:
	position.y -= velocity*delta
	if global_position.y < -10:
		queue_free()


func _on_body_entered(body):
	# Garante 1 inimigo por laser, mesmo encostando em dois no mesmo frame
	if acertou:
		return
	if body.is_in_group("aliens"):
		acertou = true
		body.receber_dano()
		queue_free()
