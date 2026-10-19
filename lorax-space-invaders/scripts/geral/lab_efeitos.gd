# LAB DE EFEITOS (opção do cheat): lista e toca os MOMENTOS do momentos_boss.tres (os mesmos
# que a luta toca), para sentir e afinar cada número sem jogar a luta.
# Cada linha é um momento; o detalhe mostra os passos dele. Passo pendente aparece com a marca
# ("SEM VALOR", "NA F1"...) e não roda; momento só com passos pendentes fica só para consulta.
# Momento ligado a animação: o LAB finge a animação com a duracao_animacao_lab (PROVISÓRIA) e
# toca o 'seguinte' no fim dela. Teclas e layout: PainelLab.
# Página ANIMACOES (B4b): as animações do gerador tocando no corpo de verdade (lorax_final),
# trocadas com as setas cima/baixo.
extends PainelLab

# O R voltou tudo ao normal (a main limpa o que é dela: as tintas do fundo)
signal resetou

const IDLE_LORAX = preload("res://meus sprites/lorax boss battle/fase1/fase1 idle.png")
const Particula = preload("res://scripts/efeitos/particula.gd")
const CENA_CORPO = preload("res://cenas/boss/lorax_final.tscn")

# O boneco fica onde o Lorax luta: altura e meio do vai e vem da fase 1
const DADOS_FASE1 = preload("res://recursos/boss/classica1.tres")
const DADOS_FASE2 = preload("res://recursos/boss/classica2.tres")
# Se a luta corta o som da carga (CORTAR_SOM_CARGA) e o power-up da ferramenta TRÚFULA
const FaseClassica = preload("res://scripts/boss/fase_classica.gd")
const TRUFULA = preload("res://recursos/powerups/trufula.tres")
# Página com as ferramentas do combate da fase 1 (ATAQUE, VAI E VEM, TRÚFULA) depois dos momentos
const PAGINA_FASE1_COMBATE = "FASE 1 (2)"
# Ângulos (graus) que a linha ANGULO percorre
const ANGULOS_LAB = [0.0, 4.0, 6.0, 8.0, 10.0]
# Passos (graus) que a linha PASSO percorre (0 = contínuo)
const PASSOS_LAB = [0.0, 0.5, 1.0, 2.0]

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
# Teste da limpeza de projéteis (PROVISÓRIO, só do LAB): segundos entre o leque sair e a
# limpeza, e a grade de folhas paradas que passa do teto (colunas × linhas, px entre elas)
const LIMPEZA_ESPERA = 0.5
const TETO_COLUNAS = 8
const TETO_LINHAS = 5
const TETO_ESPACO = Vector2(28, 16)
# Teste do player (PROVISÓRIO, só do LAB): arena de mentira (largura, altura, centro na
# horizontal e a BASE do retângulo, na altura do pé das árvores: y 196 + 14 do tronco),
# segundos de cada ida/volta do MOVER PARA e o intervalo dos dois hits seguidos (tem que
# cair dentro dos i-frames)
const ARENA_TESTE_LARGURA = 192
const ARENA_TESTE_ALTURA = 96
const ARENA_TESTE_CENTRO_X = 127
const ARENA_TESTE_BASE_Y = 210
const MOVER_TESTE_TEMPO = 1.0
const HIT_DUPLO_INTERVALO = 0.1
# Dono dos pedidos de travar/bloquear tiro feitos pelo LAB
const DONO_LAB = &"lab"
# Linhas por página (uma por tecla)
const LINHAS_POR_PAGINA = 10
# Página ANIMACOES: rótulo curto e .tres de cada conjunto do gerador (load, não preload: o
# LAB abre mesmo antes de o gerador rodar)
const CONJUNTOS_ANIMACAO = [
	["CENA", "res://recursos/boss/animacoes/cutscene.tres"],
	["PILAR", "res://recursos/boss/animacoes/pilar_alto.tres"],
	["FINAIS", "res://recursos/boss/animacoes/finais.tres"],
	["PREVIA", "res://recursos/boss/animacoes/previa_finish_him.tres"],
	["UI1", "res://recursos/boss/animacoes/batalha_ui1.tres"],
	["UI2", "res://recursos/boss/animacoes/batalha_ui2.tres"],
	["COMUM", "res://recursos/boss/animacoes/batalha_comum.tres"],
]
# Conjuntos da fase 3: os quadros de evento deles ainda são sugestão
const ROTULOS_SUGESTAO = ["UI1", "UI2", "COMUM"]
# Nomes da lista visíveis de cada vez (as teclas 1–3 ficam com as ações)
const JANELA_ANIMACOES = 7
# O pilar alto toca atrás do corpo, com a base no pé dele
const POSICAO_PILAR_ALTO = Vector2(0, -32)
# Folga (s) para o seek cair dentro do quadro, e não na borda dele
const FOLGA_QUADRO = 0.001

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
	[PAGINA_FASE1_COMBATE, [&"folhas_anulam", &"coracao_player_perdido", &"player_morre_luta"]],
	["FASE 2 E TROCAS", [&"f2_carga", &"f2_arremessa", &"f2_arvore_explode", &"f2_arvore_explode_fora", &"f2_desespero_transforma", &"f2_desespero", &"f2_desespero_fim",
		&"hit_fase2", &"ultimo_coracao_f2", &"ultimo_hit_f1", &"transicao_1_2", &"derrota_f2"]],
	["TRANSFORMACAO", [&"raiva", &"despertar", &"aura", &"pilar_sobe", &"pico_do_pilar", &"resto_do_pilar",
		&"reparo", &"chapeu", &"puxao", &"nave_chega", &"arena_nasce"]],
	["FASE 3", [&"aviso", &"raio", &"cortina_todos", &"raio_direto_carga", &"pancada",
		&"esfera_estoura", &"teleporte", &"hit_lorax_ui", &"player_hit", &"virada"]],
	["FASE 3 (2)", [&"desespero", &"janela_abre", &"respirando", &"titulo_fase3", &"dica_ws"]],
	["DESFECHO", [&"finish_him", &"finish_letra", &"golpe_final", &"poupar", &"contagem"]],
]
# Momentos que, na luta, acontecem fora do corpo do Lorax: onde o LAB solta (relativo ao boneco)
const ALVOS_DEMO = {&"folha_acerta_bloco": Vector2(-LADO_BLOCO_PX, PES_BONECO)}

