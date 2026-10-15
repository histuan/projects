# Fase clássica do boss: desce até a altura, vai e vem e, de tempos em tempos, para e
# solta um leque de projéteis. Tudo que muda de uma fase para outra está em 'dados'.
extends FaseBoss

# Fim do tremor contínuo da descida: segundos que ele leva para cair a 0 (ease-out) e
# quantos segundos antes do pouso ele chega a 0 (valores de teste)
const POUSO_TC_SOME = 1.0
const POUSO_TC_ANTES = 0.1
# Os sons da carga somem com fade do quadro de evento até o fim do "ataque" (false = tocam até o fim)
const CORTAR_SOM_CARGA = true
# Fade (s) dos sons da carga quando a fase para no meio do ataque (valor de teste)
const CARGA_CORTE_PARADA = 0.15
# Fade (s) dos sons da transição quando ela chega ao pico (valor de teste)
const TRANSICAO_CORTE_PICO = 0.1

@export var dados: FaseClassicaDados

var direcao := 1
var andando := false
var atacando := false
# Leques já soltos (escolhe a vez em 'quantidades')
var ataques_feitos := 0
# Inclinação progressiva do vai e vem (com inclinacao_graus); null = sem
var inclinacao_vv: InclinacaoVaiEVem = null
# parar() já rodou (a fase acabou ou o player morreu): nada da entrada nem da luta continua
var parada := false
# A animação "entrada" (transição de fase) está tocando
var transformando := false

# O relógio do ataque é da própria fase
func _ready():
	$TimerAtaque.timeout.connect(atacar)

# Entrada pela descida: invulnerável enquanto desce tremendo (o tremor some pouco antes do
# pouso); depois pousa, fala e só então luta. Entrada TRANSICAO: entrar_transformando()
func comecar(contexto: ContextoBatalha):
	preparar(contexto)
	var corpo = ctx.corpo
	corpo.ficar_invulneravel(true)
	if dados.entrada == FaseClassicaDados.Entrada.TRANSICAO:
		entrar_transformando()
		return
	corpo.definir_vida(dados.vida)
	tocar_momento(dados.momento_descida)
	var tempo = abs(dados.altura - corpo.position.y) / dados.vel_entrada
	var tween = create_tween()
	tween.tween_property(corpo, "position:y", dados.altura, tempo)
	tween.tween_callback(pousar)
	agendar_fim_do_tremor(tempo)

# O tremor contínuo da descida cai a 0 em POUSO_TC_SOME s e chega a 0 POUSO_TC_ANTES s antes
# do pouso (descida curta: começa já e cai no tempo que sobra)
func agendar_fim_do_tremor(tempo_descida):
	var fim = maxf(tempo_descida - POUSO_TC_ANTES, 0.0)
	var some = minf(POUSO_TC_SOME, fim)
	var tween = create_tween()
	tween.tween_interval(fim - some)
	tween.tween_callback(func(): get_viewport().get_camera_2d().parar_tremor_continuo(some, true))

# Fim da descida: o pouso (tremor, poeira, squash, som) e a fala de entrada; sem fala, a
# apresentação vem na hora
func pousar():
	if parada:
		return
	tocar_momento(dados.momento_pouso)
	entrou.emit()
	if dados.fala_entrada == &"":
		apresentar()
		return
	ctx.dialogo.terminou.connect(_on_fala_entrada_terminou, CONNECT_ONE_SHOT)
	ctx.dialogo.falar(dados.fala_entrada)

# Transição de fase: no lugar em que a fase anterior parou, ainda invulnerável e sem vida, toca a
# "entrada" e o momento da transição, que dura até o quadro de evento (o pico, em _on_evento_animacao)
func entrar_transformando():
	var corpo = ctx.corpo
	transformando = true
	corpo.tocar("entrada")
	var entrada = dados.animacao("entrada")
	if dados.momento_transicao != &"":
		Momentos.tocar(dados.momento_transicao, corpo, entrada.instante_do_quadro(entrada.quadro_evento))

