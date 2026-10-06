# Painel dos LABs do cheat (LAB DE EFEITOS, LAB DE SONS): páginas com até 10 linhas, cada
# uma disparada por uma tecla, o detalhe da última disparada e um rodapé com o status.
# Q/E trocam a página · 1–9 e 0 disparam · R volta tudo ao normal · H esconde o texto.
# Cada LAB herda daqui e preenche montar_paginas(), estado_ligado() e ao_resetar().
class_name PainelLab
extends CanvasLayer

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")

# Layout do painel (px): a lista, depois o detalhe e, colado no fim da tela, o rodapé
# fixo. As áreas nunca se cruzam
const LINHAS_LISTA = 11
# Rodapé: 1 linha de comandos + 2 de status
const LINHAS_RODAPE = 3
const COMANDOS = "Q/E PAGINA  R RESET  H TEXTO"
const MARGEM_TEXTO = 2
const FOLGA = 4
const LARGURA_PAINEL = 250
const ALFA_FUNDO = 0.6
const TECLAS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]

# Texto do detalhe antes da primeira linha disparada
var dica = "APERTE 1-0 PARA DISPARAR"

var paginas = []
var pagina = 0
var ultima = null
var aviso = ""
# Sobe a cada R: sequências que estavam esperando param de agir
var geracao = 0

var texto_lista: Label
var texto_detalhe: Label
var texto_rodape: Label
var fundo_lista: ColorRect
var fundo_detalhe: ColorRect
var fundo_rodape: ColorRect
# Calculados em montar_layout() a partir da altura de linha da fonte
var altura_linha = 0.0
var linhas_detalhe = 0

# Monta o painel e mostra a primeira página (o LAB chama depois de receber o que precisa)
func iniciar():
	# Acima da HUD (5) e dos flashes (3): o texto fica legível; as barras do letterbox (7) cobrem ele
	layer = 6
	montar_layout()
	paginas = montar_paginas()
	mostrar()

# Páginas do LAB (cada LAB sobrescreve)
func montar_paginas():
	return []

# Altura (px) em que a lista começa
func topo_da_lista():
	return FOLGA

# Status do rodapé (o que continua ligado)
func estado_ligado():
	return ""

# O que o R desfaz além do próprio painel
func ao_resetar():
	pass

# Lista (LINHAS_LISTA fixas) a partir de topo_da_lista(), o detalhe (o que sobra) e o
# rodapé fixo colado no fim da tela
func montar_layout():
	fundo_lista = criar_fundo()
	texto_lista = criar_label()
	fundo_detalhe = criar_fundo()
	texto_detalhe = criar_label()
	fundo_rodape = criar_fundo()
	texto_rodape = criar_label()
	altura_linha = texto_lista.get_line_height()
	var altura_tela = get_viewport().get_visible_rect().size.y
	var altura_rodape = LINHAS_RODAPE * altura_linha
	var topo_rodape = altura_tela - altura_rodape - 2 * MARGEM_TEXTO
	posicionar(fundo_rodape, texto_rodape, topo_rodape, altura_rodape)
	texto_rodape.max_lines_visible = LINHAS_RODAPE
	var topo_lista = topo_da_lista()
	var altura_lista = LINHAS_LISTA * altura_linha
	posicionar(fundo_lista, texto_lista, topo_lista, altura_lista)
	texto_lista.max_lines_visible = LINHAS_LISTA
	var topo_detalhe = topo_lista + altura_lista + 2 * MARGEM_TEXTO + FOLGA
	linhas_detalhe = floori((topo_rodape - FOLGA - topo_detalhe - 2 * MARGEM_TEXTO) / altura_linha)
	posicionar(fundo_detalhe, texto_detalhe, topo_detalhe, 0)
	texto_detalhe.max_lines_visible = linhas_detalhe

# Rodapé: comandos e, embaixo, o status (atualiza a cada quadro)
func _process(_delta):
	texto_rodape.text = COMANDOS + "\n" + estado_ligado()

# Coloca um texto e o fundo dele a partir de 'topo', com 'altura' de texto
func posicionar(fundo, texto, topo, altura):
	var esquerda = (get_viewport().get_visible_rect().size.x - LARGURA_PAINEL) / 2.0
	fundo.position = Vector2(esquerda, topo)
	fundo.size = Vector2(LARGURA_PAINEL, altura + 2 * MARGEM_TEXTO)
	texto.position = Vector2(esquerda + MARGEM_TEXTO, topo + MARGEM_TEXTO)
	texto.size = Vector2(LARGURA_PAINEL - 2 * MARGEM_TEXTO, altura)

