# Árvore arremessada pelo boss: vai na direção do player e explode em área.
extends Area2D

var velocidade = 90
var direcao = Vector2.DOWN
var estourou = false

@export var sheet_explosao: Texture2D
@export var raio = 26.0

func _ready():
	# Mira no player no momento do lançamento
	var player = get_tree().get_first_node_in_group("tanque")
	if player != null:
		direcao = (player.global_position - global_position).normalized()
	$AnimationPlayer.play("lancamento")
	
# Depois do lançamento, passa para a animação de voo
func _on_animation_player_animation_finished(anim):
	if anim == "lancamento":
		$AnimationPlayer.play("voando")
		
# Explode sozinha se passar do fim da tela
func _process(delta):
	position += direcao * velocidade * delta
	if global_position.y > 260 and not estourou:
		estourar()
	
func _on_body_entered(body):
	if estourou:
		return
	if body.is_in_group("blocos") or body.is_in_group("tanque"):
		estourar(body)
		
# Explosão: danifica os blocos no raio e fere o player se foi atingido ou está no raio
func estourar(atingido = null):
	estourou = true
	velocidade = 0
	var centro = global_position
	for bloco in get_tree().get_nodes_in_group("blocos"):
		if bloco.global_position.distance_to(centro) <= raio:
			bloco.destruir()
	var player = get_tree().get_first_node_in_group("tanque")
	
	if player != null and (player == atingido or player.global_position.distance_to(centro) <= raio):
		player.dano()
		
	# Sem colisão: fogo por 0,1 s → troca para a spritesheet da explosão → some
	$CollisionShape2D.set_deferred("disabled", true)

	$AnimationPlayer.play("fogo")
	await get_tree().create_timer(0.1).timeout

	$Sprite2D.texture = sheet_explosao
	$Sprite2D.hframes = 6
	$Sprite2D.frame = 0
	$AnimationPlayer.play("explosao")
	await $AnimationPlayer.animation_finished

	queue_free()

# Chamada pela animação explosao: tremor (se ainda estiver na tela) e som
func explosao():
	if global_position.y < 256:
		get_viewport().get_camera_2d().tremer(6, 0.8)
	if has_node("explosao"):
		var som = $explosao
		som.reparent(get_tree().current_scene)
		som.play()
		som.finished.connect(som.queue_free)