var camera
var tela
var estrelas
var e: EfeitosDados
var mundo
var hud
var boneco: Node2D
var flash_boneco: FlashSprite
var reacoes_boneco: ReacoesCorpo
var rastro: Afterimage
var tween_boneco: Tween = null
# Os corações do boss já apareceram (os momentos de coração do LAB os mostram)
var coracoes_boss_lab = false
# VAI E VEM ligado (o boneco anda entre os limites da fase 1) e leques já soltos pelo ATAQUE
var tween_vaivem: Tween = null
var leques_lab = 0
# Ângulo (graus) que o VAI E VEM do LAB usa (começa como o do classica1; o R volta a ele)
var angulo_lab = DADOS_FASE1.inclinacao_graus
# Inclinação progressiva do VAI E VEM do LAB: o que fazer depois do meio, o passo e a
# conta (a mesma da luta) com a posição anterior do boneco (o sentido sai do movimento)
var depois_do_meio_lab = DADOS_FASE1.inclinacao_depois_do_meio
var passo_lab = DADOS_FASE1.inclinacao_passo_graus
var inclinacao_lab: InclinacaoVaiEVem = null
var x_anterior = 0.0
var sentido_lab = 0
# Onde nascem as folhas do teste de limpeza (faz o papel do $Ataques da luta)
var ataques_teste: Node2D
var player
# O cenário (bases, chão, paredes): some com a arena ligada, como na F3
var cenario
# Contorno da arena de teste (só aparece com o modo arena ligado)
var contorno_arena: Node2D
# Onde o player estava antes da primeira ação da página PLAYER (a volta e o R vão para lá)
var posicao_original = null
# MOVER PARA: o player está no centro da arena de teste (a próxima vez volta)
var player_no_centro = false

# O boneco fica no alto (como na luta); a lista começa embaixo dele
var posicao_boneco = Vector2.ZERO

# Página ANIMACOES: o corpo de verdade (criado na primeira vez que toca) e o pilar alto de teste
var corpo = null
var anim_corpo: AnimationPlayer
var pilar_teste: Node2D
var anim_pilar: AnimationPlayer
# Todas as animações geradas: {rotulo, conjunto, dados}
var animacoes_lab = []
var escolhida = 0
var conjunto_no_corpo = null
var pagina_animacoes_indice = -1
var animacao_pausada = false

# Recebe da main quem ela vai controlar, confere o momentos_boss.tres e monta o boneco,
# o texto e as páginas
func preparar(cam, efeitos_tela, campo_estrelas, dados, pai_do_boneco, nova_hud, novo_player, novo_cenario):
	player = novo_player
	cenario = novo_cenario
	camera = cam
	tela = efeitos_tela
	estrelas = campo_estrelas
	e = dados
	mundo = pai_do_boneco
	hud = nova_hud
	dica = "APERTE 1-0 PARA DISPARAR UM EFEITO"
	posicao_boneco = Vector2((DADOS_FASE1.limite_esq + DADOS_FASE1.limite_dir) / 2.0, DADOS_FASE1.altura)
	tela.flash_barrado.connect(_on_flash_barrado)
	Momentos.pedido.connect(_on_pedido)
	Momentos.validar_todos()
	iniciar()
	criar_boneco()
	ataques_teste = Node2D.new()
	mundo.add_child(ataques_teste)
	contorno_arena = Node2D.new()
	contorno_arena.visible = false
	contorno_arena.draw.connect(_desenhar_contorno_arena)
	mundo.add_child(contorno_arena)

# O pico do pilar tocado aqui some com o cenário, como na luta (o R traz de volta)
func _on_pedido(nome, _parametros, _alvo):
	if nome == &"bases_somem":
		cenario.sumir_sob_flash()

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
		if grupo[0] == PAGINA_FASE1_COMBATE:
			linhas.append_array(linhas_combate_fase1())
		lista.append(nova_pagina(grupo[0], linhas))
	var outros = []
	for nome in Momentos.BIBLIOTECA.momentos:
		if not alcancados.has(nome):
			outros.append(linha_momento(nome))
	for inicio in range(0, outros.size(), LINHAS_POR_PAGINA):
		lista.append(nova_pagina("OUTROS", outros.slice(inicio, inicio + LINHAS_POR_PAGINA)))
	lista.append(pagina_ferramentas())
	lista.append(pagina_player())
	carregar_animacoes_lab()
	pagina_animacoes_indice = lista.size()
	lista.append(pagina_animacoes())
	return lista

# Boneco parado do Lorax 2.0 no mundo, com flash, afterimage e reações (squash...); o
# afterimage vem antes do sprite para as cópias ficarem atrás
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
	reacoes_boneco = ReacoesCorpo.new()
	boneco.add_child(reacoes_boneco)
	mundo.add_child(boneco)

# A lista começa logo abaixo do boneco
func topo_da_lista():
	return posicao_boneco.y + MEIO_BONECO + FOLGA

