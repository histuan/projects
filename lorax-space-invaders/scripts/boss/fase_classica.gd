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
# Debug (tecla J): fade (s) dos sons da descida e do pouso ao pular a entrada (valor de teste)
const PULO_CORTE_SONS = 0.1
# Segundos que o desespero espera o fim do golpe (dano ou ataque) antes de começar mesmo assim
const DESESPERO_TRAVA = 2.0
# Segundos que o zoom da transformação do desespero leva para voltar a 1,0 (fim dos braços ou parar)
const DESESPERO_ZOOM_VOLTA = 0.4

# Desespero (último coração): esperando o fim do golpe, se transformando, parado com as animações
# novas, lutando
enum Desespero { NENHUM, PENDENTE, TRANSFORMANDO, ESPERANDO, ATIVO }

@export var dados: FaseClassicaDados

var direcao := 1
var andando := false
var atacando := false
# Do começo do ataque até o quadro de evento (a carga, com o tremor contínuo dela, se tiver)
var carregando := false
# Leques já soltos (escolhe a vez em 'quantidades')
var ataques_feitos := 0
# Inclinação progressiva do vai e vem (com inclinacao_graus); null = sem
var inclinacao_vv: InclinacaoVaiEVem = null
# parar() já rodou (a fase acabou ou o player morreu): nada da entrada nem da luta continua
var parada := false
# A animação "entrada" (transição de fase) está tocando
var transformando := false
# Entrada pela descida em andamento (do comecar até o lutar): a tecla J pode pular
var na_intro := false
# A descida chegou ao pouso
var pousou := false
var tween_descida: Tween = null
var tween_tremor: Tween = null
var desespero := Desespero.NENHUM
# O pico do desespero já tocou (o que ele liga precisa do momento_desespero_fim)
var pico_desespero := false
# Vida quando o desespero começou a lutar (o intervalo diminui dela até 1)
var vida_no_desespero := 0
# X sorteado da andada errática e o ângulo real dela (antes do passo)
var alvo_x := 0.0
var graus_erratico := 0.0
var tween_trava: Tween = null
var tween_espera: Tween = null
# Espera do momento da derrota + deslize ao centro; o player morrer no meio (parar) corta e o terminou não sai
var tween_derrota: Tween = null

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
	na_intro = true
	corpo.definir_vida(dados.vida)
	tocar_momento(dados.momento_descida)
	var tempo = abs(dados.altura - corpo.position.y) / dados.vel_entrada
	tween_descida = create_tween()
	tween_descida.tween_property(corpo, "position:y", dados.altura, tempo)
	tween_descida.tween_callback(pousar)
	agendar_fim_do_tremor(tempo)

# O tremor contínuo da descida cai a 0 em POUSO_TC_SOME s e chega a 0 POUSO_TC_ANTES s antes
# do pouso (descida curta: começa já e cai no tempo que sobra)
func agendar_fim_do_tremor(tempo_descida):
	var fim = maxf(tempo_descida - POUSO_TC_ANTES, 0.0)
	var some = minf(POUSO_TC_SOME, fim)
	tween_tremor = create_tween()
	tween_tremor.tween_interval(fim - some)
	tween_tremor.tween_callback(func(): get_viewport().get_camera_2d().parar_tremor_continuo(some, true))

# Fim da descida: o pouso (tremor, poeira, squash, som) e a fala de entrada; sem fala, a
# apresentação vem na hora
func pousar():
	if parada:
		return
	pousou = true
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
	for problema in dados.problemas_animacoes():
		push_error("FaseClassica: " + problema)
	var corpo = ctx.corpo
	corpo.carregar_animacoes(dados.animacoes)
	corpo.tocar("parado")
	corpo.ferido.connect(_on_ferido)
	corpo.vida_acabou.connect(_on_vida_acabou)
	corpo.evento_animacao.connect(_on_evento_animacao)
	corpo.animacao_terminou.connect(_on_animacao_terminou)

