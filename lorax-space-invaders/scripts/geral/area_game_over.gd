# Área abaixo do chão: tira 1 vida do player quando um míssil ou um alien chega nela.
extends Area2D

# body_entered é conectado aqui no código.
func _ready():
	body_entered.connect(_on_body_entered)

func _on_area_entered(area):
	if area.is_in_group("misseis"):
		area.queue_free()
		Partida.perder_vida()

# Alien que passou por um buraco no chão: sai da horda (via sinal) e custa 1 vida
func _on_body_entered(body):
	if body.is_in_group("aliens"):
		body.emit_signal("alien_atingiu_base", body)
		body.queue_free()
		Partida.perder_vida()