# Pico da transição (quadro de evento da "entrada"): os sons dela somem, o pico toca (os corações
# começam a encher já nele), a vida da fase enche e o boss está em cena. Nessa ordem
func chegar_ao_pico():
	cortar_sons(dados.momento_transicao, TRANSICAO_CORTE_PICO)
	if dados.momento_transicao != &"":
		tocar_momento(Momentos.momento(dados.momento_transicao).seguinte)
	ctx.corpo.definir_vida(dados.vida)
	entrou.emit()

# A caixa fechou: segue a entrada
func _on_fala_entrada_terminou(_nome):
	apresentar()

# Nome do boss e estrelas da fase; a luta começa junto
func apresentar():
	if parada:
		return
	tocar_momento(dados.momento_nome)
	tocar_momento(dados.momento_estrelas)
	lutar()

# Toca um momento do momentos_boss.tres no corpo; vazio = esta fase não tem nada nesse ponto
func tocar_momento(nome: StringName):
	if nome != &"":
		Momentos.tocar(nome, ctx.corpo)

# A fase da luta vem do .tres (fase 1 ou 2)
func numero_fase():
	return dados.numero_fase

# Sem entrada (nem fala, nem nome): já aparece no meio, na altura da fase
func comecar_direto(contexto: ContextoBatalha):
	preparar(contexto)
	ctx.corpo.definir_vida(dados.vida)
	ctx.corpo.position = Vector2((dados.limite_esq + dados.limite_dir) / 2.0, dados.altura)
	entrou.emit()
	tocar_momento(dados.momento_estrelas)
	lutar()

# Veste o corpo com as animações desta fase, pede os corações da fase e passa a ouvir os sinais
# dele (a vida é de quem começa a luta: descida, comecar_direto ou o pico da transição)
func preparar(contexto: ContextoBatalha):
	ctx = contexto
	if dados.inclinacao_graus != 0:
		inclinacao_vv = InclinacaoVaiEVem.new(dados)
	if dados.coracao_boss != null:
		trocar_coracoes.emit(dados.coracao_boss)
	var corpo = ctx.corpo
	corpo.carregar_animacoes(dados.animacoes)
	corpo.tocar("parado")
	corpo.ferido.connect(_on_ferido)
	corpo.vida_acabou.connect(_on_vida_acabou)
	corpo.evento_animacao.connect(_on_evento_animacao)
	corpo.animacao_terminou.connect(_on_animacao_terminou)

# Começa o vai e vem e a contagem do primeiro ataque
func lutar():
	if parada:
		return
	ctx.corpo.ficar_invulneravel(false)
	andando = true
	$TimerAtaque.start(intervalo_atual())

# Vida cheia = intervalo_ataque; vida 1 = intervalo_minimo; no meio, proporcional
func intervalo_atual():
	var corpo = ctx.corpo
	if corpo.vida_max <= 1:
		return dados.intervalo_minimo
	var fracao = (corpo.vidas - 1) / float(corpo.vida_max - 1)
	return lerp(dados.intervalo_minimo, dados.intervalo_ataque, fracao)

# Vai e vem entre os limites (parado durante o ataque, se a fase pedir), inclinado para o
# lado em que anda
func _process(delta):
	if parada:
		return
	var parado = not andando or (atacando and dados.para_ao_atacar)
	if inclinacao_vv != null:
		ctx.corpo.definir_inclinacao(inclinacao_vv.atualizar(ctx.corpo.position.x, 0 if parado else direcao, delta))
	if parado:
		return
	var corpo = ctx.corpo
	corpo.position.x += direcao * dados.velocidade * delta
	if corpo.position.x <= dados.limite_esq:
		direcao = 1
	elif corpo.position.x >= dados.limite_dir:
		direcao = -1

# Toca a animação e a carga (que dura até o quadro de evento); os projéteis saem no quadro
# marcado dela (_on_evento_animacao)
func atacar():
	atacando = true
	if dados.momento_carga != &"":
		Momentos.tocar(dados.momento_carga, ctx.corpo, dados.duracao_carga())
	ctx.corpo.tocar("ataque")

