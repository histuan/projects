# Dados de uma fase clássica do boss (vai e vem + ataque em leque).
# Mesma fase_classica.gd, um .tres por fase.
class_name FaseClassicaDados
extends Resource

# O que a inclinação faz da metade do trajeto até a outra borda
enum DepoisDoMeio { MANTER, SINO }
# Como a fase começa: descendo do alto, ou se transformando onde a fase anterior parou
enum Entrada { DESCIDA, TRANSICAO }

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
## Graus que ele gira para o lado do movimento no vai e vem, em torno dos pés, com a borda dos
## texels suavizada (0 = não gira)
@export var inclinacao_graus := 0.0
## Segundos para chegar à inclinação e para voltar
@export var inclinacao_tempo := 0.0
## A inclinação cresce de 0 (na borda) a inclinacao_graus (no meio do trajeto); depois
## do meio MANTER segura o máximo e SINO volta a 0 até a outra borda
@export var inclinacao_depois_do_meio := DepoisDoMeio.MANTER
## O ângulo anda em passos deste tamanho (0 = contínuo)
@export var inclinacao_passo_graus := 0.0

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
## Px entre dois projéteis vizinhos no nascimento, de lado em relação à mira (0 = todos no mesmo ponto)
@export var espaco_leque := 0.0
## De onde o projétil sai, em relação ao centro do boss
@export var origem_tiro := Vector2(0, 12)
@export var para_ao_atacar := true
## O meio do leque aponta para o player no quadro de evento, limitado a ±este ângulo (0 = reto para baixo)
@export var mira_max_graus := 0.0

@export_group("Animações")
## Precisa ter "parado", "dano" e "ataque" (o ataque com quadro_evento)
@export var animacoes: Array[AnimacaoDados] = []

@export_group("Entrada")
## DESCIDA: desce do alto, pousa e fala. TRANSICAO: toca a animação "entrada" (precisa de
## quadro_evento = o pico) onde a fase anterior parou
@export var entrada := Entrada.DESCIDA
## Fala (falas_boss.tres) depois do pouso; ele só ataca quando ela fecha (vazio = sem fala)
@export var fala_entrada := &""
## Textura dos corações CHEIOS do boss nesta fase (vazio = a da hud)
@export var coracao_boss: Texture2D

@export_group("Momentos")
## Momentos do momentos_boss.tres tocados no corpo (vazio = nada nesse ponto)
## No começo da descida
@export var momento_descida := &""
## No começo da transição (entrada TRANSICAO), até o quadro de evento da "entrada"; o 'seguinte'
## dele é o pico, tocado nesse quadro
@export var momento_transicao := &""
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
## Quando a vida acaba (o último hit da fase)
@export var momento_derrota := &""
## Quando sobra o último coração (o coração da hud bate)
@export var momento_ultimo_coracao := &""

@export_group("Desespero")
## No último coração ele toca "desespero_entrada" com este momento até o quadro de evento; o
## 'seguinte' dele é o pico, tocado nesse quadro (vazio = sem desespero)
@export var momento_desespero := &""
## Quando a fase para com o desespero já ligado (desliga o que o pico deixou ligado)
@export var momento_desespero_fim := &""
## Animações que, no desespero, substituem as de mesmo nome de 'animacoes' (ex.: só o "parado")
@export var animacoes_desespero: Array[AnimacaoDados] = []
## Segundos parado (já com as animações novas) antes de voltar a lutar (-1 = nada)
@export var desespero_espera := -1.0
## Velocidade da andada errática (-1 = a 'velocidade' normal)
@export var desespero_velocidade := -1.0
## Px mínimos entre ele e cada ponto sorteado da andada errática (-1 = nenhum)
@export var desespero_distancia_min := -1.0
## Intervalo entre ataques no começo do desespero (-1 = os intervalos normais)
@export var desespero_intervalo_ataque := -1.0
## O mesmo intervalo quando resta 1 de vida (no meio, proporcional)
@export var desespero_intervalo_minimo := -1.0
## Projéteis de cada leque no desespero, alternando (vazio = as 'quantidades' normais)
@export var desespero_quantidades: Array[int] = []

# Rotação (radianos) do leque que sai de 'origem' com o meio apontado para 'alvo' (null = reto para
# baixo), limitada a ±mira_max_graus
func angulo_da_mira(origem: Vector2, alvo):
	if alvo == null or mira_max_graus <= 0:
		return 0.0
	var limite = deg_to_rad(mira_max_graus)
	return clampf(Vector2.DOWN.angle_to(alvo - origem), -limite, limite)

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

# O que falta (ou se repete) nas animações que a fase_classica toca; vazio = tudo certo
func problemas_animacoes():
	var precisa = ["parado", "dano", "ataque"]
	if entrada == Entrada.TRANSICAO:
		precisa.append("entrada")
	if momento_desespero != &"":
		precisa.append("desespero_entrada")
	var problemas = []
	var vistos = []
	for dados in animacoes:
		var nome = dados.nome if dados != null else ""
		if nome in vistos:
			problemas.append("%s: animação '%s' repetida" % [resource_path, nome])
		vistos.append(nome)
	for nome in precisa:
		if not nome in vistos:
			problemas.append("%s: falta a animação '%s'" % [resource_path, nome])
	for nome in ["entrada", "desespero_entrada"]:
		if nome in precisa and nome in vistos and animacao(nome).quadro_evento < 0:
			problemas.append("%s: a animação '%s' precisa de quadro_evento" % [resource_path, nome])
	for dados in animacoes_desespero:
		var nome = dados.nome if dados != null else ""
		if not nome in vistos:
			problemas.append("%s: '%s' de animacoes_desespero não substitui nenhuma animação" % [resource_path, nome])
	return problemas

# As animações do desespero: 'animacoes' com as de 'animacoes_desespero' no lugar das de mesmo nome
func animacoes_no_desespero():
	var lista = []
	for dados in animacoes:
		var nova = dados
		for troca in animacoes_desespero:
			if troca != null and troca.nome == dados.nome:
				nova = troca
		lista.append(nova)
	return lista
