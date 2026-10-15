# Controla a horda: cria as waves, desce os aliens, sorteia quem atira,
# aumenta a dificuldade e cria o boss e os snipers.
extends Node

# Cenas dos inimigos
var Alien = preload("res://cenas/alien/alien.tscn")
var Bonus = preload("res://cenas/alien/bonus.tscn")
var AlienForte = preload("res://cenas/alien/alien_forte.tscn")
var Sniper = preload("res://cenas/alien/sniper.tscn")


@onready var timer_disparar = $timers/TimerTiro

# lista_aliens: uma lista por fila (4 filas de 8). Filas vazias continuam na lista
var lista_aliens = []
var direcao_wave = 1
var boss_morto = false	
# A cada 3 waves, uma fila a mais de aliens fortes (máx. 4)
const WAVES_FORTE = 3
# Snipers: a partir da wave 5, entra um novo por wave se houver canto livre (máximo 2)
const WAVE_SNIPER = 5
const SLOTS_SNIPER = [Vector2(13, 49), Vector2(241, 49)]
# Na wave do boss não nasce horda nova; a main reage a este sinal (hud, spawner)
const WAVE_BOSS = 10
signal wave_boss_chegou
# Emitido uma vez, quando não sobra alien, sniper nem Lorax antigo na tela
signal boss_pode_entrar
# O Lorax antigo zerou a vida (repassado dele): a main fala e depois manda ele fugir
signal lorax_antigo_derrotado(bonus)
var em_boss = false
var lorax_antigo = null
var timer_boss_limpo: Timer
# Passagem 9→10: a wave 10 só começa com a tela vazia (aliens, snipers, Lorax antigo e tiros
# inimigos) por ESPERA_TELA_VAZIA s seguidos (valor TESTE); a vigia confere a cada ESPERA_VIGIA s
const ESPERA_TELA_VAZIA = 3.0
const ESPERA_VIGIA = 0.5
var esperando_boss = false
var timer_espera_vigia: Timer
var timer_tela_vazia: Timer

# O boss aparece uma única vez, entre 5 e 10 s depois do início
func _ready():
	# Cheat "LAB DE EFEITOS" / "LAB DE SONS" / "LAB DE TEXTOS": nada de horda, Lorax antigo nem timers
	if Partida.etapa_inicial in [Partida.Etapa.LAB_EFEITOS, Partida.Etapa.LAB_SONS, Partida.Etapa.LAB_TEXTOS]:
		for timer in $timers.get_children():
			timer.stop()
		return
	# Cheat "WAVE DO BOSS": sem Lorax antigo; espera a main conectar os sinais
	# (o _ready dela roda depois do meu) e pula direto para a wave anterior ao boss
	if Partida.etapa_inicial == Partida.Etapa.WAVE_BOSS:
		await get_parent().ready
		Partida.definir_wave(WAVE_BOSS - 1)
		entrar_wave_boss()
		return
	$timers/TimerBonus.wait_time = randf_range(5.0, 10.0)
	$timers/TimerBonus.one_shot = true
	$timers/TimerBonus.start()
	criar_horda()

# ===== SISTEMA DE DIFICULDADE =====
var nivel = 0
const BASE_DESCE = 3.0
const BASE_WAVE  = 21.0
const BASE_MOV   = 0.5
const PISO       = 0.4

# Multiplicador dos tempos: 0.9^nivel (10% mais rápido por nível), nunca abaixo de 0.4
func fator_dificuldade():
	return max(pow(0.9, nivel), PISO)

# Aplica o fator aos timers e à velocidade dos aliens vivos
func aplicar_dificuldade():
	var f = fator_dificuldade()
	$timers/TimerDesce.wait_time = BASE_DESCE * f
	$timers/TimerWave.wait_time  = BASE_WAVE  * f
	for fila in lista_aliens:
		for a in fila:
			if is_instance_valid(a):
				a.acelerar_movimento(BASE_MOV * f)

# A cada 15 s o jogo sobe um nível
func _on_timer_dificuldade_timeout():
	nivel += 1
	aplicar_dificuldade()



