# Sequenciador de efeitos (autoload "Momentos"): toca os MOMENTOS do momentos_boss.tres.
# Cada momento é uma lista de passos com tempo (s reais); a luta e o LAB DE EFEITOS tocam o
# mesmo dado. A main entrega as ferramentas em registrar() (câmera, tela, estrelas, mundo).
# Momento ligado a animação: quem toca é o QUADRO DE EVENTO dela (a fase), nunca um tempo copiado.
# Momento desconhecido ou passo com campo obrigatório zerado = push_error, e o passo não roda.
# Sem alvo, os passos que precisam dele (corpo, posição) não acontecem.
# As esperas pausam junto com o jogo (Pause).
extends Node

const BIBLIOTECA = preload("res://recursos/boss/momentos_boss.tres")
const FALAS = preload("res://recursos/boss/falas_boss.tres")
const FAISCA = preload("res://cenas/efeitos/faisca.tscn")
const POEIRA = preload("res://cenas/efeitos/poeira.tscn")
const FOLHINHAS = preload("res://cenas/efeitos/folhinhas.tscn")
const KI_SUBINDO = preload("res://cenas/efeitos/ki_subindo.tscn")

# O que só a fase sabe fazer (squash, recuo, letreiros...): passo SINAL
signal pedido(nome, parametros, alvo)

var camera
var tela
var estrelas
var mundo
var efeitos: EfeitosDados
var hud
var caixa
# Sobe a cada parar_tudo(): passos agendados deixam de acontecer
var geracao = 0
# Momento tocando → momento (ms) em que o último passo dele termina
var tocando = {}

# A main entrega quem executa os passos (mundo = onde nascem as partículas soltas;
# hud = onde aparecem os letreiros; caixa = a caixa de diálogo)
func registrar(nova_camera, nova_tela, novas_estrelas, novo_mundo, novos_efeitos, nova_hud, nova_caixa):
	camera = nova_camera
	tela = nova_tela
	estrelas = novas_estrelas
	mundo = novo_mundo
	efeitos = novos_efeitos
	hud = nova_hud
	caixa = nova_caixa

# Toca um momento no alvo (Node2D = corpo, Vector2 = posição, null = nenhum).
# duracao_animacao: a duração da animação, para os passos marcados da_animacao
func tocar(nome: StringName, alvo = null, duracao_animacao = 0.0):
	var dados = momento(nome)
	if dados == null:
		return
	if mundo == null:
		push_error("Momentos: '%s' tocado antes de registrar()" % nome)
		return
	tocando[nome] = Time.get_ticks_msec() + duracao_total(dados, duracao_animacao) * 1000.0
	for i in range(dados.passos.size()):
		var passo = dados.passos[i]
		if passo.pendente == "" and passo_valido(nome, i, passo, duracao_animacao):
			agendar(passo, alvo, duracao_animacao)

# O Momento pelo nome (erro se ele não existe)
func momento(nome: StringName):
	var dados = BIBLIOTECA.momentos.get(nome)
	if dados == null:
		push_error("Momentos: momento desconhecido '%s'" % nome)
	return dados

# Os parâmetros do passo SINAL 'sinal' do momento (vazio, com erro, se não houver)
func parametros(nome: StringName, sinal: StringName):
	var dados = momento(nome)
	if dados != null:
		for passo in dados.passos:
			if passo.tipo == Passo.Tipo.SINAL and passo.nome == sinal:
				return passo.parametros
	push_error("Momentos: o momento '%s' não tem o sinal '%s'" % [nome, sinal])
	return {}

# Nomes dos momentos que ainda têm passo para acontecer (painel de debug)
func tocando_agora():
	var agora = Time.get_ticks_msec()
	var nomes = []
	for nome in tocando:
		if tocando[nome] > agora:
			nomes.append(nome)
	return nomes

# Cancela tudo o que estava agendado, apaga os letreiros e fecha a caixa (o R do LAB)
func parar_tudo():
	geracao += 1
	tocando.clear()
	if is_instance_valid(hud):
		hud.limpar_letreiros()
	if is_instance_valid(caixa):
		caixa.fechar()

# Saindo da partida: cancela e esquece as ferramentas da main
func limpar():
	parar_tudo()
	camera = null
	tela = null
	estrelas = null
	mundo = null
	hud = null
	caixa = null

# Confere todos os momentos do arquivo de uma vez (o LAB chama ao abrir); devolve os erros
func validar_todos():
	var erros = 0
	for nome in BIBLIOTECA.momentos:
		var dados = BIBLIOTECA.momentos[nome]
		if dados.seguinte != &"" and not BIBLIOTECA.momentos.has(dados.seguinte):
			push_error("Momentos: '%s' tem seguinte desconhecido '%s'" % [nome, dados.seguinte])
			erros += 1
		for i in range(dados.passos.size()):
			var passo = dados.passos[i]
			if passo.pendente == "" and not passo_valido(nome, i, passo, 1.0):
				erros += 1
	return erros

