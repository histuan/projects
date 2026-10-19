# Cena principal da partida. Zera o estado (autoload Partida)
extends Node

@onready var camera = $Camera2D
@onready var player = $player

const BATALHA_FINAL = preload("res://cenas/boss/batalha_final.tscn")
# Estilo do letreiro FINAL WAVE (pisca e fade); o tempo na tela é o do alarme
const LETREIRO_FINAL_WAVE = preload("res://recursos/boss/letreiros/final_wave.tres")

# Ferramentas dos efeitos da boss fight: regras, cores, tela e partículas (afinadas no
# Inspector). Os momentos da luta moram no momentos_boss.tres (autoload Momentos)
const EFEITOS = preload("res://recursos/boss/efeitos_boss.tres")
const LabEfeitos = preload("res://scripts/geral/lab_efeitos.gd")
const LabSons = preload("res://scripts/geral/lab_sons.gd")
const LabTextos = preload("res://scripts/geral/lab_textos.gd")
const PainelDebug = preload("res://scripts/geral/painel_debug.gd")

# Silêncio da wave 10 (valores de teste): as estrelas desaceleram até SILENCIO_ESTRELAS_FATOR em
# SILENCIO_ESTRELAS_TEMPO s (ease-out); silêncio mais curto que isso = SILENCIO_FRACAO dele.
# Quando o alarme toca, voltam a ×1 em SILENCIO_VOLTA_TEMPO s (0 = na hora)
const SILENCIO_ESTRELAS_TEMPO = 1.5
const SILENCIO_FRACAO = 0.7
const SILENCIO_ESTRELAS_FATOR = 0.2
const SILENCIO_VOLTA_TEMPO = 0.0
# Debug (tecla J): fade (s) do alarme cortado ao pular a intro
const PULO_CORTE_ALARME = 0.1
# Transformação: fade (s) dos itens soltos, dos tiros do player e da barra do power-up que somem
# (valor de teste; o planeta usa o fade_saida dele)
const LIMPEZA_FADE = 0.3
# Dono do travamento do player durante a transformação
const DONO_TRANSFORMACAO = &"transformacao"
# Morte da nave na arena: os números dela (o corte da música mora lá) e o z do véu preto que cobre
# o mundo inteiro (a nave fica 1 acima dele)
const MORTE_ARENA = preload("res://recursos/player/morte_arena.tres")
const VEU_MORTE_Z = 100

# 1 vida na luta: batimento, música abafada e bordas vermelhas ligados
var vida_baixa_ligada = false
# Conta o fade da música do jogo (começa quando a wave 10 chega; pausa com o jogo)
var relogio_fade: Timer = null
# Painel de debug (F3); só existe em build de debug
var painel_debug = null
var caixa_dialogo: CaixaDialogo
# Tinta sobre o fundo (tom vermelho da fase 2), logo depois do nó 'fundo'
var tinta_fundo: TintaFundo
# Segunda tinta, por cima da vermelha: o escuro da transformação (pedido escurecer_fundo)
var escurecedor: TintaFundo
# A batalha final (null antes da wave 10 e no LAB)
var batalha = null
# A fala de fuga do Lorax antigo já apareceu nesta partida (é uma vez só)
var lorax_antigo_falou = false
# Debug (tecla J): a intro da wave 10 foi pulada (a sequência de _on_boss_pode_entrar para no
# próximo await) e a sequência já tinha começado
var intro_pulada = false
var sequencia_wave10 = false
# O FINAL WAVE na tela (null fora do alarme)
var letreiro_final_wave = null
# Véu preto por cima de todo o mundo (a nave morrendo na arena fica sozinha no preto)
var veu_morte: TintaFundo
# A nave morreu na arena e o mundo está escondido (o R do LAB desfaz)
var morte_arena_ligada = false
var z_player_antes = 0

# _enter_tree roda ANTES do _ready de qualquer filho
func _enter_tree():
	Partida.nova_partida()

# Saindo da partida (game over, Reiniciar, Menu): o tempo do jogo volta ao normal, os
# momentos agendados são cancelados e os autoloads de áudio soltam tudo (senão o
# batimento e a música continuariam no menu)
func _exit_tree():
	TempoJogo.limpar()
	Momentos.limpar()
	Sons.parar_tudo()
	Musica.limpar()

