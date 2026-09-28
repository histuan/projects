# Sniper: entra deslizando até um canto, carrega (pisca vermelho) e atira mirando
# no player. Não faz parte da lista da horda (não trava a troca de wave).
extends CharacterBody2D

var TiroSniper = preload("res://cenas/alien/tiro_sniper.tscn")

@export var vidas = 2
@export var valor_pontos = 300
@export var vel_entrada = 30.0
# Canto de destino, definido pelo groupAlien antes do add_child
var alvo = Vector2.ZERO

var chegou = false
var vivo = true
var tween_piscar: Tween

# "aliens": leva tiro e fere ao encostar · "snipers": o groupAlien conta quantos existem
func _ready():
	add_to_group("aliens")
	add_to_group("snipers")

# Desliza até o canto; ao chegar, agenda o primeiro tiro
func _process(delta):
	if chegou or not vivo:
		return
	global_position = global_position.move_toward(alvo, vel_entrada * delta)
	if global_position == alvo:
		chegou = true
		$TimerTiro.start(randf_range(1.5, 2.5))

# Ciclo de tiro: carga (3 piscadas vermelhas), dispara e agenda o próximo
func _on_timer_tiro_timeout():
	if not vivo:
		return
	$AnimationPlayer.play("atirando")
	var aviso = create_tween()
	for i in 3:
		aviso.tween_property($Sprite2D, "modulate", Color(1, 0.3, 0.3), 0.1)
		aviso.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.1)
	await aviso.finished
	# Pode ter morrido durante o aviso
	if not vivo:
		return
	atirar()
	$AnimationPlayer.play("idle")
	$TimerTiro.start(randf_range(3.0, 5.0))

# A direção é travada no disparo (a bala não persegue o player)
func atirar():
	var player = get_tree().get_first_node_in_group("tanque")
	if player == null or not player.vivo:
		return
	var tiro = TiroSniper.instantiate()
	tiro.global_position = $SpawnPoint.global_position
	tiro.direcao = (player.global_position - $SpawnPoint.global_position).normalized()
	get_tree().current_scene.add_child(tiro)
	$sons/tiro.play()

func explosion():
	if not vivo:
		return
	vidas -= 1
	if vidas > 0:
		$sons/dano.play()
		piscar()
		return
	morrer()

# Piscada de dano (modulate do nó inteiro; o aviso vermelho usa o do Sprite2D)
func piscar():
	if tween_piscar:
		tween_piscar.kill()
	modulate.a = 1.0
	tween_piscar = create_tween()
	for i in 3:
		tween_piscar.tween_property(self, "modulate:a", 0.2, 0.08)
		tween_piscar.tween_property(self, "modulate:a", 1.0, 0.08)

# Desliga a colisão, soma os pontos direto na main, grita e some em 0,5 s
func morrer():
	vivo = false
	$TimerTiro.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	get_tree().current_scene.Somar_pontos_alien(self)
	if has_node("sons/morte"):
		var som = $sons/morte
		som.reparent(get_tree().current_scene)
		som.play()
		som.finished.connect(som.queue_free)
	if tween_piscar:
		tween_piscar.kill()
	$AnimationPlayer.play("destroy")
	var sumir = create_tween()
	sumir.tween_property(self, "modulate:a", 0.0, 0.5)
	sumir.tween_callback(queue_free)