# Efeitos que ficam ligados até o R (zoom sem volta, tremor contínuo, estrelas, barras...)
func estado_ligado():
	var itens = []
	if reacoes_boneco != null and reacoes_boneco.graus != 0.0:
		itens.append("INCLINACAO " + n(reacoes_boneco.graus))
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
	if hud.letreiros_na_tela() > 0:
		itens.append("LETREIRO")
	if hud.pulso_boss_ligado():
		itens.append("CORACAO BATENDO")
	if reacoes_boneco != null and reacoes_boneco.em_desespero():
		itens.append("DESESPERO")
	if player.em_arena:
		itens.append("ARENA")
	if player.travado:
		itens.append("TRAVADO")
	elif not player.pode_atirar:
		itens.append("SEM TIRO")
	if player.invulneravel:
		itens.append("I-FRAMES")
	if Partida.vidas == 1:
		itens.append("1 VIDA")
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
	reacoes_boneco.parar()
	rastro.parar()
	hud.parar_pulso_boss()
	if coracoes_boss_lab:
		hud.mostrar_coracoes_boss(-1)
	for particula in get_tree().get_nodes_in_group(Particula.GRUPO):
		particula.queue_free()
	if tween_boneco != null:
		tween_boneco.kill()
	if tween_vaivem != null:
		tween_vaivem.kill()
		tween_vaivem = null
	angulo_lab = DADOS_FASE1.inclinacao_graus
	depois_do_meio_lab = DADOS_FASE1.inclinacao_depois_do_meio
	passo_lab = DADOS_FASE1.inclinacao_passo_graus
	inclinacao_lab = null
	boneco.position = posicao_boneco
	for folha in ataques_teste.get_children():
		folha.queue_free()
	resetar_player()
	parar_animacoes_lab()
	resetou.emit()

# Um flash de tela foi barrado pela regra de segurança: avisa no detalhe
func _on_flash_barrado():
	aviso = "FLASH BARRADO: LIMITE DE %d POR SEGUNDO" % e.flashes_tela_por_segundo
	mostrar()

# ---------- linhas dos momentos ----------

# Linha de um momento: título, passos descritos e, se algum passo roda, a ação de tocar
func linha_momento(nome):
	var dados = Momentos.momento(nome)
	var detalhes = detalhes_do(nome)
	if nome == DADOS_FASE1.momento_carga:
		detalhes.append("DURA %s S: O ATAQUE DO CLASSICA1 ATE O QUADRO DE EVENTO" % n(duracao_carga()))
	elif usa_animacao(dados):
		detalhes.append("ANIMACAO NO LAB: %s S (PROVISORIO)" % n(duracao_lab(nome)))
	var acao = Callable()
	if tem_efeito(nome, {}):
		acao = tocar_momento.bind(nome)
	return linha(dados.titulo, detalhes, acao)

# Guarda o momento e tudo o que ele toca (sub-momentos, o seguinte e o momento por letra
# dos letreiros)
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
		elif passo.tipo == Passo.Tipo.LETREIRO and passo.letreiro.momento_por_letra != &"":
			marcar_alcancados(passo.letreiro.momento_por_letra, alcancados)

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
	if nome == DADOS_FASE1.momento_carga:
		return duracao_carga()
	if nome == DADOS_FASE2.momento_carga:
		return DADOS_FASE2.duracao_carga()
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
	if nome == &"coracao_player_perdido":
		perder_vida_lab()
		return
	preparar_coracoes_boss(nome)
	var dados = Momentos.momento(nome)
	var duracao = duracao_lab(nome)
	Momentos.tocar(nome, alvo_demo(nome), duracao)
	for passo in dados.passos:
		if passo.tipo == Passo.Tipo.AFTERIMAGE and passo.pendente == "":
			deslizar_boneco(passo)
	if dados.seguinte != &"" and await esperar(duracao):
		tocar_momento(dados.seguinte)

# Momentos dos corações do boss: o LAB esvazia os corações de verdade antes (o efeito anima
# o primeiro vazio). PERDEU UM CORAÇÃO tira um (cheios de novo ao chegar a 1); ÚLTIMO deixa 1
func preparar_coracoes_boss(nome):
	if nome != &"coracao_boss_perdido" and nome != &"ultimo_coracao":
		return
	if not coracoes_boss_lab:
		coracoes_boss_lab = true
		hud.trocar_coracoes_boss(DADOS_FASE1.coracao_boss)
		hud.mostrar_coracoes_boss(-1)
	if nome == &"ultimo_coracao":
		hud.mostrar_coracoes_boss(1)
		return
	if hud.coracoes_boss_cheios <= 1:
		hud.mostrar_coracoes_boss(-1)
	hud.mostrar_coracoes_boss(hud.coracoes_boss_cheios - 1)

# Coração do player: perde uma vida de verdade pela Partida (a main toca o momento, como no
# jogo); com 1 vida ganha uma antes (o LAB não deixa morrer)
func perder_vida_lab():
	if Partida.vidas <= 1:
		Partida.ganhar_vida()
	Partida.perder_vida()
	aviso = "VIDAS: %d" % Partida.vidas
	mostrar()

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
		Passo.Tipo.LETREIRO:
			return texto_do_letreiro(passo)
	return "PASSO SEM TIPO"