# Debug (tecla J): da descida, do pouso ou da fala, o boss já fica na altura e luta, sem o nome.
# Matar a descida cancela o pouso (só ela chama pousar); a fala fecha sem 'terminou', com a voz
# cortada; os sons da entrada somem e a câmera volta ao normal
func pular_intro():
	if not na_intro or parada:
		return
	for tween in [tween_descida, tween_tremor]:
		if tween != null:
			tween.kill()
	ctx.corpo.position.y = dados.altura
	if ctx.dialogo != null:
		if ctx.dialogo.terminou.is_connected(_on_fala_entrada_terminou):
			ctx.dialogo.terminou.disconnect(_on_fala_entrada_terminou)
		if ctx.dialogo.aberta:
			ctx.dialogo.fechar()
	cortar_sons(dados.momento_descida, PULO_CORTE_SONS)
	cortar_sons(dados.momento_pouso, PULO_CORTE_SONS)
	get_viewport().get_camera_2d().restaurar()
	if not pousou:
		entrou.emit()
	tocar_momento(dados.momento_estrelas)
	lutar()

# Sobrou o último coração: o coração da hud bate e, se a fase tem desespero, ele fica pendente:
# invulnerável e parado até o fim do golpe que está tocando (dano ou ataque), ou até a trava.
# O golpe que trouxe o último coração já passou da checagem de invulnerável: o ferido dele chega
func ultimo_coracao():
	tocar_momento(dados.momento_ultimo_coracao)
	if parada or dados.momento_desespero == &"" or desespero != Desespero.NENHUM:
		return
	desespero = Desespero.PENDENTE
	ctx.corpo.ficar_invulneravel(true)
	andando = false
	$TimerAtaque.stop()
	tween_trava = create_tween()
	tween_trava.tween_interval(DESESPERO_TRAVA)
	tween_trava.tween_callback(_on_trava_desespero)

# O fim do golpe não chegou: o desespero começa mesmo assim (no uso normal nunca acontece)
func _on_trava_desespero():
	if desespero != Desespero.PENDENTE:
		return
	push_warning("FaseClassica: o fim do dano/ataque não chegou em %s s; o desespero começou pela trava" % DESESPERO_TRAVA)
	comecar_desespero()

# Endireita e toca a "desespero_entrada" com o momento do desespero, que dura até o quadro de evento
# (o pico, em _on_evento_animacao). Um ataque cortado pela trava perde os sons e o tremor da carga
func comecar_desespero():
	if tween_trava != null:
		tween_trava.kill()
	if atacando:
		cortar_sons_da_carga(CARGA_CORTE_PARADA)
	if carregando:
		parar_tremor_da_carga(CARGA_CORTE_PARADA)
	atacando = false
	carregando = false
	inclinacao_vv = null
	desespero = Desespero.TRANSFORMANDO
	transformando = true
	var corpo = ctx.corpo
	corpo.inclinar(0, dados.inclinacao_tempo)
	corpo.tocar("desespero_entrada")
	var entrada = dados.animacao("desespero_entrada")
	Momentos.tocar(dados.momento_desespero, corpo, entrada.instante_do_quadro(entrada.quadro_evento))

# Pico do desespero: os sons da transformação somem e o pico toca (sem encher a vida)
func chegar_ao_pico_desespero():
	cortar_sons(dados.momento_desespero, TRANSICAO_CORTE_PICO)
	tocar_momento(Momentos.momento(dados.momento_desespero).seguinte)
	pico_desespero = true

# Fim da transformação: as animações do desespero entram e ele fica parado 'desespero_espera' s.
# Chamada adiada: a biblioteca de animações não é trocada dentro do animation_finished
func respirar_desesperado():
	if parada:
		return
	transformando = false
	desespero = Desespero.ESPERANDO
	var corpo = ctx.corpo
	corpo.carregar_animacoes(dados.animacoes_no_desespero())
	corpo.tocar("parado")
	tween_espera = create_tween()
	tween_espera.tween_interval(maxf(dados.desespero_espera, 0.0))
	tween_espera.tween_callback(lutar_desesperado)

# Volta a lutar no desespero: vulnerável, andada errática e leques do desespero (o primeiro da lista)
func lutar_desesperado():
	if parada:
		return
	desespero = Desespero.ATIVO
	var corpo = ctx.corpo
	vida_no_desespero = corpo.vidas
	ataques_feitos = 0
	graus_erratico = 0.0
	alvo_x = sortear_alvo()
	corpo.ficar_invulneravel(false)
	andando = true
	$TimerAtaque.start(intervalo_atual())