# Música, ajustes da câmera e da tela, ferramentas dos momentos, reações aos sinais da
# Partida, tiro travado durante as falas e o LAB (cheat)
func _ready():
	Musica.adotar($sons/musga)
	camera.configurar(EFEITOS)
	$EfeitosTela.configurar(EFEITOS)
	caixa_dialogo = CaixaDialogo.new()
	add_child(caixa_dialogo)
	tinta_fundo = TintaFundo.new()
	add_child(tinta_fundo)
	move_child(tinta_fundo, $fundo.get_index() + 1)
	escurecedor = TintaFundo.new()
	escurecedor.pedido = &"escurecer_fundo"
	add_child(escurecedor)
	move_child(escurecedor, tinta_fundo.get_index() + 1)
	veu_morte = TintaFundo.new()
	veu_morte.pedido = &""
	veu_morte.z_index = VEU_MORTE_Z
	add_child(veu_morte)
	Momentos.registrar(camera, $EfeitosTela, $fundo/estrelas, self, EFEITOS, $hud, caixa_dialogo)
	caixa_dialogo.abriu.connect(player.bloquear_tiro.bind(&"caixa"))
	# Diferido: o Espaço que fecha a caixa não pode virar tiro no mesmo quadro
	caixa_dialogo.fechou.connect(player.liberar_tiro.bind(&"caixa"), CONNECT_DEFERRED)
	Partida.vida_perdida.connect(_on_vida_perdida)
	Partida.vida_ganha.connect($sons/coletarCoracao.play)
	Partida.morreu.connect(_on_morreu)
	Partida.vidas_mudaram.connect(atualizar_vida_baixa)
	$groupAlien.wave_boss_chegou.connect($hud.esconder_placar)
	$groupAlien.wave_boss_chegou.connect($spawner.parar_planeta)
	$groupAlien.wave_boss_chegou.connect(_on_wave_boss_chegou)
	$groupAlien.boss_pode_entrar.connect(_on_boss_pode_entrar)
	$groupAlien.lorax_antigo_derrotado.connect(_on_lorax_antigo_derrotado)
	$hud.coracao_boss_perdido.connect(_on_coracao_boss_perdido)
	$hud.ultimo_coracao_boss.connect(_on_ultimo_coracao_boss)
	$hud.coracoes_boss_reencheram.connect(_on_coracoes_boss_reencheram)
	if EFEITOS.hud_treme:
		camera.tremeu.connect($hud.acompanhar_tremor)
	if OS.is_debug_build():
		painel_debug = PainelDebug.new()
		add_child(painel_debug)
		painel_debug.pediu_tirar_coracao.connect(_on_debug_tirar_coracao)
		painel_debug.pediu_pular_intro.connect(_on_debug_pular_intro)
	if Partida.etapa_inicial == Partida.Etapa.LAB_EFEITOS:
		abrir_lab()
	elif Partida.etapa_inicial == Partida.Etapa.LAB_SONS:
		abrir_lab_sons()
	elif Partida.etapa_inicial == Partida.Etapa.LAB_TEXTOS:
		abrir_lab_textos()
	elif Partida.etapa_inicial == Partida.Etapa.FASE_2:
		comecar_fase2_direto()
	elif Partida.etapa_inicial == Partida.Etapa.TRANSFORMACAO:
		comecar_transformacao_direto()

# LAB DE EFEITOS: painel que toca cada momento do momentos_boss.tres; o spawner para (nada
# cai nem passa) e o boneco do Lorax fica no mundo (filho da main) para tremor e zoom valerem
func abrir_lab():
	$spawner.parar_tudo()
	var lab = LabEfeitos.new()
	add_child(lab)
	lab.preparar(camera, $EfeitosTela, $fundo/estrelas, EFEITOS, self, $hud, player, $cenario)
	lab.resetou.connect(_on_lab_resetou)

# O R do LAB: as tintas do fundo ficam transparentes e o mundo escondido pela morte na arena volta
func _on_lab_resetou():
	limpar_tintas()
	desfazer_morte_arena()

# As duas tintas do fundo (vermelha e escurecedor) voltam a ficar transparentes
func limpar_tintas():
	tinta_fundo.limpar()
	escurecedor.limpar()

