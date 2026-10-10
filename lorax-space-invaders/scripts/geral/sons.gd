# Efeitos sonoros (autoload "Sons"): toca EVENTOS do sons_boss.tres. O evento diz
# arquivo, pitch, volume e bus; trocar um som é mexer só no .tres.
# Evento desconhecido ou arquivo que falta = push_error com o nome (nunca silêncio).
# Pausa junto com o jogo (process_mode padrão): sons e loops congelam no Pause.
extends Node

const BIBLIOTECA = preload("res://recursos/boss/sons_boss.tres")
const TAMANHO_POOL = 12

var pool: Array[AudioStreamPlayer] = []
var proximo_do_pool = 0
# Caminho → AudioStream carregado (e a versão com loop, separada)
var cache = {}
var cache_loop = {}
# Evento → índice da última variante tocada (para não repetir)
var ultima_variante = {}
# Evento em loop → player que está tocando ele
var loops = {}
var tweens_pitch: Array[Tween] = []

# Cria os players do pool (AudioStreamPlayer comum: sem atenuação nem pan)
func _ready():
	for i in range(TAMANHO_POOL):
		var player = AudioStreamPlayer.new()
		add_child(player)
		pool.append(player)

# Toca o evento (e as camadas dele); devolve o player principal, ou null se não deu
func tocar(evento: StringName):
	var dados = dados_do_evento(evento)
	if dados == null:
		return null
	for camada in dados.camadas:
		tocar_dados(evento, camada)
	return tocar_dados(evento, dados)

# Toca o evento na nota 'indice' da escala dele (dá a volta no fim da escala); sem a
# variação aleatória, para a nota sair afinada
func tocar_na_escala(evento: StringName, indice):
	var dados = dados_do_evento(evento)
	if dados == null:
		return null
	if dados.escala.is_empty():
		push_error("Sons: o evento '%s' não tem escala" % evento)
		return null
	var player = tocar(evento)
	if player != null:
		player.pitch_scale = dados.escala[posmod(indice, dados.escala.size())] * fator_camera_lenta()
	return player

# Toca o evento e desliza o pitch até o pitch_final dele em 'duracao' segundos
func tocar_deslizando(evento: StringName, duracao):
	var player = tocar(evento)
	var dados = dados_do_evento(evento)
	if player != null and dados.pitch_final > 0:
		deslizar_pitch(player, dados.pitch_final, duracao)
	return player

# Para um evento em loop
func parar(evento: StringName):
	if loops.has(evento):
		loops[evento].stop()
		loops.erase(evento)

# Corta na hora todo som deste evento que ainda está tocando (loop ou não), por exemplo a
# voz quando o texto da fala acaba
func cortar(evento: StringName):
	for player in pool:
		if player.playing and player.get_meta(&"evento", &"") == evento:
			player.stop()
	loops.erase(evento)

# Para tudo (a main chama ao sair da árvore, para nada continuar no menu)
func parar_tudo():
	for tween in tweens_pitch:
		if tween.is_valid():
			tween.kill()
	tweens_pitch.clear()
	for player in pool:
		player.stop()
	loops.clear()

# Nomes dos eventos tocando agora (para o LAB DE SONS)
func eventos_tocando():
	var nomes = []
	for player in pool:
		if player.playing:
			nomes.append(player.get_meta(&"evento"))
	return nomes

# O evento em loop está tocando
func em_loop(evento: StringName):
	return loops.has(evento)

# Põe arquivo, volume e pitch do evento num player de fora do pool (prévia de volume no
# Pause, que toca com o jogo pausado); devolve false se não deu
func preparar_player(evento: StringName, player):
	var dados = dados_do_evento(evento)
	if dados == null:
		return false
	var caminho = arquivo_do_evento(evento, dados)
	if caminho == "":
		return false
	player.stream = stream_de(caminho, false)
	player.volume_db = volume_de(dados, caminho)
	player.pitch_scale = dados.pitch
	return true

