extends CharacterBody2D

# Mudou quem trava o player ou bloqueia o tiro (o LAB e o painel de debug leem)
signal controle_mudou
# mover_para() terminou
signal chegou
# A explosão da morte terminou (com ouvinte, quem ouve decide quando ir ao game over)
signal destruicao_terminou

@export var laser = preload("res://cenas/player/laser.tscn")

@onready var ptolaser = $LaserSpawn
@onready var timer_tiro = $timers/TimerTiro
@onready var anim = $AnimationPlayer
@onready var timer_power = $timers/TimerPowerUp

const GAME_OVER = preload("res://cenas/geral/game_over.tscn")
# i-frames e modo arena (afinados no Inspector)
const DADOS = preload("res://recursos/player/player_dados.tres")

const SPEED = 100.0
var direction = Vector2()
var podisp = true
var vivo = true
var powerup_ativo: PowerUp = null

# I-frames: sem levar dano até o relógio acabar, piscando
var invulneravel := false
var relogio_iframes: Timer
var tween_iframes: Tween = null
var alfa_antes_iframes := 1.0

# Pedidos por dono (ex.: &"caixa"): travar = não anda nem atira; sem tiro = só não atira
var donos_travando = {}
var donos_sem_tiro = {}
var travado: bool:
	get:
		return not donos_travando.is_empty()
var pode_atirar: bool:
	get:
		return donos_sem_tiro.is_empty() and not travado

# mover_para() em andamento: o código leva o player, o input não vale
var movendo := false
var tween_mover: Tween = null

# Modo arena: 8 direções, preso no limite, hurtbox pequena, nave pequena, sem sensorAlien
var em_arena := false
var limite_arena := Rect2()
var forma_normal: Shape2D
# Troca os quadros da chama da nave pequena
var relogio_chama: Timer
# A morte na arena (a nave parte e estoura em cacos)
var morte_arena: MorteArena

# Relógios dos i-frames e da chama da nave pequena, e a morte na arena
func _ready():
	relogio_iframes = Timer.new()
	relogio_iframes.one_shot = true
	relogio_iframes.timeout.connect(terminar_iframes)
	add_child(relogio_iframes)
	relogio_chama = Timer.new()
	relogio_chama.timeout.connect(_on_relogio_chama)
	add_child(relogio_chama)
	morte_arena = MorteArena.new()
	morte_arena.partiu.connect($Sprite2Dmini.hide)
	morte_arena.terminou.connect(eliminado)
	add_child(morte_arena)

# Movimento, animação e tiro, a cada frame de física
func _physics_process(_delta):
	if not vivo or movendo:
		return
	if travado:
		velocity = Vector2.ZERO
		return
	if em_arena:
		var entrada = Input.get_vector("esquerda", "direita", "cima", "baixo")
		velocity = entrada * DADOS.velocidade_arena
		animar(entrada.x)
	else:
		# -1 esquerda, 0 parado, 1 direita
		direction = Input.get_axis("esquerda", "direita")
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		animar(direction)
	if pode_atirar and Input.is_action_just_pressed("shoot") and podisp == true:
		atirar()
	move_and_slide()
	if em_arena:
		global_position = preso_na_arena(global_position)

# Troca entre o sprite parado e o de movimento e escolhe a animação pelo lado; na arena,
# só a nave pequena (sem inclinar)
func animar(lado):
	if em_arena:
		$Sprite2Didle.hide()
		$Sprite2Dmov.hide()
		$Sprite2Dmini.show()
	elif lado < 0:
		$Sprite2Didle.hide()
		$Sprite2Dmov.show()
		anim.play("mov_esq")
	elif lado > 0:
		$Sprite2Didle.hide()
		$Sprite2Dmov.show()
		anim.play("mov_dir")
	else:
		$Sprite2Dmov.hide()
		$Sprite2Didle.show()
		anim.play("idle")

# O power-up ativo decide o que sai; sem power-up, laser. Depois o cooldown (TimerTiro)
func atirar():
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

# Fim do cooldown
func _on_timer_tiro_timeout():
	podisp = true

# Perde 1 vida na Partida (a main reage com tremor, o momento da arena ou a morte) e, se
# sobreviveu, fica invulnerável piscando. Durante os i-frames o golpe não conta.
# Na arena o som do dano é do momento player_hit (a main toca)
func receber_dano(_quantidade = 1, _fonte = ""):
	if invulneravel:
		return
	Partida.perder_vida()
	if not em_arena:
		$sons/dano.play()
	if vivo:
		comecar_iframes()

# Invulnerável por iframes_duracao s, piscando entre iframes_alfa e o alfa de antes
func comecar_iframes():
	invulneravel = true
	alfa_antes_iframes = modulate.a
	tween_iframes = create_tween().set_loops()
	tween_iframes.tween_property(self, "modulate:a", DADOS.iframes_alfa, DADOS.iframes_pisca)
	tween_iframes.tween_property(self, "modulate:a", alfa_antes_iframes, DADOS.iframes_pisca)
	relogio_iframes.start(DADOS.iframes_duracao)