# Cria uma horda 4x8; as filas de cima viram aliens fortes conforme a wave
func criar_horda():
	if Partida.wave + 1 >= WAVE_BOSS:
		comecar_espera_boss()
		return
	var wave = Partida.avancar_wave()
	var linhas_fortes = mini(floori(wave / float(WAVES_FORTE)), 4)
	for i in range(4):
		var fila = []
		for j in range (8):
			var alien
			if i < linhas_fortes:
				alien = AlienForte.instantiate()
			else:
				alien = Alien.instantiate()
			alien.global_position = Vector2(56 + 20*j, 60 + 20*i)
			alien.direction = direcao_wave
			add_child(alien)
			alien.acelerar_movimento(BASE_MOV * fator_dificuldade())
			fila.append(alien)
			# Sai da lista ao morrer ou ao bater num bloco; a main soma os pontos
			alien.connect("alien_eliminado", Callable(self, "eliminar_alien"))
			alien.connect("alien_atingiu_base", Callable(self, "eliminar_alien"))
		lista_aliens.append(fila)
	# Snipers entram depois que o letreiro WAVE some (TimerSniper = 4,5 s)
	if wave >= WAVE_SNIPER:
		$timers/TimerSniper.start()

# Tira o alien da lista e vê se já dá para adiantar a próxima wave
func eliminar_alien(a):
	for fila in lista_aliens:
		for i in range(len(fila)):
			if a == fila[i]:
				fila.remove_at(i)
				checar_proxima_wave()
				return
				
			
# true quando todas as filas estão vazias
func horda_vazia():
	for fila in lista_aliens:
		if fila.size() > 0:
			return false
	return true

# A horda inteira desce 16 px
func _on_timer_desce_timeout():
	for fila in lista_aliens:
		for a in fila:
			if is_instance_valid(a):
				a.position.y += 16

# Sorteia um alien vivo para atirar e sorteia o próximo intervalo
func _on_timer_tiro_timeout():
	var lista_aliens_vivos = []
	for fila in lista_aliens:
		for a in fila:
			if is_instance_valid(a) and !a.is_queued_for_deletion():
				lista_aliens_vivos.append(a)
				
	if lista_aliens_vivos:
		var indice = int(floor(randf_range(0, len(lista_aliens_vivos))))
		lista_aliens_vivos[indice].disparar()
		timer_disparar.wait_time = randf_range(2, 5) * fator_dificuldade()


# Cria o boss e liga os sinais dele à main (pontos, corações) e a este nó (próxima wave)
func _on_timer_bonus_timeout():
	var bonus = Bonus.instantiate()
	var hud = get_parent().get_node("hud")
	bonus.boss_dano.connect(hud.perder_vida_boss)
	bonus.boss_apareceu.connect(hud.mostrar_vida_boss)
	bonus.boss_desceu.connect(hud.parar_piscada_boss)
	bonus.bonus_eliminado.connect(_on_boss_morreu)
	bonus.derrotado.connect(lorax_antigo_derrotado.emit.bind(bonus))
	lorax_antigo = bonus
	self.add_child(bonus)
	$loraxChegada.play()

# Adianta a wave só depois que o boss morreu E a horda foi toda destruída
func checar_proxima_wave():
	if em_boss or esperando_boss:
		return
	if boss_morto and horda_vazia() and $timers/TimerProximaWave.is_stopped():
		$timers/TimerProximaWave.start()

func _on_boss_morreu():
	boss_morto = true
	checar_proxima_wave()
	
# A wave 9 acabou: nada novo nasce (horda, sniper, Lorax antigo) e a vigia espera a tela vazia.
# Os aliens que sobraram continuam descendo e atirando
func comecar_espera_boss():
	if esperando_boss or em_boss:
		return
	esperando_boss = true
	parar_timers_de_wave()
	timer_tela_vazia = Timer.new()
	timer_tela_vazia.one_shot = true
	timer_tela_vazia.wait_time = ESPERA_TELA_VAZIA
	timer_tela_vazia.timeout.connect(_on_timer_tela_vazia_timeout)
	add_child(timer_tela_vazia)
	timer_espera_vigia = Timer.new()
	timer_espera_vigia.wait_time = ESPERA_VIGIA
	timer_espera_vigia.timeout.connect(_on_timer_espera_vigia_timeout)
	add_child(timer_espera_vigia)
	timer_espera_vigia.start()