# Quadro marcado do ataque: os sons da carga somem, o disparo toca e sai o leque da vez.
# Quadro marcado da "entrada": o pico da transição
func _on_evento_animacao(nome):
	if parada:
		return
	if nome == "entrada":
		chegar_ao_pico()
	elif nome == "ataque":
		cortar_sons_da_carga(dados.duracao_depois_do_disparo())
		tocar_momento(dados.momento_disparo)
		var origem = ctx.corpo.global_position + dados.origem_tiro
		Projetil.criar_leque(dados.projetil, quantidade_do_leque(), dados.angulo_leque,
				origem, ctx.ataques, dados.angulo_da_mira(origem, posicao_do_player()))
		ataques_feitos += 1

# Onde o player está, para a mira (null sem player vivo na cena: o leque sai reto para baixo)
func posicao_do_player():
	var player = ctx.player
	if not is_instance_valid(player) or not player.is_inside_tree() or not player.vivo:
		return null
	return player.global_position

# Os sons (passos SOM) do momento da carga somem com fade de 'fade' s
func cortar_sons_da_carga(fade):
	if CORTAR_SOM_CARGA:
		cortar_sons(dados.momento_carga, fade)

# Os sons (passos SOM) do momento 'nome' somem com fade de 'fade' s, em amplitude linear (em dB
# a queda soa mais curta que o fade); vazio = nada
func cortar_sons(nome: StringName, fade):
	if nome == &"":
		return
	for passo in Momentos.momento(nome).passos:
		if passo.tipo == Passo.Tipo.SOM:
			Sons.cortar(passo.nome, fade, Sons.Curva.LINEAR)

# Projéteis deste leque: a vez em 'quantidades', ou sempre 'quantidade'
func quantidade_do_leque():
	if dados.quantidades.is_empty():
		return dados.quantidade
	return dados.quantidades[ataques_feitos % dados.quantidades.size()]

# Fim do ataque: agenda o próximo. Fim da transição: a luta começa. Em todos: volta a ficar parado
func _on_animacao_terminou(nome):
	if parada:
		return
	ctx.corpo.tocar("parado")
	if nome == "ataque":
		atacando = false
		$TimerAtaque.start(intervalo_atual())
	elif nome == "entrada":
		transformando = false
		apresentar()

# Momento do hit sempre; a animação de dano não interrompe um ataque em andamento
# (a piscada acontece sempre)
func _on_ferido():
	tocar_momento(dados.momento_hit)
	if not atacando:
		ctx.corpo.tocar("dano")

# Vida no zero (os projéteis já foram limpos pela BatalhaFinal): fica invulnerável, toca o
# último hit da fase, para e só avisa a BatalhaFinal quando o momento acaba (em tempo real,
# pausando com o Pause), para a próxima fase não atropelar o golpe
func _on_vida_acabou():
	ctx.corpo.ficar_invulneravel(true)
	tocar_momento(dados.momento_derrota)
	parar()
	if dados.momento_derrota != &"":
		var espera = Momentos.duracao(dados.momento_derrota)
		if espera > 0:
			await get_tree().create_timer(espera, false, false, true).timeout
	terminou.emit()

# Para relógio e movimento (no meio de um ataque ou da transição, os sons dela somem rápido),
# deixa o corpo parado e de pé (no meio da transição a animação termina sozinha, sem efeito),
# solta a fala de entrada e deixa de ouvir os sinais dele. Chamar de novo não faz nada (boss e
# player podem morrer no mesmo instante)
func parar():
	if parada:
		return
	parada = true
	if atacando:
		cortar_sons_da_carga(CARGA_CORTE_PARADA)
	if transformando:
		cortar_sons(dados.momento_transicao, CARGA_CORTE_PARADA)
	inclinacao_vv = null
	andando = false
	atacando = false
	$TimerAtaque.stop()
	if ctx.dialogo != null and ctx.dialogo.terminou.is_connected(_on_fala_entrada_terminou):
		ctx.dialogo.terminou.disconnect(_on_fala_entrada_terminou)
	var corpo = ctx.corpo
	corpo.inclinar(0, dados.inclinacao_tempo)
	if not transformando:
		corpo.tocar("parado")
	corpo.ferido.disconnect(_on_ferido)
	corpo.vida_acabou.disconnect(_on_vida_acabou)
	corpo.evento_animacao.disconnect(_on_evento_animacao)
	corpo.animacao_terminou.disconnect(_on_animacao_terminou)
