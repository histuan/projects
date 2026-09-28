# Bala do sniper: linha reta na direção travada. Sem grupo de propósito: não entra
# em "misseis" (não tira vida ao passar do chão) e atravessa os blocos.
extends Area2D

var velocidade = 120
var direcao = Vector2.DOWN

# Anda e some ao sair da tela
func _process(delta):
	global_position += direcao * velocidade * delta
	if global_position.y > 260 or global_position.x < -10 or global_position.x > 264:
		queue_free()

# Só acerta o player
func _on_body_entered(body):
	if body.is_in_group("tanque"):
		body.dano()
		queue_free()