# Tela vazia: a contagem corre; apareceu algo: a contagem volta do zero
func _on_timer_espera_vigia_timeout():
	if not esperando_boss:
		return
	if tela_vazia():
		if timer_tela_vazia.is_stopped():
			timer_tela_vazia.start()
	else:
		timer_tela_vazia.stop()

# A tela ficou vazia o tempo todo: a wave 10 começa
func _on_timer_tela_vazia_timeout():
	if tela_vazia():
		entrar_wave_boss()

# Avança para a wave 10 e começa a wave do boss (fim da espera, cheat WAVE DO BOSS e tecla J)
func entrar_wave_boss():
	esperando_boss = false
	for timer in [timer_espera_vigia, timer_tela_vazia]:
		if timer != null:
			timer.stop()
			timer.queue_free()
	timer_espera_vigia = null
	timer_tela_vazia = null
	Partida.avancar_wave()
	comecar_wave_boss()

# Nenhuma horda, sniper ou Lorax antigo novo
func parar_timers_de_wave():
	$timers/TimerWave.stop()
	$timers/TimerProximaWave.stop()
	$timers/TimerSniper.stop()
	$timers/TimerBonus.stop()

# Wave do boss: para de criar hordas e snipers e começa a vigiar a tela até ela ficar limpa
func comecar_wave_boss():
	em_boss = true
	parar_timers_de_wave()
	wave_boss_chegou.emit()
	timer_boss_limpo = Timer.new()
	timer_boss_limpo.wait_time = 0.5
	timer_boss_limpo.timeout.connect(_on_timer_boss_limpo_timeout)
	add_child(timer_boss_limpo)
	timer_boss_limpo.start()

# Com a tela limpa, avisa a main que o boss final pode entrar
func _on_timer_boss_limpo_timeout():
	if tela_limpa():
		timer_boss_limpo.stop()
		boss_pode_entrar.emit()

# Debug (tecla J): apaga aliens, snipers, Lorax antigo e tiros inimigos sem pontos nem sons; o
# timer_boss_limpo vê a tela limpa e avisa a main normalmente
func limpar_tela_debug():
	for fila in lista_aliens:
		fila.clear()
	for grupo in ["aliens", "misseis", "tiros_inimigos"]:
		for no in get_tree().get_nodes_in_group(grupo):
			no.remove_from_group(grupo)
			no.queue_free()

# true sem nenhum alien, sniper ou Lorax antigo na tela
func tela_limpa():
	return horda_vazia() and get_tree().get_nodes_in_group("aliens").is_empty()

# tela_limpa e também sem tiro inimigo no ar (míssil, tiro de sniper, árvore do Lorax antigo)
func tela_vazia():
	return tela_limpa() and get_tree().get_nodes_in_group("tiros_inimigos").is_empty()

# Wave por tempo: inverte a direção e cria outra horda (a anterior continua em jogo)
func _on_timer_wave_timeout():
	direcao_wave *= -1
	criar_horda()
	
# Wave adiantada: cria a horda e reinicia a contagem do TimerWave
func _on_timer_proxima_wave_timeout():
	if em_boss or esperando_boss:
		return
	if horda_vazia():
		_on_timer_wave_timeout()
		if not esperando_boss:
			$timers/TimerWave.start()
		
# Cria UM sniper por wave no primeiro canto livre (esquerda antes da direita).
func _on_timer_sniper_timeout():
	if em_boss or esperando_boss:
		return
	for slot in SLOTS_SNIPER:
		if slot_livre(slot):
			var lado = -1 if slot.x < 127 else 1
			var s = Sniper.instantiate()
			s.global_position = Vector2(slot.x + 30 * lado, slot.y)
			s.alvo = slot
			get_parent().add_child(s)
			return

# Um canto está livre se nenhum sniper tem ele como alvo
func slot_livre(slot):
	for s in get_tree().get_nodes_in_group("snipers"):
		if s.alvo == slot:
			return false
	return true
	