# Texto mostrado ("O LORAX / Guardião...") e o estilo do letreiro
func texto_do_letreiro(passo):
	var conteudo = passo.texto
	if passo.subtitulo != "":
		conteudo += " / " + passo.subtitulo
	if conteudo == "":
		return texto_letreiro(passo.letreiro)
	return "\"%s\" %s" % [conteudo.to_upper(), texto_letreiro(passo.letreiro)]

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
		Passo.Particula.GOTAS_SANGUE:
			texto = "SANGUE %s, %s PX, VIDA %s S" % [n(e.gotas_sangue.x), n(e.gotas_sangue.y), n(e.gotas_sangue_vida)]
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
	if passo.cor != EfeitosDados.Cor.NENHUMA:
		texto += " COR " + nome_da_cor(passo.cor)
	for chave in passo.parametros:
		var valor = passo.parametros[chave]
		if valor is Vector2:
			texto += " %s (%s;%s)" % [maiusculo(chave), n(valor.x), n(valor.y)]
		elif valor is String or valor is StringName:
			texto += " %s %s" % [maiusculo(chave), maiusculo(valor)]
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
		linha("LIMPAR PROJETEIS", ["LEQUE DE %d FOLHAS DO BONECO; %s S DEPOIS VIRAM FAISCA" % [DADOS_FASE1.quantidade, n(LIMPEZA_ESPERA)],
			texto_limpeza()], limpar_leque),
		linha("LIMPAR %d (TETO)" % (TETO_COLUNAS * TETO_LINHAS), ["FOLHAS PARADAS, LIMPAS NA HORA",
			texto_limpeza()], limpar_grade),
	])

# Os números da limpeza (efeitos_boss.tres) e o som dela
func texto_limpeza():
	return "FAISCA %d (%s PX); TETO %d, DEPOIS 1 A CADA %d; SOM PROJETEIS LIMPAM" % [
		e.limpeza_faisca.x, n(e.limpeza_faisca.y), e.limpeza_teto, e.limpeza_faisca_a_cada]

# Solta o leque da fase 1 do boneco e, depois da espera, limpa como a troca de fase
func limpar_leque():
	Projetil.criar_leque(DADOS_FASE1.projetil, DADOS_FASE1.quantidade, DADOS_FASE1.angulo_leque,
			boneco.global_position + DADOS_FASE1.origem_tiro, ataques_teste)
	if not await esperar(LIMPEZA_ESPERA):
		return
	limpar_teste()

# Grade de folhas paradas (mais que o teto) limpa na hora
func limpar_grade():
	var largura = (TETO_COLUNAS - 1) * TETO_ESPACO.x
	var inicio = Vector2(boneco.position.x - largura / 2.0, boneco.position.y + MEIO_BONECO + TETO_ESPACO.y)
	for linha_grade in range(TETO_LINHAS):
		for coluna in range(TETO_COLUNAS):
			var folha = DADOS_FASE1.projetil.instantiate()
			folha.velocidade = 0.0
			folha.position = inicio + Vector2(coluna, linha_grade) * TETO_ESPACO
			ataques_teste.add_child(folha)
	limpar_teste()

# A mesma limpeza da luta, nas folhas do teste; o detalhe diz quantas limpou
func limpar_teste():
	var quantos = LimpezaProjeteis.limpar(ataques_teste, mundo)
	aviso = "LIMPOU %d PROJETEIS" % quantos
	mostrar()

# ---------- combate da fase 1 (F1b) ----------

# Ferramentas da página FASE 1 (2): o ataque inteiro, o vai e vem e a Trúfula do player
func linhas_combate_fase1():
	var leque = "LEQUES %s ALTERNANDO, %s GRAUS, COM RASTRO" % [str(DADOS_FASE1.quantidades), n(DADOS_FASE1.angulo_leque)]
	var postura = "CLASSICA1: ROTACAO %s GRAUS EM %s S" % [
		n(DADOS_FASE1.inclinacao_graus), n(DADOS_FASE1.inclinacao_tempo)]
	return [
		linha("ATAQUE", ["CARGA %s S; NO DISPARO O SOM SOME EM %s S (AMPLITUDE LINEAR, ATE O FIM DO ATAQUE)" % [n(duracao_carga()), n(DADOS_FASE1.duracao_depois_do_disparo())], leque + "; MIRA NO PLAYER ATE %s GRAUS" % n(DADOS_FASE1.mira_max_graus)], atacar_lab),
		linha("VAI E VEM LIGA/DESLIGA", ["VELOCIDADE %s, LIMITES %s A %s" % [n(DADOS_FASE1.velocidade), n(DADOS_FASE1.limite_esq), n(DADOS_FASE1.limite_dir)], postura], alternar_vaivem),
		linha("TRUFULA", ["DA O POWER-UP AO PLAYER: ATIRE NAS FOLHAS (AS DUAS SOMEM)"], func(): player.ativar_powerup(TRUFULA)),
		linha("ANGULO", ["%s GRAUS (SO NO LAB; O R VOLTA AO CLASSICA1)" % " / ".join(ANGULOS_LAB.map(func(a): return n(a)))], trocar_angulo_lab),
		linha("DEPOIS DO MEIO", ["ROTACAO: MANTER O MAXIMO ATE A BORDA / SINO (VOLTA A 0) (SO NO LAB)"], trocar_depois_do_meio_lab),
		linha("PASSO", ["ROTACAO EM PASSOS DE %s GRAUS (0 = CONTINUO) (SO NO LAB)" % " / ".join(PASSOS_LAB.map(func(a): return n(a)))], trocar_passo_lab),
	]

# Duração da carga como na luta: o "ataque" do classica1 até o quadro de evento
func duracao_carga():
	return DADOS_FASE1.duracao_carga()

