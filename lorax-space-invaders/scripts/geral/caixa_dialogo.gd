# Caixa de diálogo (montada por código): retrato do personagem à esquerda e o texto da
# Fala aparecendo letra por letra, com voz e pausa nos "...". A seta ▼ aparece quando o
# texto acaba. 'shoot' completa o texto; com ele completo, avança para o 'seguinte' (ou
# fecha). A música abaixa enquanto a caixa está aberta.
# Camada 8: acima do letterbox (7) e abaixo do Pause (10). Pausa junto com o jogo e conta o
# tempo real (hit-stop e câmera lenta não seguram o texto).
class_name CaixaDialogo
extends CanvasLayer

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
const DADOS = preload("res://recursos/boss/caixa_dialogo.tres")
const FALAS = preload("res://recursos/boss/falas_boss.tres")
const LAYER_CAIXA = 8
# Pedido de música abaixada feito pela caixa
const PEDIDO_MUSICA = &"fala"
# Tamanho da seta ▼ (px de largura; a altura é a metade)
const SETA_PX = 6
const COR_FUNDO = Color.BLACK
const COR_BORDA = Color.WHITE

# A conversa que começou em 'nome' terminou (a caixa fechou)
signal terminou(nome)
# Abriu uma conversa / fechou (o Pause, que só mostra a fala, não conta): a main trava o
# tiro do player enquanto a conversa está aberta
signal abriu
signal fechou

var caixa: Control
var retrato: Sprite2D
var texto: RichTextLabel
var seta: Control

var aberta = false
# Mostrando a fala inteira e parada (Pause): sem voz e sem avançar
var so_mostrando = false
var digitando = false
var fala_atual: Fala = null
var nome_conversa = &""
# Segundos até a próxima letra
var espera = 0.0
var ultimo_tick = 0
# Letras por segundo da fala atual (a dela ou a da caixa)
var ritmo = 0.0
# Multiplicadores do ritmo: da frase inteira (longa = mais rápida) e da palavra (rajada)
var mult_frase = 1.0
var mult_palavra = 1.0
# Momento (ms) do último som da voz
var ultima_voz = -100000
# Segundos até a boca trocar (aberta/fechada) e se ela está aberta agora
var espera_boca = 0.0
var boca_aberta = false
var tween_seta: Tween = null
var seta_y = 0.0

# Monta a caixa (escondida) colada no fim da tela
func _ready():
	layer = LAYER_CAIXA
	var tela = get_viewport().get_visible_rect().size
	var altura = DADOS.espaco_retrato + 2 * DADOS.margem
	caixa = Control.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.position = Vector2(DADOS.distancia_tela, tela.y - DADOS.distancia_tela - altura)
	caixa.size = Vector2(tela.x - 2 * DADOS.distancia_tela, altura)
	caixa.draw.connect(_desenhar_caixa)
	add_child(caixa)
	retrato = Sprite2D.new()
	retrato.position = Vector2(DADOS.margem, DADOS.margem) + Vector2.ONE * DADOS.espaco_retrato / 2.0
	caixa.add_child(retrato)
	texto = RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.scroll_active = false
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.add_theme_font_override("normal_font", FONTE)
	texto.add_theme_font_size_override("normal_font_size", DADOS.tamanho_fonte)
	texto.add_theme_constant_override("line_separation", 0)
	var esquerda = DADOS.margem * 2 + DADOS.espaco_retrato
	texto.position = Vector2(esquerda, DADOS.margem)
	texto.size = Vector2(caixa.size.x - esquerda - DADOS.margem, caixa.size.y - 2 * DADOS.margem)
	caixa.add_child(texto)
	seta = Control.new()
	seta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seta.size = Vector2(SETA_PX, SETA_PX / 2.0)
	seta.position = caixa.size - Vector2(DADOS.margem + SETA_PX, DADOS.margem + SETA_PX / 2.0)
	seta.draw.connect(_desenhar_seta)
	caixa.add_child(seta)
	seta_y = seta.position.y
	visible = false

# Abre a caixa na fala 'nome' e segue a conversa até o fim (emite 'terminou')
func falar(nome: StringName):
	var fala = fala_de(nome)
	if fala == null:
		return
	if not aberta:
		Sons.tocar(&"fala_caixa_abre")
		Musica.pedir_abaixar(PEDIDO_MUSICA, DADOS.musica_abaixa_db, DADOS.musica_abaixa_entrada)
		abriu.emit()
	aberta = true
	so_mostrando = false
	nome_conversa = nome
	visible = true
	comecar(fala, true)

# Mostra a fala inteira, parada, sem voz e sem avançar (o Pause usa)
func mostrar_inteira(nome: StringName):
	var fala = fala_de(nome)
	if fala == null:
		return
	aberta = true
	so_mostrando = true
	visible = true
	comecar(fala, false)

