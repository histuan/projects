# Câmera fixa da partida: tremor de tela (pontual e contínuo) e zoom.
# Tudo em tempo real: hit-stop e câmera lenta (TempoJogo) não esticam nem congelam estes efeitos.
extends Camera2D

# Quanto o tremor sem duração perde de força por segundo
const QUEDA_PADRAO = 20.0

# Tremor pontual: força atual e quanto ela diminui por segundo
var forca_tremor = 0.0
var queda_tremor = QUEDA_PADRAO
# Tremor contínuo: força levada por tween até parar_tremor_continuo()
var forca_continua = 0.0
var tween_continuo: Tween = null

# Deslocamento do zoom/foco; o tremor é somado por cima a cada quadro
var offset_base = Vector2.ZERO
var tween_zoom: Tween = null

# Ajustados pela main a partir do efeitos_boss.tres
var zoom_ligado = true
var fator_tremor_reduzido = 1.0

# Relógio real (ms) do quadro anterior
var ultimo_tick = 0

# Começa o relógio real
func _ready():
	ultimo_tick = Time.get_ticks_msec()

# Ao sair do Pause, recomeça o relógio real (senão o tremor pularia o tempo pausado)
func _notification(what):
	if what == NOTIFICATION_UNPAUSED:
		ultimo_tick = Time.get_ticks_msec()

# Começa um tremor. Um mais fraco não substitui um mais forte que ainda está rolando.
# duracao > 0: zera em 'duracao' segundos; senão cai QUEDA_PADRAO por segundo
func tremer(forca, duracao = 0.0):
	if forca < forca_tremor:
		return
	forca_tremor = forca
	if duracao > 0:
		queda_tremor = forca / duracao
	else:
		queda_tremor = QUEDA_PADRAO

# Tremor que vai de 'de' até 'ate' em 'duracao' segundos e fica em 'ate' até ser parado
func tremer_continuo(de, ate, duracao):
	if tween_continuo != null:
		tween_continuo.kill()
	forca_continua = de
	tween_continuo = create_tween().set_ignore_time_scale()
	tween_continuo.tween_property(self, "forca_continua", ate, duracao)

# Desliga o tremor contínuo, levando a força a 0 em 'fade' segundos (0 = na hora)
func parar_tremor_continuo(fade = 0.0):
	if tween_continuo != null:
		tween_continuo.kill()
	if fade <= 0:
		forca_continua = 0.0
		return
	tween_continuo = create_tween().set_ignore_time_scale()
	tween_continuo.tween_property(self, "forca_continua", 0.0, fade)

# Zoom suave até 'fator' em 'duracao' segundos. Sem foco, centrado na tela; com foco,
# a área visível se aproxima do ponto sem mostrar nada fora da tela
func zoom_para(fator, duracao, foco_global = null):
	if not zoom_ligado:
		return
	if tween_zoom != null:
		tween_zoom.kill()
	tween_zoom = create_tween().set_ignore_time_scale().set_parallel()
	tween_zoom.tween_property(self, "zoom", Vector2(fator, fator), duracao)
	tween_zoom.tween_property(self, "offset_base", offset_para(fator, foco_global), duracao)

# Vai na hora para 'fator' (mantendo o centro do que está na tela) e volta ao zoom de
# antes em 'duracao' segundos
func zoom_punch(fator, duracao):
	if not zoom_ligado:
		return
	if tween_zoom != null:
		tween_zoom.kill()
	var zoom_antes = zoom
	var offset_antes = offset_base
	var centro = offset_base + get_viewport_rect().size / zoom / 2.0
	zoom = Vector2(fator, fator)
	offset_base = offset_para(fator, centro)
	tween_zoom = create_tween().set_ignore_time_scale().set_parallel()
	tween_zoom.tween_property(self, "zoom", zoom_antes, duracao)
	tween_zoom.tween_property(self, "offset_base", offset_antes, duracao)

# offset_base que mostra a área do zoom 'fator' centrada no foco (ou no meio da tela).
# A câmera é ancorada no canto, então o offset é o canto de cima da área visível
func offset_para(fator, foco_global):
	var tela = get_viewport_rect().size
	var visivel = tela / fator
	if fator <= 1.0:
		return (tela - visivel) / 2.0
	var centro = tela / 2.0 if foco_global == null else foco_global
	return (centro - visivel / 2.0).clamp(Vector2.ZERO, tela - visivel)

# Desconta o tremor pelo tempo real e aplica zoom + tremor no offset
func _process(_delta):
	var agora = Time.get_ticks_msec()
	var passado = (agora - ultimo_tick) / 1000.0
	ultimo_tick = agora
	forca_tremor = move_toward(forca_tremor, 0, queda_tremor * passado)
	var forca = max(forca_tremor, forca_continua)
	if Configuracoes.reduzir_efeitos:
		forca *= fator_tremor_reduzido
	var tremor = Vector2(randf_range(-forca, forca), randf_range(-forca, forca))
	offset = (offset_base + tremor).round()
