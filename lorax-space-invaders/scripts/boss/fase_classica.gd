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

@export var dados: FaseClassicaDados

var direcao := 1
var andando := false
var atacando := false
# Leques já soltos (escolhe a vez em 'quantidades')
var ataques_feitos := 0
# Lado para onde o corpo está inclinado agora (-1, 0, 1)
var postura := 0

# O relógio do ataque é da própria fase
func _ready():
	$TimerAtaque.timeout.connect(atacar)

# Entrada: invulnerável enquanto desce tremendo (o tremor some pouco antes do pouso);
# depois pousa, fala e só então luta
func comecar(contexto: ContextoBatalha):
	preparar(contexto)
	var corpo = ctx.corpo
	corpo.ficar_invulneravel(true)
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
	tocar_momento(dados.momento_pouso)
	entrou.emit()
	if dados.fala_entrada == &"":
		apresentar()
		return
	ctx.dialogo.terminou.connect(_on_fala_entrada_terminou, CONNECT_ONE_SHOT)
	ctx.dialogo.falar(dados.fala_entrada)

# A caixa fechou: segue a entrada
func _on_fala_entrada_terminou(_nome):
	apresentar()

# Nome do boss e estrelas da fase; a luta começa junto
func apresentar():
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
	ctx.corpo.position = Vector2((dados.limite_esq + dados.limite_dir) / 2.0, dados.altura)
	entrou.emit()
	tocar_momento(dados.momento_estrelas)
	lutar()

# Veste o corpo com a vida e as animações desta fase, pede os corações da fase e passa a
# ouvir os sinais dele
func preparar(contexto: ContextoBatalha):
	ctx = contexto
	if dados.coracao_boss != null:
		trocar_coracoes.emit(dados.coracao_boss)
	var corpo = ctx.corpo
	corpo.carregar_animacoes(dados.animacoes)
	corpo.definir_vida(dados.vida)
	corpo.tocar("parado")
	corpo.ferido.connect(_on_ferido)
	corpo.vida_acabou.connect(_on_vida_acabou)
	corpo.evento_animacao.connect(_on_evento_animacao)
	corpo.animacao_terminou.connect(_on_animacao_terminou)

# Começa o vai e vem e a contagem do primeiro ataque
func lutar():
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
	var parado = not andando or (atacando and dados.para_ao_atacar)
	atualizar_postura(0 if parado else direcao)
	if parado:
		return
	var corpo = ctx.corpo
	corpo.position.x += direcao * dados.velocidade * delta
	if corpo.position.x <= dados.limite_esq:
		direcao = 1
	elif corpo.position.x >= dados.limite_dir:
		direcao = -1

# Inclina (girando ou em fileiras, pelo modo do .tres) e/ou desloca o corpo para 'lado' só
# quando ele muda; com os valores em 0 no .tres, nada acontece
func atualizar_postura(lado):
	if lado == postura:
		return
	postura = lado
	if dados.modo_inclinacao == FaseClassicaDados.ModoInclinacao.ROTACAO_AA and dados.inclinacao_graus != 0:
		ctx.corpo.inclinar(lado * dados.inclinacao_graus, dados.inclinacao_tempo)
	elif dados.modo_inclinacao == FaseClassicaDados.ModoInclinacao.LEAN and dados.inclinacao != 0:
		ctx.corpo.inclinar_lean(lado * dados.inclinacao, dados.inclinacao_tempo)
	if dados.inclinacao_px != 0:
		ctx.corpo.deslocar(lado * dados.inclinacao_px, dados.inclinacao_tempo)

# Toca a animação e a carga (que dura até o quadro de evento); os projéteis saem no quadro
# marcado dela (_on_evento_animacao)
func atacar():
	atacando = true
	if dados.momento_carga != &"":
		Momentos.tocar(dados.momento_carga, ctx.corpo, dados.duracao_carga())
	ctx.corpo.tocar("ataque")

# Quadro marcado do ataque: os sons da carga somem, o disparo toca e sai o leque da vez
func _on_evento_animacao(nome):
	if nome == "ataque":
		cortar_sons_da_carga(dados.duracao_depois_do_disparo())
		tocar_momento(dados.momento_disparo)
		Projetil.criar_leque(dados.projetil, quantidade_do_leque(), dados.angulo_leque,
				ctx.corpo.global_position + dados.origem_tiro, ctx.ataques)
		ataques_feitos += 1

# Os sons (passos SOM) do momento da carga somem com fade de 'fade' s
func cortar_sons_da_carga(fade):
	if not CORTAR_SOM_CARGA or dados.momento_carga == &"":
		return
	for passo in Momentos.momento(dados.momento_carga).passos:
		if passo.tipo == Passo.Tipo.SOM:
			Sons.cortar(passo.nome, fade)

# Projéteis deste leque: a vez em 'quantidades', ou sempre 'quantidade'
func quantidade_do_leque():
	if dados.quantidades.is_empty():
		return dados.quantidade
	return dados.quantidades[ataques_feitos % dados.quantidades.size()]

# Fim do ataque: agenda o próximo. Fim do ataque ou do dano: volta a ficar parado
func _on_animacao_terminou(nome):
	if nome == "ataque":
		atacando = false
		$TimerAtaque.start(intervalo_atual())
	ctx.corpo.tocar("parado")

# Momento do hit sempre; a animação de dano não interrompe um ataque em andamento
# (a piscada acontece sempre)
func _on_ferido():
	tocar_momento(dados.momento_hit)
	if not atacando:
		ctx.corpo.tocar("dano")

# Vida no zero: a fase para e avisa a BatalhaFinal
func _on_vida_acabou():
	parar()
	terminou.emit()

# Para relógio e movimento (no meio de um ataque, os sons da carga somem rápido), deixa o
# corpo parado e deixa de ouvir os sinais dele
func parar():
	if atacando:
		cortar_sons_da_carga(CARGA_CORTE_PARADA)
	andando = false
	atacando = false
	$TimerAtaque.stop()
	var corpo = ctx.corpo
	corpo.tocar("parado")
	corpo.ferido.disconnect(_on_ferido)
	corpo.vida_acabou.disconnect(_on_vida_acabou)
	corpo.evento_animacao.disconnect(_on_evento_animacao)
	corpo.animacao_terminou.disconnect(_on_animacao_terminou)
