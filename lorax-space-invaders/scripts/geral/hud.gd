# HUD: placar, corações do player e do boss, letreiro da wave, os letreiros da boss fight
# (Letreiro + estilo LetreiroDados) e os "+N" flutuantes.
# Só desenha; quem decide pontos e vidas é a Partida.
extends CanvasLayer

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
var tween_wave: Tween = null
var pontos_visiveis = true

# Boss final: um coração cheio esvaziou (a main reage com a câmera)
signal coracao_boss_perdido
# Boss final: sobrou só 1 coração cheio (a main toca o momento do último coração)
signal ultimo_coracao_boss
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
	# Os passos SINAL dos momentos que desenham na hud (coração que esvazia, batida do último)
	Momentos.pedido.connect(_on_pedido)
	$coracoesBoss.encheu.connect(_on_coracoes_boss_encheram)
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

# Boss final: os corações cheios acompanham a proporção vida / vida_max. Enchendo um a um (troca
# de fase), só guarda o número: o desenho e o aviso vêm no fim do enchimento
func mostrar_vida_boss_final(vida, vida_max):
	var total = $coracoesBoss.coracoes.size()
	var cheios = ceili(vida * float(total) / vida_max)
	$coracoesBoss.show()
	if $coracoesBoss.enchendo():
		coracoes_boss_cheios = cheios
		return
	$coracoesBoss.set_vidas(cheios)
	if cheios < coracoes_boss_cheios and cheios > 0:
		coracao_boss_perdido.emit()
		if cheios == 1:
			ultimo_coracao_boss.emit()
	elif cheios > coracoes_boss_cheios:
		coracoes_boss_reencheram.emit()
	coracoes_boss_cheios = cheios

# Boss final: terminaram de encher um a um (troca de fase)
func _on_coracoes_boss_encheram():
	coracoes_boss_cheios = $coracoesBoss.cheios
	coracoes_boss_reencheram.emit()

# Boss final: o último coração para de bater (o player morreu, o R do LAB)
func parar_pulso_boss():
	$coracoesBoss.parar_pulso()

# O último coração do boss está batendo (status do LAB)
func pulso_boss_ligado():
	return $coracoesBoss.pulsando()

# LAB: mostra os corações do boss com 'cheios' cheios (−1 = todos) SEM emitir os sinais (quem
# toca o momento é o próprio LAB)
func mostrar_coracoes_boss(cheios):
	var total = $coracoesBoss.coracoes.size()
	coracoes_boss_cheios = total if cheios < 0 else clampi(cheios, 0, total)
	$coracoesBoss.show()
	$coracoesBoss.set_vidas(coracoes_boss_cheios)

# Pedidos dos momentos para a hud. coracao_da_hud: anima o coração que acabou de esvaziar
# (o primeiro vazio) do boss ou do player; coracao_pulsa: o último coração do boss bate;
# coracoes_reenchem: os do boss esvaziam e enchem um a um
func _on_pedido(nome, parametros, _alvo):
	match nome:
		&"coracao_da_hud":
			var qual = $coracoes if parametros.get("coracoes", "boss") == "player" else $coracoesBoss
			qual.perdeu(qual.cheios, parametros.get("escala", 1.0), parametros.get("duracao", 0.0),
				parametros.get("tremor_px", 0), parametros.get("tremor_duracao", 0.0),
				parametros.get("cor", Color.WHITE), parametros.get("alfa", 0.0), parametros.get("duracao_flash", 0.0))
		&"coracao_pulsa":
			$coracoesBoss.pulsar_ultimo(parametros.get("escala", 1.0), parametros.get("periodo", 0.0),
				parametros.get("batida", 0.0), parametros.get("som", &""))
		&"coracoes_reenchem":
			$coracoesBoss.show()
			$coracoesBoss.encher_aos_poucos(parametros.get("intervalo", 0.0), parametros.get("som", &""))

# Boss final: os corações cheios passam a usar a textura da fase (null = não muda)
func trocar_coracoes_boss(textura):
	if textura != null:
		$coracoesBoss.trocar_cheio(textura)

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

# Some na hora com o letreiro "WAVE N" (o FINAL WAVE aparece no lugar dele)
func esconder_letreiro_wave():
	if tween_wave != null:
		tween_wave.kill()
	$wave.modulate.a = 0.0

# Mostra um letreiro no estilo 'dados' e devolve ele (sinais sumiu e letra_entrou).
# 'tempo' < 0 = o tempo do estilo
func mostrar_letreiro(dados, texto = "", subtitulo = "", tempo = -1.0):
	var letreiro = Letreiro.new()
	add_child(letreiro)
	letreiro.mostrar(dados, texto, subtitulo, tempo)
	return letreiro

# Quantos letreiros estão na tela (para o status dos LABs)
func letreiros_na_tela():
	var total = 0
	for filho in get_children():
		if filho is Letreiro and not filho.is_queued_for_deletion():
			total += 1
	return total

# Apaga na hora todos os letreiros (R dos LABs)
func limpar_letreiros():
	for filho in get_children():
		if filho is Letreiro:
			filho.queue_free()

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
