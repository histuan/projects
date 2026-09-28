# Alien da horda (base também do alien_forte, que herda esta cena):
# vaivém lateral, tiro, dano e morte com animação.
extends CharacterBody2D

var missil = preload("res://cenas/alien/missil.tscn")

@onready var time_movimento = $TimerMov
@onready var animation_alien = $AnimationAlien
@onready var spawn_point = $SpawnPoint

# O alien_forte sobrescreve: 2 vidas e 200 pontos
@export var vidas = 1
@export var valor_pontos = 100

# Vaivém: anda 'passo' px a cada TimerMov e inverte ao se afastar 'distancia' px da posição inicial
var origin = 0
var distancia = 30
var passo = 7
var direction = 1
var atingiu_base = false



# Ouvidos pelo groupAlien (tirar da lista) e pela main (somar pontos)
signal alien_eliminado(alien)
signal alien_atingiu_base(alien);

func _ready():
	time_movimento.start()
	origin = self.position.x
	
func _on_timer_mov_timeout():
	self.position.x += direction * passo
	if self.position.x >= origin + distancia or self.position.x <= origin - distancia:
		direction *= -1

# Tiro de laser: se ainda tem vida, só leva dano; senão toca "destroy" (que chama elimination())
func explosion():
	vidas -= 1
	if vidas > 0:
		levar_dano()
		return
	animation_alien.play("destroy")
	# Os sons de morte vão para a cena principal para terminarem depois que o alien sumir.
	if has_node("sons/explosionsfx"):
		var som = $sons/explosionsfx
		som.reparent(get_tree().current_scene)
		som.play()
		som.finished.connect(som.queue_free)
	# forte_morte só existe no alien_forte
	if has_node("sons/forte_morte"):
		var som2 = $sons/forte_morte
		som2.reparent(get_tree().current_scene)
		som2.play()
		som2.finished.connect(som2.queue_free)

# Dano sem morrer (só o forte chega aqui): som de dano, se existir, + piscada
func levar_dano():
	if has_node("sons/danoSFX"):
		$sons/danoSFX.play()
	piscar()

var tween_pisca: Tween = null
# Pisca 3 vezes; mata a piscada anterior para não acumular tweens
func piscar():
	if tween_pisca != null:
		tween_pisca.kill()
	tween_pisca = create_tween()
	for i in range(3):
		tween_pisca.tween_property(self, "modulate:a", 0.2, 0.08)
		tween_pisca.tween_property(self, "modulate:a", 1.0, 0.08)
	
# Chamada pela animação destroy: avisa quem está ouvindo e remove o alien
func elimination():
	emit_signal("alien_eliminado",self)
	get_parent().remove_child(self)
	queue_free()

# Chamada pelo groupAlien: solta um míssil para baixo
func disparar():
	var novo_missil = missil.instantiate()
	$sons/tiro.play()
	novo_missil.global_position = spawn_point.global_position
	get_parent().add_child(novo_missil)


# Encostou num bloco: danifica o bloco e some junto (atingiu_base evita repetir)
func _on_area_base_body_entered(body):
	if atingiu_base:
		return
	if body.is_in_group("blocos"):
		hide()
		atingiu_base = true
		body.destruir()
		emit_signal("alien_atingiu_base",self)
		queue_free()
		
# Chamada pelo sistema de dificuldade do groupAlien
func acelerar_movimento(novo_tempo):
	time_movimento.wait_time = novo_tempo
	
# Igual à explosion(), mas para o golpe da motosserra (som de morte diferente)
func explosion_moto():
	vidas -= 1
	if vidas > 0:
		levar_dano()
		return
	animation_alien.play("destroy")
	if has_node("sons/motoHitSFX"):
		var som = $sons/motoHitSFX
		som.reparent(get_tree().current_scene)
		som.play()
		som.finished.connect(som.queue_free)
	if has_node("sons/forte_morte"):
		var som2 = $sons/forte_morte
		som2.reparent(get_tree().current_scene)
		som2.play()
		som2.finished.connect(som2.queue_free)
	
