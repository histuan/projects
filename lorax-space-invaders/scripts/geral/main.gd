# Cena principal do jogo: placar, vidas, tremor de tela, letreiro de wave
# e spawn dos itens (motosserra, coração, planeta).
extends Node

# Cenas que a main instancia durante a partida
var Motosserra = preload("res://cenas/player/motosserra.tscn")
var Planeta = preload("res://cenas/geral/planeta.tscn")

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
var Coracao = preload("res://cenas/player/coracao_item.tscn")

# Nós da cena (organizados nas pastas hud/timers/sons)
@onready var labelp = $hud/VBoxContainer/LabelP
@onready var coracoes = $hud/coracoes
@onready var coracoes_boss = $hud/coracoesBoss
@onready var player = $player
@onready var camera = $Camera2D
@onready var timer_moto = $timers/TimerSpawnMoto
@onready var timer_planeta = $timers/TimerPlaneta
@onready var timer_coracao = $timers/TimerSpawnCoracao

# Tremor de tela: força atual e quanto ela diminui por segundo
var forca_tremor = 0.0
var queda_tremor = 20.0
var pontos = 0
var vidas = 3
var tween_wave: Tween = null
# static: continua legível pela tela de game over depois que a main é destruída
static var pontuacao_final = 0
const MAX_VIDAS = 3

# Sorteia o primeiro spawn de cada item e começa a música
func _ready():
	pontuacao_final = 0
	coracoes_boss.hide()
	timer_moto.wait_time = randf_range(7,14)
	timer_moto.start()
	timer_planeta.wait_time = randf_range(5, 10)
	timer_planeta.start()
	timer_coracao.wait_time = randf_range(1,2)
	timer_coracao.start()
	$sons/musga.play()
	
# Tira 1 vida. com_piscada = true faz o player piscar (dano direto);
# false não pisca (bala que passou do chão, vinda da AreaGameOver)
func perder_vida(com_piscada):
	# Já morto: ignora danos extras
	if vidas <= 0:
		return
	vidas -=1
	coracoes.set_vidas(vidas)
	tremer(4)
	# Era a última vida: morte + tremor forte + hit-stop
	if vidas <= 0:
		player.morrer()
		tremer(21,1.2)
		congelar(0.15)
	elif com_piscada:
		player.piscar()

# Atualiza os corações do boss (sinal boss_dano); no zero eles somem piscando
func perder_vida_boss(v):
	coracoes_boss.set_vidas(v)
	if v <= 0:
		coracoes_boss.sumir_piscando()

# Soma os pontos de um inimigo morto e mostra o "+N" no lugar dele
func Somar_pontos_alien(a):
	pontos += a.valor_pontos
	pontuacao_final = pontos
	labelp.text = str(pontos)
	mostrar_pontos(a.valor_pontos, a.global_position)

# Bônus por matar o boss (o "+500" flutuante é chamado pelo próprio bonus.gd)
func somar_bonus():
	pontos+= 500
	pontuacao_final = pontos
	labelp.text = str(pontos)

# Ligadas aos sinais do boss: corações piscam enquanto ele desce e param quando ele chega
func mostrar_vida_boss():
	coracoes_boss.show()
	coracoes_boss.piscar_ate_parar()

func parar_piscada_boss():
	coracoes_boss.parar_piscada()


# Cria uma motosserra no topo, em x aleatório, e agenda a próxima
func _on_timer_spawn_moto_timeout():
	var m = Motosserra.instantiate()
	var x = randf_range(20, 234)
	m.global_position = Vector2(x, 0)
	add_child(m)
	timer_moto.wait_time = randf_range(8, 16)
	timer_moto.start()
	
# Cria um planeta dentro de "fundo" (desenhado logo depois das estrelas, atrás de tudo)
func _on_timer_planeta_timeout():
	var p = Planeta.instantiate()
	$fundo.add_child(p)
	timer_planeta.wait_time = randf_range(45, 70)
	timer_planeta.start()
	
# Começa um tremor. Um mais fraco não substitui um mais forte que ainda está rolando.
# duracao > 0: zera em 'duracao' segundos; senão cai 20 por segundo
func tremer(forca, duracao = 0.0):
	if forca < forca_tremor:
		return
	forca_tremor = forca
	if duracao > 0:
		queda_tremor = forca / duracao
	else:
		queda_tremor = 20.0

# Aplica o tremor: desloca a câmera aleatoriamente e diminui a força a cada frame
func _process(delta):
	if forca_tremor > 0:
		camera.offset = Vector2(randf_range(-forca_tremor, forca_tremor), randf_range(-forca_tremor, forca_tremor)).round()
		forca_tremor = move_toward(forca_tremor, 0, queda_tremor * delta)
	else:
		camera.offset = Vector2.ZERO

# Letreiro "WAVE N" piscando 2 vezes (~4,2 s).
# Usa $ e não @onready porque é chamada pelo groupAlien ANTES do _ready da main
func mostrar_wave(n):
	var w = $hud/wave
	var l = $hud/wave/LabelWave
	l.text = str(n)
	w.modulate.a = 0.0
	if tween_wave != null:
		tween_wave.kill()
	tween_wave = create_tween()
	for i in range(2):
		tween_wave.tween_property(w, "modulate:a", 1.0, 0.8)
		tween_wave.tween_interval(0.5)
		tween_wave.tween_property(w, "modulate:a", 0.0, 0.8)

# Texto "+N" que sobe e some. Cor por valor: 200 forte, 300 sniper, 500 boss
func mostrar_pontos(valor, pos):
	var l = Label.new()
	l.text = "+" + str(valor)
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(40, 8)
	l.position = pos - Vector2(20, 4)
	if(valor == 200):
		l.add_theme_color_override("font_color", Color.from_rgba8(253, 208, 23, 220))
	elif(valor == 300):
		l.add_theme_color_override("font_color", Color.from_rgba8(251, 140, 7, 204))
	elif(valor == 500):
		l.add_theme_color_override("font_color", Color.from_rgba8(217, 25, 255))
	else:
		l.add_theme_color_override("font_color", Color.from_rgba8(255, 255, 255))
	add_child(l)
	# Sobe 12 px e desaparece ao mesmo tempo; no fim o Label é apagado
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 12, 0.6)
	t.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.2)
	t.chain().tween_callback(l.queue_free)

# Hit-stop: para o tempo do jogo por um instante.
# O último true do create_timer faz ele ignorar o time_scale (senão nunca terminaria)
func congelar(duracao):
	Engine.time_scale = 0.0
	await get_tree().create_timer(duracao, true, false, true).timeout
	Engine.time_scale = 1.0

# Garante que o tempo volte ao normal se a cena trocar durante um congelamento
func _exit_tree():
	Engine.time_scale = 1.0

# Chamada pelo coração que cai: +1 vida, até o máximo, só com o player vivo
func ganhar_vida():
	if vidas <= 0 or vidas >= MAX_VIDAS:
		return
	vidas += 1
	coracoes.set_vidas(vidas)
	$sons/coletarCoracao.play()

# Só cria coração se faltar vida; o timer é reagendado sempre
func _on_timer_spawn_coracao_timeout():
	if vidas > 0 and vidas < MAX_VIDAS:
		var c = Coracao.instantiate()
		c.global_position = Vector2(randf_range(20, 234), 0)
		add_child(c)
	timer_coracao.wait_time = randf_range(10, 15)
	timer_coracao.start()
