# Coração que cai: dá 1 vida ao encostar no player.
extends Area2D

var velocidade = 70
var pego = false

func _ready():
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

# "pego" evita dar vida duas vezes; get_parent() é a main (o coração nasce nela)
func _on_body_entered(body):
	if pego:
		return
	if body.is_in_group("tanque"):
		pego = true
		get_parent().ganhar_vida()
		queue_free()
