# Cena principal da partida. Zera o estado (autoload Partida)
extends Node

@onready var camera = $Camera2D
@onready var player = $player

const BATALHA_FINAL = preload("res://cenas/boss/batalha_final.tscn")
# Estilo do letreiro FINAL WAVE (pisca e fade); o tempo na tela é o do alarme
const LETREIRO_FINAL_WAVE = preload("res://recursos/boss/letreiros/final_wave.tres")

# Ferramentas dos efeitos da boss fight: regras, cores, tela e partículas (afinadas no
# Inspector). Os momentos da luta moram no momentos_boss.tres (autoload Momentos)
const EFEITOS = preload("res://recursos/boss/efeitos_boss.tres")
const LabEfeitos = preload("res://scripts/geral/lab_efeitos.gd")
const LabSons = preload("res://scripts/geral/lab_sons.gd")
const LabTextos = preload("res://scripts/geral/lab_textos.gd")
const PainelDebug = preload("res://scripts/geral/painel_debug.gd")

# 1 vida na luta: batimento, música abafada e bordas vermelhas ligados
var vida_baixa_ligada = false
# Conta o fade da música do jogo (começa quando a wave 10 chega; pausa com o jogo)
var relogio_fade: Timer = null
# Painel de debug (F3); só existe em build de debug
var painel_debug = null
var caixa_dialogo: CaixaDialogo

# _enter_tree roda ANTES do _ready de qualquer filho
func _enter_tree():
	Partida.nova_partida()

# Saindo da partida (game over, Reiniciar, Menu): o tempo do jogo volta ao normal, os
# momentos agendados são cancelados e os autoloads de áudio soltam tudo (senão o
# batimento e a música continuariam no menu)
func _exit_tree():
	TempoJogo.limpar()
	Momentos.limpar()
	Sons.parar_tudo()
	Musica.limpar()

# Música, ajustes da câmera e da tela, ferramentas dos momentos, reações aos sinais da
# Partida, tiro travado durante as falas e o LAB (cheat)
func _ready():
	Musica.adotar($sons/musga)
	camera.configurar(EFEITOS)
	$EfeitosTela.configurar(EFEITOS)
	caixa_dialogo = CaixaDialogo.new()
	add_child(caixa_dialogo)
	Momentos.registrar(camera, $EfeitosTela, $fundo/estrelas, self, EFEITOS, $hud, caixa_dialogo)
	caixa_dialogo.abriu.connect(player.bloquear_tiro.bind(&"caixa"))
	# Diferido: o Espaço que fecha a caixa não pode virar tiro no mesmo quadro
	caixa_dialogo.fechou.connect(player.liberar_tiro.bind(&"caixa"), CONNECT_DEFERRED)
	Partida.vida_perdida.connect(_on_vida_perdida)
	Partida.vida_ganha.connect($sons/coletarCoracao.play)
	Partida.morreu.connect(_on_morreu)
	Partida.vidas_mudaram.connect(atualizar_vida_baixa)
	$groupAlien.wave_boss_chegou.connect($hud.esconder_placar)
	$groupAlien.wave_boss_chegou.connect($spawner.parar_planeta)
	$groupAlien.wave_boss_chegou.connect(_on_wave_boss_chegou)
	$groupAlien.boss_pode_entrar.connect(_on_boss_pode_entrar)
	$hud.coracao_boss_perdido.connect(_on_coracao_boss_perdido)
	$hud.coracoes_boss_reencheram.connect(_on_coracoes_boss_reencheram)
	if EFEITOS.hud_treme:
		camera.tremeu.connect($hud.acompanhar_tremor)
	if OS.is_debug_build():
		painel_debug = PainelDebug.new()
		add_child(painel_debug)
	if Partida.etapa_inicial == Partida.Etapa.LAB_EFEITOS:
		abrir_lab()
	elif Partida.etapa_inicial == Partida.Etapa.LAB_SONS:
		abrir_lab_sons()
	elif Partida.etapa_inicial == Partida.Etapa.LAB_TEXTOS:
		abrir_lab_textos()

# LAB DE EFEITOS: painel que toca cada momento do momentos_boss.tres; o spawner para (nada
# cai nem passa) e o boneco do Lorax fica no mundo (filho da main) para tremor e zoom valerem
func abrir_lab():
	$spawner.parar_tudo()
	var lab = LabEfeitos.new()
	add_child(lab)
	lab.preparar(camera, $EfeitosTela, $fundo/estrelas, EFEITOS, self, $hud, player, $cenario)

# LAB DE SONS: toca cada evento do sons_boss.tres (a música do jogo segue tocando,
# para dar para ouvir os crossfades a partir dela)
func abrir_lab_sons():
	var lab = LabSons.new()
	add_child(lab)
	lab.iniciar()

# LAB DE TEXTOS: mostra cada letreiro e cada fala como a luta mostra
func abrir_lab_textos():
	var lab = LabTextos.new()
	add_child(lab)
	lab.preparar($hud, caixa_dialogo)

