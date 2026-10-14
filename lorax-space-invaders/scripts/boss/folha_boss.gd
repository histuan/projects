# Folha navalha do boss: desce girando com um rastro; fere o player ou danifica o bloco que
# acertar; uma semente da Trúfula anula a folha (as duas somem).
# Fica FORA do grupo "misseis": passar do chão não custa vida.
extends Projetil

# Quadros por segundo do giro (a folha tem 4 quadros, um por direção)
@export var fps_giro := 12.0
## Momento do momentos_boss.tres ao bater num bloco (vazio = nada); o valor fica na cena
@export var momento_bloco := &""
## Momento quando uma semente da Trúfula anula a folha (vazio = nada)
@export var momento_anulada := &""
## Posições guardadas no rastro (0 = sem rastro)
@export var rastro_pontos := 0
## Largura do rastro em px
@export var rastro_largura := 0.0
## Alfa do rastro junto da folha (some até 0 na ponta)
@export var rastro_alfa := 0.0
@export var rastro_cor := Color.WHITE
var tempo := 0.0
var rastro: Line2D = null

# A velocidade fica na cena (folha_boss.tscn), para ajustar pelo Inspector
func _init():
	direcao = Vector2.DOWN
	grupos_alvo = ["tanque", "blocos"]

# Liga o encontro com outras áreas (a semente da Trúfula) e cria o rastro, se a cena pedir
func _ready():
	area_entered.connect(_on_area_entered)
	if rastro_pontos > 0:
		criar_rastro()

# Linha solta no mundo (top_level), clara junto da folha e transparente na ponta
func criar_rastro():
	rastro = Line2D.new()
	rastro.top_level = true
	rastro.width = rastro_largura
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(rastro_cor, 0.0))
	gradiente.set_color(1, Color(rastro_cor, rastro_alfa))
	rastro.gradient = gradiente
	add_child(rastro)

# Bateu num bloco: o momento no ponto; o dano e o sumiço são os do Projetil
func ao_acertar(body):
	if body.is_in_group("blocos") and momento_bloco != &"":
		Momentos.tocar(momento_bloco, global_position)
	super(body)

# Uma semente da Trúfula (Projetil com fonte "trufula") que ainda não acertou nada: as
# duas somem e o momento toca no ponto
func _on_area_entered(area):
	if acertou or not area is Projetil or area.fonte != "trufula" or area.acertou:
		return
	acertou = true
	area.acertou = true
	if momento_anulada != &"":
		Momentos.tocar(momento_anulada, global_position)
	area.queue_free()
	queue_free()

# Anda (Projetil), troca o quadro do giro e arrasta o rastro
func _process(delta):
	super(delta)
	tempo += delta
	$Sprite2D.frame = int(tempo * fps_giro) % $Sprite2D.hframes
	if rastro != null:
		rastro.add_point(global_position)
		while rastro.get_point_count() > rastro_pontos:
			rastro.remove_point(0)
