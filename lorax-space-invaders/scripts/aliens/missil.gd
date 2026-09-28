# Míssil dos aliens: desce reto; fere o player ou danifica o bloco que acertar.
# Se passar do chão, a AreaGameOver cuida dele (grupo "misseis").
extends Area2D

var speed = 150

func _process(delta):
	position.y += speed*delta

func _on_body_entered(body):
	if body.is_in_group("tanque"):
		body.dano()
		queue_free()
	if  body.is_in_group("blocos"):
		body.destruir()
		queue_free()
