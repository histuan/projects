# LAB DE EFEITOS (opção do cheat): lista e toca os MOMENTOS do momentos_boss.tres (os mesmos
# que a luta toca), para sentir e afinar cada número sem jogar a luta.
# Cada linha é um momento; o detalhe mostra os passos dele. Passo pendente aparece com a marca
# ("SEM VALOR", "NA F1"...) e não roda; momento só com passos pendentes fica só para consulta.
# Momento ligado a animação: o LAB finge a animação com a duracao_animacao_lab (PROVISÓRIA) e
# toca o 'seguinte' no fim dela. Teclas e layout: PainelLab.
extends PainelLab

const IDLE_LORAX = preload("res://meus sprites/lorax boss battle/fase1/fase1 idle.png")
const Particula = preload("res://scripts/efeitos/particula.gd")

# O boneco fica onde o Lorax luta: altura e meio do vai e vem da fase 1
const DADOS_FASE1 = preload("res://recursos/boss/classica1.tres")

# Meia altura do quadro de 32 px do boneco
const MEIO_BONECO = 16
# Pés do boneco: linha 28 do quadro de 32 px centrado = 12 px abaixo do centro
const PES_BONECO = 12
# Só para mostrar o afterimage: o boneco desliza esta distância e volta
const DEMO_ESQUIVA_PX = 40
# Poeira da folha no bloco: à esquerda do boneco, na altura dos pés (fora do painel e
# do lado oposto ao do teleporte)
const LADO_BLOCO_PX = 40
# Teste da regra de segurança: 4 flashes com este intervalo (s)
const TESTE_FLASH_INTERVALO = 0.1
const TESTE_FLASH_VEZES = 4
# Linhas por página (uma por tecla)
const LINHAS_POR_PAGINA = 10

# Páginas da tabela 4 do efeitos.md: título e momentos, na ordem das teclas
const PAGINAS = [
	["ESTRELAS", [&"estrelas_normal", &"wave10_silencio", &"fase1_estrelas", &"fase2_estrelas",
		&"derrota_f2_estrelas", &"despertar_estrelas", &"pico_estrelas", &"arena_estrelas",
		&"virada_estrelas", &"desespero_estrelas"]],
	["ESTRELAS 2", [&"tonto_estrelas", &"final_ruim_estrelas", &"raiva_estrelas",
		&"reparo_estrelas", &"poupar_estrelas", &"puxao_estrelas", &"ataque_grande_estrelas"]],
	["WAVE 10", [&"wave10_silencio", &"wave10_alarme", &"wave10_musica_entra"]],
	["FASE 1", [&"descida", &"pouso", &"nome_do_boss", &"hit_comum", &"coracao_boss_perdido",
		&"ultimo_coracao", &"carga_ataque", &"soltar_folhas", &"folha_acerta_bloco"]],
	["FASE 2 E TROCAS", [&"f2_carga", &"f2_arvore_explode", &"f2_respira", &"f2_desespero",
		&"ultimo_hit_f1", &"transicao_1_2", &"derrota_f2"]],
	["TRANSFORMACAO", [&"raiva", &"despertar", &"aura", &"pico_do_pilar", &"resto_do_pilar",
		&"reparo", &"chapeu", &"puxao", &"nave_chega", &"arena_nasce"]],
	["FASE 3", [&"aviso", &"raio", &"cortina_todos", &"raio_direto_carga", &"pancada",
		&"esfera_estoura", &"teleporte", &"hit_lorax_ui", &"player_hit", &"virada"]],
	["FASE 3 (2)", [&"desespero", &"janela_abre", &"respirando"]],
	["DESFECHO", [&"finish_him", &"golpe_final", &"poupar"]],
]
# Momentos que, na luta, acontecem fora do corpo do Lorax: onde o LAB solta (relativo ao boneco)
const ALVOS_DEMO = {&"folha_acerta_bloco": Vector2(-LADO_BLOCO_PX, PES_BONECO)}

