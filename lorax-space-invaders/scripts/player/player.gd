# Player: movimento, animação por direção, tiro (laser ou motosserra), dano, morte
# e o power-up da motosserra.
extends CharacterBody2D

@export var laser = preload("res://cenas/player/laser.tscn")

@onready var ptolaser = $LaserSpawn
@onready var timer_tiro = $timers/TimerTiro
@onready var anim = $AnimationPlayer
@onready var timer_power = $timers/TimerPowerUp

const GAME_OVER = preload("res://cenas/geral/game_over.tscn")

const SPEED = 100.0
var direction = Vector2()
# podisp: pode atirar (volta a true no fim do TimerTiro)
var podisp = true
var vivo = true
# powerup_ativo: power-up ligado ou null
var powerup_ativo: PowerUp = null

# Movimento, animação e tiro, a cada frame de física
func _physics_process(delta):
	if not vivo:
		return
	# -1 esquerda, 0 parado, 1 direita
	direction = Input.get_axis("esquerda", "direita")
	if direction != 0: 
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	# Troca entre o sprite parado e o de movimento e escolhe a animação
	if direction < 0:
		$Sprite2Didle.hide()
		$Sprite2Dmov.show()
		anim.play("mov_esq")
	elif direction > 0:
		$Sprite2Didle.hide()
		$Sprite2Dmov.show()
		anim.play("mov_dir")
	else :
		$Sprite2Dmov.hide()
		$Sprite2Didle.show()
		anim.play("idle")
		
	# Tiro: o power-up ativo decide o que sai; sem power-up, laser. Depois o cooldown (TimerTiro)
	if Input.is_action_just_pressed("shoot") and podisp == true:
		if powerup_ativo != null:
			powerup_ativo.atirar(ptolaser.global_position, get_parent())
			tocar_som($sons/powerTiro, powerup_ativo.som_tiro, powerup_ativo.volume_tiro)
		else:
			var l = laser.instantiate()
			l.global_position = ptolaser.global_position
			get_parent().add_child(l)
			$sons/shootSFX.play()
		podisp = false
		timer_tiro.start()
	
	move_and_slide()

# Fim do cooldown
func _on_timer_tiro_timeout():
	podisp = true
	
# Perde 1 vida na Partida (a main reage com tremor ou morte); pisca se sobreviveu
func dano():
	Partida.perder_vida()
	$sons/dano.play()
	if vivo:
		piscar()
	
func piscar():
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(self, "modulate:a", 0.2, 0.08)
		tween.tween_property(self, "modulate:a", 1.0, 0.08)
		
# Trava os controles e toca "destroy" (que chama descida() e, no fim, eliminado())
func morrer():
	vivo = false
	$Sprite2Dmov.hide()
	$Sprite2Didle.show()
	anim.play("destroy")
	# O som vai para a raiz da árvore para continuar tocando depois da troca de cena
	var som = $sons/morte
	som.reparent(get_tree().root)
	som.play()
	som.finished.connect(som.queue_free)
	
# Chamada pela animação destroy: o player afunda 4 px por quadro
func descida():
	self.position.y += 4

# Chamada no fim da animação destroy: vai para o game over
func eliminado():
	if !self.is_queued_for_deletion():
		get_tree().change_scene_to_packed(GAME_OVER)

# Chamada pelo item que cai: liga o power-up por pu.duracao segundos.
# Pegar outro com um ativo substitui o antigo e reinicia o tempo.
func ativar_powerup(pu):
	if powerup_ativo != null:
		powerup_ativo.ao_acabar(self)
	powerup_ativo = pu
	pu.ao_ativar(self)
	tocar_som($sons/powerColeta, pu.som_coleta, pu.volume_coleta)
	timer_power.start(pu.duracao)
	
# Fim do tempo: desliga o power-up (a barra some sozinha)
func _on_timer_power_up_timeout():
	if powerup_ativo == null:
		return
	powerup_ativo.ao_acabar(self)
	powerup_ativo = null
	
# Toca um som vindo do PowerUp num AudioStreamPlayer genérico (ignora se não houver som)
func tocar_som(no, stream, volume):
	if stream == null:
		return
	no.stream = stream
	no.volume_db = volume
	no.play()

# Encostar num inimigo destrói o inimigo e tira vida do player
func _on_sensor_alien_body_entered(body):
	if body.is_in_group("aliens"):
		body.explosion()
		dano()  