# Erro (com momento e passo) se falta um campo obrigatório, se o momento citado não existe
# ou se um passo da_animacao veio sem a duração da animação
func passo_valido(nome, indice, passo, duracao_animacao):
	var problema = ""
	var falta = passo.campo_faltando()
	if falta != "":
		problema = "%s = 0" % falta
	elif passo.da_animacao and duracao_animacao <= 0:
		problema = "tocado sem a duração da animação"
	elif passo.tipo == Passo.Tipo.MOMENTO and (passo.nome == nome or not BIBLIOTECA.momentos.has(passo.nome)):
		problema = "momento '%s' inválido" % passo.nome
	elif passo.tipo == Passo.Tipo.LETREIRO and passo.letreiro.momento_por_letra != &"" 			and not BIBLIOTECA.momentos.has(passo.letreiro.momento_por_letra):
		problema = "momento_por_letra '%s' inválido" % passo.letreiro.momento_por_letra
	elif passo.tipo == Passo.Tipo.FALA and not FALAS.falas.has(passo.nome):
		problema = "fala '%s' não existe no falas_boss.tres" % passo.nome
	if problema != "":
		push_error("Momentos: '%s' passo %d (%s): %s" % [nome, indice + 1, Passo.Tipo.keys()[passo.tipo], problema])
		return false
	return true

# Espera o tempo do passo e o executa (com as repetições); para se o R vier no meio
func agendar(passo, alvo, duracao_animacao):
	var minha = geracao
	if passo.tempo > 0:
		if not await esperar(passo.tempo, minha):
			return
	var vezes = maxi(passo.repetir, 1)
	for i in range(vezes):
		executar(passo, alvo, duracao_animacao)
		if i < vezes - 1 and not await esperar(passo.repetir_a_cada, minha):
			return

# Espera em tempo real (pausa no Pause); false se parar_tudo() veio no meio
func esperar(segundos, minha):
	await get_tree().create_timer(segundos, false, false, true).timeout
	return minha == geracao

# Segundos do início ao fim do último passo (para o painel de debug)
func duracao_total(dados, duracao_animacao):
	var fim = 0.0
	for passo in dados.passos:
		var duracao = duracao_animacao if passo.da_animacao else passo.duracao
		fim = maxf(fim, passo.tempo + maxi(passo.repetir - 1, 0) * passo.repetir_a_cada + duracao)
	return fim

# Faz o passo acontecer na ferramenta certa
func executar(passo, alvo, duracao_animacao):
	var duracao = duracao_animacao if passo.da_animacao else passo.duracao
	var cor = efeitos.cor(passo.cor)
	var ponto = posicao(alvo)
	match passo.tipo:
		Passo.Tipo.TREMER:
			camera.tremer(passo.forca, duracao)
		Passo.Tipo.TREMER_CONTINUO:
			camera.tremer_continuo(passo.de, passo.ate, duracao)
		Passo.Tipo.PARAR_TREMOR_CONTINUO:
			camera.parar_tremor_continuo(duracao)
		Passo.Tipo.ZOOM:
			if not passo.focar_alvo:
				camera.zoom_para(passo.fator, duracao)
			elif ponto != null:
				camera.zoom_para(passo.fator, duracao, ponto)
		Passo.Tipo.ZOOM_PUNCH:
			camera.zoom_punch(passo.fator, duracao)
		Passo.Tipo.CONGELAR:
			TempoJogo.congelar(duracao)
		Passo.Tipo.CAMERA_LENTA:
			TempoJogo.camera_lenta(passo.escala, duracao)
		Passo.Tipo.FLASH_TELA:
			tela.flash_tela(cor, passo.alfa, duracao)
		Passo.Tipo.FLASH_CORPO:
			var flash = achar(alvo, FlashSprite)
			if flash != null and passo.pulsar > 0:
				flash.pulsar(cor, passo.alfa, passo.pulsar)
			elif flash != null:
				flash.flash(cor, passo.alfa, duracao)
		Passo.Tipo.LETTERBOX:
			tela.letterbox(passo.ligar)
		Passo.Tipo.ONDA:
			if ponto != null:
				tela.onda_choque(ponto, passo.raio, duracao, passo.forca)
		Passo.Tipo.ABERRACAO:
			tela.aberracao(passo.px)
		Passo.Tipo.BORDAS:
			if passo.ligar:
				tela.bordas(cor, passo.alfa, passo.pulsar, passo.vezes)
			else:
				tela.bordas(cor, 0.0)
		Passo.Tipo.ESTRELAS_VELOCIDADE:
			estrelas.mudar_velocidade(passo.fator, duracao)
		Passo.Tipo.ESTRELAS_COR:
			estrelas.mudar_cor(cor, duracao)
		Passo.Tipo.ESTRELAS_BRILHO:
			estrelas.mudar_brilho(passo.fator, duracao)
		Passo.Tipo.ESTRELAS_RISCO:
			estrelas.modo_risco(passo.ligar, passo.fator, passo.limiar)
		Passo.Tipo.ESTRELAS_EMPURRAR:
			if ponto != null:
				estrelas.empurrar(estrelas.to_local(ponto), passo.forca, duracao)
		Passo.Tipo.ESTRELAS_APAGAR:
			estrelas.apagar_uma_a_uma(duracao)
		Passo.Tipo.ESTRELAS_ACENDER:
			estrelas.acender_novas(cor, passo.quantidade, duracao)
		Passo.Tipo.PARTICULA:
			if ponto != null:
				soltar_particula(passo, alvo, ponto, duracao)
		Passo.Tipo.AFTERIMAGE:
			var rastro = achar(alvo, Afterimage)
			if rastro != null:
				rastro.soltar(passo.copias, passo.intervalo, passo.vida, cor, passo.alfa)
		Passo.Tipo.SOM:
			Sons.tocar(passo.nome)
		Passo.Tipo.SINAL:
			pedido.emit(passo.nome, passo.parametros, alvo)
		Passo.Tipo.MOMENTO:
			tocar(passo.nome, alvo, duracao_animacao)
		Passo.Tipo.LETREIRO:
			mostrar_letreiro(passo, alvo)
		Passo.Tipo.FALA:
			caixa.falar(passo.nome)
		_:
			push_error("Momentos: o passo %s ainda não faz nada" % Passo.Tipo.keys()[passo.tipo])

