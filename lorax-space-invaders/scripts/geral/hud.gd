# HUD: placar, corações do player e do boss, letreiro da wave e os "+N" flutuantes.
# Só desenha; quem decide pontos e vidas é a Partida.
extends Node

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
var tween_wave: Tween = null

# Esconde os corações do boss e passa a escutar a Partida
func _ready():
	$coracoesBoss.hide()
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

# Texto "+N" que sobe e some. Cor por valor: 200 forte, 300 sniper, 500 boss
func mostrar_pontos(valor, pos, tamanho = 8):
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