var camera
var tela
var estrelas
var e: EfeitosDados
var mundo
var boneco: Node2D
var flash_boneco: FlashSprite
var rastro: Afterimage
var tween_boneco: Tween = null

# O boneco fica no alto (como na luta); a lista começa embaixo dele
var posicao_boneco = Vector2.ZERO

# Recebe da main quem ela vai controlar, confere o momentos_boss.tres e monta o boneco,
# o texto e as páginas
func preparar(cam, efeitos_tela, campo_estrelas, dados, pai_do_boneco):
	camera = cam
	tela = efeitos_tela
	estrelas = campo_estrelas
	e = dados
	mundo = pai_do_boneco
	dica = "APERTE 1-0 PARA DISPARAR UM EFEITO"
	posicao_boneco = Vector2((DADOS_FASE1.limite_esq + DADOS_FASE1.limite_dir) / 2.0, DADOS_FASE1.altura)
	tela.flash_barrado.connect(_on_flash_barrado)
	Momentos.validar_todos()
	iniciar()
	criar_boneco()

# As páginas de PAGINAS, depois OUTROS (momentos do arquivo que nenhuma linha alcança)
# e, por último, as FERRAMENTAS
func montar_paginas():
	var lista = []
	var alcancados = {}
	for grupo in PAGINAS:
		var linhas = []
		for nome in grupo[1]:
			linhas.append(linha_momento(nome))
			marcar_alcancados(nome, alcancados)
		lista.append(nova_pagina(grupo[0], linhas))
	var outros = []
	for nome in Momentos.BIBLIOTECA.momentos:
		if not alcancados.has(nome):
			outros.append(linha_momento(nome))
	for inicio in range(0, outros.size(), LINHAS_POR_PAGINA):
		lista.append(nova_pagina("OUTROS", outros.slice(inicio, inicio + LINHAS_POR_PAGINA)))
	lista.append(pagina_ferramentas())
	return lista

# Boneco parado do Lorax 2.0 no mundo, com flash e afterimage (o afterimage vem antes
# do sprite para as cópias ficarem atrás)
func criar_boneco():
	boneco = Node2D.new()
	boneco.position = posicao_boneco
	rastro = Afterimage.new()
	rastro.sprite = NodePath("../Sprite2D")
	boneco.add_child(rastro)
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = IDLE_LORAX
	sprite.hframes = 4
	boneco.add_child(sprite)
	flash_boneco = FlashSprite.new()
	sprite.add_child(flash_boneco)
	mundo.add_child(boneco)

# A lista começa logo abaixo do boneco
func topo_da_lista():
	return posicao_boneco.y + MEIO_BONECO + FOLGA

# Efeitos que ficam ligados até o R (zoom sem volta, tremor contínuo, estrelas, barras...)
func estado_ligado():
	var itens = []
	if not camera.zoom.is_equal_approx(Vector2.ONE):
		itens.append("ZOOM " + n(camera.zoom.x))
	if camera.forca_continua > 0:
		itens.append("TREMOR CONTINUO")
	if not is_equal_approx(estrelas.velocidade_mult, 1.0):
		itens.append("ESTRELAS x" + n(estrelas.velocidade_mult))
	if estrelas.tem_apagadas():
		itens.append("ESTRELAS APAGADAS")
	if estrelas.cor != Color.WHITE:
		itens.append("ESTRELAS COLORIDAS")
	if tela.letterbox_visivel():
		itens.append("LETTERBOX")
	if tela.bordas_visiveis():
		itens.append("BORDAS")
	if ki_emitindo():
		itens.append("KI")
	if itens.is_empty():
		return "LIGADO: NADA"
	return "LIGADO: " + ", ".join(itens)

# Alguma partícula contínua (o ki subindo) ainda está saindo
func ki_emitindo():
	for particula in get_tree().get_nodes_in_group(Particula.GRUPO):
		if not particula.one_shot and particula.emitting:
			return true
	return false

