class_name PowerUp
extends Resource

@export var nome := ""

@export_group("Visual")
## Spritesheet horizontal do item (o 1º quadro vira o ícone da HUD)
@export var sprite: Texture2D
@export var quadros := 1
@export var fps := 10.0
@export var cor_barra := Color.WHITE

@export_group("Efeito")
@export var duracao := 8.0
@export var projetil: PackedScene
@export var quantidade := 1
## Graus entre dois tiros vizinhos (só importa com quantidade > 1)
@export var angulo_leque := 0.0

@export_group("Sons")
@export var som_coleta: AudioStream
@export var volume_coleta := 0.0
@export var som_tiro: AudioStream
@export var volume_tiro := 0.0

# Cria os projéteis saindo de 'origem'; com quantidade > 1 eles abrem em leque
func atirar(origem: Vector2, pai: Node):
	Projetil.criar_leque(projetil, quantidade, angulo_leque, origem, pai)

# Ganchos vazios para power-ups que não são "tipo de tiro" (escudo, velocidade...):
# um script que faça "extends PowerUp" pode sobrescrever estas duas
func ao_ativar(_player):
	pass

func ao_acabar(_player):
	pass
