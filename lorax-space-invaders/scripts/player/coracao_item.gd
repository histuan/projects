# Coração que cai: dá 1 vida ao encostar no player.
extends Area2D

var velocidade = 70
var pego = false
var tween_piscar: Tween = null

func _ready():
	add_to_group(&"itens_soltos")
	piscar()

func piscar():
	tween_piscar = create_tween()
	for i in range(5):
		tween_piscar.tween_property(self, "modulate:a", 0.2, 0.25)
		tween_piscar.tween_property(self, "modulate:a", 1.0, 0.25)

# Some com fade em 'duracao' s sem poder mais ser pego (a tela da transformação fica limpa)
func sumir(duracao):
	pego = true
	if tween_piscar != null:
		tween_piscar.kill()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duracao)
	tween.tween_callback(queue_free)

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
		Partida.ganhar_vida()
		queue_free()