# Tudo volta ao normal na hora: momentos agendados, tempo, câmera, tela, estrelas e boneco
func ao_resetar():
	Momentos.parar_tudo()
	TempoJogo.limpar()
	camera.restaurar()
	tela.limpar()
	estrelas.restaurar()
	flash_boneco.parar()
	rastro.parar()
	for particula in get_tree().get_nodes_in_group(Particula.GRUPO):
		particula.queue_free()
	if tween_boneco != null:
		tween_boneco.kill()
	boneco.position = posicao_boneco

# Um flash de tela foi barrado pela regra de segurança: avisa no detalhe
func _on_flash_barrado():
	aviso = "FLASH BARRADO: LIMITE DE %d POR SEGUNDO" % e.flashes_tela_por_segundo
	mostrar()

# ---------- linhas dos momentos ----------

# Linha de um momento: título, passos descritos e, se algum passo roda, a ação de tocar
func linha_momento(nome):
	var dados = Momentos.momento(nome)
	var detalhes = detalhes_do(nome)
	if usa_animacao(dados):
		detalhes.append("ANIMACAO NO LAB: %s S (PROVISORIO)" % n(duracao_lab(nome)))
	var acao = Callable()
	if tem_efeito(nome, {}):
		acao = tocar_momento.bind(nome)
	return linha(dados.titulo, detalhes, acao)

# Guarda o momento e tudo o que ele toca (sub-momentos e o seguinte)
func marcar_alcancados(nome, alcancados):
	if alcancados.has(nome):
		return
	alcancados[nome] = true
	var dados = Momentos.momento(nome)
	if dados == null:
		return
	if dados.seguinte != &"":
		marcar_alcancados(dados.seguinte, alcancados)
	for passo in dados.passos:
		if passo.tipo == Passo.Tipo.MOMENTO:
			marcar_alcancados(passo.nome, alcancados)

# Algum passo do momento (ou do que ele toca) roda de verdade
func tem_efeito(nome, vistos):
	if vistos.has(nome):
		return false
	vistos[nome] = true
	var dados = Momentos.momento(nome)
	if dados == null:
		return false
	if dados.seguinte != &"" and tem_efeito(dados.seguinte, vistos):
		return true
	for passo in dados.passos:
		if passo.pendente != "":
			continue
		if passo.tipo != Passo.Tipo.MOMENTO or tem_efeito(passo.nome, vistos):
			return true
	return false

# O momento depende da duração da animação (passo da_animacao ou seguinte no fim dela)
func usa_animacao(dados):
	if dados.seguinte != &"":
		return true
	for passo in dados.passos:
		if passo.da_animacao:
			return true
	return false

# Duração de animação que o LAB finge para o momento: a dele ou, se ele não tem, a do
# momento que toca ele (ex.: as estrelas do despertar usam a do despertar)
func duracao_lab(nome):
	var dados = Momentos.momento(nome)
	if dados.duracao_animacao_lab > 0:
		return dados.duracao_animacao_lab
	for outro in Momentos.BIBLIOTECA.momentos:
		for passo in Momentos.BIBLIOTECA.momentos[outro].passos:
			if passo.tipo == Passo.Tipo.MOMENTO and passo.nome == nome:
				return duracao_lab(outro)
	return 0.0

# Os passos do momento em texto (sub-momentos abertos no lugar; o seguinte no fim)
func detalhes_do(nome):
	var dados = Momentos.momento(nome)
	var partes = []
	for passo in dados.passos:
		if passo.tipo == Passo.Tipo.MOMENTO and passo.rotulo == "":
			var dentro = detalhes_do(passo.nome)
			if passo.tempo > 0:
				dentro = ["AOS %s S: %s" % [n(passo.tempo), " + ".join(dentro)]]
			partes.append_array(dentro)
		else:
			partes.append(descrever(passo))
	if dados.seguinte != &"":
		partes.append("NO FIM DA ANIMACAO: " + " + ".join(detalhes_do(dados.seguinte)))
	return partes

