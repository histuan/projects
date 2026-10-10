# Música (autoload "Musica"): dona de toda música da partida, para nunca tocarem duas
# juntas. Troca por crossfade, corta seco, some com fade e abafa (low-pass do bus Musica)
# por pedidos nomeados. Pausa junto com o jogo (process_mode padrão).
extends Node

const BUS = &"Musica"
# Corte do low-pass "aberto" (não abafa nada)
const ABERTO_HZ = 20000.0
# Volume em que a música já é inaudível (início e fim dos fades)
const SILENCIO_DB = -60.0

var players: Array[AudioStreamPlayer] = []
# O que está tocando agora (um dos dois players ou o adotado da main)
var atual: AudioStreamPlayer = null
var adotado: AudioStreamPlayer = null
# Evento da música atual (vazio = nenhuma ou a adotada)
var evento_atual: StringName = &""
# Player posto para tocar com o jogo pausado (OPÇÕES do Pause)
var tocando_na_pausa: AudioStreamPlayer = null
var tweens: Array[Tween] = []
# Nome do pedido → corte (Hz); vale o mais baixo
var pedidos_abafar = {}
var tween_abafar: Tween = null
# Nome do pedido → dB (negativo); vale o mais baixo
var pedidos_abaixar = {}
var tween_abaixar: Tween = null

# Dois players no bus Musica, para o crossfade
func _ready():
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		players.append(player)

# A main entrega a música que já toca nela (sons/musga); a partir daqui a Musica cuida dela
func adotar(player):
	player.bus = BUS
	adotado = player
	atual = player
	evento_atual = &""

# Solta o adotado, para tweens e músicas e destampa (a main chama ao sair da árvore)
func limpar():
	matar_tweens()
	for player in players:
		player.stop()
	adotado = null
	atual = null
	evento_atual = &""
	tocando_na_pausa = null
	pedidos_abafar.clear()
	aplicar_abafar(0.0)
	pedidos_abaixar.clear()
	aplicar_abaixar(0.0)

# Toca a música do evento a partir de 'inicio' s (−1 = o do evento); com crossfade
# (−1 = o do evento), a anterior some enquanto a nova entra
func tocar(evento: StringName, crossfade = -1.0, inicio = -1.0):
	var dados = Sons.dados_do_evento(evento)
	if dados == null:
		return
	var caminho = Sons.arquivo_do_evento(evento, dados)
	if caminho == "":
		return
	var duracao = dados.crossfade if crossfade < 0 else crossfade
	var anterior = atual if valido(atual) else null
	var novo = players[1] if anterior == players[0] else players[0]
	var alvo_db = Sons.volume_de(dados, caminho)
	novo.stream = Sons.stream_de(caminho, dados.loop)
	novo.volume_db = SILENCIO_DB if duracao > 0 else alvo_db
	novo.play(dados.inicio if inicio < 0 else inicio)
	atual = novo
	evento_atual = evento
	if duracao > 0:
		var tween = novo_tween()
		tween.tween_method(definir_amplitude.bind(novo), 0.0, db_to_linear(alvo_db), duracao)
	sumir(anterior, duracao)

# A música atual some em 'duracao' segundos e para
func fade_out(duracao):
	sumir(atual if valido(atual) else null, duracao)
	atual = null
	evento_atual = &""

# Corte SECO: tudo para no mesmo instante, sem fade (golpe final)
func cortar():
	matar_tweens()
	for player in players:
		player.stop()
	if valido(adotado):
		adotado.stop()
	atual = null
	evento_atual = &""

# Nome do que está tocando (para o LAB DE SONS): o evento, "JOGO" (a adotada) ou ""
func nome_atual():
	if not valido(atual) or not atual.playing:
		return ""
	if atual == adotado:
		return "JOGO"
	return String(evento_atual)

# Com o jogo pausado, deixa a música atual tocar (true) ou volta a pausar com o jogo (false).
# Mudar o process_mode faz o Godot pausar/retomar o player na hora. Os fades continuam
# congelados (os tweens são desta autoload, que segue pausada)
func ouvir_na_pausa(ligado):
	if valido(tocando_na_pausa):
		tocando_na_pausa.process_mode = Node.PROCESS_MODE_INHERIT
	tocando_na_pausa = null
	if ligado and valido(atual):
		atual.process_mode = Node.PROCESS_MODE_ALWAYS
		tocando_na_pausa = atual

