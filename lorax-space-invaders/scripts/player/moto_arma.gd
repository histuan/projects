# Projétil da motosserra: sobe e, ao encostar num inimigo, acerta todos num raio de 40 px.
extends Projetil

@export var raio := 40.0

# Anda como o laser; só a fonte do dano e a folga de saída mudam
func _init():
	fonte = "moto"
	margem_tela = 20.0

func _ready():
	$AnimationPlayer.play("moto")

# Em vez de ferir só o alvo: dano em área em todo inimigo no raio
func ao_acertar(_body):
	var centro = global_position
	for alien in get_tree().get_nodes_in_group("aliens"):
		if is_instance_valid(alien) and alien.global_position.distance_to(centro) <= raio:
			alien.receber_dano(dano, fonte)
	hide()
	queue_free()