# Toca o momento no boneco (ou no ponto de demonstração) e, no fim da animação fingida,
# o seguinte. Momento com afterimage: o boneco desliza para as cópias aparecerem
func tocar_momento(nome):
	var dados = Momentos.momento(nome)
	var duracao = duracao_lab(nome)
	Momentos.tocar(nome, alvo_demo(nome), duracao)
	for passo in dados.passos:
		if passo.tipo == Passo.Tipo.AFTERIMAGE and passo.pendente == "":
			deslizar_boneco(passo)
	if dados.seguinte != &"" and await esperar(duracao):
		tocar_momento(dados.seguinte)

# O boneco, ou o ponto de demonstração do momento
func alvo_demo(nome):
	if ALVOS_DEMO.has(nome):
		return posicao_boneco + ALVOS_DEMO[nome]
	return boneco

# O boneco desliza enquanto solta as cópias e depois volta
func deslizar_boneco(passo):
	if tween_boneco != null:
		tween_boneco.kill()
	var ida = passo.copias * passo.intervalo
	tween_boneco = boneco.create_tween().set_ignore_time_scale()
	tween_boneco.tween_property(boneco, "position:x", posicao_boneco.x + DEMO_ESQUIVA_PX, ida)
	tween_boneco.tween_interval(passo.vida)
	tween_boneco.tween_property(boneco, "position", posicao_boneco, ida)

# ---------- texto dos passos ----------

# Um passo em texto: quando, o quê (ou o rótulo), repetições e a marca de pendente
func descrever(passo):
	var texto = passo.rotulo if passo.rotulo != "" else texto_do_passo(passo)
	if passo.tempo > 0:
		texto = "AOS %s S: %s" % [n(passo.tempo), texto]
	if passo.repetir > 1:
		texto += " %dx A CADA %s S" % [passo.repetir, n(passo.repetir_a_cada)]
	if passo.pendente != "":
		texto += ": " + passo.pendente
	return texto

