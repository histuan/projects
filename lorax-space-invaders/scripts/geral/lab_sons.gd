# LAB DE SONS (opção do cheat): toca cada evento do sons_boss.tres, mostra se os arquivos
# dele existem (OK/FALTA) e testa a música (crossfade, troca sincronizada, fade, corte, abafar).
# Teclas e layout: PainelLab. Evento com arquivo faltando fica só para consulta (marcado X).
extends PainelLab

const BIBLIOTECA = preload("res://recursos/boss/sons_boss.tres")
# Encurta os caminhos no detalhe
const PASTA_SONS = "res://efeitos sonoros reais/"
# Grupos da parte 3 do sons_boss_fight.txt, sem as músicas (elas ficam na página MÚSICA)
const GRUPOS = [
	["WAVE 10", [&"wave_boss_alarme"]],
	["LORAX 2.0", [&"lorax2_chegada", &"lorax2_pouso", &"lorax2_arremesso", &"folha_voando",
		&"folha_acerta", &"folhas_anulam", &"lorax2_dano", &"boss_coracao_perdido",
		&"boss_coracoes_reenchem", &"lorax2_carga", &"lorax2_invocar", &"marcador_arvore",
		&"arvore_explode", &"lorax2_raiva", &"lorax2_derrota", &"projeteis_limpam"]],
	["TRANSFORMAÇÃO", [&"transf_respira", &"transf_raiva_pulso", &"transf_despertar",
		&"transf_aura_pilar", &"transf_varredura", &"transf_reparo", &"transf_chapeu",
		&"transf_piscada", &"puxao", &"estrelas_warp", &"arena_criando", &"arena_pronta",
		&"escurecer", &"vidas_reenchem"]],
	["DIÁLOGO", [&"fala_lorax", &"fala_lorax_serio", &"fala_avancar", &"fala_caixa_abre",
		&"lorax_fuga_fala"]],
	["FASE 3", [&"aviso", &"raio", &"raio_carga", &"raio_disparo", &"mao_brilho",
		&"folhas_chuva", &"pancada", &"onda_choque", &"orbe_lanca", &"orbe_quica",
		&"esfera_carga", &"esfera_estoura", &"teleporte", &"esquiva", &"janela_abre",
		&"arena_redimensiona", &"arena_treme", &"lorax_ui_dano", &"graze", &"virada_fase",
		&"desespero", &"player_hit_arena"]],
	["DESFECHO", [&"finish_him", &"finish_letra", &"finalizar_golpe", &"finalizar_rachar",
		&"finalizar_desfazer", &"poluicao", &"semente", &"semente_coletada", &"vinhas_fecham",
		&"fumaca_cobre", &"reflorestar", &"luz_desfaz", &"estrelas_apagam", &"estrelas_acendem",
		&"constelacao", &"pontos_contagem", &"arvores_salvas_bom", &"arvores_salvas_ruim"]],
	["INTERFACE", [&"titulo_boss", &"lorax_fuga", &"cheat_abre", &"menu_navega",
		&"menu_escolhe", &"batimento_vida_baixa", &"ultimo_coracao_pulso", &"estrela_cadente"]],
]
const MUSICAS = [&"musica_wave10", &"musica_transformacao", &"musica_fase3a", &"musica_fase3b",
	&"musica_final_bom", &"musica_final_ruim"]
# Sem valor no documento (decididos na F3 e na F5): o LAB testa com estes, marcados TESTE
const TESTE_CROSSFADE = 1.0
const TESTE_FADE = 1.0
# Pedidos de abafar feitos pelo LAB
const ABAFAR_DESPERTAR = &"lab_despertar"
const ABAFAR_VIDA_BAIXA = &"lab_vida_baixa"

# Quantos arquivos diferentes (de todos os eventos) não existem na pasta
var faltando_total = 0
var abafar_ligados = {}

# Texto antes do primeiro som
func _init():
	dica = "APERTE 1-0 PARA TOCAR UM SOM"