# Leva o pitch de um player tocando até 'ate' em 'duracao' segundos (tempo real)
func deslizar_pitch(player, ate, duracao):
	tweens_pitch = tweens_pitch.filter(func(antigo): return antigo.is_valid())
	var tween = create_tween().set_ignore_time_scale()
	tween.tween_property(player, "pitch_scale", ate, duracao)
	tweens_pitch.append(tween)

# Dados do evento no sons_boss.tres (erro se ele não existe)
func dados_do_evento(evento: StringName):
	var dados = BIBLIOTECA.eventos.get(evento)
	if dados == null:
		push_error("Sons: evento desconhecido '%s'" % evento)
	return dados

# Escolhe a variante e confere se o arquivo existe; "" (com erro) se não der
func arquivo_do_evento(evento: StringName, dados):
	if dados.arquivos.is_empty():
		push_error("Sons: o evento '%s' não tem arquivo" % evento)
		return ""
	var indice = 0
	if dados.arquivos.size() > 1:
		indice = randi() % dados.arquivos.size()
		if indice == ultima_variante.get(evento, -1):
			indice = (indice + 1) % dados.arquivos.size()
		ultima_variante[evento] = indice
	var caminho = dados.arquivos[indice]
	if not ResourceLoader.exists(caminho):
		push_error("Sons: o arquivo '%s' do evento '%s' não existe" % [caminho, evento])
		return ""
	return caminho

# Volume final: o ajuste do evento (mixagem de ouvido) + o ganho do arquivo
func volume_de(dados, caminho):
	return dados.volume_db + BIBLIOTECA.ganhos.get(caminho, 0.0)

# Carrega o arquivo (com cache); com loop, uma cópia com o loop ligado por código
func stream_de(caminho, com_loop):
	if not cache.has(caminho):
		cache[caminho] = load(caminho)
	if not com_loop:
		return cache[caminho]
	if not cache_loop.has(caminho):
		var copia = cache[caminho].duplicate()
		if copia is AudioStreamWAV:
			copia.loop_mode = AudioStreamWAV.LOOP_FORWARD
			copia.loop_begin = 0
			copia.loop_end = int(copia.get_length() * copia.mix_rate)
		else:
			copia.loop = true
		cache_loop[caminho] = copia
	return cache_loop[caminho]

# Toca um SomDados (o evento ou uma camada dele), agora ou depois do atraso
func tocar_dados(evento: StringName, dados):
	var caminho = arquivo_do_evento(evento, dados)
	if caminho == "":
		return null
	if dados.atraso > 0:
		get_tree().create_timer(dados.atraso, false, false, true).timeout.connect(iniciar.bind(evento, dados, caminho))
		return null
	return iniciar(evento, dados, caminho)

# Põe o arquivo num player livre com volume, pitch e bus do evento e toca
func iniciar(evento: StringName, dados, caminho):
	var player = player_livre()
	player.stream = stream_de(caminho, dados.loop)
	player.volume_db = volume_de(dados, caminho)
	player.pitch_scale = pitch_sorteado(dados) * fator_camera_lenta()
	player.bus = dados.bus
	player.set_meta(&"evento", evento)
	player.play()
	if dados.loop:
		loops[evento] = player
	return player

# Pitch do evento com a variação sorteada (1,08 = entre 1/1,08 e 1,08 vezes)
func pitch_sorteado(dados):
	if dados.pitch_aleatorio <= 1.0:
		return dados.pitch
	return dados.pitch * randf_range(1.0 / dados.pitch_aleatorio, dados.pitch_aleatorio)

# Na câmera lenta os efeitos ficam mais graves (efeitos.md §2); fora dela, 1
func fator_camera_lenta():
	if TempoJogo.em_camera_lenta(BIBLIOTECA.escala_camera_lenta):
		return BIBLIOTECA.pitch_camera_lenta
	return 1.0

# Um player parado; com todos ocupados, reaproveita o próximo que não é loop
func player_livre():
	for player in pool:
		if not player.playing:
			return player
	for i in range(TAMANHO_POOL):
		var player = pool[(proximo_do_pool + i) % TAMANHO_POOL]
		if not loops.values().has(player):
			proximo_do_pool = (proximo_do_pool + i + 1) % TAMANHO_POOL
			player.stop()
			return player
	return pool[0]