# Carga no boneco; no disparo o som some até o fim do ataque (como na luta), o disparo toca
# e sai o leque da vez
func atacar_lab():
	var duracao = duracao_carga()
	Momentos.tocar(DADOS_FASE1.momento_carga, boneco, duracao)
	if not await esperar(duracao):
		return
	for passo in Momentos.momento(DADOS_FASE1.momento_carga).passos:
		if passo.tipo == Passo.Tipo.SOM and FaseClassica.CORTAR_SOM_CARGA:
			Sons.cortar(passo.nome, DADOS_FASE1.duracao_depois_do_disparo(), Sons.Curva.LINEAR)
	Momentos.tocar(DADOS_FASE1.momento_disparo, boneco)
	var quantidades = DADOS_FASE1.quantidades
	var quantidade = quantidades[leques_lab % quantidades.size()] if not quantidades.is_empty() else DADOS_FASE1.quantidade
	leques_lab += 1
	var origem = boneco.global_position + DADOS_FASE1.origem_tiro
	var alvo = player.global_position if player.vivo else null
	Projetil.criar_leque(DADOS_FASE1.projetil, quantidade, DADOS_FASE1.angulo_leque,
			origem, ataques_teste, DADOS_FASE1.angulo_da_mira(origem, alvo))

# Liga: o boneco vai e vem entre os limites da fase 1, inclinado para o lado em que anda
# (progressivo, como na luta). Desliga: volta ao meio, de pé
func alternar_vaivem():
	inclinacao_lab = null
	if tween_vaivem != null:
		tween_vaivem.kill()
		tween_vaivem = null
		boneco.position = posicao_boneco
		inclinar_boneco(0)
		return
	x_anterior = boneco.position.x
	sentido_lab = 0
	var tempo_lado = (DADOS_FASE1.limite_dir - DADOS_FASE1.limite_esq) / DADOS_FASE1.velocidade
	tween_vaivem = boneco.create_tween().set_loops()
	tween_vaivem.tween_callback(inclinar_boneco.bind(1))
	tween_vaivem.tween_property(boneco, "position:x", DADOS_FASE1.limite_dir, tempo_lado / 2.0)
	tween_vaivem.tween_callback(inclinar_boneco.bind(-1))
	tween_vaivem.tween_property(boneco, "position:x", DADOS_FASE1.limite_esq, tempo_lado)
	tween_vaivem.tween_callback(inclinar_boneco.bind(1))
	tween_vaivem.tween_property(boneco, "position:x", posicao_boneco.x, tempo_lado / 2.0)

# Alterna o que a rotação do VAI E VEM do LAB faz depois do meio do trajeto (MANTER / SINO)
func trocar_depois_do_meio_lab():
	depois_do_meio_lab = FaseClassicaDados.DepoisDoMeio.SINO if depois_do_meio_lab == FaseClassicaDados.DepoisDoMeio.MANTER else FaseClassicaDados.DepoisDoMeio.MANTER
	inclinacao_lab = null
	aviso = "DEPOIS DO MEIO: %s" % FaseClassicaDados.DepoisDoMeio.keys()[depois_do_meio_lab]
	mostrar()

# Próximo passo da rotação do VAI E VEM do LAB (0 = contínuo)
func trocar_passo_lab():
	passo_lab = PASSOS_LAB[(PASSOS_LAB.find(passo_lab) + 1) % PASSOS_LAB.size()]
	inclinacao_lab = null
	aviso = "PASSO: %s GRAUS" % n(passo_lab)
	mostrar()

# A conta da inclinação progressiva com os números escolhidos no LAB (criada de novo quando mudam)
func inclinacao_do_lab():
	if inclinacao_lab == null:
		inclinacao_lab = InclinacaoVaiEVem.new(DADOS_FASE1)
		inclinacao_lab.graus_max = angulo_lab
		inclinacao_lab.passo = passo_lab
		inclinacao_lab.depois_do_meio = depois_do_meio_lab
		inclinacao_lab.atual = reacoes_boneco.graus
	return inclinacao_lab

# Próximo ângulo da lista (0, 4, 6, 8, 10); com o VAI E VEM desligado, mostra o boneco já inclinado
# para a direita
func trocar_angulo_lab():
	angulo_lab = ANGULOS_LAB[(ANGULOS_LAB.find(angulo_lab) + 1) % ANGULOS_LAB.size()]
	inclinacao_lab = null
	if tween_vaivem == null:
		reacoes_boneco.parar()
		inclinar_boneco(1, true)
	aviso = "ANGULO: %s GRAUS" % n(angulo_lab)
	mostrar()

# Inclina o boneco para 'lado', como a luta faz. Andando, quem gira é a conta
# progressiva (_process); 'fixo' mostra o ângulo parado
func inclinar_boneco(lado, fixo = false):
	if lado == 0 or fixo:
		reacoes_boneco.inclinar(lado * angulo_lab, DADOS_FASE1.inclinacao_tempo)

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

# ---------- player (B4a) ----------