# Fecha na hora (o R do LAB, o Pause ao continuar). A música volta se a caixa a abaixou
func fechar():
	var era_conversa = aberta and not so_mostrando
	if era_conversa:
		Musica.liberar_abaixar(PEDIDO_MUSICA, DADOS.musica_abaixa_saida)
	aberta = false
	parar_voz()
	digitando = false
	mostrar_seta(false)
	visible = false
	if era_conversa:
		fechou.emit()

# A Fala pelo nome (erro se ela não existe no falas_boss.tres)
func fala_de(nome):
	var fala = FALAS.falas.get(nome)
	if fala == null:
		push_error("CaixaDialogo: fala desconhecida '%s'" % nome)
	return fala

# Põe a fala na caixa: retrato, texto e (digitando) a máquina de escrever do começo
func comecar(fala, digitar):
	parar_voz()
	fala_atual = fala
	texto.text = fala.texto
	texto.add_theme_font_size_override("normal_font_size", fala.tamanho_fonte if fala.tamanho_fonte > 0 else DADOS.tamanho_fonte)
	ritmo = fala.letras_por_segundo if fala.letras_por_segundo > 0 else DADOS.letras_por_segundo
	if digitar and ritmo <= 0:
		push_error("CaixaDialogo: letras_por_segundo = 0 (caixa_dialogo.tres)")
		digitar = false
	digitando = digitar
	texto.visible_characters = 0 if digitar else -1
	espera = 0.0
	mult_frase = velocidade_da_frase(texto.get_parsed_text())
	mult_palavra = 1.0
	espera_boca = DADOS.boca_intervalo
	ultimo_tick = Time.get_ticks_msec()
	boca_aberta = digitar
	mostrar_retrato(boca_aberta)
	mostrar_seta(not digitar)

# Quadro do retrato: a folha do personagem, a expressão (a primeira, se a folha não tem
# aquela) e +1 enquanto fala. Quadro quadrado com lado = altura da folha
func mostrar_retrato(falando):
	var folha = folha_do(fala_atual.personagem)
	retrato.texture = folha
	if folha == null:
		push_error("CaixaDialogo: sem folha de retrato para %s" % Fala.Personagem.keys()[fala_atual.personagem])
		return
	var lado = folha.get_height()
	retrato.hframes = folha.get_width() / lado
	var expressoes = folha.get_width() / (2 * lado)
	var expressao = fala_atual.expressao if fala_atual.expressao < expressoes else 0
	retrato.frame = expressao * 2 + (1 if falando else 0)

# A folha de retratos de quem fala. AUTO = o Lorax da fase atual da luta (fora dela, a fase 1)
func folha_do(personagem):
	if personagem == Fala.Personagem.AUTO:
		match Partida.fase_luta:
			2:
				personagem = Fala.Personagem.FASE2
			3:
				personagem = Fala.Personagem.INSTINTO
			_:
				personagem = Fala.Personagem.FASE1
	match personagem:
		Fala.Personagem.LORAX_ANTIGO:
			return DADOS.retrato_lorax_antigo
		Fala.Personagem.FASE1:
			return DADOS.retrato_fase1
		Fala.Personagem.FASE2:
			return DADOS.retrato_fase2
		Fala.Personagem.INSTINTO:
			return DADOS.retrato_instinto
	return null

# Ao sair do Pause, recomeça o relógio real (senão o texto pularia o tempo pausado)
func _notification(what):
	if what == NOTIFICATION_UNPAUSED:
		ultimo_tick = Time.get_ticks_msec()

# Máquina de escrever em tempo real: solta as letras que já deviam ter aparecido
func _process(_delta):
	if not digitando:
		return
	var agora = Time.get_ticks_msec()
	var passado = (agora - ultimo_tick) / 1000.0
	ultimo_tick = agora
	mexer_boca(passado)
	espera -= passado
	while digitando and espera <= 0:
		proxima_letra()

# Enquanto o texto aparece, a boca abre e fecha a cada boca_intervalo
func mexer_boca(passado):
	if DADOS.boca_intervalo <= 0:
		return
	espera_boca -= passado
	while espera_boca <= 0:
		espera_boca += DADOS.boca_intervalo
		boca_aberta = not boca_aberta
		mostrar_retrato(boca_aberta)

# Frase longa fala mais rápido: ritmo normal até frase_curta_letras, o mais rápido a partir
# de frase_longa_letras e, entre os dois, aumentando aos poucos
func velocidade_da_frase(simples):
	var letras = 0
	for letra in simples:
		if eh_letra(letra):
			letras += 1
	var faixa = DADOS.frase_longa_letras - DADOS.frase_curta_letras
	if faixa <= 0 or DADOS.frase_longa_velocidade <= 0:
		return 1.0
	var quanto = clampf(float(letras - DADOS.frase_curta_letras) / faixa, 0.0, 1.0)
	return lerpf(1.0, DADOS.frase_longa_velocidade, quanto)