# Wave 10 começou: a música do jogo some, e ficar com 1 vida passa a ligar a vida baixa
func _on_wave_boss_chegou():
	Partida.comecar_luta_boss()
	atualizar_vida_baixa(Partida.vidas)
	Musica.fade_out(Sons.BIBLIOTECA.wave10_fade_musica)
	relogio_fade = Timer.new()
	relogio_fade.one_shot = true
	relogio_fade.ignore_time_scale = true
	add_child(relogio_fade)
	relogio_fade.start(Sons.BIBLIOTECA.wave10_fade_musica)

# Tela limpa na wave do boss: espera a música do jogo terminar de sumir (se ainda não
# sumiu), silêncio, alarme com FINAL WAVE piscando e, quando o letreiro some, a música do
# Lorax 2.0 entra junto com a descida dele. Tudo pausa com o jogo
func _on_boss_pode_entrar():
	if relogio_fade != null and relogio_fade.time_left > 0:
		await esperar(relogio_fade.time_left)
	await esperar(Sons.BIBLIOTECA.wave10_silencio)
	var alarme = Sons.tocar(&"wave_boss_alarme")
	var duracao_alarme = 0.0
	if alarme != null:
		duracao_alarme = alarme.stream.get_length() / alarme.pitch_scale
	$hud.esconder_letreiro_wave()
	var letreiro = $hud.mostrar_letreiro(LETREIRO_FINAL_WAVE, "", "", duracao_alarme)
	await letreiro.sumiu
	Musica.tocar(&"musica_wave10")
	comecar_batalha()

# Cria a batalha final logo depois do groupAlien na árvore (desenha atrás do cenário e
# da hud), liga os sinais dela à hud (e ao painel de debug, se existir) e manda começar
func comecar_batalha():
	var batalha = BATALHA_FINAL.instantiate()
	batalha.vida_boss_mudou.connect($hud.mostrar_vida_boss_final)
	batalha.boss_invulneravel.connect($hud.piscar_vida_boss)
	if painel_debug != null:
		batalha.fase_mudou.connect(painel_debug.mostrar_fase)
		batalha.vida_boss_mudou.connect(painel_debug.mostrar_vida_boss)
		batalha.boss_invulneravel.connect(painel_debug.mostrar_invulneravel)
	batalha.fase_mudou.connect(_on_fase_mudou)
	batalha.terminou.connect(_on_batalha_terminou)
	add_child(batalha)
	move_child(batalha, $groupAlien.get_index() + 1)
	batalha.comecar(player)

# Espera em tempo real que congela no Pause. O Timer é filho da main: se a cena trocar
# no meio, ele some junto e a sequência simplesmente não continua
func esperar(segundos):
	var timer = Timer.new()
	timer.one_shot = true
	timer.ignore_time_scale = true
	add_child(timer)
	timer.start(segundos)
	await timer.timeout
	timer.queue_free()

# Uma fase da luta começou: a Partida guarda o número dela (o "FIM" vem com 0 e não muda nada)
func _on_fase_mudou(_nome, numero):
	if numero > 0:
		Partida.definir_fase_luta(numero)

# Acabaram as fases que existem (por enquanto só imprime)
func _on_batalha_terminou():
	print("FASE 2 ENTRARIA AQUI")

# Um coração do boss esvaziou (não vale para o último): o momento tem o stinger, o tremor
# leve e o hit-stop curto (sem alvo por enquanto: as folhinhas entram quando a F1 passar o corpo)
func _on_coracao_boss_perdido():
	Momentos.tocar(&"coracao_boss_perdido")

# Os corações do boss encheram (entrada da fase)
func _on_coracoes_boss_reencheram():
	Sons.tocar(&"boss_coracoes_reenchem")

# Com 1 vida durante a luta (ou no LAB DE EFEITOS, para testar): o coração bate em loop, a
# música abafa e as bordas vermelhas pulsam. Com mais vidas (ou morto), as três param
func atualizar_vida_baixa(vidas):
	var em_luta = Partida.em_luta_boss or Partida.etapa_inicial == Partida.Etapa.LAB_EFEITOS
	var deve_ligar = em_luta and vidas == 1
	if deve_ligar and not vida_baixa_ligada:
		Sons.tocar(&"batimento_vida_baixa")
		Musica.pedir_abafar(&"vida_baixa", EFEITOS.vida_baixa_abafar_hz, EFEITOS.vida_baixa_abafar_duracao)
		$EfeitosTela.bordas_fixas(EFEITOS.cor_dano, EFEITOS.vida_baixa_bordas_alfa, EFEITOS.vida_baixa_bordas_pulsar)
	elif not deve_ligar and vida_baixa_ligada:
		Sons.parar(&"batimento_vida_baixa")
		Musica.liberar_abafar(&"vida_baixa", EFEITOS.vida_baixa_abafar_duracao)
		$EfeitosTela.soltar_bordas_fixas()
	vida_baixa_ligada = deve_ligar

# Qualquer vida perdida: na arena, o momento do hit (tremor, hit-stop, bordas e som);
# fora dela, tremor leve
func _on_vida_perdida():
	if player.em_arena:
		Momentos.tocar(&"player_hit", player)
	else:
		camera.tremer(4)

# Última vida: player morre + tremor forte + hit-stop
func _on_morreu():
	player.morrer()
	camera.tremer(21, 1.2)
	TempoJogo.congelar(0.15)
