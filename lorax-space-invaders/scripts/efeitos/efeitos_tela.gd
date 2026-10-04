# Efeitos de TELA: flash, letterbox, bordas, onda de choque e aberração cromática.
# Ordem das camadas: mundo (0) < distorção/bordas/flash (3, este nó) < HUD (5) < LAB (6)
# < letterbox (7, camada própria criada no _ready) < Pause (10). Assim o flash e a onda
# ficam abaixo dos corações e as barras cobrem a HUD. Tudo em tempo real (hit-stop e
# câmera lenta não esticam estes efeitos) e respeitando "reduzir efeitos".
extends CanvasLayer

const SHADER_TELA = preload("res://shaders/efeitos_tela.gdshader")
# Camada das barras do letterbox: acima da HUD (5) e do LAB (6), abaixo do Pause (10)
const LAYER_LETTERBOX = 7
# Janela da regra de segurança dos flashes (efeitos.md §1: N flashes por SEGUNDO)
const JANELA_FLASH_MS = 1000

# Lidos do efeitos_boss.tres em configurar()
var fator_flash_reduzido = 1.0
var alfa_maximo_flash_reduzido = 1.0
var flashes_por_segundo = 0
var barras_letterbox = 0.0
var largura_bordas = 0

var distorcao: ColorRect
var material_tela: ShaderMaterial
var desenho_bordas: Control
var retangulo_flash: ColorRect
var barra_cima: ColorRect
var barra_baixo: ColorRect

# Momentos (ms) dos flashes do último segundo
var momentos_flash = []
var forca_onda = 0.0
var px_aberracao = 0.0
var cor_bordas = Color.TRANSPARENT
var alfa_bordas = 0.0
var bordas_acesas = false

var tween_flash: Tween = null
var tween_letterbox: Tween = null
var tween_bordas: Tween = null
var tween_onda: Tween = null
var tween_aberracao: Tween = null

# Monta as camadas na ordem de desenho: distorção, bordas e flash aqui (layer 3);
# as barras do letterbox numa camada própria acima da HUD
func _ready():
	var tela = tamanho_tela()
	distorcao = criar_retangulo(tela, Color.WHITE)
	material_tela = ShaderMaterial.new()
	material_tela.shader = SHADER_TELA
	material_tela.set_shader_parameter("tamanho", tela)
	distorcao.material = material_tela
	distorcao.hide()
	desenho_bordas = Control.new()
	desenho_bordas.size = tela
	desenho_bordas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desenho_bordas.draw.connect(_desenhar_bordas)
	add_child(desenho_bordas)
	retangulo_flash = criar_retangulo(tela, Color(1, 1, 1, 0))
	var camada_letterbox = CanvasLayer.new()
	camada_letterbox.layer = LAYER_LETTERBOX
	add_child(camada_letterbox)
	barra_cima = criar_retangulo(Vector2(tela.x, 0), Color.BLACK, camada_letterbox)
	barra_baixo = criar_retangulo(Vector2(tela.x, 0), Color.BLACK, camada_letterbox)
	barra_baixo.position.y = tela.y

# Lê do efeitos_boss.tres os números que são da tela (a main chama)
func configurar(efeitos):
	fator_flash_reduzido = efeitos.fator_flash_reduzido
	alfa_maximo_flash_reduzido = efeitos.alfa_maximo_flash_reduzido
	flashes_por_segundo = efeitos.flashes_tela_por_segundo
	barras_letterbox = efeitos.letterbox_barras
	largura_bordas = efeitos.bordas_largura
	material_tela.set_shader_parameter("largura", efeitos.onda_largura)

# Acende a tela com 'cor' em 'alfa' e apaga até 0 em 'duracao' s. Devolve false se a
# regra de segurança (flashes por segundo) barrou este flash
func flash_tela(cor, alfa, duracao):
	if not pode_piscar():
		return false
	if Configuracoes.reduzir_efeitos:
		alfa = minf(alfa * fator_flash_reduzido, alfa_maximo_flash_reduzido)
	if tween_flash != null:
		tween_flash.kill()
	retangulo_flash.color = Color(cor.r, cor.g, cor.b, alfa)
	tween_flash = novo_tween()
	tween_flash.tween_property(retangulo_flash, "color:a", 0.0, duracao)
	return true

# Barras pretas de cinema entram (ligar) ou saem em 'duracao' segundos
func letterbox(ligar, duracao):
	if tween_letterbox != null:
		tween_letterbox.kill()
	var alvo = barras_letterbox if ligar else 0.0
	tween_letterbox = novo_tween()
	tween_letterbox.tween_method(definir_letterbox, barra_cima.size.y, alvo, duracao)

# Anel que sai de 'posicao_global' até 'raio_final' px em 'duracao' s, entortando a
# imagem em 'forca' e enfraquecendo até 0. Desligada com "reduzir efeitos"
func onda_choque(posicao_global, raio_final, duracao, forca):
	if Configuracoes.reduzir_efeitos:
		return
	var centro = get_viewport().get_canvas_transform() * posicao_global
	material_tela.set_shader_parameter("centro", centro)
	if tween_onda != null:
		tween_onda.kill()
	tween_onda = novo_tween().set_parallel()
	tween_onda.tween_method(definir_raio_onda, 0.0, raio_final, duracao)
	tween_onda.tween_method(definir_forca_onda, forca, 0.0, duracao)