# LAB DE SONS: toca cada evento do sons_boss.tres (a música do jogo segue tocando,
# para dar para ouvir os crossfades a partir dela)
func abrir_lab_sons():
	var lab = LabSons.new()
	add_child(lab)
	lab.iniciar()

# LAB DE TEXTOS: mostra cada letreiro e cada fala como a luta mostra
func abrir_lab_textos():
	var lab = LabTextos.new()
	add_child(lab)
	lab.preparar($hud, caixa_dialogo)

# Cheat FASE 2: o mundo como a transição 1→2 deixa (wave do boss sem placar e sem planeta, música
# da luta, tinta vermelha com os números do pico, que não toca) e a luta já na Classica2
func comecar_fase2_direto():
	$groupAlien.entrar_luta_direta()
	$hud.esconder_placar()
	$spawner.parar_planeta()
	Partida.comecar_luta_boss()
	atualizar_vida_baixa(Partida.vidas)
	Musica.cortar()
	Musica.tocar(&"musica_wave10", 0.0)
	pintar_tom_vermelho()
	comecar_batalha(&"Classica2")

# Cheat TRANSFORMAÇÃO: o mundo como a derrota da fase 2 deixa (wave do boss sem placar e sem planeta,
# música da luta, tinta vermelha, estrelas da fase 2 paradas) e a transformação já começando
func comecar_transformacao_direto():
	$groupAlien.entrar_luta_direta()
	$hud.esconder_placar()
	$spawner.parar_planeta()
	Partida.comecar_luta_boss()
	atualizar_vida_baixa(Partida.vidas)
	Musica.cortar()
	Musica.tocar(&"musica_wave10", 0.0)
	pintar_tom_vermelho(&"f2_desespero")
	Momentos.tocar(&"fase2_estrelas")
	Momentos.tocar(&"derrota_f2_estrelas")
	comecar_batalha(&"Transformacao")

# A tinta vermelha na hora, com os números do 'tom_vermelho' do momento pedido (os cheats): por
# padrão o pico da transição 1→2 (fase 2); o da TRANSFORMAÇÃO pede o pico do desespero
func pintar_tom_vermelho(momento = &"transicao_1_2_pico"):
	var tom = Momentos.parametros(momento, &"tom_vermelho")
	tinta_fundo.tingir(tom.get("cor", Color.BLACK), tom.get("alfa", 0.0), 0.0)

# Wave 10 começou: a música do jogo some, e ficar com 1 vida passa a ligar a vida baixa
func _on_wave_boss_chegou():
	Partida.comecar_luta_boss()
	atualizar_vida_baixa(Partida.vidas)
	Musica.fade_out(Sons.BIBLIOTECA.wave10_fade_musica)
	relogio_fade = Timer.new()
	relogio_fade.one_shot = true
	relogio_fade.ignore_time_scale = true
	add_child(relogio_fade)
	relogio_fade.start(Sons.BIBLIOTECA.wave10_fade_musica)

# Tela limpa na wave do boss: espera a música do jogo terminar de sumir (se ainda não
# sumiu), silêncio com as estrelas quase paradas, alarme (bordas, tremor) com FINAL WAVE
# piscando e, quando o letreiro some, a música do Lorax 2.0 entra junto com a descida dele
# e as estrelas aceleram. Tudo pausa com o jogo. Pulada (tecla J), cada await sai na volta
func _on_boss_pode_entrar():
	if intro_pulada:
		pular_sequencia_wave10()
		return
	sequencia_wave10 = true
	if relogio_fade != null and relogio_fade.time_left > 0:
		await esperar(relogio_fade.time_left)
		if intro_pulada:
			return
	var silencio = Sons.BIBLIOTECA.wave10_silencio
	var desacelera = silencio * SILENCIO_FRACAO if silencio < SILENCIO_ESTRELAS_TEMPO else SILENCIO_ESTRELAS_TEMPO
	$fundo/estrelas.mudar_velocidade(SILENCIO_ESTRELAS_FATOR, desacelera, true)
	Momentos.tocar(&"wave10_silencio")
	await esperar(silencio)
	if intro_pulada:
		return
	$fundo/estrelas.mudar_velocidade(1.0, SILENCIO_VOLTA_TEMPO, true)
	Momentos.tocar(&"wave10_alarme")
	var alarme = Sons.tocar(&"wave_boss_alarme")
	var duracao_alarme = 0.0
	if alarme != null:
		duracao_alarme = alarme.stream.get_length() / alarme.pitch_scale
	$hud.esconder_letreiro_wave()
	letreiro_final_wave = $hud.mostrar_letreiro(LETREIRO_FINAL_WAVE, "", "", duracao_alarme)
	await letreiro_final_wave.sumiu
	letreiro_final_wave = null
	if intro_pulada:
		return
	Musica.tocar(&"musica_wave10")
	Momentos.tocar(&"wave10_musica_entra")
	comecar_batalha()

