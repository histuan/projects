# Letreiro animado (FINAL WAVE, nome do boss, FINISH HIM, dica W/S, contagem): monta o texto
# ou o sprite e anima entrada, permanência e saída conforme o estilo (LetreiroDados).
# Os tweens pausam com o jogo e ignoram o time_scale (hit-stop e câmera lenta não esticam).
# Some sozinho no fim (a não ser que o estilo peça 'fica': aí só some com esconder()).
class_name Letreiro
extends Node2D

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")

# Uma letra entrou (letra por letra) ou a contagem deu um tique
signal letra_entrou(indice)
# Terminou de sumir (o nó é apagado logo depois)
signal sumiu

var dados: LetreiroDados
var tween: Tween = null
# Letras separadas (letra por letra); vazio quando o texto entra inteiro
var letras: Array[Label] = []
var fonte_variavel: FontVariation
var numero_contagem: Label
# O texto principal (o que pulsa); null para sprite e letra por letra
var label_principal: Label = null
var alvo_contagem = 0
var ultimo_tique = -1

# Monta o conteúdo e começa a animação. 'tempo' < 0 = o tempo do estilo
func mostrar(estilo: LetreiroDados, texto = "", subtitulo = "", tempo = -1.0):
	dados = estilo
	position = dados.posicao
	var duracao = dados.tempo if tempo < 0 else tempo
	var falta = campo_faltando(texto, duracao)
	if falta != "":
		push_error("Letreiro '%s': %s" % [dados.resource_path.get_file(), falta])
		queue_free()
		return
	montar(texto, subtitulo)
	modulate.a = 0.0
	animar(duracao)
	pulsar()

# O que impede o letreiro de aparecer ("" = nada)
func campo_faltando(texto, duracao):
	if dados.textura == null and dados.texturas.is_empty() and texto == "":
		return "sem textura nem texto"
	if dados.letra_intervalo > 0 and dados.letra_escala.x <= 0:
		return "letra_escala = 0"
	if dados.contagem and dados.contagem_duracao <= 0:
		return "contagem_duracao = 0"
	if not dados.fica and dados.fade_in + duracao + dados.fade_out <= 0 and dados.letra_intervalo <= 0:
		return "tempo = 0"
	return ""

# Sprite, sprites lado a lado, contagem, letras separadas ou texto inteiro (+ subtítulo)
func montar(texto, subtitulo):
	if dados.textura != null:
		var sprite = Sprite2D.new()
		sprite.texture = dados.textura
		add_child(sprite)
	elif not dados.texturas.is_empty():
		montar_texturas()
	elif dados.contagem:
		alvo_contagem = int(texto)
		numero_contagem = criar_label("0", dados.tamanho_fonte, null, dados.cor)
	elif dados.letra_intervalo > 0:
		montar_letras(texto)
	else:
		fonte_variavel = FontVariation.new()
		fonte_variavel.base_font = FONTE
		fonte_variavel.spacing_glyph = int(dados.espacamento.x)
		label_principal = criar_label(texto, dados.tamanho_fonte, fonte_variavel, dados.cor)
	if subtitulo != "":
		var label = criar_label(subtitulo, dados.tamanho_subtitulo, fonte_variavel, dados.cor_subtitulo)
		label.position.y += dados.distancia_subtitulo

# Sprites lado a lado, centrados, cada um no quadro 0
func montar_texturas():
	var sprites = []
	var largura_total = 0.0
	for textura in dados.texturas:
		var sprite = Sprite2D.new()
		sprite.texture = textura
		sprite.hframes = maxi(dados.quadros_por_textura, 1)
		sprites.append(sprite)
		largura_total += textura.get_width() / float(sprite.hframes)
	largura_total += dados.espaco_texturas * (sprites.size() - 1)
	var x = -largura_total / 2.0
	for sprite in sprites:
		var largura = sprite.texture.get_width() / float(sprite.hframes)
		sprite.position.x = roundf(x + largura / 2.0)
		add_child(sprite)
		x += largura + dados.espaco_texturas

# Um Label por letra (os espaços só ocupam lugar), centrados; começam invisíveis
func montar_letras(texto):
	var larguras = []
	var largura_total = 0.0
	for letra in texto:
		var largura = FONTE.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, dados.tamanho_fonte).x
		larguras.append(largura)
		largura_total += largura
	var x = -largura_total / 2.0
	for i in range(texto.length()):
		if texto[i] != " ":
			var label = criar_label(texto[i], dados.tamanho_fonte, null, dados.cor, larguras[i])
			label.position.x = roundf(x)
			label.pivot_offset = label.size / 2.0
			label.modulate.a = 0.0
			letras.append(label)
		x += larguras[i]

