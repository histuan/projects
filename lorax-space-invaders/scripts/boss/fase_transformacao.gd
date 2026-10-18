# Transformação do boss (entre a fase 2 e a fase 3): começa onde a fase 2 o deixou, invulnerável e
# sem vida. O player trava e a tela fica limpa (pedidos que a BatalhaFinal repassa para a main), e o
# boss toca a derrota com raiva, o despertar e a aura. Termina parado no último quadro da aura.
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

# Quadro marcado da derrota com raiva: a respiração antes do despertar
func _on_evento_animacao(nome):
	if parada:
		return
	if nome == "derrota_raiva":
		Momentos.tocar(dados.momento_raiva_respira, ctx.corpo)

# Batida do símbolo de raiva
func _on_pulso_animacao(nome):
	if parada:
		return
	if nome == "derrota_raiva":
		Momentos.tocar(dados.momento_raiva_pulso, ctx.corpo)

# Encadeia as animações: derrota com raiva → despertar → aura (a aura fica no último quadro)
func _on_animacao_terminou(nome):
	if parada:
		return
	if nome == "derrota_raiva":
		comecar_despertar()
	elif nome == "despertar":
		comecar_aura()

# Corta a cauda da respiração e toca o despertar com o momento dele
func comecar_despertar():
	Sons.cortar(&"transf_respira", dados.respira_fade, Sons.Curva.LINEAR)
	ctx.corpo.tocar("despertar")
	Momentos.tocar(dados.momento_despertar, ctx.corpo, dados.animacoes.dados("despertar").duracao())

# Toca a aura com o momento dela
func comecar_aura():
	ctx.corpo.tocar("aura")
	Momentos.tocar(dados.momento_aura, ctx.corpo, dados.animacoes.dados("aura").duracao())

# Sinais dos momentos que só esta fase sabe fazer: abafar a música e fazê-la sumir
func _on_pedido(nome, parametros, _alvo):
	if parada:
		return
	if nome == &"abafar_musica":
		Musica.pedir_abafar(PEDIDO_ABAFAR, parametros["hz"], parametros["duracao"])
	elif nome == &"musica_some":
		Musica.fade_out(parametros["fade"])
		await get_tree().create_timer(parametros["fade"], false, false, true).timeout
		if not parada:
			Musica.liberar_abaixar(PEDIDO_MUSICA)

# A fase da luta vem do .tres
func numero_fase():
	return dados.numero_fase

# Para de ouvir o corpo e tira o tremor contínuo (o player morreu). Chamar de novo não faz nada
func parar():
	if parada:
		return
	parada = true
	Musica.liberar_abaixar(PEDIDO_MUSICA)
	get_viewport().get_camera_2d().parar_tremor_continuo(TREMOR_CORTE_PARADA)
	var corpo = ctx.corpo
	corpo.evento_animacao.disconnect(_on_evento_animacao)
	corpo.pulso_animacao.disconnect(_on_pulso_animacao)
	corpo.animacao_terminou.disconnect(_on_animacao_terminou)
	Momentos.pedido.disconnect(_on_pedido)
