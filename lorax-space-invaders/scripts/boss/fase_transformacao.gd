# Transformação do boss (entre a fase 2 e a fase 3): começa onde a fase 2 o deixou, invulnerável e
# sem vida. O player trava e a tela fica limpa (pedidos que a BatalhaFinal repassa para a main), e o
# boss toca a derrota com raiva. Por enquanto termina parado no último quadro dela.
extends FaseBoss

# Fade (s) do tremor contínuo se a transformação parar no meio (valor de teste)
const TREMOR_CORTE_PARADA = 0.15
# Nome do pedido de abaixar a música (Musica.pedir_abaixar / liberar_abaixar)
const PEDIDO_MUSICA = &"transformacao"

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
