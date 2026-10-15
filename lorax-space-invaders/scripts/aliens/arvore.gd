# Árvore arremessada pelo boss: vai na direção do player; fere quem acerta e explode
# danificando os blocos em volta.
extends Projetil

@export var sheet_explosao: Texture2D
## Raio do dano em área nos BLOCOS (o player só leva dano no contato)
@export var raio = 26.0

# Alvos: blocos e player. Margem pequena: explode logo depois de passar do fim da tela
func _init():
	velocidade = 90.0
	direcao = Vector2.DOWN
	grupos_alvo = ["blocos", "tanque"]
	margem_tela = 4.0
	# Tiro inimigo no ar: a wave 10 espera ele sumir
	add_to_group("tiros_inimigos")

func _ready():
	mirar_no_player()
	$AnimationPlayer.play("lancamento")

# Mira no player no momento do lançamento
func mirar_no_player():
	var player = get_tree().get_first_node_in_group("tanque")
	if player != null:
		direcao = (player.global_position - global_position).normalized()

# Depois do lançamento, passa para a animação de voo
func _on_animation_player_animation_finished(anim):
	if anim == "lancamento":
		$AnimationPlayer.play("voando")
		
# Acertou um bloco ou o player: fere o player só se foi ele o atingido; os blocos do raio levam dano
func ao_acertar(body):
	estourar(body)

# Passou da borda da tela sem acertar nada: explode lá mesmo
func ao_sair_da_tela():
	acertou = true
	estourar()

# Explosão: danifica os blocos no raio; o player só é ferido se foi o atingido (contato)
func estourar(atingido = null):
	velocidade = 0
	var centro = global_position
	for bloco in get_tree().get_nodes_in_group("blocos"):
		if bloco.global_position.distance_to(centro) <= raio:
			bloco.receber_dano()
	if atingido != null and atingido.is_in_group("tanque"):
		atingido.receber_dano(dano, fonte)
		
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
	var som = $explosao
	som.reparent(get_tree().current_scene)
	som.play()
	som.finished.connect(som.queue_free)