# Ferramentas do player: modo arena, hits e i-frames, 1 vida, travar, tiro e mover_para
func pagina_player():
	var d = player.DADOS
	var arena = "ARENA DE TESTE %dx%d, BASE EM Y %d (PROVISORIO); VELOCIDADE %s; HURTBOX %dx%d; PONTINHO %d PX; SPRITE %dx%d DENTRO" % [
		ARENA_TESTE_LARGURA, ARENA_TESTE_ALTURA, ARENA_TESTE_BASE_Y, n(d.velocidade_arena), d.hurtbox.x, d.hurtbox.y,
		d.pontinho_px, d.caixa_sprite.size.x, d.caixa_sprite.size.y]
	var iframes = "I-FRAMES %s S, PISCA %s S ATE ALFA %s" % [n(d.iframes_duracao), n(d.iframes_pisca), n(d.iframes_alfa)]
	var vida_baixa = "LOW-PASS %s HZ EM %s S; BORDAS ALFA %s PULSANDO %s S; BATIMENTO" % [
		n(e.vida_baixa_abafar_hz), n(e.vida_baixa_abafar_duracao), n(e.vida_baixa_bordas_alfa), n(e.vida_baixa_bordas_pulsar)]
	return nova_pagina("PLAYER", [
		linha("MODO ARENA LIGA/DESLIGA", [arena, "VAI AO CENTRO EM %s S; O CENARIO SOME; W/A/S/D OU SETAS ANDAM EM 8 DIRECOES" % n(MOVER_TESTE_TEMPO)], alternar_arena),
		linha("LEVAR HIT", [iframes, "NA ARENA: MOMENTO PLAYER HIT (TREMOR, HIT-STOP, BORDAS, SOM)"], levar_hit),
		linha("2 HITS SEGUIDOS", ["O 2o HIT VEM %s S DEPOIS: TEM QUE SER IGNORADO" % n(HIT_DUPLO_INTERVALO), iframes], dois_hits),
		linha("1 VIDA LIGA/DESLIGA", [vida_baixa], alternar_vida_baixa),
		linha("TRAVADO LIGA/DESLIGA", ["NAO ANDA NEM ATIRA (DONO LAB)"], alternar_travado),
		linha("TIRO LIGA/DESLIGA", ["ANDA MAS NAO ATIRA (DONO LAB)"], alternar_tiro),
		linha("MOVER PARA", ["VAI AO CENTRO DA ARENA DE TESTE E VOLTA, %s S (PROVISORIO)" % n(MOVER_TESTE_TEMPO)], mover_player),
	])

# A arena de teste, montada pelas constantes do topo
func arena_teste() -> Rect2:
	var tamanho = Vector2(ARENA_TESTE_LARGURA, ARENA_TESTE_ALTURA)
	return Rect2(Vector2(ARENA_TESTE_CENTRO_X - tamanho.x / 2.0, ARENA_TESTE_BASE_Y - tamanho.y), tamanho)

# Liga: o cenário some, o player vai ao centro da arena (mover_para) e entra no modo arena
# ao chegar. Desliga: sai do modo arena, o cenário volta e o player volta para onde estava
func alternar_arena():
	if player.em_arena or player.chegou.is_connected(_on_player_chegou_na_arena):
		if player.chegou.is_connected(_on_player_chegou_na_arena):
			player.chegou.disconnect(_on_player_chegou_na_arena)
		player.sair_arena()
		cenario.mostrar(true)
		contorno_arena.visible = false
		player.mover_para(posicao_original, MOVER_TESTE_TEMPO)
		player_no_centro = false
		return
	guardar_posicao_original()
	cenario.mostrar(false)
	contorno_arena.visible = true
	contorno_arena.queue_redraw()
	player.chegou.connect(_on_player_chegou_na_arena, CONNECT_ONE_SHOT)
	player.mover_para(arena_teste().get_center(), MOVER_TESTE_TEMPO)

# O player chegou ao centro da arena de teste: liga o modo arena
func _on_player_chegou_na_arena():
	player.entrar_arena(arena_teste())

# Guarda onde o player está antes da primeira ação que o tira do lugar
func guardar_posicao_original():
	if posicao_original == null:
		posicao_original = player.global_position

# Um hit no player; com 1 vida, ganha uma antes (o LAB não deixa morrer)
func levar_hit():
	if Partida.vidas <= 1:
		Partida.ganhar_vida()
	player.receber_dano()
	aviso = "VIDAS: %d" % Partida.vidas

# Dois hits seguidos: só o primeiro pode tirar vida
func dois_hits():
	if Partida.vidas <= 2:
		Partida.ganhar_vida()
	var antes = Partida.vidas
	player.receber_dano()
	if not await esperar(HIT_DUPLO_INTERVALO):
		return
	player.receber_dano()
	aviso = "PERDEU %d VIDA(S) (TEM QUE SER 1)" % (antes - Partida.vidas)
	mostrar()

# Vai a 1 vida (perdendo pela Partida) ou volta ao máximo
func alternar_vida_baixa():
	if Partida.vidas > 1:
		while Partida.vidas > 1:
			Partida.perder_vida()
	else:
		while Partida.pode_ganhar_vida():
			Partida.ganhar_vida()

# Pedido do LAB para travar o player
func alternar_travado():
	if player.donos_travando.has(DONO_LAB):
		player.destravar(DONO_LAB)
	else:
		player.travar(DONO_LAB)

# Pedido do LAB para bloquear o tiro
func alternar_tiro():
	if player.donos_sem_tiro.has(DONO_LAB):
		player.liberar_tiro(DONO_LAB)
	else:
		player.bloquear_tiro(DONO_LAB)

# Leva o player ao centro da arena de teste; na próxima vez, de volta para onde estava
func mover_player():
	guardar_posicao_original()
	if player_no_centro:
		player.mover_para(posicao_original, MOVER_TESTE_TEMPO)
	else:
		player.mover_para(arena_teste().get_center(), MOVER_TESTE_TEMPO)
	player_no_centro = not player_no_centro

# Contorno de 1 px da arena de teste
func _desenhar_contorno_arena():
	contorno_arena.draw_rect(arena_teste().grow(-0.5), e.cor_branco, false, 1.0)

# O R: para o mover_para, sai da arena, o cenário volta, o player volta na hora para onde
# estava, solta os pedidos do LAB, corta os i-frames e volta ao máximo de vidas
func resetar_player():
	if player.chegou.is_connected(_on_player_chegou_na_arena):
		player.chegou.disconnect(_on_player_chegou_na_arena)
	player.parar_movimento()
	player.sair_arena()
	cenario.mostrar(true)
	contorno_arena.visible = false
	if posicao_original != null:
		player.global_position = posicao_original
		posicao_original = null
	player.velocity = Vector2.ZERO
	player_no_centro = false
	player.destravar(DONO_LAB)
	player.liberar_tiro(DONO_LAB)
	player.terminar_iframes()
	while Partida.pode_ganhar_vida():
		Partida.ganhar_vida()

