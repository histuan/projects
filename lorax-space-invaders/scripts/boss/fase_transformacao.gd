# Transformação do boss (entre a fase 2 e a fase 3): começa onde a fase 2 o deixou, invulnerável e
# sem vida. O player trava e a tela fica limpa (pedidos que a BatalhaFinal repassa para a main), e o
# boss toca a derrota com raiva, o despertar, a aura e o pilar (com o pilar alto atrás do corpo e o PICO
# no quadro de evento: o cenário some e a fase da luta passa a 3). Termina parado no último quadro do pilar.
extends FaseBoss

# Fade (s) do tremor contínuo se a transformação parar no meio (valor de teste)
const TREMOR_CORTE_PARADA = 0.15
# Nome do pedido de abaixar a música (Musica.pedir_abaixar / liberar_abaixar)
const PEDIDO_MUSICA = &"transformacao"
# Nome do pedido de abafar a música (low-pass); só é liberado na arena (F3b)
const PEDIDO_ABAFAR = &"transformacao_despertar"

@export var dados: TransformacaoDados

# parar() já rodou: nada da transformação continua
var parada := false

# Veste o corpo com a cutscene, trava o player, limpa a tela e toca a derrota com raiva com o
# momento dela, que dura a animação inteira
func comecar(contexto: ContextoBatalha):
	ctx = contexto
	var corpo = ctx.corpo
	corpo.ficar_invulneravel(true)
	corpo.carregar_animacoes(dados.animacoes.animacoes)
	corpo.evento_animacao.connect(_on_evento_animacao)
	corpo.pulso_animacao.connect(_on_pulso_animacao)
	corpo.animacao_terminou.connect(_on_animacao_terminou)
	Momentos.pedido.connect(_on_pedido)
	entrou.emit()
	travar_player.emit(true)
	limpar_tela.emit()
	Musica.pedir_abaixar(PEDIDO_MUSICA, dados.musica_abaixar_db, dados.musica_abaixar_tempo)
	corpo.tocar("derrota_raiva")
	Momentos.tocar(dados.momento_raiva, corpo, dados.animacoes.dados("derrota_raiva").duracao())

# Cheat: o boss aparece onde a fase 2 o deixa, com os corações dela vazios, e a transformação começa
func comecar_direto(contexto: ContextoBatalha):
	contexto.corpo.position = dados.posicao_direta
	if dados.coracao_boss != null:
		trocar_coracoes.emit(dados.coracao_boss)
	contexto.corpo.zerar_vida()
	comecar(contexto)

# Quadros marcados: a respiração antes do despertar (derrota com raiva) e o pico do pilar
func _on_evento_animacao(nome):
	if parada:
		return
	if nome == "derrota_raiva":
		Momentos.tocar(dados.momento_raiva_respira, ctx.corpo)
	elif nome == "pilar":
		chegar_ao_pico()

# Batida do símbolo de raiva
func _on_pulso_animacao(nome):
	if parada:
		return
	if nome == "derrota_raiva":
		Momentos.tocar(dados.momento_raiva_pulso, ctx.corpo)

# Encadeia as animações: derrota com raiva → despertar → aura → pilar (o pilar fica no último quadro)
func _on_animacao_terminou(nome):
	if parada:
		return
	if nome == "derrota_raiva":
		comecar_despertar()
	elif nome == "despertar":
		comecar_aura()
	elif nome == "aura":
		comecar_pilar()

# Corta a cauda da respiração e toca o despertar com o momento dele
func comecar_despertar():
	Sons.cortar(&"transf_respira", dados.respira_fade, Sons.Curva.LINEAR)
	ctx.corpo.tocar("despertar")
	Momentos.tocar(dados.momento_despertar, ctx.corpo, dados.animacoes.dados("despertar").duracao())

# Toca a aura com o momento dela
func comecar_aura():
	ctx.corpo.tocar("aura")
	Momentos.tocar(dados.momento_aura, ctx.corpo, dados.animacoes.dados("aura").duracao())

# Toca o pilar com o pilar alto atrás do corpo e a subida dele, que dura até o quadro de evento (o pico)
func comecar_pilar():
	var pilar = dados.animacoes.dados("pilar")
	ctx.corpo.tocar("pilar")
	ctx.pilar_alto.carregar_animacoes(dados.pilar_alto.animacoes)
	ctx.pilar_alto.tocar("pilar_alto", ctx.corpo.pes_globais())
	Momentos.tocar(dados.momento_pilar_sobe, ctx.corpo, pilar.instante_do_quadro(pilar.quadro_evento))

# Pico do pilar: a fase da luta passa a ser a do pico e o momento dele dura o que resta do pilar
func chegar_ao_pico():
	var pilar = dados.animacoes.dados("pilar")
	if dados.numero_fase_pico > 0:
		fase_luta_mudou.emit(dados.numero_fase_pico)
	Momentos.tocar(dados.momento_pico, ctx.corpo, pilar.duracao() - pilar.instante_do_quadro(pilar.quadro_evento))

# Sinais dos momentos que só esta fase sabe fazer: abafar a música, fazê-la sumir e tirar o cenário
func _on_pedido(nome, parametros, _alvo):
	if parada:
		return
	if nome == &"bases_somem":
		limpar_cenario.emit()
	elif nome == &"abafar_musica":
		Musica.pedir_abafar(PEDIDO_ABAFAR, parametros["hz"], parametros["duracao"])
	elif nome == &"musica_some":
		Musica.fade_out(parametros["fade"])
		await get_tree().create_timer(parametros["fade"], false, false, true).timeout
		if not parada:
			Musica.liberar_abaixar(PEDIDO_MUSICA)

# A fase da luta vem do .tres
func numero_fase():
	return dados.numero_fase

# Para de ouvir o corpo, tira o tremor contínuo e o pilar alto (o player morreu). Chamar de novo não faz nada
func parar():
	if parada:
		return
	parada = true
	Musica.liberar_abaixar(PEDIDO_MUSICA)
	get_viewport().get_camera_2d().parar_tremor_continuo(TREMOR_CORTE_PARADA)
	ctx.pilar_alto.parar()
	var corpo = ctx.corpo
	corpo.evento_animacao.disconnect(_on_evento_animacao)
	corpo.pulso_animacao.disconnect(_on_pulso_animacao)
	corpo.animacao_terminou.disconnect(_on_animacao_terminou)
	Momentos.pedido.disconnect(_on_pedido)
