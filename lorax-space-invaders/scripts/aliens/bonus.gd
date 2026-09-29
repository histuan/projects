# Boss (Lorax): desce até a altura alvo, anda de um lado pro outro
extends CharacterBody2D

signal bonus_eliminado

var arvore = preload("res://cenas/alien/arvore.tscn")

var vivo = true
var vidas = 5

# Entrada e movimentacao: desce até altura_alvo e depois anda entre os limites
@export var altura_alvo := 48.0
@export var vel_descida := 40.0
@export var vel_lado := 60.0
@export var limite_esq := 37.0
@export var limite_dir := 217.0
var dir_lado := 1
var chegou = false

# Ouvidos pela main (corações do boss)
signal boss_dano(vidas)
signal boss_desceu
signal boss_apareceu

# Começa acima da tela, no centro
func _ready():
	position = Vector2(127, -20)
	emit_signal("boss_apareceu")
	
# Descendo; ao chegar, começa a arremessar e passa a de um lado pro outro
func _process(delta):
	if not vivo:
		return
	if position.y < altura_alvo:
		position.y += vel_descida * delta
	else:
		if not chegou:
			chegou = true
			emit_signal("boss_desceu")
			$TimerArremesso.start()
		position.x += dir_lado * vel_lado * delta
		if position.x <= limite_esq or position.x >= limite_dir:
			dir_lado *= -1 

# Fim da animação de morte: "+500", avisa main e groupAlien e some
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "destruido":
		Partida.somar_pontos(500, global_position, 16)
		emit_signal("bonus_eliminado")
		queue_free()

# Chamada pela animação destruido: cai em diagonal enquanto explode
func descida():
	self.position.x += 3 * dir_lado
	self.position.y += 5

# Levou dano: perde vida e avisa a hud (corações); morre no zero
func receber_dano(quantidade = 1, _fonte = "tiro"):
	if not vivo:
		return
	vidas -= quantidade
	$AnimationPlayer.play("dano")
	emit_signal("boss_dano",vidas)
	if vidas <=0:
		morrer()
	else:
		$sons/dano.play()
		piscar()

# Para de atacar, toca a animação de morte e treme a tela + hit-stop
func morrer():
	vivo = false
	$AnimationPlayer.play("destruido")
	var som = $sons/morte
	som.reparent(get_tree().current_scene)
	som.play()
	som.finished.connect(som.queue_free)
	$TimerArremesso.stop()
	var camera = get_viewport().get_camera_2d()
	camera.tremer(8)
	camera.congelar(0.12)
	
func _on_timer_arremesso_timeout():
	arremessar()

# Joga uma árvore (a mira no player é feita pelo arvore.gd)
func arremessar():
	$AnimationPlayer.play("atacando")
	$sons/arvere.play()
	var arv = arvore.instantiate()
	arv.global_position = global_position
	get_parent().add_child(arv)

# Chamada no fim de atacando/dano: volta à animação normal
func idle():
	$AnimationPlayer.play("normal")
	
var tween_pisca: Tween = null
# Pisca 3 vezes; mata a piscada anterior para não acumular
func piscar():
	if tween_pisca != null:
		tween_pisca.kill()
	tween_pisca = create_tween()
	for i in range(3):
		tween_pisca.tween_property(self, "modulate:a", 0.2, 0.08)
		tween_pisca.tween_property(self, "modulate:a", 1.0, 0.08)
