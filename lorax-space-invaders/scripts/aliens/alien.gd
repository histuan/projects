# Alien da horda (base também do alien_forte, que herda esta cena):
# vaivém lateral e tiro. Vida, dano, piscada e sons vêm do Inimigo.
extends Inimigo

var missil = preload("res://cenas/alien/missil.tscn")

@onready var time_movimento = $TimerMov
@onready var animation_alien = $AnimationAlien
@onready var spawn_point = $SpawnPoint

# Vaivém: anda 'passo' px a cada TimerMov e inverte ao se afastar 'distancia' px da posição inicial
var origin = 0
var distancia = 30
var passo = 7
var direction = 1
var atingiu_base = false

# Ouvidos pelo groupAlien (tirar da lista)
signal alien_eliminado(alien)
signal alien_atingiu_base(alien);

# Nomes dos sons nesta cena (o alien_forte muda vidas/pontos pelo Inspector: 2 e 200)
func _init():
	som_dano = "sons/danoSFX"
	som_morte = "sons/explosionsfx"

func _ready():
	time_movimento.start()
	origin = self.position.x

func _on_timer_mov_timeout():
	self.position.x += direction * passo
	if self.position.x >= origin + distancia or self.position.x <= origin - distancia:
		direction *= -1

# Morte com animação: toca "destroy" (que chama elimination() no fim).
# Golpe de motosserra usa o som próprio; forte_morte só existe no alien_forte
func morrer(fonte):
	animation_alien.play("destroy")
	if fonte == "moto":
		soltar_som("sons/motoHitSFX")
	else:
		soltar_som(som_morte)
	soltar_som("sons/forte_morte")

# Chamada pela animação destroy: dá os pontos, avisa o groupAlien e remove o alien
func elimination():
	dar_pontos()
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
		body.receber_dano()
		emit_signal("alien_atingiu_base",self)
		queue_free()

# Chamada pelo sistema de dificuldade do groupAlien
func acelerar_movimento(novo_tempo):
	time_movimento.wait_time = novo_tempo
