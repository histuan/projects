# LAB DE TEXTOS (opção do cheat): mostra cada letreiro e cada fala da boss fight como a luta
# mostra (os momentos do momentos_boss.tres que têm letreiro, o FINAL WAVE com o alarme, como a
# main faz na wave 10, e as falas do falas_boss.tres na caixa de diálogo). A "FASE SIMULADA"
# troca a fase da luta na Partida para testar o retrato AUTO. Teclas e layout: PainelLab;
# o H esconde o painel para ver o texto; Espaço (shoot) avança a fala.
extends PainelLab

const LETREIRO_FINAL_WAVE = preload("res://recursos/boss/letreiros/final_wave.tres")
# Momentos com letreiro, na ordem das teclas (depois do FINAL WAVE)
const LETREIROS = [&"nome_do_boss", &"titulo_fase3", &"finish_him", &"dica_ws", &"contagem"]
const FALAS = preload("res://recursos/boss/falas_boss.tres")
# Linhas por página (uma por tecla)
const LINHAS_POR_PAGINA = 10

var hud
var caixa: CaixaDialogo

# Recebe da main a hud (onde os letreiros aparecem) e a caixa de diálogo e monta as páginas
func preparar(nova_hud, nova_caixa):
	hud = nova_hud
	caixa = nova_caixa
	dica = "APERTE 1-0 PARA MOSTRAR UM TEXTO; H ESCONDE O PAINEL; ESPACO AVANCA A FALA"
	Momentos.validar_todos()
	iniciar()

# Página dos letreiros (o FINAL WAVE e os momentos com letreiro) e as das falas (a primeira
# linha troca a fase simulada)
func montar_paginas():
	var linhas = [linha("FINAL WAVE", ["TOCA O ALARME E MOSTRA COMO NA WAVE 10", texto_letreiro(LETREIRO_FINAL_WAVE)], mostrar_final_wave)]
	for nome in LETREIROS:
		linhas.append(linha_momento(nome))
	var lista = [nova_pagina("LETREIROS", linhas)]
	var falas = [linha("FASE SIMULADA: 1 / 2 / 3", ["TROCA A FASE DA LUTA (PARTIDA.FASE_LUTA) PARA TESTAR O RETRATO AUTO", "FORA DA LUTA (0) O AUTO USA A FASE 1"], trocar_fase)]
	for nome in FALAS.falas:
		falas.append(linha_fala(nome))
	for inicio in range(0, falas.size(), LINHAS_POR_PAGINA):
		var titulo = "FALAS" if inicio == 0 else "FALAS %d" % (inicio / LINHAS_POR_PAGINA + 1)
		lista.append(nova_pagina(titulo, falas.slice(inicio, inicio + LINHAS_POR_PAGINA)))
	return lista

# Letreiros na tela, fase simulada (com o retrato que o AUTO usa) e a caixa
func estado_ligado():
	var auto = Fala.Personagem.keys()[{2: Fala.Personagem.FASE2, 3: Fala.Personagem.INSTINTO}.get(Partida.fase_luta, Fala.Personagem.FASE1)]
	var texto = "LETREIROS: %d  FASE: %d (AUTO = %s)" % [hud.letreiros_na_tela(), Partida.fase_luta, auto]
	if caixa.aberta:
		texto += "  CAIXA ABERTA"
	return texto

# Apaga letreiros, momentos agendados, a caixa, sons e o tempo do jogo (a fase simulada fica)
func ao_resetar():
	Momentos.parar_tudo()
	caixa.fechar()
	Sons.parar_tudo()
	TempoJogo.limpar()

# Próxima fase simulada: 1 → 2 → 3 → 1
func trocar_fase():
	Partida.definir_fase_luta(Partida.fase_luta % 3 + 1)

# Linha de uma fala: texto, quem fala, expressão, voz e a seguinte
func linha_fala(nome):
	var fala = FALAS.falas[nome]
	var detalhes = ["\"%s\"" % fala.texto.to_upper(), "PERSONAGEM " + Fala.Personagem.keys()[fala.personagem],
		"EXPRESSAO " + Fala.Expressao.keys()[fala.expressao],
		"VOZ " + (String(fala.voz).replace("_", " ").to_upper() if fala.voz != &"" else "NENHUMA")]
	if fala.seguinte != &"":
		detalhes.append("DEPOIS: " + String(fala.seguinte).replace("_", " ").to_upper())
	return linha(String(nome).replace("_", " ").to_upper(), detalhes, caixa.falar.bind(nome))

# Linha de um momento: os passos dele e, se algum roda, a ação de tocar
func linha_momento(nome):
	var dados = Momentos.momento(nome)
	var detalhes = []
	var roda = false
	for passo in dados.passos:
		var texto = Passo.Tipo.keys()[passo.tipo]
		if passo.tipo == Passo.Tipo.LETREIRO:
			texto = texto_letreiro(passo.letreiro)
			if passo.texto != "":
				var conteudo = passo.texto + (" / " + passo.subtitulo if passo.subtitulo != "" else "")
				texto = "\"%s\" %s" % [conteudo.to_upper(), texto]
		elif passo.tipo == Passo.Tipo.SOM:
			texto = "SOM " + String(passo.nome).replace("_", " ").to_upper()
		if passo.pendente != "":
			texto += ": " + passo.pendente
		else:
			roda = true
		detalhes.append(texto)
	var acao = Momentos.tocar.bind(nome) if roda else Callable()
	return linha(dados.titulo, detalhes, acao)

# O FINAL WAVE como a main mostra na wave 10: o alarme toca e o letreiro pisca enquanto ele dura
func mostrar_final_wave():
	hud.esconder_letreiro_wave()
	var alarme = Sons.tocar(&"wave_boss_alarme")
	var duracao_alarme = 0.0
	if alarme != null:
		duracao_alarme = alarme.stream.get_length() / alarme.pitch_scale
	hud.mostrar_letreiro(LETREIRO_FINAL_WAVE, "", "", duracao_alarme)