# Cria a batalha final logo depois do groupAlien na árvore (desenha atrás do cenário e
# da hud), liga os sinais dela à hud, à Partida (e ao painel de debug, se existir) e manda
# começar com a caixa de diálogo (com 'nome_fase', já nessa fase, sem entrada)
func comecar_batalha(nome_fase := &""):
	batalha = BATALHA_FINAL.instantiate()
	batalha.vida_boss_mudou.connect($hud.mostrar_vida_boss_final)
	batalha.boss_invulneravel.connect($hud.piscar_vida_boss)
	batalha.coracoes_boss_trocados.connect($hud.trocar_coracoes_boss)
	batalha.boss_entrou.connect(Partida.marcar_boss_em_cena)
	if painel_debug != null:
		batalha.fase_mudou.connect(painel_debug.mostrar_fase)
		batalha.vida_boss_mudou.connect(painel_debug.mostrar_vida_boss)
		batalha.boss_invulneravel.connect(painel_debug.mostrar_invulneravel)
	batalha.fase_mudou.connect(_on_fase_mudou)
	batalha.player_travado.connect(_on_player_travado)
	batalha.tela_limpa_pedida.connect(limpar_tela_transformacao)
	batalha.cenario_limpo_pedido.connect($cenario.sumir_sob_flash)
	batalha.terminou.connect(_on_batalha_terminou)
	add_child(batalha)
	move_child(batalha, $groupAlien.get_index() + 1)
	if nome_fase == &"":
		batalha.comecar(player, caixa_dialogo)
	else:
		batalha.comecar_direto(player, caixa_dialogo, nome_fase)

# Espera em tempo real que congela no Pause. O Timer é filho da main: se a cena trocar
# no meio, ele some junto e a sequência simplesmente não continua
func esperar(segundos):
	var timer = Timer.new()
	timer.one_shot = true
	timer.ignore_time_scale = true
	add_child(timer)
	timer.start(segundos)
	await timer.timeout
	timer.queue_free()

# Uma fase da luta começou: a Partida guarda o número dela (o "FIM" vem com 0 e não muda nada)
func _on_fase_mudou(_nome, numero):
	if numero > 0:
		Partida.definir_fase_luta(numero)

# A batalha pediu o player travado (não anda nem atira) ou solto
func _on_player_travado(ligado):
	if ligado:
		player.travar(DONO_TRANSFORMACAO)
		player.bloquear_tiro(DONO_TRANSFORMACAO)
	else:
		player.destravar(DONO_TRANSFORMACAO)
		player.liberar_tiro(DONO_TRANSFORMACAO)

# A batalha pediu a tela limpa: nada novo cai nem passa, o planeta, os itens soltos e os tiros do
# player somem com fade, e a barra do power-up some antes de o power-up acabar
func limpar_tela_transformacao():
	$spawner.parar_tudo()
	get_tree().call_group(&"itens_soltos", &"sumir", LIMPEZA_FADE)
	get_tree().call_group(&"tiros_player", &"sumir", LIMPEZA_FADE)
	await $hud.sumir_barra_power(LIMPEZA_FADE).finished
	player.encerrar_powerup()

# Acabaram as fases que existem (por enquanto só imprime)
func _on_batalha_terminou():
	print("TRANSFORMACAO ENTRARIA AQUI")

# Um coração do boss esvaziou (não vale para o último): stinger, tremor leve, hit-stop curto,
# folhinhas saindo do corpo e o coração da hud quebrando
func _on_coracao_boss_perdido():
	Momentos.tocar(&"coracao_boss_perdido", corpo_do_boss())

# Sobrou 1 coração do boss: a fase da vez decide a reação (o coração da hud bate; na fase 1 o
# boss treme, na fase 2 ele entra em desespero)
func _on_ultimo_coracao_boss():
	if batalha != null:
		batalha.ultimo_coracao()

