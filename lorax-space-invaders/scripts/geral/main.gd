# Cena principal da partida. Zera o estado (autoload Partida)
extends Node

@onready var camera = $Camera2D
@onready var player = $player

const BATALHA_FINAL = preload("res://cenas/boss/batalha_final.tscn")

# Números dos efeitos da boss fight (afinados no Inspector)
const EFEITOS = preload("res://recursos/boss/efeitos_boss.tres")

# _enter_tree roda ANTES do _ready de qualquer filho
func _enter_tree():
	Partida.nova_partida()

# Saindo da partida (game over, Reiniciar, Menu): o tempo do jogo volta ao normal
func _exit_tree():
	TempoJogo.limpar()

# Música, ajustes da câmera e reações aos sinais da Partida
func _ready():
	$sons/musga.play()
	camera.zoom_ligado = EFEITOS.zoom_ligado
	camera.fator_tremor_reduzido = EFEITOS.fator_tremor_reduzido
	Partida.vida_perdida.connect(_on_vida_perdida)
	Partida.vida_ganha.connect($sons/coletarCoracao.play)
	Partida.morreu.connect(_on_morreu)
	$groupAlien.wave_boss_chegou.connect($hud.esconder_placar)
	$groupAlien.wave_boss_chegou.connect($spawner.parar_planeta)
	$groupAlien.boss_pode_entrar.connect(_on_boss_pode_entrar)
	$hud.coracao_boss_perdido.connect(_on_coracao_boss_perdido)

# Tela limpa na wave do boss: cria a batalha final logo depois do groupAlien na árvore
# (desenha atrás do cenário e da hud), liga os sinais dela à hud e manda começar
func _on_boss_pode_entrar():
	var batalha = BATALHA_FINAL.instantiate()
	batalha.vida_boss_mudou.connect($hud.mostrar_vida_boss_final)
	batalha.boss_invulneravel.connect($hud.piscar_vida_boss)
	batalha.terminou.connect(_on_batalha_terminou)
	add_child(batalha)
	move_child(batalha, $groupAlien.get_index() + 1)
	batalha.comecar(player)

# Acabaram as fases que existem (por enquanto só imprime)
func _on_batalha_terminou():
	print("FASE 2 ENTRARIA AQUI")

# Um coração do boss esvaziou (não vale para o último): tremor leve + hit-stop curto
func _on_coracao_boss_perdido():
	camera.tremer(EFEITOS.coracao_boss_tremor.x, EFEITOS.coracao_boss_tremor.y)
	TempoJogo.congelar(EFEITOS.coracao_boss_hitstop)

# Qualquer vida perdida: tremor leve
func _on_vida_perdida():
	camera.tremer(4)

# Última vida: player morre + tremor forte + hit-stop
func _on_morreu():
	player.morrer()
	camera.tremer(21, 1.2)
	TempoJogo.congelar(0.15)
