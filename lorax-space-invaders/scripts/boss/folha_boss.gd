# Folha navalha do boss: desce girando; fere o player ou danifica o bloco que acertar.
# Fica FORA do grupo "misseis": passar do chão não custa vida.
extends Projetil

# Quadros por segundo do giro (a folha tem 4 quadros, um por direção)
@export var fps_giro := 12.0
## Evento do sons_boss.tres ao bater num bloco (vazio = sem som); o valor fica na cena
@export var som_acerto := &""
var tempo := 0.0

# A velocidade fica na cena (folha_boss.tscn), para ajustar pelo Inspector
func _init():
	direcao = Vector2.DOWN
	grupos_alvo = ["tanque", "blocos"]

# Bateu num bloco: som da folha; o dano e o sumiço são os do Projetil
func ao_acertar(body):
	if body.is_in_group("blocos") and som_acerto != &"":
		Sons.tocar(som_acerto)
	super(body)

# Anda (Projetil) e troca o quadro do giro
func _process(delta):
	super(delta)
	tempo += delta
	$Sprite2D.frame = int(tempo * fps_giro) % $Sprite2D.hframes
