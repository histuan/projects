# Cena principal da partida. Zera o estado (autoload Partida)
extends Node

@onready var camera = $Camera2D
@onready var player = $player

const BATALHA_FINAL = preload("res://cenas/boss/batalha_final.tscn")

# Ferramentas dos efeitos da boss fight: regras, cores, tela e partículas (afinadas no
# Inspector). Os momentos da luta moram no momentos_boss.tres (autoload Momentos)
const EFEITOS = preload("res://recursos/boss/efeitos_boss.tres")
const LabEfeitos = preload("res://scripts/geral/lab_efeitos.gd")
const LabSons = preload("res://scripts/geral/lab_sons.gd")

# A wave do boss começou (o batimento com 1 vida só vale daqui em diante)
var luta_comecou = false
var batimento_ligado = false
# Conta o fade da música do jogo (começa quando a wave 10 chega; pausa com o jogo)
var relogio_fade: Timer = null

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
# Partida e o LAB (cheat)
func _ready():
	Musica.adotar($sons/musga)
	camera.configurar(EFEITOS)
	$EfeitosTela.configurar(EFEITOS)
	Momentos.registrar(camera, $EfeitosTela, $fundo/estrelas, self, EFEITOS)
	Partida.vida_perdida.connect(_on_vida_perdida)
	Partida.vida_ganha.connect($sons/coletarCoracao.play)
	Partida.morreu.connect(_on_morreu)
	Partida.vidas_mudaram.connect(atualizar_batimento)
	$groupAlien.wave_boss_chegou.connect($hud.esconder_placar)
	$groupAlien.wave_boss_chegou.connect($spawner.parar_planeta)
	$groupAlien.wave_boss_chegou.connect(_on_wave_boss_chegou)
	$groupAlien.boss_pode_entrar.connect(_on_boss_pode_entrar)
	$hud.coracao_boss_perdido.connect(_on_coracao_boss_perdido)
	$hud.coracoes_boss_reencheram.connect(_on_coracoes_boss_reencheram)
	if EFEITOS.hud_treme:
		camera.tremeu.connect($hud.acompanhar_tremor)
	if Partida.etapa_inicial == Partida.Etapa.LAB_EFEITOS:
		abrir_lab()
	elif Partida.etapa_inicial == Partida.Etapa.LAB_SONS:
		abrir_lab_sons()

# LAB DE EFEITOS: painel que toca cada momento do momentos_boss.tres;
# o boneco do Lorax fica no mundo (filho da main) para tremor e zoom valerem para ele
func abrir_lab():
	var lab = LabEfeitos.new()
	add_child(lab)
	lab.preparar(camera, $EfeitosTela, $fundo/estrelas, EFEITOS, self)

# LAB DE SONS: toca cada evento do sons_boss.tres (a música do jogo segue tocando,
# para dar para ouvir os crossfades a partir dela)
func abrir_lab_sons():
	var lab = LabSons.new()
	add_child(lab)
	lab.iniciar()

# Wave 10 começou: a música do jogo some, e ficar com 1 vida passa a ligar o batimento
func _on_wave_boss_chegou():
	luta_comecou = true
	atualizar_batimento(Partida.vidas)
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
	var letreiro = Momentos.parametros(&"wave10_alarme", &"letreiro_final_wave")
	$hud.mostrar_final_wave(duracao_alarme, letreiro.get("pisca", 0.0), letreiro.get("fade", 0.0))
	await $hud.final_wave_sumiu
	Musica.tocar(&"musica_wave10")
	comecar_batalha()

# Cria a batalha final logo depois do groupAlien na árvore (desenha atrás do cenário e
# da hud), liga os sinais dela à hud e manda começar
func comecar_batalha():
	var batalha = BATALHA_FINAL.instantiate()
	batalha.vida_boss_mudou.connect($hud.mostrar_vida_boss_final)
	batalha.boss_invulneravel.connect($hud.piscar_vida_boss)
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

# Com 1 vida durante a luta, o coração bate em loop; com mais (ou morto), para
func atualizar_batimento(vidas):
	var deve_bater = luta_comecou and vidas == 1
	if deve_bater and not batimento_ligado:
		Sons.tocar(&"batimento_vida_baixa")
	elif not deve_bater and batimento_ligado:
		Sons.parar(&"batimento_vida_baixa")
	batimento_ligado = deve_bater

# Qualquer vida perdida: tremor leve
func _on_vida_perdida():
	camera.tremer(4)

# Última vida: player morre + tremor forte + hit-stop
func _on_morreu():
	player.morrer()
	camera.tremer(21, 1.2)
	TempoJogo.congelar(0.15)