# Fundo escuro semitransparente atrás de um bloco de texto
func criar_fundo():
	var fundo = ColorRect.new()
	fundo.color = Color(0, 0, 0, ALFA_FUNDO)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	return fundo

# Label com a fonte do jogo e contorno preto; texto comprido quebra de linha
func criar_label():
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONTE)
	label.add_theme_font_size_override("font_size", 8)
	# Sem espaço extra entre linhas (o padrão do Label é 3 px): cabe mais texto no painel
	label.add_theme_constant_override("line_spacing", 0)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(label)
	return label

# Teclas do LAB (o resto continua com o player e o Pause)
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var tecla = event.physical_keycode
	if tecla == KEY_Q:
		trocar_pagina(-1)
	elif tecla == KEY_E:
		trocar_pagina(1)
	elif tecla == KEY_R:
		resetar()
	elif tecla == KEY_H:
		for no in [fundo_lista, texto_lista, fundo_detalhe, texto_detalhe]:
			no.visible = not no.visible
	elif tecla in TECLAS:
		disparar(TECLAS.find(tecla))
	else:
		return
	get_viewport().set_input_as_handled()

# Vai para a página anterior/seguinte (dá a volta)
func trocar_pagina(passo):
	pagina = (pagina + passo + paginas.size()) % paginas.size()
	mostrar()

# Dispara a linha 'indice' da página atual e mostra os valores dela
func disparar(indice):
	var linhas = paginas[pagina]["linhas"]
	if indice >= linhas.size():
		return
	ultima = linhas[indice]
	aviso = ""
	if ultima["acao"].is_valid():
		ultima["acao"].call()
	mostrar()

# Tudo volta ao normal na hora (o LAB desfaz o dele em ao_resetar)
func resetar():
	geracao += 1
	ao_resetar()
	ultima = null
	aviso = ""
	mostrar()

# Escreve a página atual e, embaixo, os valores da última linha disparada
func mostrar():
	var atual = paginas[pagina]
	var texto = "Q< %d/%d %s >E" % [pagina + 1, paginas.size(), atual["titulo"]]
	for i in range(atual["linhas"].size()):
		var linha_atual = atual["linhas"][i]
		var tecla = str((i + 1) % 10) if linha_atual["acao"].is_valid() else "-"
		texto += "\n%s %s" % [tecla, linha_atual["nome"]]
	texto_lista.text = texto
	var detalhe = dica
	if ultima != null:
		detalhe = ultima["nome"] + "\n" + "; ".join(ultima["detalhes"])
		if not ultima["acao"].is_valid():
			detalhe = "SO CONSULTA: " + detalhe
		if aviso != "":
			detalhe += "\n" + aviso
	texto_detalhe.text = detalhe
	ajustar_detalhe()

# O fundo dos detalhes cresce com o texto (já quebrado), até o fim da tela
func ajustar_detalhe():
	var linhas = mini(texto_detalhe.get_line_count(), linhas_detalhe)
	texto_detalhe.size.y = linhas * altura_linha
	fundo_detalhe.size.y = linhas * altura_linha + 2 * MARGEM_TEXTO

# ---------- ferramentas usadas pelas linhas ----------

# Uma linha da lista: nome, partes (com marcas) e o que ela dispara
func linha(nome, detalhes, acao = Callable()):
	return {"nome": nome, "detalhes": detalhes, "acao": acao}

# Uma página: título e linhas (no máximo 10, uma por tecla)
func nova_pagina(titulo, linhas):
	return {"titulo": titulo, "linhas": linhas}

# Espera em tempo real; devolve false se o R foi apertado no meio
func esperar(segundos):
	var minha = geracao
	await get_tree().create_timer(segundos, false, false, true).timeout
	return minha == geracao

# Número no jeito brasileiro: 0.25 → "0,25", 5.0 → "5"
func n(valor):
	if is_equal_approx(valor, roundf(valor)):
		return str(int(roundf(valor)))
	return str(snappedf(valor, 0.01)).replace(".", ",")
