# Fase clássica do boss: desce até a altura, vai e vem e, de tempos em tempos, para e
# solta um leque de projéteis. Tudo que muda de uma fase para outra está em 'dados'.
extends FaseBoss

@export var dados: FaseClassicaDados

var direcao := 1
var andando := false
var atacando := false

# O relógio do ataque é da própria fase
func _ready():
	$TimerAtaque.timeout.connect(atacar)

# Entrada: invulnerável enquanto chega até a altura; depois começa a luta
func comecar(contexto: ContextoBatalha):
	preparar(contexto)
	var corpo = ctx.corpo
	corpo.ficar_invulneravel(true)
	var tempo = abs(dados.altura - corpo.position.y) / dados.vel_entrada
	var tween = create_tween()
	tween.tween_property(corpo, "position:y", dados.altura, tempo)
	tween.tween_callback(lutar)

# Sem entrada: já aparece no meio, na altura da fase
func comecar_direto(contexto: ContextoBatalha):
	preparar(contexto)
	ctx.corpo.position = Vector2((dados.limite_esq + dados.limite_dir) / 2.0, dados.altura)
	lutar()

# Veste o corpo com a vida e as animações desta fase e passa a ouvir os sinais dele
func preparar(contexto: ContextoBatalha):
	ctx = contexto
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

# Vai e vem entre os limites (parado durante o ataque, se a fase pedir)
func _process(delta):
	if not andando or (atacando and dados.para_ao_atacar):
		return
	var corpo = ctx.corpo
	corpo.position.x += direcao * dados.velocidade * delta
	if corpo.position.x <= dados.limite_esq:
		direcao = 1
	elif corpo.position.x >= dados.limite_dir:
		direcao = -1

# Só toca a animação; os projéteis saem no quadro marcado dela (_on_evento_animacao)
func atacar():
	atacando = true
	ctx.corpo.tocar("ataque")

# Quadro marcado do ataque: solta o leque de projéteis
func _on_evento_animacao(nome):
	if nome == "ataque":
		Projetil.criar_leque(dados.projetil, dados.quantidade, dados.angulo_leque,
				ctx.corpo.global_position + dados.origem_tiro, ctx.ataques)

# Fim do ataque: agenda o próximo. Fim do ataque ou do dano: volta a ficar parado
func _on_animacao_terminou(nome):
	if nome == "ataque":
		atacando = false
		$TimerAtaque.start(intervalo_atual())
	ctx.corpo.tocar("parado")

# A animação de dano não interrompe um ataque em andamento (a piscada acontece sempre)
func _on_ferido():
	if not atacando:
		ctx.corpo.tocar("dano")

# Vida no zero: a fase para e avisa a BatalhaFinal
func _on_vida_acabou():
	parar()
	terminou.emit()

# Para relógio e movimento, deixa o corpo parado e deixa de ouvir os sinais dele
func parar():
	andando = false
	atacando = false
	$TimerAtaque.stop()
	var corpo = ctx.corpo
	corpo.tocar("parado")
	corpo.ferido.disconnect(_on_ferido)
	corpo.vida_acabou.disconnect(_on_vida_acabou)
	corpo.evento_animacao.disconnect(_on_evento_animacao)
	corpo.animacao_terminou.disconnect(_on_animacao_terminou)