# Um X entre os limites a pelo menos desespero_distancia_min do X atual (10 tentativas; senão, o último)
func sortear_alvo():
	var x = ctx.corpo.position.x
	var alvo = x
	for _tentativa in range(10):
		alvo = randf_range(dados.limite_esq, dados.limite_dir)
		if absf(alvo - x) >= dados.desespero_distancia_min:
			break
	return alvo

# Andada errática: vai até o X sorteado e, ao chegar, sorteia outro; parado durante o ataque, se a
# fase pedir
func mover_erratico(delta):
	var corpo = ctx.corpo
	var parado = not andando or (atacando and dados.para_ao_atacar)
	inclinar_erratico(0.0 if parado else signf(alvo_x - corpo.position.x), delta)
	if parado:
		return
	var velocidade = dados.desespero_velocidade if dados.desespero_velocidade >= 0 else dados.velocidade
	corpo.position.x = move_toward(corpo.position.x, alvo_x, velocidade * delta)
	if is_equal_approx(corpo.position.x, alvo_x):
		alvo_x = sortear_alvo()

# Inclinação fixa para o lado da andada (0 = parado): segue o alvo a no máximo graus ÷
# inclinacao_tempo por s e sai em passos de inclinacao_passo_graus
func inclinar_erratico(lado, delta):
	var maximo = dados.inclinacao_graus
	var velocidade = maximo / dados.inclinacao_tempo if dados.inclinacao_tempo > 0 else INF
	graus_erratico = move_toward(graus_erratico, lado * maximo, velocidade * delta)
	var graus = graus_erratico
	if dados.inclinacao_passo_graus > 0:
		graus = roundf(graus / dados.inclinacao_passo_graus) * dados.inclinacao_passo_graus
	ctx.corpo.definir_inclinacao(graus)

# Começa o vai e vem e a contagem do primeiro ataque
func lutar():
	if parada:
		return
	na_intro = false
	ctx.corpo.ficar_invulneravel(false)
	andando = true
	$TimerAtaque.start(intervalo_atual())

# Vida cheia = intervalo_ataque; vida 1 = intervalo_minimo; no meio, proporcional. No desespero, os
# intervalos dele, da vida em que ele começou até 1
func intervalo_atual():
	var corpo = ctx.corpo
	if desespero == Desespero.ATIVO and dados.desespero_intervalo_ataque >= 0:
		var maximo = dados.desespero_intervalo_ataque
		var minimo = dados.desespero_intervalo_minimo if dados.desespero_intervalo_minimo >= 0 else maximo
		if vida_no_desespero <= 1:
			return minimo
		var parte = (corpo.vidas - 1) / float(vida_no_desespero - 1)
		return lerp(minimo, maximo, clampf(parte, 0.0, 1.0))
	if corpo.vida_max <= 1:
		return dados.intervalo_minimo
	var fracao = (corpo.vidas - 1) / float(corpo.vida_max - 1)
	return lerp(dados.intervalo_minimo, dados.intervalo_ataque, fracao)

# Vai e vem entre os limites (parado durante o ataque, se a fase pedir), inclinado para o
# lado em que anda; no desespero, a andada errática
func _process(delta):
	if parada:
		return
	if desespero == Desespero.ATIVO:
		mover_erratico(delta)
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
	carregando = true
	if dados.momento_carga != &"":
		Momentos.tocar(dados.momento_carga, ctx.corpo, dados.duracao_carga())
	ctx.corpo.tocar("ataque")

# Quadro marcado do ataque: os sons da carga somem, o disparo toca e sai o leque da vez.
# Quadro marcado da "entrada": o pico da transição; da "desespero_entrada": o pico do desespero
func _on_evento_animacao(nome):
	if parada:
		return
	if nome == "entrada":
		chegar_ao_pico()
	elif nome == "desespero_entrada":
		chegar_ao_pico_desespero()
	elif nome == "ataque":
		carregando = false
		cortar_sons_da_carga(dados.duracao_depois_do_disparo())
		tocar_momento(dados.momento_disparo)
		var origem = ctx.corpo.global_position + dados.origem_tiro
		Projetil.criar_leque(dados.projetil, quantidade_do_leque(), dados.angulo_leque,
				origem, ctx.ataques, dados.angulo_da_mira(origem, posicao_do_player()), dados.espaco_leque)
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

