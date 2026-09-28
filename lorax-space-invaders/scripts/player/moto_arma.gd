# Projétil da motosserra: sobe e, ao encostar num inimigo, acerta todos num raio de 40 px.
extends Area2D

var velocity = 200
var estourou = false
@export var raio := 40.0

func _ready():
	$AnimationPlayer.play("moto")

func _process(delta):
	position.y -= velocity * delta
	if global_position.y < -20:
		queue_free()

func _on_body_entered(body):
	if estourou:
		return
	if body.is_in_group("aliens"):
		estourar()

# Dano em área: explosion_moto() nos aliens (som próprio); explosion() no boss e no sniper
func estourar():
	estourou = true
	var centro = global_position
	for alien in get_tree().get_nodes_in_group("aliens"):
		if is_instance_valid(alien) and alien.global_position.distance_to(centro) <= raio:
			if alien.has_method("explosion_moto"):
				alien.explosion_moto()
			else:
				alien.explosion()
	hide()
	queue_free()
