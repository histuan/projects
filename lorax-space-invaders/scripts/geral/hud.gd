# HUD: placar, corações do player e do boss, letreiro da wave e os "+N" flutuantes.
# Só desenha; quem decide pontos e vidas é a Partida.
extends CanvasLayer

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
var tween_wave: Tween = null
var pontos_visiveis = true

## Desenho do letreiro "FINAL WAVE" (wave 10). Vazio = provisório em texto com a fonte do jogo
@export var letreiro_final_wave: Texture2D
# O alarme acabou e o FINAL WAVE terminou de sumir (a main espera isto para soltar o boss)
signal final_wave_sumiu
var final_wave: CanvasItem = null
var tween_final: Tween = null

# Boss final: um coração cheio esvaziou (a main reage com a câmera)
signal coracao_boss_perdido
# Boss final: o número de corações cheios subiu (entrada da fase, troca de fase)
signal coracoes_boss_reencheram
var coracoes_boss_cheios = 0

# Treme junto com a tela: a câmera desloca a visão em +d, então o mundo anda -d
func acompanhar_tremor(deslocamento):
	offset = -deslocamento

# Esconde os corações do boss e passa a escutar a Partida
func _ready():
	$coracoesBoss.hide()
	# O letreiro só aparece quando uma wave começa (no LAB nenhuma começa)
	$wave.modulate.a = 0.0
	Partida.pontos_mudaram.connect(mostrar_pontuacao)
	Partida.pontos_ganhos.connect(mostrar_pontos)
	Partida.vidas_mudaram.connect(mostrar_vidas)
	Partida.wave_mudou.connect(mostrar_wave)
	# A wave 1 foi criada antes deste _ready (o groupAlien vem antes na árvore)
	if Partida.wave > 0:
		mostrar_wave(Partida.wave)

# Número do placar
func mostrar_pontuacao(p):
	$placar/LabelP.text = str(p)

# Esconde o placar e os "+N" (a Partida continua somando os pontos)
func esconder_placar():
	$placar.hide()
	pontos_visiveis = false

# Corações do player (cheios = vidas)
func mostrar_vidas(v):
	$coracoes.set_vidas(v)

# Corações do boss: atualiza e, no zero, somem piscando
func perder_vida_boss(v):
	$coracoesBoss.set_vidas(v)
	if v <= 0:
		$coracoesBoss.sumir_piscando()

# Piscam enquanto o boss desce e param quando ele chega
func mostrar_vida_boss():
	$coracoesBoss.show()
	$coracoesBoss.piscar_ate_parar()

func parar_piscada_boss():
	$coracoesBoss.parar_piscada()

# Boss final: os corações cheios acompanham a proporção vida / vida_max
func mostrar_vida_boss_final(vida, vida_max):
	var total = $coracoesBoss.coracoes.size()
	var cheios = ceili(vida * float(total) / vida_max)
	$coracoesBoss.show()
	$coracoesBoss.set_vidas(cheios)
	if cheios < coracoes_boss_cheios and cheios > 0:
		coracao_boss_perdido.emit()
	elif cheios > coracoes_boss_cheios:
		coracoes_boss_reencheram.emit()
	coracoes_boss_cheios = cheios

# Boss final: corações piscando = ele está invulnerável
func piscar_vida_boss(ligado):
	if ligado:
		$coracoesBoss.show()
		$coracoesBoss.piscar_ate_parar()
	else:
		$coracoesBoss.parar_piscada()

# Letreiro "WAVE N" piscando 2 vezes (~4,2 s)
func mostrar_wave(n):
	var w = $wave
	$wave/LabelWave.text = str(n)
	w.modulate.a = 0.0
	if tween_wave != null:
		tween_wave.kill()
	tween_wave = create_tween()
	for i in range(2):
		tween_wave.tween_property(w, "modulate:a", 1.0, 0.8)
		tween_wave.tween_interval(0.5)
		tween_wave.tween_property(w, "modulate:a", 0.0, 0.8)

# Wave 10: FINAL WAVE no lugar do letreiro de wave, piscando ('pisca' s aceso/apagado)
# por 'duracao' s (o tamanho do alarme) e sumindo com fade de 'fade' s. Pausa com o jogo
func mostrar_final_wave(duracao, pisca, fade):
	if tween_wave != null:
		tween_wave.kill()
	$wave.modulate.a = 0.0
	if final_wave == null:
		final_wave = criar_final_wave()
	if tween_final != null:
		tween_final.kill()
	tween_final = create_tween().set_ignore_time_scale()
	tween_final.set_loops(maxi(1, roundi(duracao / (2.0 * pisca))))
	tween_final.tween_callback(func(): final_wave.modulate.a = 1.0)
	tween_final.tween_interval(pisca)
	tween_final.tween_callback(func(): final_wave.modulate.a = 0.0)
	tween_final.tween_interval(pisca)
	tween_final.finished.connect(sumir_final_wave.bind(fade))

# Fim do alarme: o FINAL WAVE aparece uma última vez e some com fade
func sumir_final_wave(fade):
	final_wave.modulate.a = 1.0
	tween_final = create_tween().set_ignore_time_scale()
	tween_final.tween_property(final_wave, "modulate:a", 0.0, fade)
	tween_final.tween_callback(final_wave_sumiu.emit)

# O letreiro FINAL WAVE na posição do letreiro de wave: o desenho, ou o texto provisório
func criar_final_wave():
	var no: CanvasItem
	if letreiro_final_wave != null:
		var sprite = Sprite2D.new()
		sprite.texture = letreiro_final_wave
		sprite.position = $wave.position
		no = sprite
	else:
		var texto = Label.new()
		texto.text = "FINAL WAVE"
		texto.add_theme_font_override("font", FONTE)
		texto.add_theme_font_size_override("font_size", 16)
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		texto.size = Vector2(get_viewport().get_visible_rect().size.x, 16)
		texto.position = Vector2(0, $wave.position.y - texto.size.y / 2.0)
		no = texto
	no.modulate.a = 0.0
	add_child(no)
	return no

# Texto "+N" que sobe e some. Cor por valor: 200 forte, 300 sniper, 500 boss
func mostrar_pontos(valor, pos, tamanho = 8):
	if not pontos_visiveis:
		return
	var l = Label.new()
	l.text = "+" + str(valor)
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", tamanho)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(tamanho * 6, tamanho)
	l.position = pos - l.size / 2
	if valor == 200:
		l.add_theme_color_override("font_color", Color.from_rgba8(253, 208, 23, 220))
	elif valor == 300:
		l.add_theme_color_override("font_color", Color.from_rgba8(251, 140, 7, 204))
	elif valor == 500:
		l.add_theme_color_override("font_color", Color.from_rgba8(217, 25, 255))
	else:
		l.add_theme_color_override("font_color", Color.from_rgba8(255, 255, 255))
	add_child(l)
	# Boss: sobe, pulsa 4 vezes e some
	if valor == 500:
		l.pivot_offset = l.size / 2
		var tb = create_tween()
		tb.tween_property(l, "position:y", l.position.y - 12, 0.4)
		for i in range(4):
			tb.tween_property(l, "scale", Vector2(1.25, 1.25), 0.15)
			tb.tween_property(l, "scale", Vector2(1.0, 1.0), 0.15)
		tb.tween_property(l, "modulate:a", 0.0, 0.4)
		tb.tween_callback(l.queue_free)
		return
	# Demais: sobe 12 px e desaparece ao mesmo tempo; no fim o Label é apagado
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 12, 0.6)
	t.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.2)
	t.chain().tween_callback(l.queue_free)
