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
# Snipers: a partir da wave 4, no máximo 2, um em cada canto
const WAVE_SNIPER = 5
const MAX_SNIPERS = 2
const SLOTS_SNIPER = [Vector2(13, 49), Vector2(241, 49)]
# Na wave do boss não nasce horda nova; a main reage a este sinal (hud, spawner)
const WAVE_BOSS = 10
signal wave_boss_chegou
# Emitido uma vez, quando não sobra alien, sniper nem Lorax antigo na tela
signal boss_pode_entrar
var em_boss = false
var lorax_antigo = null
var timer_boss_limpo: Timer

# O boss aparece uma única vez, entre 5 e 10 s depois do início
func _ready():
	# Cheat "LAB DE EFEITOS": nada de horda, Lorax antigo nem timers rodando
	if Partida.etapa_inicial == Partida.Etapa.LAB_EFEITOS:
		for timer in $timers.get_children():
			timer.stop()
		return
	# Cheat "WAVE DO BOSS": sem Lorax antigo; espera a main conectar os sinais
	# (o _ready dela roda depois do meu) e pula direto para a wave anterior ao boss
	if Partida.etapa_inicial == Partida.Etapa.WAVE_BOSS:
		await get_parent().ready
		Partida.definir_wave(WAVE_BOSS - 1)
		criar_horda()
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
	var wave = Partida.avancar_wave()
	if wave >= WAVE_BOSS:
		comecar_wave_boss()
		return
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
	lorax_antigo = bonus
	self.add_child(bonus)
	$loraxChegada.play()

# Adianta a wave só depois que o boss morreu E a horda foi toda destruída
func checar_proxima_wave():
	if em_boss:
		return
	if boss_morto and horda_vazia() and $timers/TimerProximaWave.is_stopped():
		$timers/TimerProximaWave.start()

func _on_boss_morreu():
	boss_morto = true
	checar_proxima_wave()
	
# Wave do boss: para de criar hordas e snipers, tira o Lorax antigo de cena e
# começa a vigiar a tela até ela ficar limpa
func comecar_wave_boss():
	em_boss = true
	$timers/TimerWave.stop()
	$timers/TimerProximaWave.stop()
	$timers/TimerSniper.stop()
	$timers/TimerBonus.stop()
	if is_instance_valid(lorax_antigo) and lorax_antigo.vivo:
		lorax_antigo.retirar()
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

# true sem nenhum alien, sniper ou Lorax antigo na tela
func tela_limpa():
	return horda_vazia() and get_tree().get_nodes_in_group("aliens").is_empty()

# Wave por tempo: inverte a direção e cria outra horda (a anterior continua em jogo)
func _on_timer_wave_timeout():
	direcao_wave *= -1
	criar_horda()
	
# Wave adiantada: cria a horda e reinicia a contagem do TimerWave
func _on_timer_proxima_wave_timeout():
	if em_boss:
		return
	if horda_vazia():
		_on_timer_wave_timeout()
		$timers/TimerWave.start()
		
# Cria os snipers que faltam: 1 nas waves 4–6, 2 a partir da 7.
# Cada um nasce 30 px fora da tela e desliza até o canto livre
func _on_timer_sniper_timeout():
	if em_boss:
		return
	var desejados = mini(1 + floori((Partida.wave - WAVE_SNIPER) / 3.0), MAX_SNIPERS)
	var vivos = get_tree().get_nodes_in_group("snipers").size()
	for slot in SLOTS_SNIPER:
		if vivos >= desejados:
			return
		if slot_livre(slot):
			var lado = -1 if slot.x < 127 else 1
			var s = Sniper.instantiate()
			s.global_position = Vector2(slot.x + 30 * lado, slot.y)
			s.alvo = slot
			get_parent().add_child(s)
			vivos += 1

# Um canto está livre se nenhum sniper tem ele como alvo
func slot_livre(slot):
	for s in get_tree().get_nodes_in_group("snipers"):
		if s.alvo == slot:
			return false
	return true
	