# Mostra o letreiro na hud; cada letra que entra toca o momento_por_letra do estilo no mesmo alvo
func mostrar_letreiro(passo, alvo):
	var letreiro = hud.mostrar_letreiro(passo.letreiro, passo.texto, passo.subtitulo, passo.duracao if passo.duracao > 0 else -1.0)
	var por_letra = passo.letreiro.momento_por_letra
	if por_letra != &"":
		letreiro.letra_entrou.connect(func(_indice): tocar(por_letra, alvo))

# Posição global do alvo (null se não há alvo ou ele já saiu da cena)
func posicao(alvo):
	if alvo is Vector2:
		return alvo
	if is_instance_valid(alvo) and alvo is Node2D:
		return alvo.global_position
	return null

# Um nó do tipo 'classe' dentro do corpo (FlashSprite, Afterimage); null se não há
func achar(alvo, classe):
	if not (is_instance_valid(alvo) and alvo is Node2D):
		return null
	for filho in alvo.find_children("*", "", true, false):
		if is_instance_of(filho, classe):
			return filho
	return null

# Solta a partícula do passo; quantidade, distância e vida vêm de Partículas do efeitos_boss.
# O ki subindo é contínuo: fica preso ao corpo e para de emitir depois de 'duracao'
func soltar_particula(passo, alvo, ponto, duracao):
	var cena = FAISCA
	var quantidade = 0.0
	var distancia = 0.0
	match passo.particula:
		Passo.Particula.FAISCA:
			quantidade = efeitos.faisca_hit.x
			distancia = efeitos.faisca_hit.y
		Passo.Particula.POEIRA_POUSO:
			cena = POEIRA
			quantidade = efeitos.poeira_pouso.x
			distancia = efeitos.poeira_pouso.y
		Passo.Particula.POEIRA_BLOCO:
			cena = POEIRA
			quantidade = efeitos.poeira_bloco.x
			distancia = efeitos.poeira_bloco.y
		Passo.Particula.FOLHINHAS:
			cena = FOLHINHAS
			quantidade = randi_range(int(efeitos.folhinhas_quantidade.x), int(efeitos.folhinhas_quantidade.y))
		Passo.Particula.KI_HIT:
			quantidade = efeitos.ki_hit.x
			distancia = efeitos.ki_hit.y
		Passo.Particula.KI_SUBINDO:
			soltar_ki(passo, alvo, ponto, duracao)
			return
	var particula = cena.instantiate()
	particula.position = ponto + passo.deslocamento
	if passo.direcao != Vector2.ZERO:
		particula.direction = passo.direcao
	if passo.espalhar > 0:
		particula.spread = passo.espalhar
	if passo.particula == Passo.Particula.KI_HIT:
		particula.lifetime = efeitos.ki_hit_vida
		particula.color_initial_ramp = gradiente(efeitos.cores_ki)
	particula.configurar(quantidade, distancia)
	mundo.add_child(particula)

# Ki subindo do corpo (ou do ponto) por 'duracao' segundos
func soltar_ki(passo, alvo, ponto, duracao):
	var ki = KI_SUBINDO.instantiate()
	ki.definir_taxa(efeitos.ki_subindo_por_segundo)
	if is_instance_valid(alvo) and alvo is Node2D:
		ki.position = passo.deslocamento
		alvo.add_child(ki)
	else:
		ki.position = ponto + passo.deslocamento
		mundo.add_child(ki)
	if await esperar(duracao, geracao) and is_instance_valid(ki):
		ki.emitting = false

# Gradiente de cores sorteadas (uma por partícula) a partir de uma lista
func gradiente(cores):
	var g = Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var posicoes = PackedFloat32Array()
	for i in range(cores.size()):
		posicoes.append(float(i) / cores.size())
	g.offsets = posicoes
	g.colors = cores
	return g
