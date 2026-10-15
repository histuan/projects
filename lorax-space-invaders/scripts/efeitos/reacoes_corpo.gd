# Reações do corpo do boss pedidas pelos momentos (passo SINAL) e pela fase (inclinar,
# deslocar): mexem só no Sprite2D, nunca na colisão. O Momentos acha este nó no alvo, como
# faz com FlashSprite e Afterimage. Fica como filho do corpo (ou aponte 'sprite' para o Sprite2D).
# PIVÔ NOS PÉS: no _ready o sprite passa a ter offset (0, -pes) e o nó dele desce para a linha
# dos pés (o desenho não muda de lugar); assim escala (squash) e rotação giram em torno do pé.
# Inclinar = girar o sprite (o shader do FlashSprite suaviza a borda dos texels).
class_name ReacoesCorpo
extends Node

## O Sprite2D que reage
@export var sprite: NodePath = ^"../Sprite2D"
## Px do centro do sprite até a linha dos pés (linha 28 do quadro de 32 px = 12)
@export var pes := 12.0

var alvo: Sprite2D
var posicao_base := Vector2.ZERO
# O que cada reação faz agora; aplicar() junta tudo no sprite
var escala := Vector2.ONE
var graus := 0.0
var recuo := 0.0
var lado := 0.0
# Desespero (último coração): px do pulo atual (alterna o lado a cada tique) e os números do passo
var tremor := 0.0
var desespero := {}
var relogio_desespero: Timer
var tween_squash: Tween = null
var tween_recuo: Tween = null
var tween_inclinar: Tween = null
var tween_lado: Tween = null

# Põe o pivô do sprite nos pés (sem mudar o desenho de lugar) e guarda onde ele fica parado
func _ready():
	alvo = get_node(sprite)
	alvo.offset += Vector2(0, -pes)
	alvo.position += Vector2(0, pes)
	posicao_base = alvo.position
	# Pausável (Pause e hit-stop param o tique, como o resto do corpo)
	relogio_desespero = Timer.new()
	relogio_desespero.timeout.connect(tique_desespero)
	add_child(relogio_desespero)

# Faz a reação 'nome' com os números do passo; os outros nomes são de outros ouvintes (hud...)
func reagir(nome, parametros):
	match nome:
		&"squash":
			squash(parametros.get("escala", Vector2.ONE), parametros.get("duracao", 0.0))
		&"recuo":
			recuar(parametros.get("px", 0.0), parametros.get("tempos", Vector2.ZERO))
		&"desespero_corpo":
			comecar_desespero(parametros)

# Achata na hora e volta a (1, 1) em 'duracao' s com um repique, presos pelos pés
func squash(nova_escala, duracao):
	if duracao <= 0:
		push_error("ReacoesCorpo: squash sem duracao")
		return
	if tween_squash != null:
		tween_squash.kill()
	tween_squash = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_squash.tween_method(definir_escala, nova_escala, Vector2.ONE, duracao)

# Sobe 'px' em tempos.x segundos e volta em tempos.y
func recuar(px, tempos):
	if px <= 0 or tempos.x <= 0 or tempos.y <= 0:
		push_error("ReacoesCorpo: recuo sem px ou tempos")
		return
	if tween_recuo != null:
		tween_recuo.kill()
	tween_recuo = create_tween()
	tween_recuo.tween_method(definir_recuo, 0.0, -px, tempos.x)
	tween_recuo.tween_method(definir_recuo, -px, 0.0, tempos.y)

# Último coração: a cada 'periodo' s o sprite pula 'px' (alternando o lado) e pisca 'cor' em 'alfa'
# por 'duracao_flash' s. Fica ligado até parar_desespero() ou parar()
func comecar_desespero(parametros):
	var periodo = parametros.get("periodo", 0.0)
	if periodo <= 0 or parametros.get("px", 0.0) <= 0:
		push_error("ReacoesCorpo: desespero_corpo sem periodo ou px")
		return
	desespero = parametros
	relogio_desespero.start(periodo)

# Um tique do desespero: pula para o outro lado e pisca (pulado se o flash já está em uso,
# para não cortar o brilho da carga nem o flash do hit)
func tique_desespero():
	tremor = desespero.px if tremor <= 0 else -desespero.px
	aplicar()
	var flash = flash_do_sprite()
	if flash != null and not flash.ocupado():
		flash.flash(desespero.get("cor", Color.RED), desespero.get("alfa", 0.0), desespero.get("duracao_flash", 0.0))

# Desliga o desespero (o sprite volta para o meio); as outras reações continuam
func parar_desespero():
	if relogio_desespero != null:
		relogio_desespero.stop()
	desespero = {}
	tremor = 0.0
	if alvo != null:
		aplicar()

# Está tremendo de desespero agora
func em_desespero():
	return relogio_desespero != null and not relogio_desespero.is_stopped()

# Gira até 'novos_graus' (negativo = esquerda; 0 = de pé) em 'tempo' s, em torno dos pés; com
# o sprite girado o shader suaviza a borda dos texels
func inclinar(novos_graus, tempo):
	if tween_inclinar != null:
		tween_inclinar.kill()
	tween_inclinar = create_tween()
	tween_inclinar.tween_method(definir_graus, graus, novos_graus, maxf(tempo, 0.001))

# Põe a rotação em 'novos_graus' na hora (o vai e vem progressivo chama a cada quadro); só
# mexe no sprite quando o ângulo muda
func definir_inclinacao(novos_graus):
	if tween_inclinar != null:
		tween_inclinar.kill()
		tween_inclinar = null
	if novos_graus != graus:
		definir_graus(novos_graus)

# Alternativa à inclinação: desloca 'px' para o lado em 'tempo' s (0 = no lugar)
func deslocar(px, tempo):
	if tween_lado != null:
		tween_lado.kill()
	tween_lado = create_tween()
	tween_lado.tween_method(definir_lado, lado, px, maxf(tempo, 0.001))

# Escala do squash (o tween chama a cada quadro)
func definir_escala(valor):
	escala = valor
	aplicar()

# Px do recuo (negativo = para cima)
func definir_recuo(valor):
	recuo = valor
	aplicar()

# Graus da rotação; a borda suavizada liga só com o sprite girado (de pé fica o nearest de sempre)
func definir_graus(valor):
	graus = valor
	aplicar()
	var flash = flash_do_sprite()
	if flash != null:
		flash.definir_suavizar(graus != 0.0)

# O FlashSprite filho do sprite (dono do material), ou null
func flash_do_sprite():
	for filho in alvo.get_children():
		if filho is FlashSprite:
			return filho
	return null

# Px do deslocamento para o lado
func definir_lado(valor):
	lado = valor
	aplicar()

# Escala, rotação e posição do sprite (o pivô já está nos pés); recuo, lado e tremor somam em px inteiros
func aplicar():
	alvo.scale = escala
	alvo.rotation = deg_to_rad(graus)
	alvo.position = posicao_base + Vector2(lado + tremor, recuo).round()

# Corta qualquer reação e devolve o sprite ao normal
func parar():
	for tween in [tween_squash, tween_recuo, tween_inclinar, tween_lado]:
		if tween != null:
			tween.kill()
	parar_desespero()
	escala = Vector2.ONE
	graus = 0.0
	recuo = 0.0
	lado = 0.0
	if alvo != null:
		aplicar()
	var flash = flash_do_sprite() if alvo != null else null
	if flash != null:
		flash.definir_suavizar(false)