# O que o passo faz, na notação do efeitos.md (T, TC, HS, CL, Z, F)
func texto_do_passo(passo):
	var cor = nome_da_cor(passo.cor)
	match passo.tipo:
		Passo.Tipo.TREMER:
			return "T(%s;%s)" % [n(passo.forca), n(passo.duracao)]
		Passo.Tipo.TREMER_CONTINUO:
			return "TC(%s->%s)%s" % [n(passo.de), n(passo.ate), quando(passo)]
		Passo.Tipo.PARAR_TREMOR_CONTINUO:
			return "PARA O TC" + (" EM %s S" % n(passo.duracao) if passo.duracao > 0 else "")
		Passo.Tipo.ZOOM:
			return "Z(%s;%s)%s" % [n(passo.fator), n(passo.duracao), " NO LORAX" if passo.focar_alvo else ""]
		Passo.Tipo.ZOOM_PUNCH:
			return "ZOOM PUNCH Z(%s;%s)" % [n(passo.fator), n(passo.duracao)]
		Passo.Tipo.CONGELAR:
			return "HS " + n(passo.duracao)
		Passo.Tipo.CAMERA_LENTA:
			return "CL(%s;%s)" % [n(passo.escala), n(passo.duracao)]
		Passo.Tipo.FLASH_TELA:
			return "%s F %s/%s S" % [cor, n(passo.alfa), n(passo.duracao)]
		Passo.Tipo.FLASH_CORPO:
			if passo.pulsar > 0:
				return "CORPO %s PULSA 0->%s A CADA %s S" % [cor, n(passo.alfa), n(passo.pulsar)]
			if passo.duracao > 0:
				return "FLASH NO CORPO %s F %s/%s S" % [cor, n(passo.alfa), n(passo.duracao)]
			return "CORPO %s 0->%s" % [cor, n(passo.alfa)]
		Passo.Tipo.LETTERBOX:
			if passo.ligar:
				return "LETTERBOX %d PX ENTRA EM %s S" % [e.letterbox_barras, n(e.letterbox_duracao)]
			return "LETTERBOX SAI EM %s S" % n(e.letterbox_duracao)
		Passo.Tipo.ONDA:
			return "ONDA %s PX %s S FORCA %s" % [n(passo.raio), n(passo.duracao), n(passo.forca)]
		Passo.Tipo.ABERRACAO:
			return "ABERRACAO %s PX, VOLTA EM %s S" % [n(passo.px), n(e.aberracao_volta)]
		Passo.Tipo.BORDAS:
			return texto_bordas(passo, cor)
		Passo.Tipo.ESTRELAS_VELOCIDADE:
			var parada = " (CONGELAM)" if passo.fator == 0 else ""
			return "ESTRELAS x%s%s%s" % [n(passo.fator), parada, quando(passo)]
		Passo.Tipo.ESTRELAS_COR:
			return "ESTRELAS %s%s" % [cor, quando(passo)]
		Passo.Tipo.ESTRELAS_BRILHO:
			return "BRILHO DAS ESTRELAS %s%s" % [n(passo.fator), quando(passo)]
		Passo.Tipo.ESTRELAS_RISCO:
			if passo.ligar:
				return "RISCOS x%s ACIMA DE %s PX/S" % [n(passo.fator), n(passo.limiar)]
			return "RISCOS DESLIGAM"
		Passo.Tipo.ESTRELAS_EMPURRAR:
			return "EMPURRAR %s PX EM %s S" % [n(passo.forca), n(passo.duracao)]
		Passo.Tipo.ESTRELAS_APAGAR:
			return "APAGAM UMA A UMA EM %s S" % n(passo.duracao)
		Passo.Tipo.ESTRELAS_ACENDER:
			return "%d ESTRELAS NOVAS %s EM %s S" % [passo.quantidade, cor, n(passo.duracao)]
		Passo.Tipo.PARTICULA:
			return texto_particula(passo)
		Passo.Tipo.AFTERIMAGE:
			return "AFTERIMAGE %d COPIAS, %s S, VIDA %s S, ALFA %s" % [passo.copias, n(passo.intervalo), n(passo.vida), n(passo.alfa)]
		Passo.Tipo.SOM:
			return "SOM " + maiusculo(passo.nome)
		Passo.Tipo.SINAL:
			return texto_sinal(passo)
		Passo.Tipo.MOMENTO:
			return "MOMENTO " + maiusculo(passo.nome)
	return "PASSO SEM TIPO"

# Duração de um passo que leva tempo: " EM x S", " DA ANIMACAO" ou " (FICA LIGADO)"
func quando(passo):
	if passo.da_animacao:
		return " DA ANIMACAO"
	if passo.duracao > 0:
		return " EM %s S" % n(passo.duracao)
	if passo.fica_ligado:
		return " (FICA LIGADO)"
	return ""

# Bordas ligando (fixas, piscando sem parar ou N vezes) ou desligando
func texto_bordas(passo, cor):
	if not passo.ligar:
		return "BORDAS DESLIGAM"
	var texto = "BORDAS %s ALFA %s" % [cor, n(passo.alfa)]
	if passo.pulsar <= 0:
		return texto + " (FICAM LIGADAS)"
	if passo.vezes > 0:
		return texto + " PISCAM %dx %s S" % [passo.vezes, n(passo.pulsar)]
	return texto + " PISCANDO %s S" % n(passo.pulsar)

# Partícula com os números de Partículas do efeitos_boss.tres
func texto_particula(passo):
	var texto = "PARTICULA SEM TIPO"
	match passo.particula:
		Passo.Particula.FAISCA:
			texto = "FAISCA %s, %s PX" % [n(e.faisca_hit.x), n(e.faisca_hit.y)]
		Passo.Particula.POEIRA_POUSO:
			texto = "POEIRA %s, %s PX" % [n(e.poeira_pouso.x), n(e.poeira_pouso.y)]
		Passo.Particula.POEIRA_BLOCO:
			texto = "POEIRA %s, %s PX" % [n(e.poeira_bloco.x), n(e.poeira_bloco.y)]
		Passo.Particula.FOLHINHAS:
			texto = "FOLHINHAS %s-%s" % [n(e.folhinhas_quantidade.x), n(e.folhinhas_quantidade.y)]
		Passo.Particula.KI_HIT:
			texto = "KI %s, %s PX, VIDA %s S" % [n(e.ki_hit.x), n(e.ki_hit.y), n(e.ki_hit_vida)]
		Passo.Particula.KI_SUBINDO:
			texto = "KI SUBINDO %s/S%s" % [n(e.ki_subindo_por_segundo), quando(passo)]
	if passo.direcao.x < 0:
		texto += " PARA A ESQUERDA"
	elif passo.direcao.x > 0:
		texto += " PARA A DIREITA"
	elif passo.direcao.y < 0:
		texto += " PARA CIMA"
	return texto