# Uma página por grupo (dividida de 10 em 10), OUTROS com o que não está em grupo e MÚSICA
func montar_paginas():
	faltando_total = contar_faltando()
	var lista = []
	var agrupados = MUSICAS.duplicate()
	for grupo in GRUPOS:
		agrupados.append_array(grupo[1])
		lista.append_array(paginas_do_grupo(grupo[0], grupo[1]))
	var outros = []
	for evento in BIBLIOTECA.eventos:
		if not (evento in agrupados):
			outros.append(evento)
	lista.append_array(paginas_do_grupo("OUTROS", outros))
	lista.append(pagina_musica())
	return lista

# Páginas de um grupo, até 10 eventos cada ("FASE 3", "FASE 3 (2)", ...)
func paginas_do_grupo(titulo, eventos):
	var lista = []
	var numero = 0
	for inicio in range(0, eventos.size(), TECLAS.size()):
		var linhas = []
		for evento in eventos.slice(inicio, inicio + TECLAS.size()):
			linhas.append(linha_evento(evento))
		numero += 1
		lista.append(nova_pagina(titulo if numero == 1 else "%s (%d)" % [titulo, numero], linhas))
	return lista

# Linha de um evento: toca se todos os arquivos existem; senão, X e só consulta
func linha_evento(evento):
	var nome = String(evento).to_upper()
	var dados = BIBLIOTECA.eventos.get(evento)
	if dados == null:
		return linha(nome + " X", ["NAO EXISTE NO SONS_BOSS.TRES"])
	if not arquivos_faltando(dados).is_empty():
		return linha(nome + " X", detalhes_do(dados))
	return linha(nome, detalhes_do(dados), tocar_evento.bind(evento))

# Toca o evento; loop liga/desliga; com deslize, o pitch desliza pela duração do som
func tocar_evento(evento):
	var dados = BIBLIOTECA.eventos[evento]
	if dados.loop and Sons.em_loop(evento):
		Sons.parar(evento)
		aviso = "LOOP PARADO"
		return
	var player = Sons.tocar(evento)
	if dados.pitch_final > 0 and player != null:
		Sons.deslizar_pitch(player, dados.pitch_final, player.stream.get_length() / player.pitch_scale)
		aviso = "DESLIZE NA DURACAO DO SOM (TESTE: NO JOGO QUEM TOCA DECIDE)"

# Página MÚSICA: cada música, a troca da fase 3, fade, corte e os dois abafar
func pagina_musica():
	return nova_pagina("MUSICA", [
		linha_musica(&"musica_wave10"),
		linha_musica(&"musica_transformacao"),
		linha_musica(&"musica_fase3a"),
		linha_troca_fase3(),
		linha_musica(&"musica_final_bom"),
		linha_musica(&"musica_final_ruim"),
		linha("FADE OUT", ["%s S (TESTE)" % n(TESTE_FADE)], Musica.fade_out.bind(TESTE_FADE)),
		linha("CORTAR", ["SECO, SEM FADE (GOLPE FINAL)"], Musica.cortar),
		linha("ABAFAR DESPERTAR", ["LIGA/DESLIGA", "%s HZ EM %s S" % [n(BIBLIOTECA.abafar_despertar_hz), n(BIBLIOTECA.abafar_despertar_duracao)], "DESTAMPA EM %s S" % n(BIBLIOTECA.destampar_duracao)],
			alternar_abafar.bind(ABAFAR_DESPERTAR, BIBLIOTECA.abafar_despertar_hz, BIBLIOTECA.abafar_despertar_duracao)),
		linha("ABAFAR VIDA BAIXA", ["LIGA/DESLIGA", "%s HZ" % n(BIBLIOTECA.abafar_vida_baixa_hz), "DESTAMPA EM %s S" % n(BIBLIOTECA.destampar_duracao)],
			alternar_abafar.bind(ABAFAR_VIDA_BAIXA, BIBLIOTECA.abafar_vida_baixa_hz, 0.0)),
	])

# Uma música: entra com o crossfade do evento
func linha_musica(evento):
	var linha_base = linha_evento(evento)
	if linha_base["acao"].is_valid():
		linha_base["acao"] = Musica.tocar.bind(evento)
	return linha_base