# O tremor contínuo da carga some em 'fade' s (só se o momento da carga liga um: não corta o de outro dono)
func parar_tremor_da_carga(fade):
	if dados.momento_carga == &"":
		return
	for passo in Momentos.momento(dados.momento_carga).passos:
		if passo.tipo == Passo.Tipo.TREMER_CONTINUO:
			get_viewport().get_camera_2d().parar_tremor_continuo(fade)
			return

# Os sons (passos SOM) do momento 'nome' somem com fade de 'fade' s, em amplitude linear (em dB
# a queda soa mais curta que o fade); vazio = nada
func cortar_sons(nome: StringName, fade):
	if nome == &"":
		return
	for passo in Momentos.momento(nome).passos:
		if passo.tipo == Passo.Tipo.SOM:
			Sons.cortar(passo.nome, fade, Sons.Curva.LINEAR)

# Projéteis deste leque: a vez em 'quantidades' (no desespero, em 'desespero_quantidades'), ou
# sempre 'quantidade'
func quantidade_do_leque():
	var lista = dados.quantidades
	if desespero == Desespero.ATIVO and not dados.desespero_quantidades.is_empty():
		lista = dados.desespero_quantidades
	if lista.is_empty():
		return dados.quantidade
	return lista[ataques_feitos % lista.size()]

# Fim do ataque: agenda o próximo. Fim da transição: a luta começa. Desespero pendente: o fim do
# dano ou do ataque começa a transformação; o fim dela, a espera. Nos outros: volta a ficar parado
func _on_animacao_terminou(nome):
	if parada:
		return
	if nome == "desespero_entrada":
		get_viewport().get_camera_2d().zoom_para(1.0, DESESPERO_ZOOM_VOLTA)
		respirar_desesperado.call_deferred()
		return
	if desespero == Desespero.PENDENTE and (nome == "dano" or nome == "ataque"):
		atacando = false
		comecar_desespero()
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
# último hit da fase, para e só avisa a BatalhaFinal quando o momento acaba e o deslize ao centro
# (se a fase tem) termina (em tempo real, pausando com o Pause), para a próxima fase não atropelar
# o golpe. Sem momento e sem deslize, avisa na hora
func _on_vida_acabou():
	ctx.corpo.ficar_invulneravel(true)
	tocar_momento(dados.momento_derrota)
	parar()
	var espera = Momentos.duracao(dados.momento_derrota) if dados.momento_derrota != &"" else 0.0
	if espera <= 0 and dados.derrota_deslize <= 0:
		terminou.emit()
		return
	tween_derrota = create_tween().set_ignore_time_scale()
	if espera > 0:
		tween_derrota.tween_interval(espera)
	if dados.derrota_deslize > 0:
		var centro = (dados.limite_esq + dados.limite_dir) / 2.0
		tween_derrota.tween_property(ctx.corpo, "position:x", centro, dados.derrota_deslize) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_derrota.tween_callback(terminou.emit)

# Para relógio e movimento (no meio de um ataque ou de uma transformação, os sons dela somem rápido;
# no meio da carga ou de uma transformação, o tremor contínuo também; com o pico do desespero já
# tocado, o momento_desespero_fim desliga o que ele ligou),
# deixa o corpo parado e de pé (no meio da transição a animação termina sozinha, sem efeito),
# solta a fala de entrada e deixa de ouvir os sinais dele. Chamar de novo não faz nada (boss e
# player podem morrer no mesmo instante)
func parar():
	if parada:
		if tween_derrota != null:
			tween_derrota.kill()
		return
	parada = true
	if atacando:
		cortar_sons_da_carga(CARGA_CORTE_PARADA)
	if carregando:
		parar_tremor_da_carga(CARGA_CORTE_PARADA)
	if transformando:
		var momento = dados.momento_desespero if desespero == Desespero.TRANSFORMANDO else dados.momento_transicao
		cortar_sons(momento, CARGA_CORTE_PARADA)
		get_viewport().get_camera_2d().parar_tremor_continuo(CARGA_CORTE_PARADA)
		if desespero == Desespero.TRANSFORMANDO:
			get_viewport().get_camera_2d().zoom_para(1.0, DESESPERO_ZOOM_VOLTA)
	if pico_desespero:
		tocar_momento(dados.momento_desespero_fim)
		pico_desespero = false
	for tween in [tween_trava, tween_espera]:
		if tween != null:
			tween.kill()
	desespero = Desespero.NENHUM
	inclinacao_vv = null
	andando = false
	atacando = false
	carregando = false
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