# Troca para outra música começando na posição da atual − 'recuo' s (fight1 → fight2);
# sem música tocando, começa no 'inicio' do evento
func trocar_sincronizado(evento: StringName, recuo, crossfade):
	var posicao = -1.0
	if valido(atual) and atual.playing:
		posicao = maxf(atual.get_playback_position() - recuo, 0.0)
	tocar(evento, crossfade, posicao)

# Pede para abafar a música em 'hz'; vale o corte mais baixo entre os pedidos ativos
func pedir_abafar(nome, hz, duracao = 0.0):
	pedidos_abafar[nome] = hz
	aplicar_abafar(duracao)

# Tira um pedido de abafar e recalcula o corte
func liberar_abafar(nome, duracao = 0.0):
	pedidos_abafar.erase(nome)
	aplicar_abafar(duracao)

# Leva o corte do low-pass do bus Musica ao menor pedido (sem pedidos, aberto)
func aplicar_abafar(duracao):
	var filtro = filtro_low_pass()
	if filtro == null:
		return
	var alvo = ABERTO_HZ
	for hz in pedidos_abafar.values():
		alvo = minf(alvo, hz)
	if tween_abafar != null:
		tween_abafar.kill()
	if duracao <= 0:
		filtro.cutoff_hz = alvo
		return
	tween_abafar = create_tween().set_ignore_time_scale()
	tween_abafar.tween_property(filtro, "cutoff_hz", alvo, duracao)

# Pede para abaixar a música 'db' (negativo) em 'duracao' s; vale o mais baixo entre os pedidos
# (a caixa de diálogo abaixa enquanto está aberta). Não mexe no volume do jogador (bus)
func pedir_abaixar(nome, db, duracao = 0.0):
	pedidos_abaixar[nome] = db
	aplicar_abaixar(duracao)

# Tira um pedido de abaixar e recalcula
func liberar_abaixar(nome, duracao = 0.0):
	pedidos_abaixar.erase(nome)
	aplicar_abaixar(duracao)

# Leva o Amplify do bus Musica ao pedido mais baixo (sem pedidos, 0 dB)
func aplicar_abaixar(duracao):
	var amplificador = efeito_do_bus("AudioEffectAmplify")
	if amplificador == null:
		return
	var alvo = 0.0
	for db in pedidos_abaixar.values():
		alvo = minf(alvo, db)
	if tween_abaixar != null:
		tween_abaixar.kill()
	if duracao <= 0:
		amplificador.volume_db = alvo
		return
	tween_abaixar = create_tween().set_ignore_time_scale()
	tween_abaixar.tween_property(amplificador, "volume_db", alvo, duracao)

# O AudioEffectLowPassFilter do bus Musica (erro se o bus ou o efeito não existem)
func filtro_low_pass():
	return efeito_do_bus("AudioEffectLowPassFilter")

# O efeito da classe 'classe' no bus Musica (erro se o bus ou o efeito não existem)
func efeito_do_bus(classe):
	var indice = AudioServer.get_bus_index(BUS)
	if indice < 0:
		push_error("Musica: o bus '%s' não existe (default_bus_layout.tres)" % BUS)
		return null
	for i in range(AudioServer.get_bus_effect_count(indice)):
		var efeito = AudioServer.get_bus_effect(indice, i)
		if efeito.is_class(classe):
			return efeito
	push_error("Musica: o bus '%s' não tem %s" % [BUS, classe])
	return null

# Faz um player sumir em 'duracao' s e parar (0 = para na hora). O fade é linear na
# AMPLITUDE: em dB a música despencaria no começo e soaria como um corte
func sumir(player, duracao):
	if player == null:
		return
	if duracao <= 0:
		player.stop()
		return
	var tween = novo_tween()
	tween.tween_method(definir_amplitude.bind(player), db_to_linear(player.volume_db), 0.0, duracao)
	tween.tween_callback(player.stop)

# Volume por amplitude (0 a 1+), sem descer abaixo do silêncio
func definir_amplitude(amplitude, player):
	player.volume_db = maxf(linear_to_db(amplitude), SILENCIO_DB)

# O player ainda existe (o adotado some quando a main é liberada)
func valido(player):
	return player != null and is_instance_valid(player)

# Tween em tempo real, guardado para o limpar() e o cortar() poderem matar
func novo_tween():
	tweens = tweens.filter(func(antigo): return antigo.is_valid())
	var tween = create_tween().set_ignore_time_scale()
	tweens.append(tween)
	return tween

# Mata todos os tweens de volume em andamento
func matar_tweens():
	for tween in tweens:
		if tween.is_valid():
			tween.kill()
	tweens.clear()