# Fase 3: final_fight2 entra na posição da final_fight1 menos o recuo
func linha_troca_fase3():
	var linha_base = linha_evento(&"musica_fase3b")
	linha_base["nome"] = linha_base["nome"].replace("MUSICA_FASE3B", "FASE3A -> FASE3B")
	linha_base["detalhes"] = ["TOQUE A MUSICA_FASE3A ANTES", "RECUO %s S" % n(BIBLIOTECA.recuo_troca_fase3), "CROSSFADE %s S (TESTE)" % n(TESTE_CROSSFADE)] + linha_base["detalhes"]
	if linha_base["acao"].is_valid():
		linha_base["acao"] = Musica.trocar_sincronizado.bind(&"musica_fase3b", BIBLIOTECA.recuo_troca_fase3, TESTE_CROSSFADE)
	return linha_base

# Liga/desliga um pedido de abafar a música
func alternar_abafar(nome, hz, duracao):
	if abafar_ligados.has(nome):
		abafar_ligados.erase(nome)
		Musica.liberar_abafar(nome, BIBLIOTECA.destampar_duracao)
	else:
		abafar_ligados[nome] = true
		Musica.pedir_abafar(nome, hz, duracao)

# Detalhe de um evento: arquivos (OK/FALTA e ganho), pitch, volume, bus e o resto
func detalhes_do(dados):
	var partes = []
	for caminho in dados.arquivos:
		partes.append("%s %s (GANHO %s)" % [curto(caminho), "OK" if ResourceLoader.exists(caminho) else "FALTA", n(BIBLIOTECA.ganhos.get(caminho, 0.0))])
	var pitch = "PITCH " + n(dados.pitch)
	if dados.pitch_aleatorio > 1.0:
		pitch += " +-%s%%" % n((dados.pitch_aleatorio - 1.0) * 100.0)
	if dados.pitch_final > 0:
		pitch += " -> " + n(dados.pitch_final)
	partes.append(pitch)
	partes.append("VOL %s DB" % n(dados.volume_db))
	partes.append("BUS " + String(dados.bus).to_upper())
	if dados.atraso > 0:
		partes.append("ATRASO %s S" % n(dados.atraso))
	if dados.loop:
		partes.append("LOOP (DE NOVO PARA PARAR)")
	if dados.crossfade > 0:
		partes.append("CROSSFADE %s S" % n(dados.crossfade))
	for camada in dados.camadas:
		partes.append("CAMADA: " + ", ".join(detalhes_do(camada)))
	return partes

# Caminho sem a pasta dos sons, em maiúsculas
func curto(caminho):
	return caminho.trim_prefix(PASTA_SONS).to_upper()

# Arquivos do evento e das camadas dele que não existem
func arquivos_faltando(dados):
	var lista = []
	for caminho in dados.arquivos:
		if not ResourceLoader.exists(caminho):
			lista.append(caminho)
	for camada in dados.camadas:
		lista.append_array(arquivos_faltando(camada))
	return lista

# Quantos arquivos diferentes faltam em toda a biblioteca
func contar_faltando():
	var caminhos = {}
	for dados in BIBLIOTECA.eventos.values():
		for caminho in arquivos_faltando(dados):
			caminhos[caminho] = true
	return caminhos.size()

# Rodapé: arquivos que faltam, abafar ligado e o que está tocando
func estado_ligado():
	var topo = "FALTAM %d ARQUIVOS" % faltando_total
	if not abafar_ligados.is_empty():
		topo += "  ABAFADA"
	var tocando = PackedStringArray()
	for evento in Sons.eventos_tocando():
		var nome = String(evento).to_upper()
		if not (nome in tocando):
			tocando.append(nome)
	var musica = Musica.nome_atual()
	if musica != "":
		tocando.append("MUSICA " + musica.to_upper())
	if tocando.is_empty():
		return topo + "\nTOCANDO: NADA"
	return topo + "\nTOCANDO: " + ", ".join(tocando)

# Para todos os sons e a música e destampa
func ao_resetar():
	Sons.parar_tudo()
	Musica.cortar()
	for nome in abafar_ligados:
		Musica.liberar_abafar(nome)
	abafar_ligados.clear()