# Separa vermelho e azul em 'px' e volta ao normal em 'volta' s. Desligada com "reduzir efeitos"
func aberracao(px, volta):
	if Configuracoes.reduzir_efeitos:
		return
	if tween_aberracao != null:
		tween_aberracao.kill()
	tween_aberracao = novo_tween()
	tween_aberracao.tween_method(definir_aberracao, px, 0.0, volta)

# Degradê de 'cor' nas bordas. pulsar = segundos aceso/apagado (0 = fixa);
# vezes = quantas piscadas (0 = até a próxima chamada). alfa 0 desliga
func bordas(cor, alfa, pulsar = 0.0, vezes = 0):
	if tween_bordas != null:
		tween_bordas.kill()
	cor_bordas = cor
	alfa_bordas = alfa
	definir_bordas_acesas(true)
	if alfa <= 0 or pulsar <= 0:
		return
	tween_bordas = novo_tween()
	tween_bordas.set_loops(vezes)
	tween_bordas.tween_callback(definir_bordas_acesas.bind(true))
	tween_bordas.tween_interval(pulsar)
	tween_bordas.tween_callback(definir_bordas_acesas.bind(false))
	tween_bordas.tween_interval(pulsar)

# As barras do letterbox estão na tela (entrando, paradas ou saindo)
func letterbox_visivel():
	return barra_cima.size.y > 0

# As bordas estão ligadas (fixas ou ainda piscando)
func bordas_visiveis():
	var piscando = tween_bordas != null and tween_bordas.is_running()
	return alfa_bordas > 0 and (bordas_acesas or piscando)

# Desliga tudo na hora (usado pelo LAB)
func limpar():
	for tween in [tween_flash, tween_letterbox, tween_bordas, tween_onda, tween_aberracao]:
		if tween != null:
			tween.kill()
	retangulo_flash.color.a = 0.0
	momentos_flash.clear()
	definir_letterbox(0.0)
	alfa_bordas = 0.0
	definir_bordas_acesas(false)
	definir_forca_onda(0.0)
	definir_aberracao(0.0)

# Regra de segurança: no máximo 'flashes_por_segundo' flashes de tela em 1 s (tempo real)
func pode_piscar():
	var agora = Time.get_ticks_msec()
	momentos_flash = momentos_flash.filter(func(momento): return agora - momento < JANELA_FLASH_MS)
	if flashes_por_segundo > 0 and momentos_flash.size() >= flashes_por_segundo:
		return false
	momentos_flash.append(agora)
	return true

# Altura das barras do letterbox (arredondada: pixel inteiro)
func definir_letterbox(altura):
	altura = roundf(altura)
	barra_cima.size.y = altura
	barra_baixo.size.y = altura
	barra_baixo.position.y = tamanho_tela().y - altura

# Raio atual do anel da onda
func definir_raio_onda(raio):
	material_tela.set_shader_parameter("raio", raio)

# Força atual da onda; mostra/esconde a distorção
func definir_forca_onda(forca):
	forca_onda = forca
	material_tela.set_shader_parameter("forca", forca)
	atualizar_distorcao()

# Separação atual das cores; mostra/esconde a distorção
func definir_aberracao(px):
	px_aberracao = px
	material_tela.set_shader_parameter("aberracao_px", px)
	atualizar_distorcao()

# A distorção só fica visível (e só custa) enquanto onda ou aberração estão ativas
func atualizar_distorcao():
	distorcao.visible = forca_onda > 0 or px_aberracao > 0

# Liga/desliga as bordas e pede um novo desenho
func definir_bordas_acesas(acesas):
	bordas_acesas = acesas
	desenho_bordas.queue_redraw()

# Degradê pixelado: uma linha de 1 px por camada, da beira para dentro, com o alfa
# caindo até 0 na última camada
func _desenhar_bordas():
	if not bordas_acesas or alfa_bordas <= 0:
		return
	var tela = desenho_bordas.size
	for i in range(largura_bordas):
		var alfa = alfa_bordas * (1.0 - float(i) / largura_bordas)
		var retangulo = Rect2(Vector2(i, i) + Vector2(0.5, 0.5), tela - Vector2(i, i) * 2 - Vector2.ONE)
		desenho_bordas.draw_rect(retangulo, Color(cor_bordas.r, cor_bordas.g, cor_bordas.b, alfa), false, 1.0)

# Retângulo de cor sem receber mouse (para não roubar clique do Pause), dentro de 'pai'
# (esta camada, se nada for dito)
func criar_retangulo(tamanho, cor, pai = self):
	var retangulo = ColorRect.new()
	retangulo.size = tamanho
	retangulo.color = cor
	retangulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(retangulo)
	return retangulo

# Tamanho da tela do jogo (254×256)
func tamanho_tela():
	return get_viewport().get_visible_rect().size

# Tween que ignora o time_scale (efeitos.md 2b.3)
func novo_tween():
	return create_tween().set_ignore_time_scale()
