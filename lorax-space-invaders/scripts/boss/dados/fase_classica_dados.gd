# Dados de uma fase clássica do boss (vai e vem + ataque em leque).
# Mesma fase_classica.gd, um .tres por fase.
class_name FaseClassicaDados
extends Resource

enum ModoInclinacao { ROTACAO_AA, LEAN }

@export_group("Vida")
## Golpes que o boss aguenta nesta fase (a hud reparte isso nos corações)
@export var vida := 15
## Fase da luta (1, 2 ou 3): decide o retrato AUTO das falas (0 = não informada)
@export var numero_fase := 0

@export_group("Movimento")
@export var velocidade := 50.0
## Altura em que ele fica indo e vindo
@export var altura := 48.0
@export var limite_esq := 37.0
@export var limite_dir := 217.0
## Velocidade com que chega até a altura no começo da fase
@export var vel_entrada := 40.0
## Como ele inclina no vai e vem: girando (com a borda dos texels suavizada) ou em fileiras inteiras
@export var modo_inclinacao := ModoInclinacao.ROTACAO_AA
## ROTACAO_AA: graus que ele gira para o lado do movimento, em torno dos pés (0 = não gira)
@export var inclinacao_graus := 0.0
## LEAN: px que o topo do sprite desloca para o lado do movimento no vai e vem, em fileiras inteiras
## (0 nos pés; 0 = não inclina)
@export var inclinacao := 0.0
## Px que ele se desloca para o lado do movimento, em vez de inclinar (0 = não desloca)
@export var inclinacao_px := 0.0
## Segundos para chegar à inclinação (ou ao deslocamento) e para voltar
@export var inclinacao_tempo := 0.0

@export_group("Ataque")
## Segundos entre o fim de um ataque e o começo do próximo, com a vida cheia
@export var intervalo_ataque := 2.5
## O mesmo intervalo quando resta 1 de vida (entre os dois, diminui proporcionalmente)
@export var intervalo_minimo := 2.5
@export var projetil: PackedScene
@export var quantidade := 1
## Projéteis de cada leque, alternando a cada ataque (ex.: [5, 4]); vazio = sempre 'quantidade'
@export var quantidades: Array[int] = []
## Graus entre dois projéteis vizinhos (só importa com quantidade > 1)
@export var angulo_leque := 0.0
## De onde o projétil sai, em relação ao centro do boss
@export var origem_tiro := Vector2(0, 12)
@export var para_ao_atacar := true

@export_group("Animações")
## Precisa ter "parado", "dano" e "ataque" (o ataque com quadro_evento)
@export var animacoes: Array[AnimacaoDados] = []

@export_group("Entrada")
## Fala (falas_boss.tres) depois do pouso; ele só ataca quando ela fecha (vazio = sem fala)
@export var fala_entrada := &""
## Textura dos corações CHEIOS do boss nesta fase (vazio = a da hud)
@export var coracao_boss: Texture2D

@export_group("Momentos")
## Momentos do momentos_boss.tres tocados no corpo (vazio = nada nesse ponto)
## No começo da descida
@export var momento_descida := &""
## No fim da descida
@export var momento_pouso := &""
## Depois da fala de entrada (nome do boss)
@export var momento_nome := &""
## Quando a luta começa (estrelas da fase)
@export var momento_estrelas := &""
## No começo do ataque, até o quadro de evento (a duração vem da animação "ataque")
@export var momento_carga := &""
## No quadro de evento do ataque, quando os projéteis nascem
@export var momento_disparo := &""
## A cada golpe que tira vida
@export var momento_hit := &""

# Segundos da carga: do começo do "ataque" até o quadro de evento
func duracao_carga():
	var ataque = animacao("ataque")
	return ataque.instante_do_quadro(ataque.quadro_evento)

# Segundos do quadro de evento até o fim do "ataque" (a volta ao parado)
func duracao_depois_do_disparo():
	return animacao("ataque").duracao() - duracao_carga()

# A animação 'nome' da lista (null, com erro, se ela não existe)
func animacao(nome):
	for dados in animacoes:
		if dados.nome == nome:
			return dados
	push_error("FaseClassicaDados: sem a animação '%s'" % nome)
	return null
