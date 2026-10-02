# Projétil genérico: anda em linha reta na 'direcao' (girada pela rotação do nó),
# acerta o primeiro corpo dos grupos_alvo chamando receber_dano() e some.
# Cada projétil faz "extends Projetil" e só muda os valores no _init (ou no Inspector).
# Os que explodem ou agem em área sobrescrevem ao_acertar() e/ou ao_sair_da_tela().
class_name Projetil
extends Area2D

@export var velocidade := 200.0
## Direção com rotação 0; girar o nó (ex.: leque de tiros) gira a direção junto
@export var direcao := Vector2.UP
@export var dano := 1
## Repassada ao alvo em receber_dano (o alien usa "moto" para trocar o som de morte)
@export var fonte := "tiro"
@export var grupos_alvo: Array[String] = ["aliens"]
## Quantos px além da borda da tela ele ainda anda antes de ao_sair_da_tela()
@export var margem_tela := 10.0

const LARGURA_TELA = 254
const ALTURA_TELA = 256

# 'acertou' trava tudo depois do primeiro acerto (dois alvos no mesmo frame, saída da tela)
var acertou := false

# Cria 'quantidade' projéteis da 'cena' saindo de 'origem', filhos de 'pai'.
# Com mais de um, abrem em leque: 'angulo' graus entre dois vizinhos
static func criar_leque(cena: PackedScene, quantidade: int, angulo: float, origem: Vector2, pai: Node):
	for i in range(quantidade):
		var p = cena.instantiate()
		p.global_position = origem
		p.rotation = deg_to_rad((i - (quantidade - 1) / 2.0) * angulo)
		pai.add_child(p)

# Anda e, se saiu da tela sem acertar nada, avisa ao_sair_da_tela()
func _process(delta):
	position += direcao.rotated(rotation) * velocidade * delta
	if not acertou and fora_da_tela():
		ao_sair_da_tela()

func fora_da_tela():
	var p = global_position
	return p.x < -margem_tela or p.x > LARGURA_TELA + margem_tela \
		or p.y < -margem_tela or p.y > ALTURA_TELA + margem_tela

# Ligado ao body_entered na cena de cada projétil
func _on_body_entered(body):
	if acertou:
		return
	if eh_alvo(body):
		acertou = true
		ao_acertar(body)

# O corpo está em algum dos grupos_alvo?
func eh_alvo(body):
	for grupo in grupos_alvo:
		if body.is_in_group(grupo):
			return true
	return false

# Padrão: fere só quem foi atingido e some
func ao_acertar(body):
	body.receber_dano(dano, fonte)
	queue_free()

# Padrão: some sem fazer nada
func ao_sair_da_tela():
	queue_free()