# ---------- animações (B4b) ----------

# Lê os conjuntos do gerador (falta algum = erro com o caminho) e monta a lista da página
func carregar_animacoes_lab():
	animacoes_lab = []
	for par in CONJUNTOS_ANIMACAO:
		if not ResourceLoader.exists(par[1]):
			push_error("LAB DE EFEITOS: falta %s (rode o gerador_animacoes.gd)" % par[1])
			continue
		var conjunto = load(par[1])
		for dados in conjunto.animacoes:
			animacoes_lab.append({"rotulo": par[0], "conjunto": conjunto, "dados": dados})

# Página ANIMACOES: 1–3 controlam a animação; embaixo, uma janela da lista com a escolhida
func pagina_animacoes():
	var linhas = [
		linha("TOCAR DE NOVO", [], tocar_animacao_lab),
		linha("PAUSAR/CONTINUAR", [], pausar_animacao_lab),
		linha("AVANCAR 1 QUADRO", [], avancar_quadro_lab),
	]
	if animacoes_lab.is_empty():
		linhas.append(linha("RODE O GERADOR DE ANIMACOES", []))
		return nova_pagina("ANIMACOES", linhas)
	var meio = floori(JANELA_ANIMACOES / 2.0)
	var inicio = clampi(escolhida - meio, 0, maxi(animacoes_lab.size() - JANELA_ANIMACOES, 0))
	for i in range(inicio, mini(inicio + JANELA_ANIMACOES, animacoes_lab.size())):
		var marca = "> " if i == escolhida else "  "
		linhas.append(linha(marca + nome_animacao_lab(animacoes_lab[i]), []))
	return nova_pagina("ANIMACOES", linhas)

# "UI1 MAO DIR": rótulo do conjunto + nome da animação
func nome_animacao_lab(item):
	return item["rotulo"] + " " + item["dados"].nome.replace("_", " ").to_upper()

# A animação de 'nome' no conjunto de 'rotulo' (null se não existe)
func item_lab(rotulo, nome):
	for item in animacoes_lab:
		if item["rotulo"] == rotulo and item["dados"].nome == nome:
			return item
	return null

# A página da vez é a ANIMACOES
func na_pagina_animacoes():
	return pagina == pagina_animacoes_indice

# Pilar e pilar alto tocam sempre juntos (o alto atrás do corpo)
func eh_pilar(item):
	return item["dados"].nome in ["pilar", "pilar_alto"]

# Setas cima/baixo trocam a animação (só na página ANIMACOES; segurar repete)
func _unhandled_input(event):
	if na_pagina_animacoes() and event is InputEventKey and event.pressed \
			and event.physical_keycode in [KEY_UP, KEY_DOWN]:
		escolher_animacao(1 if event.physical_keycode == KEY_DOWN else -1)
		get_viewport().set_input_as_handled()
		return
	super(event)

# Entrar na página mostra o corpo tocando a escolhida; sair devolve o boneco da fase 1
func trocar_pagina(passo):
	parar_animacoes_lab()
	super(passo)
	if na_pagina_animacoes():
		tocar_animacao_lab()

# Na página ANIMACOES o detalhe é o estado da animação
func mostrar():
	super()
	if na_pagina_animacoes():
		texto_detalhe.text = texto_animacao_lab()
		ajustar_detalhe()

# O detalhe da página ANIMACOES acompanha o quadro a cada frame; com o VAI E VEM ligado,
# o boneco gira pela conta progressiva (o sentido sai do movimento dele)
func _process(delta):
	super(delta)
	if tween_vaivem != null:
		var dx = boneco.position.x - x_anterior
		if dx != 0:
			sentido_lab = 1 if dx > 0 else -1
		x_anterior = boneco.position.x
		reacoes_boneco.definir_inclinacao(inclinacao_do_lab().atualizar(boneco.position.x, sentido_lab, delta))
	if na_pagina_animacoes() and corpo != null and corpo.visible:
		texto_detalhe.text = texto_animacao_lab()
		ajustar_detalhe()

# Anda na lista (dá a volta) e já toca a nova
func escolher_animacao(passo):
	if animacoes_lab.is_empty():
		return
	escolhida = (escolhida + passo + animacoes_lab.size()) % animacoes_lab.size()
	tocar_animacao_lab()

# O corpo de verdade (lorax_final.tscn) no lugar do boneco: invulnerável, sem colisão e fora
# do grupo aliens. O pilar alto de teste é o primeiro filho dele (desenhado atrás do Sprite2D)
func criar_corpo_lab():
	corpo = CENA_CORPO.instantiate()
	corpo.remove_from_group(&"aliens")
	corpo.collision_layer = 0
	corpo.collision_mask = 0
	corpo.position = posicao_boneco
	corpo.visible = false
	corpo.evento_animacao.connect(_on_evento_animacao_lab)
	pilar_teste = Node2D.new()
	pilar_teste.position = POSICAO_PILAR_ALTO
	pilar_teste.visible = false
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	pilar_teste.add_child(sprite)
	anim_pilar = AnimationPlayer.new()
	pilar_teste.add_child(anim_pilar)
	corpo.add_child(pilar_teste)
	corpo.move_child(pilar_teste, 0)
	mundo.add_child(corpo)
	corpo.ficar_invulneravel(true)
	anim_corpo = corpo.get_node("AnimationPlayer")