# Debug (tecla K do painel): o boss perde um coração, como se levasse os tiros
func _on_debug_tirar_coracao():
	if batalha != null:
		batalha.tirar_coracao()

# Debug (tecla J do painel): da espera da wave 10 em diante, o boss vai direto para a luta. Com a
# batalha criada, quem pula é ela; com a sequência da main andando, ela é cortada; com a tela suja
# (na espera ou já na wave 10), a tela é limpa, a espera acaba na hora e a sequência é pulada
# quando o groupAlien avisar (uma vez só)
func _on_debug_pular_intro():
	if batalha != null:
		batalha.pular_intro()
		return
	if intro_pulada:
		return
	if $groupAlien.esperando_boss:
		fechar_fala_pendente()
		$groupAlien.limpar_tela_debug()
		intro_pulada = true
		$groupAlien.entrar_wave_boss()
		return
	if not Partida.em_luta_boss:
		return
	intro_pulada = true
	fechar_fala_pendente()
	if sequencia_wave10:
		pular_sequencia_wave10()
	else:
		$groupAlien.limpar_tela_debug()

# O mundo fica como se a sequência da wave 10 tivesse sido esperada: alarme e bordas dele
# cortados, FINAL WAVE fora, estrelas e música da luta já no lugar; a batalha começa e pula a
# entrada do boss
func pular_sequencia_wave10():
	if relogio_fade != null:
		relogio_fade.stop()
	Sons.cortar(&"wave_boss_alarme", PULO_CORTE_ALARME)
	if letreiro_final_wave != null:
		letreiro_final_wave.esconder(0.0)
	$hud.esconder_letreiro_wave()
	$EfeitosTela.voltar_para_bordas_fixas()
	$fundo/estrelas.mudar_velocidade(1.0)
	Musica.cortar()
	Musica.tocar(&"musica_wave10", 0.0)
	comecar_batalha()
	batalha.pular_intro()

# A fala do Lorax antigo, se ainda estiver aberta (ele morreu no mesmo quadro em que a wave 10
# chegou), fecha com a voz cortada e solta o congelamento dela: sem isso o groupAlien nunca veria
# a tela limpa. Ele não foge: some com a limpeza da tela
func fechar_fala_pendente():
	for conexao in caixa_dialogo.terminou.get_connections():
		if conexao.callable.get_method() == &"_on_fala_lorax_antigo_terminou":
			caixa_dialogo.terminou.disconnect(conexao.callable)
	TempoJogo.liberar(&"fala")
	if caixa_dialogo.aberta:
		caixa_dialogo.fechar()

# O corpo do boss para os momentos (null fora da luta: os passos que precisam dele não acontecem)
func corpo_do_boss():
	return batalha.corpo() if batalha != null else null

# Os corações do boss encheram (entrada da fase)
func _on_coracoes_boss_reencheram():
	Sons.tocar(&"boss_coracoes_reenchem")

# Com 1 vida durante a luta (ou no LAB DE EFEITOS, para testar): o coração bate em loop, a
# música abafa e as bordas vermelhas pulsam. Com mais vidas (ou morto), as três param
func atualizar_vida_baixa(vidas):
	var em_luta = Partida.em_luta_boss or Partida.etapa_inicial == Partida.Etapa.LAB_EFEITOS
	var deve_ligar = em_luta and vidas == 1
	if deve_ligar and not vida_baixa_ligada:
		Sons.tocar(&"batimento_vida_baixa")
		Musica.pedir_abafar(&"vida_baixa", EFEITOS.vida_baixa_abafar_hz, EFEITOS.vida_baixa_abafar_duracao)
		$EfeitosTela.bordas_fixas(EFEITOS.cor_dano, EFEITOS.vida_baixa_bordas_alfa, EFEITOS.vida_baixa_bordas_pulsar)
	elif not deve_ligar and vida_baixa_ligada:
		Sons.parar(&"batimento_vida_baixa")
		Musica.liberar_abafar(&"vida_baixa", EFEITOS.vida_baixa_abafar_duracao)
		$EfeitosTela.soltar_bordas_fixas()
	vida_baixa_ligada = deve_ligar

