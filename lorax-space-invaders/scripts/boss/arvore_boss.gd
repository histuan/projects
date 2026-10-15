# Árvore do boss na fase 2: sai em leque já mirado (não mira de novo). O desenho inclina com a
# direção do voo até um limite, com a borda suavizada pelo flash.gdshader, e explode em pé; a
# direção e a colisão giram com o nó. Dano igual ao da árvore do Lorax pequeno.
extends "res://scripts/aliens/arvore.gd"

## Momento do momentos_boss.tres quando ela explode na tela (tremor e som)
@export var momento_explosao := &""
## Momento quando ela explode fora da tela (sem tremor)
@export var momento_explosao_fora := &""
## Limite do ângulo do desenho (±); 0 = sempre em pé
@export var inclinacao_max_graus := 0.0
## Passos do ângulo do desenho; 0 = contínuo
@export var inclinacao_passo_graus := 0.0
## A folha é de ponta-cabeça (copa embaixo). true = o desenho gira junto com o voo: a copa vai na
## frente, alinhada com a colisão; false = o topo do desenho (as raízes) inclina para o lado do voo
@export var base_aponta_para_o_alvo := false

func _ready():
	super()
	inclinar_desenho()
	$AnimationPlayer.animation_started.connect(_on_animacao_comecou)

# O leque já apontou: a direção é a dele
func mirar_no_player():
	pass

# Ângulo do desenho pela rotação do nó (limitado e em passos); de pé fica o nearest de sempre
func inclinar_desenho():
	var graus = clampf(rad_to_deg(rotation), -inclinacao_max_graus, inclinacao_max_graus)
	if not base_aponta_para_o_alvo:
		graus = -graus
	if inclinacao_passo_graus > 0.0:
		graus = snappedf(graus, inclinacao_passo_graus)
	$Sprite2D.global_rotation = deg_to_rad(graus)
	if graus == 0.0:
		$Sprite2D.material = null

# A explosão sai em pé e sem o shader (a folha dela tem outro tamanho de quadro)
func endireitar():
	$Sprite2D.global_rotation = 0.0
	$Sprite2D.material = null

# O estourar() começa pelo fogo: dali em diante o desenho fica em pé
func _on_animacao_comecou(anim):
	if anim == &"fogo" or anim == &"explosao":
		endireitar()

# Chamada pela animação explosao: os momentos no lugar do tremor e do som embutidos
func explosao():
	var nome = momento_explosao if global_position.y < 256 else momento_explosao_fora
	if nome != &"":
		Momentos.tocar(nome, global_position)