# Label com a fonte do jogo na 'cor' (e o contorno do estilo), centrado no ponto (0, 0) deste nó;
# sem 'largura', da largura da tela
func criar_label(texto, tamanho, fonte, cor, largura = -1.0):
	var label = Label.new()
	label.text = texto
	label.add_theme_font_override("font", fonte if fonte != null else FONTE)
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	if dados.contorno_px > 0:
		label.add_theme_color_override("font_outline_color", dados.contorno_cor)
		label.add_theme_constant_override("outline_size", dados.contorno_px)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(largura if largura > 0 else get_viewport_rect().size.x, tamanho)
	label.position = Vector2(-label.size.x / 2.0, -label.size.y / 2.0).round()
	add_child(label)
	return label

# O texto principal clareia de leve e volta, sem parar, enquanto o letreiro existe
func pulsar():
	if label_principal == null or dados.pulso_claro <= 0 or dados.pulso_periodo <= 0:
		return
	var pulso = create_tween().set_ignore_time_scale().set_loops()
	pulso.tween_method(definir_claro, 0.0, dados.pulso_claro, dados.pulso_periodo / 2.0)
	pulso.tween_method(definir_claro, dados.pulso_claro, 0.0, dados.pulso_periodo / 2.0)

# Cor do texto principal puxada para o branco em 'quanto' (0 = a cor do estilo)
func definir_claro(quanto):
	label_principal.add_theme_color_override("font_color", dados.cor.lerp(Color.WHITE, quanto))

# Os ciclos entra-fica-some (vezes) e, no fim, avisa e se apaga
func animar(duracao):
	tween = create_tween().set_ignore_time_scale()
	for ciclo in range(maxi(dados.vezes, 1)):
		entrar()
		if dados.fica:
			return
		ficar(duracao)
		sair(dados.fade_out)
	tween.tween_callback(terminar)

# Entrada: letra por letra, contagem ou fade (com o espaçamento abrindo junto)
func entrar():
	if not letras.is_empty():
		tween.tween_callback(func(): modulate.a = 1.0)
		for i in range(letras.size()):
			tween.tween_callback(entrar_letra.bind(i))
			tween.tween_interval(dados.letra_intervalo)
		return
	if dados.fade_in <= 0:
		tween.tween_callback(func(): modulate.a = 1.0)
	else:
		tween.tween_callback(func(): modulate.a = 0.0)
		tween.tween_property(self, "modulate:a", 1.0, dados.fade_in)
		if fonte_variavel != null and dados.espacamento.x != dados.espacamento.y:
			tween.parallel().tween_method(definir_espacamento, dados.espacamento.x, dados.espacamento.y, dados.fade_in)
	if dados.contagem:
		tween.tween_method(definir_contagem, 0.0, float(alvo_contagem), dados.contagem_duracao)

# Uma letra aparece crescida e encolhe até o tamanho final; avisa quem quiser reagir
func entrar_letra(indice):
	var letra = letras[indice]
	letra.modulate.a = 1.0
	letra.scale = Vector2.ONE * dados.letra_escala.x
	var encolher = letra.create_tween().set_ignore_time_scale()
	encolher.tween_property(letra, "scale", Vector2.ONE * dados.letra_escala.y, dados.letra_intervalo)
	letra_entrou.emit(indice)

# Permanência: pisca ('pisca' s aceso/apagado) ou só espera; no fim, aceso de novo
func ficar(duracao):
	if dados.pisca <= 0:
		tween.tween_interval(duracao)
		return
	for i in range(maxi(1, roundi(duracao / (2.0 * dados.pisca)))):
		tween.tween_callback(func(): modulate.a = 1.0)
		tween.tween_interval(dados.pisca)
		tween.tween_callback(func(): modulate.a = 0.0)
		tween.tween_interval(dados.pisca)
	tween.tween_callback(func(): modulate.a = 1.0)

# Saída: some com fade (ou na hora)
func sair(fade):
	if fade <= 0:
		tween.tween_callback(func(): modulate.a = 0.0)
	else:
		tween.tween_property(self, "modulate:a", 0.0, fade)

# Some agora (o FINISH HIM, que fica até a fase mandar). fade < 0 = o fade_out do estilo
func esconder(fade = -1.0):
	if tween != null:
		tween.kill()
	tween = create_tween().set_ignore_time_scale()
	sair(dados.fade_out if fade < 0 else fade)
	tween.tween_callback(terminar)

# Avisa que sumiu e se apaga
func terminar():
	sumiu.emit()
	queue_free()

# Espaço extra entre as letras (px inteiros: pixel art)
func definir_espacamento(valor):
	fonte_variavel.spacing_glyph = roundi(valor)

# Número atual da contagem; cada número novo é um tique
func definir_contagem(valor):
	var atual = int(valor)
	numero_contagem.text = str(atual)
	if atual != ultimo_tique:
		ultimo_tique = atual
		letra_entrou.emit(atual)
