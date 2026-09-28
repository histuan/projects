# Cena principal da partida. Zera o estado (autoload Partida) ao entrar e liga as
# reações da cena aos avisos dela: tremor, hit-stop, morte do player e som de vida.
# Números: partida.gd · itens: spawner · tela: hud · tremor: Camera2D
extends Node

@onready var camera = $Camera2D
@onready var player = $player

# _enter_tree roda ANTES do _ready de qualquer filho: o estado já está zerado
# quando o groupAlien cria a wave 1
func _enter_tree():
	Partida.nova_partida()

# Música e reações aos sinais da Partida
func _ready():
	$sons/musga.play()
	Partida.vida_perdida.connect(_on_vida_perdida)
	Partida.vida_ganha.connect($sons/coletarCoracao.play)
	Partida.morreu.connect(_on_morreu)

# Qualquer vida perdida: tremor leve
func _on_vida_perdida():
	camera.tremer(4)

# Última vida: player morre + tremor forte + hit-stop
func _on_morreu():
	player.morrer()
	camera.tremer(21, 1.2)
	camera.congelar(0.15)