# Toca a escolhida do começo no corpo (pilar e pilar alto tocam juntos)
func tocar_animacao_lab():
	if animacoes_lab.is_empty():
		return
	if corpo == null:
		criar_corpo_lab()
	var item = animacoes_lab[escolhida]
	boneco.visible = false
	corpo.visible = true
	animacao_pausada = false
	aviso = ""
	anim_pilar.stop()
	pilar_teste.visible = false
	if eh_pilar(item):
		tocar_no_corpo(item_lab("CENA", "pilar"))
		tocar_no_pilar(item_lab("PILAR", "pilar_alto"))
	else:
		tocar_no_corpo(item)
	paginas[pagina_animacoes_indice] = pagina_animacoes()
	mostrar()

# Carrega no corpo o conjunto da animação (se ainda não está) e toca do começo
func tocar_no_corpo(item):
	if item == null:
		return
	if conjunto_no_corpo != item["conjunto"]:
		corpo.carregar_animacoes(item["conjunto"].animacoes)
		conjunto_no_corpo = item["conjunto"]
	anim_corpo.stop()
	anim_corpo.play(item["dados"].nome)

# O pilar alto tem nó próprio: toca junto com o corpo, atrás dele
func tocar_no_pilar(item):
	if item == null:
		return
	var biblioteca = AnimationLibrary.new()
	biblioteca.add_animation(item["dados"].nome, item["dados"].criar_animacao())
	if anim_pilar.has_animation_library(""):
		anim_pilar.remove_animation_library("")
	anim_pilar.add_animation_library("", biblioteca)
	pilar_teste.visible = true
	anim_pilar.play(item["dados"].nome)

# Os AnimationPlayers do LAB que estão em uso (o do pilar alto só com ele visível)
func players_lab():
	return [anim_corpo, anim_pilar] if pilar_teste.visible else [anim_corpo]

# O AnimationPlayer que toca a escolhida (o do pilar alto, se for ela)
func player_da_escolhida():
	return anim_pilar if animacoes_lab[escolhida]["dados"].nome == "pilar_alto" else anim_corpo

# Pausa ou continua o corpo (e o pilar alto junto)
func pausar_animacao_lab():
	if corpo == null or not corpo.visible:
		return
	animacao_pausada = not animacao_pausada
	for anim in players_lab():
		if animacao_pausada:
			anim.pause()
		else:
			anim.play()

# Pausa e vai para o quadro seguinte da escolhida (do último volta ao primeiro)
func avancar_quadro_lab():
	if corpo == null or not corpo.visible:
		return
	if not animacao_pausada:
		pausar_animacao_lab()
	var dados = animacoes_lab[escolhida]["dados"]
	var proximo = (quadro_atual(dados, player_da_escolhida()) + 1) % dados.quadros_tocados().size()
	var instante = dados.instante_do_quadro(proximo) + FOLGA_QUADRO
	for anim in players_lab():
		anim.seek(instante, true)

# Posição (a partir de 0) do quadro em que a animação está
func quadro_atual(dados, anim):
	if anim.assigned_animation == &"":
		return 0
	var posicao = anim.current_animation_position + FOLGA_QUADRO
	for i in range(dados.quadros_tocados().size() - 1, -1, -1):
		if posicao >= dados.instante_do_quadro(i):
			return i
	return 0

# O corpo passou pelo quadro de evento: avisa no detalhe
func _on_evento_animacao_lab(nome):
	aviso = "EVENTO! (%s)" % String(nome).to_upper()

# Nome, quadro, tempo, loop e evento da escolhida, e o aviso do último evento
func texto_animacao_lab():
	if animacoes_lab.is_empty():
		return "NENHUMA ANIMACAO: RODE O GERADOR (FILE > RUN) E ABRA O LAB DE NOVO"
	var item = animacoes_lab[escolhida]
	var dados = item["dados"]
	var linhas = ["%d/%d %s" % [escolhida + 1, animacoes_lab.size(), nome_animacao_lab(item)]]
	if corpo == null or not corpo.visible:
		linhas.append("APERTE 1 PARA TOCAR; CIMA/BAIXO TROCA")
		return "\n".join(linhas)
	var lista = dados.quadros_tocados()
	var i = quadro_atual(dados, player_da_escolhida())
	var quadro = "QUADRO %d (0 A %d), %s S" % [i, lista.size() - 1, n(dados.tempo_do_quadro(i))]
	if i == dados.quadro_evento:
		quadro += " << EVENTO"
	linhas.append(quadro)
	linhas.append("ASEPRITE %d; LOOP %s; DURACAO %s S" % [lista[i] + 1, "SIM" if dados.repetir else "NAO", n(dados.duracao())])
	if dados.quadro_evento >= 0:
		var sugestao = " (SUGESTAO)" if item["rotulo"] in ROTULOS_SUGESTAO else ""
		linhas.append("EVENTO NO QUADRO %d%s" % [dados.quadro_evento, sugestao])
	else:
		linhas.append("SEM EVENTO")
	if animacao_pausada:
		linhas.append("PAUSADO")
	if eh_pilar(item):
		linhas.append("PILAR E PILAR ALTO TOCAM JUNTOS")
	if player.em_arena:
		linhas.append("MODO ARENA: CIMA/BAIXO TAMBEM ANDAM COM O PLAYER")
	if aviso != "":
		linhas.append(aviso)
	return "\n".join(linhas)

# Para o corpo e o pilar alto de teste e devolve o boneco da fase 1
func parar_animacoes_lab():
	animacao_pausada = false
	if corpo != null:
		anim_corpo.stop()
		anim_pilar.stop()
		corpo.visible = false
		pilar_teste.visible = false
	boneco.visible = true
