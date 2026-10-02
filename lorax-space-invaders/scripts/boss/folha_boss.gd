# Folha navalha do boss: desce girando; fere o player ou danifica o bloco que acertar.
# Fica FORA do grupo "misseis": passar do chão não custa vida.
extends Projetil

# Quadros por segundo do giro (a folha tem 4 quadros, um por direção)
@export var fps_giro := 12.0
var tempo := 0.0

# A velocidade fica na cena (folha_boss.tscn), para ajustar pelo Inspector
func _init():
	direcao = Vector2.DOWN
	grupos_alvo = ["tanque", "blocos"]

# Anda (Projetil) e troca o quadro do giro
func _process(delta):
	super(delta)
	tempo += delta
	$Sprite2D.frame = int(tempo * fps_giro) % $Sprite2D.hframes