# Fim dos i-frames (ou cortados pelo LAB): para de piscar e volta ao alfa de antes
func terminar_iframes():
	relogio_iframes.stop()
	if tween_iframes != null:
		tween_iframes.kill()
		tween_iframes = null
	if invulneravel:
		modulate.a = alfa_antes_iframes
	invulneravel = false

# 'dono' trava o player (não anda nem atira) até destravar
func travar(dono):
	donos_travando[dono] = true
	velocity = Vector2.ZERO
	animar(0)
	controle_mudou.emit()

# 'dono' solta o player (outros donos podem continuar travando)
func destravar(dono):
	donos_travando.erase(dono)
	controle_mudou.emit()

# 'dono' bloqueia só o tiro até liberar
func bloquear_tiro(dono):
	donos_sem_tiro[dono] = true
	controle_mudou.emit()

# 'dono' libera o tiro (outros donos podem continuar bloqueando)
func liberar_tiro(dono):
	donos_sem_tiro.erase(dono)
	controle_mudou.emit()

# Leva o player até 'pos' em 'tempo' s, sem input no caminho; emite 'chegou' no fim.
# Devolve o tween (dá para dar await nele)
func mover_para(pos, tempo):
	if tween_mover != null:
		tween_mover.kill()
	movendo = true
	velocity = Vector2.ZERO
	animar(0)
	tween_mover = create_tween()
	tween_mover.tween_property(self, "global_position", pos, tempo)
	tween_mover.finished.connect(_on_chegou)
	return tween_mover

# Corta o mover_para no meio (o player fica onde estiver)
func parar_movimento():
	if tween_mover != null:
		tween_mover.kill()
		tween_mover = null
	movendo = false

# Fim do mover_para
func _on_chegou():
	movendo = false
	chegou.emit()

# Modo arena: anda em 8 direções preso em 'limite' (coordenadas do mundo), hurtbox pequena,
# nave pequena com a chama animada e sensorAlien desligado. Chamar de novo só troca o limite
func entrar_arena(limite: Rect2):
	limite_arena = limite
	if not em_arena:
		forma_normal = $CollisionShape2D.shape
		var forma = RectangleShape2D.new()
		forma.size = DADOS.hurtbox
		$CollisionShape2D.set_deferred("shape", forma)
		$sensorAlien.set_deferred("monitoring", false)
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		relogio_chama.start(DADOS.mini_tempo_quadro)
	em_arena = true
	animar(0)
	global_position = preso_na_arena(global_position)

# Volta ao jogo normal: hurtbox, sprites e sensorAlien de antes, só o eixo X
func sair_arena():
	if not em_arena:
		return
	em_arena = false
	$CollisionShape2D.set_deferred("shape", forma_normal)
	$sensorAlien.set_deferred("monitoring", true)
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	velocity = Vector2.ZERO
	relogio_chama.stop()
	$Sprite2Dmini.hide()
	animar(0)

# Próximo quadro da chama da nave pequena
func _on_relogio_chama():
	var mini = $Sprite2Dmini
	mini.frame = (mini.frame + 1) % mini.hframes

# 'pos' ajustada para o sprite inteiro (caixa_sprite) ficar dentro do limite da arena
func preso_na_arena(pos):
	var caixa = DADOS.caixa_sprite
	return pos.clamp(limite_arena.position - caixa.position, limite_arena.end - caixa.end)

# Trava os controles e toca "destroy" (que chama descida() e, no fim, eliminado()); na arena,
# a nave parte e estoura em cacos (MorteArena, que chama eliminado() no fim)
func morrer():
	vivo = false
	terminar_iframes()
	if em_arena:
		relogio_chama.stop()
		morte_arena.comecar()
		return
	$Sprite2Dmov.hide()
	$Sprite2Didle.show()
	anim.play("destroy")
	var som = $sons/morte
	som.reparent(get_tree().root)
	som.play()
	som.finished.connect(som.queue_free)

# Chamada pela animação destroy: o player afunda 4 px por quadro
func descida():
	self.position.y += 4

# Chamada no fim da animação destroy: avisa quem ouve 'destruicao_terminou' (a luta mostra
# uma fala antes) ou, sem ouvinte, vai direto para o game over
func eliminado():
	if destruicao_terminou.get_connections().is_empty():
		ir_para_game_over()
	else:
		destruicao_terminou.emit()

# Volta a viver no lugar (só o R do LAB): a morte na arena é interrompida e a nave reaparece
func reviver():
	morte_arena.cancelar()
	vivo = true
	if em_arena:
		relogio_chama.start(DADOS.mini_tempo_quadro)
	animar(0)

# Troca para a cena de game over
func ir_para_game_over():
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
	encerrar_powerup()

# Desliga o power-up ativo antes do tempo (ou no fim dele); sem power-up, nada
func encerrar_powerup():
	timer_power.stop()
	if powerup_ativo == null:
		return
	powerup_ativo.ao_acabar(self)
	powerup_ativo = null

# Toca um som vindo do PowerUp (todo power-up precisa ter som_coleta e som_tiro)
func tocar_som(no, stream, volume):
	no.stream = stream
	no.volume_db = volume
	no.play()

# Encostar num inimigo destrói o inimigo e tira vida do player
func _on_sensor_alien_body_entered(body):
	if body.is_in_group("aliens"):
		body.receber_dano()
		receber_dano()
