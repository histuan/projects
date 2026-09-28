# Player: movimento, animação por direção, tiro (laser ou motosserra), dano, morte
# e o power-up da motosserra.
extends CharacterBody2D

@export var laser = preload("res://cenas/player/laser.tscn")
@export var motoArma = preload("res://cenas/player/moto_arma.tscn")

@onready var ptolaser = $LaserSpawn
@onready var timer_tiro = $timers/TimerTiro
@onready var anim = $AnimationPlayer
@onready var timer_moto = $timers/TimerMotosserra

const GAME_OVER = preload("res://cenas/geral/game_over.tscn")

const SPEED = 100.0
var direction = Vector2()
# podisp: pode atirar (volta a true no fim do TimerTiro) · com_moto: power-up ativo
var podisp = true
var vivo = true
var com_moto = false

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
		
	# Tiro: motosserra se o power-up estiver ativo; depois espera o cooldown (TimerTiro)
	if Input.is_action_just_pressed("shoot") and podisp == true:
		var l
		if com_moto:
			l = motoArma.instantiate()
			$sons/motoSFX.play()    
		else:
			l = laser.instantiate()
			$sons/shootSFX.play()
		l.global_position = ptolaser.global_position
		get_parent().add_child(l)
		podisp = false
		timer_tiro.start()
	
	move_and_slide()

# Fim do cooldown
func _on_timer_tiro_timeout():
	podisp = true
	
# A main desconta a vida e decide se o player pisca ou morre
func dano():
	get_parent().perder_vida(true)
	$sons/dano.play()
	
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

# Chamada pelo item da motosserra: power-up por 8 s (TimerMotosserra)
func ativar_moto():
	com_moto = true
	$sons/motoColeta.play()
	timer_moto.start()
	
func _on_timer_motosserra_timeout():
	com_moto = false

# Encostar num inimigo destrói o inimigo e tira vida do player
func _on_sensor_alien_body_entered(body):
	if body.is_in_group("aliens"):
		body.explosion()
		dano()  