# Qualquer vida perdida: na arena, o momento do hit (tremor, hit-stop, bordas e som);
# fora dela, tremor leve. Em qualquer wave o coração da hud quebra (mesmo efeito do boss).
# O hit que mata na arena não toca nada: a morte na arena assume
func _on_vida_perdida():
	if player.em_arena and Partida.vidas <= 0:
		return
	if player.em_arena:
		Momentos.tocar(&"player_hit", player)
	else:
		camera.tremer(4)
	Momentos.tocar(&"coracao_player_perdido")

# Última vida: player morre + tremor forte + hit-stop; o último coração do boss para de bater
# e ele para de tremer de desespero. Na luta o boss também para, as estrelas param e, quando
# a explosão termina, o Lorax fala antes do game over. Na arena é a morte da nave pequena
func _on_morreu():
	if player.em_arena:
		morrer_na_arena()
		return
	$hud.parar_pulso_boss()
	if batalha != null:
		batalha.parar_desespero()
		batalha.parar_luta()
		Momentos.tocar(&"player_morre_luta")
		player.destruicao_terminou.connect(_on_player_destruido, CONNECT_ONE_SHOT)
	player.morrer()
	camera.tremer(21, 1.2)
	TempoJogo.congelar(0.15)

# A nave morreu na arena: o boss para, os ataques somem secos, o mundo fica preto (só a nave por
# cima), a música corta seco (se o morte_arena.tres pedir) e a nave parte e estoura. Sem o tremor e
# o hit-stop da morte normal. Na luta, quando os cacos acabam, segue o fluxo de sempre (fala e game over)
func morrer_na_arena():
	$hud.parar_pulso_boss()
	if batalha != null:
		batalha.parar_desespero()
		batalha.parar_luta()
		batalha.remover_ataques()
		Momentos.tocar(&"player_morre_luta")
		player.destruicao_terminou.connect(_on_player_destruido, CONNECT_ONE_SHOT)
	esconder_mundo()
	if MORTE_ARENA.cortar_musica:
		Musica.cortar()
	player.morrer()

# Tudo some menos a nave: o véu preto cobre o mundo e as camadas acima dele (hud, efeitos de tela,
# caixa de diálogo) somem
func esconder_mundo():
	morte_arena_ligada = true
	veu_morte.tingir(Color.BLACK, 1.0, 0.0)
	z_player_antes = player.z_index
	player.z_index = VEU_MORTE_Z + 1
	$hud.visible = false
	$EfeitosTela.limpar()
	if caixa_dialogo.aberta:
		caixa_dialogo.fechar()

# Desfaz o esconder_mundo (o R do LAB): véu fora, hud de volta, a nave no z de antes e a música
# do jogo de novo (do começo), se foi cortada
func desfazer_morte_arena():
	if not morte_arena_ligada:
		return
	morte_arena_ligada = false
	veu_morte.limpar()
	player.z_index = z_player_antes
	$hud.visible = true
	Musica.voltar_adotado()

# A explosão do player terminou na luta: a fala de morte (a de entrada, se ainda estiver aberta,
# fecha antes) e, quando ela fecha, o game over
func _on_player_destruido():
	if caixa_dialogo.aberta:
		caixa_dialogo.fechar()
	caixa_dialogo.terminou.connect(_on_fala_morte_terminou, CONNECT_ONE_SHOT)
	caixa_dialogo.falar(&"player_morre_f12")

# Fechou a fala de morte: game over
func _on_fala_morte_terminou(_nome):
	player.ir_para_game_over()

# O Lorax antigo zerou a vida na wave 1: o jogo congela, ele diz a fala e, quando a caixa
# fecha, o jogo volta e ele foge. Só na primeira vez da partida
func _on_lorax_antigo_derrotado(bonus):
	if lorax_antigo_falou:
		bonus.fugir()
		return
	lorax_antigo_falou = true
	TempoJogo.pedir(&"fala", 0.0)
	caixa_dialogo.terminou.connect(_on_fala_lorax_antigo_terminou.bind(bonus), CONNECT_ONE_SHOT)
	caixa_dialogo.falar(&"lorax_antigo_foge")

# Fechou a fala do Lorax antigo: o jogo volta e ele foge
func _on_fala_lorax_antigo_terminou(_nome, bonus):
	TempoJogo.liberar(&"fala")
	if is_instance_valid(bonus):
		bonus.fugir()
