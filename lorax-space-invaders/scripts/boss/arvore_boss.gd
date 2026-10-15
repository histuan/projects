# Árvore do boss na fase 2: sai em leque já mirado (não mira de novo) e o desenho fica sempre em
# pé; só a direção e a colisão giram com o nó. Dano igual ao da árvore do Lorax pequeno.
extends "res://scripts/aliens/arvore.gd"

## Momento do momentos_boss.tres quando ela explode na tela (tremor e som)
@export var momento_explosao := &""
## Momento quando ela explode fora da tela (sem tremor)
@export var momento_explosao_fora := &""

# Girado ele serrilha: o desenho desfaz a rotação do leque
func _ready():
	super()
	$Sprite2D.global_rotation = 0.0

# O leque já apontou: a direção é a dele
func mirar_no_player():
	pass

# Chamada pela animação explosao: os momentos no lugar do tremor e do som embutidos
func explosao():
	var nome = momento_explosao if global_position.y < 256 else momento_explosao_fora
	if nome != &"":
		Momentos.tocar(nome, global_position)