# Pedido para a fase: o nome e os números dele
func texto_sinal(passo):
	var texto = maiusculo(passo.nome)
	for chave in passo.parametros:
		var valor = passo.parametros[chave]
		if valor is Vector2:
			texto += " %s (%s;%s)" % [maiusculo(chave), n(valor.x), n(valor.y)]
		else:
			texto += " %s %s" % [maiusculo(chave), n(valor)]
	return texto

# "folha_acerta" → "FOLHA ACERTA"
func maiusculo(texto):
	return String(texto).replace("_", " ").to_upper()

# Nome da cor de um passo ("CORACAO FASE1")
func nome_da_cor(cor):
	return maiusculo(EfeitosDados.Cor.keys()[cor])

# ---------- ferramentas soltas ----------

# Ferramentas da tela, para testar cada uma (números da Tela e de passos de momentos)
func pagina_ferramentas():
	var bordas = primeiro_passo(&"wave10_alarme", Passo.Tipo.BORDAS)
	var flash = primeiro_passo(&"esfera_estoura", Passo.Tipo.FLASH_TELA)
	return nova_pagina("FERRAMENTAS", [
		linha("ABERRACAO MINIMA", ["%s PX, VOLTA EM %s S" % [n(e.aberracao_px.x), n(e.aberracao_volta)]],
			func(): tela.aberracao(e.aberracao_px.x)),
		linha("ABERRACAO MAXIMA", ["%s PX, VOLTA EM %s S" % [n(e.aberracao_px.y), n(e.aberracao_volta)]],
			func(): tela.aberracao(e.aberracao_px.y)),
		linha("LETTERBOX LIGA/DESLIGA", ["%d PX EM %s S" % [e.letterbox_barras, n(e.letterbox_duracao)]],
			func(): tela.letterbox(not tela.letterbox_ligado())),
		linha("BORDAS LIGA/DESLIGA", ["DEGRADE %d PX, ALARME PISCANDO SEM PARAR" % e.bordas_largura],
			alternar_bordas.bind(bordas)),
		linha("4 FLASHES SEGUIDOS", ["TESTA A REGRA: NO MAXIMO %d POR SEGUNDO" % e.flashes_tela_por_segundo],
			quatro_flashes.bind(flash)),
	])

# O primeiro passo do tipo dado no momento (erro se não houver)
func primeiro_passo(nome, tipo):
	for passo in Momentos.momento(nome).passos:
		if passo.tipo == tipo:
			return passo
	push_error("LAB DE EFEITOS: o momento '%s' não tem passo %s" % [nome, Passo.Tipo.keys()[tipo]])
	return null

# Liga/desliga as bordas do alarme da wave 10, piscando sem parar
func alternar_bordas(passo):
	var cor = e.cor(passo.cor)
	if tela.bordas_visiveis():
		tela.bordas(cor, 0.0)
	else:
		tela.bordas(cor, passo.alfa, passo.pulsar)

# Quatro flashes da esfera em menos de 1 s: o quarto tem que ser barrado
func quatro_flashes(passo):
	for i in range(TESTE_FLASH_VEZES):
		tela.flash_tela(e.cor(passo.cor), passo.alfa, passo.duracao)
		if not await esperar(TESTE_FLASH_INTERVALO):
			return