# Mostra mais uma letra (estilo Undertale): cada palavra pode sair numa rajada, a voz soa
# nas letras de verdade e a pontuação segura o texto um pouco
func proxima_letra():
	var simples = texto.get_parsed_text()
	var indice = texto.visible_characters
	if indice >= simples.length():
		terminar_texto()
		return
	if indice == 0 or simples[indice - 1] == " ":
		sortear_palavra()
	texto.visible_characters = indice + 1
	var letra = simples[indice]
	espera += 1.0 / (ritmo * mult_frase * mult_palavra) + pausa_da_letra(simples, indice)
	if eh_letra(letra):
		tocar_voz()
	if texto.visible_characters >= simples.length():
		terminar_texto()

# Uma palavra nova: às vezes sai numa rajada, mais rápida
func sortear_palavra():
	mult_palavra = 1.0
	if DADOS.rajada_velocidade > 0 and randf() < DADOS.rajada_chance:
		mult_palavra = DADOS.rajada_velocidade

# Pausa a mais depois da letra 'indice': reticências, fim de frase, vírgula ou espaço
func pausa_da_letra(simples, indice):
	var letra = simples[indice]
	if letra == "…":
		return 3 * DADOS.pausa_ponto
	if letra == ".":
		if simples.substr(indice - 1, 1) == "." or simples.substr(indice + 1, 1) == ".":
			return DADOS.pausa_ponto
		return DADOS.pausa_frase
	if letra in "!?":
		return DADOS.pausa_frase
	if letra in ",;:":
		return DADOS.pausa_virgula
	if letra == " ":
		return DADOS.pausa_espaco
	return 0.0

# Um som da voz, cortando o anterior; com as letras rápidas demais, várias saem num som só
func tocar_voz():
	var agora = Time.get_ticks_msec()
	if fala_atual.voz == &"" or agora - ultima_voz < DADOS.voz_intervalo_min * 1000.0:
		return
	ultima_voz = agora
	Sons.cortar(fala_atual.voz)
	Sons.tocar(fala_atual.voz)

# Letra de verdade: não é espaço nem pontuação
func eh_letra(letra):
	return letra.strip_edges() != "" and not letra in ".,!?…:;-\"'"

# O texto inteiro na caixa: a boca fecha e a seta aparece pulando (o último som da voz,
# curtinho, termina sozinho; completar com Espaço ou fechar corta a voz na hora)
func terminar_texto():
	digitando = false
	texto.visible_characters = -1
	boca_aberta = false
	mostrar_retrato(false)
	mostrar_seta(true)

# Corta a voz que ainda está soando
func parar_voz():
	if fala_atual != null and fala_atual.voz != &"":
		Sons.cortar(fala_atual.voz)

# Mostra a seta pulando (sobe seta_pulo_px e volta, sem parar) ou esconde
func mostrar_seta(ligada):
	if tween_seta != null:
		tween_seta.kill()
	seta.visible = ligada
	seta.position.y = seta_y
	if not ligada or DADOS.seta_pulo_px <= 0 or DADOS.seta_pulo_periodo <= 0:
		return
	tween_seta = create_tween().set_loops()
	tween_seta.tween_method(definir_altura_seta, 0.0, float(DADOS.seta_pulo_px), DADOS.seta_pulo_periodo / 2.0)
	tween_seta.tween_method(definir_altura_seta, float(DADOS.seta_pulo_px), 0.0, DADOS.seta_pulo_periodo / 2.0)

# Seta 'altura' px acima do lugar dela (em px inteiros: pixel art)
func definir_altura_seta(altura):
	seta.position.y = seta_y - roundf(altura)

# 'shoot' completa o texto ou, com ele completo, avança
func _unhandled_input(event):
	if not aberta or so_mostrando or not event.is_action_pressed("shoot"):
		return
	if digitando:
		parar_voz()
		terminar_texto()
	else:
		avancar()

# Próxima fala da conversa, ou fecha e avisa
func avancar():
	Sons.tocar(&"fala_avancar")
	if fala_atual.seguinte != &"":
		var fala = fala_de(fala_atual.seguinte)
		if fala != null:
			comecar(fala, true)
			return
	fechar()
	terminou.emit(nome_conversa)

# Fundo preto com borda branca de 1 px
func _desenhar_caixa():
	var retangulo = Rect2(Vector2.ZERO, caixa.size)
	caixa.draw_rect(retangulo, COR_FUNDO)
	caixa.draw_rect(retangulo.grow(-0.5), COR_BORDA, false, 1.0)

# Seta ▼ (triângulo cheio)
func _desenhar_seta():
	seta.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(SETA_PX, 0), Vector2(SETA_PX / 2.0, SETA_PX / 2.0)]), COR_BORDA)
