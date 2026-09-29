# Boss (Lorax): desce até a altura alvo, anda de um lado pro outro e arremessa árvores.
# Vida, dano, piscada e sons vêm do Inimigo.
extends Inimigo

signal bonus_eliminado

var arvore = preload("res://cenas/alien/arvore.tscn")

# Entrada e movimentacao: desce até altura_alvo e depois anda entre os limites
@export var altura_alvo := 48.0
@export var vel_descida := 40.0
@export var vel_lado := 60.0
@export var limite_esq := 37.0
@export var limite_dir := 217.0
var dir_lado := 1
var chegou = false

# Ouvidos pela hud (corações do boss)
signal boss_dano(vidas)
signal boss_desceu
signal boss_apareceu

# Valores próprios do Lorax (sons de dano/morte: os padrões do Inimigo)
func _init():
	vidas = 5
	valor_pontos = 500

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

# Fim da animação de morte: "+500" grande, avisa o groupAlien e some
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "destruido":
		dar_pontos(16)
		emit_signal("bonus_eliminado")
		queue_free()

# Chamada pela animação destruido: cai em diagonal enquanto explode
func descida():
	self.position.x += 3 * dir_lado
	self.position.y += 5

# Além do dano normal, avisa a hud para atualizar os corações do boss
func receber_dano(quantidade = 1, fonte = "tiro"):
	if not vivo:
		return
	super(quantidade, fonte)
	boss_dano.emit(max(vidas, 0))

# Sobreviveu ao golpe: animação de dano + o padrão (som e piscada)
func ao_ferir(fonte):
	$AnimationPlayer.play("dano")
	super(fonte)

# Para de atacar, toca a animação de morte e treme a tela + hit-stop
# (os pontos saem no fim da animação "destruido")
func morrer(_fonte):
	$AnimationPlayer.play("destruido")
	soltar_som(som_morte)
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
