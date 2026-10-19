# A morte da nave na arena, acompanhando os dois golpes do som: no 1º a nave parte (quadro 1 da
# folha), no 2º estoura e cada pedaço do quadro 2 vira um caco que voa. Criado por código pelo
# player; os relógios e o voo andam em tempo real e pausam com o jogo
class_name MorteArena
extends Node2D

# A nave partiu (quem mostra a nave inteira a esconde)
signal partiu
# Os cacos terminaram de voar
signal terminou

const DADOS = preload("res://recursos/player/morte_arena.tres")
const SOM = &"finalizar_golpe"

var quadro_partido: Sprite2D
var cacos: Node2D
# Peças do quadro 2: {imagem, textura, retangulo} (retângulo dentro do quadro)
var pecas = []
# Centro do desenho do quadro 2 (de onde os cacos se afastam), dentro do quadro
var centro_pecas := Vector2.ZERO
var relogios: Array[Timer] = []
var tween_cacos: Tween = null

# O quadro 1 (escondido) e as peças do quadro 2, separadas uma vez só
func _ready():
	quadro_partido = Sprite2D.new()
	quadro_partido.texture = DADOS.textura
	quadro_partido.centered = false
	quadro_partido.position = DADOS.posicao_quadro
	quadro_partido.region_enabled = true
	quadro_partido.region_rect = Rect2(Vector2.ZERO, DADOS.tamanho_quadro)
	quadro_partido.visible = false
	add_child(quadro_partido)
	cacos = Node2D.new()
	add_child(cacos)
	var imagem = DADOS.textura.get_image()
	if imagem.is_compressed():
		imagem.decompress()
	var regiao = Rect2i(Vector2i(DADOS.tamanho_quadro.x, 0), DADOS.tamanho_quadro)
	if not Rect2i(Vector2i.ZERO, imagem.get_size()).encloses(regiao):
		push_error("MorteArena: a folha %s não tem o quadro 2 (precisa de %d px de largura, tem %d)" % [
			DADOS.textura.resource_path, regiao.end.x, imagem.get_width()])
		return
	var quadro2 = imagem.get_region(regiao)
	pecas = pecas_do_quadro(quadro2)
	centro_pecas = Rect2(quadro2.get_used_rect()).get_center()

# Separa as peças da imagem (pixels com alfa > 0 ligados pelos 8 vizinhos); cada peça leva só
# os pixels dela, recortados no retângulo dela
static func pecas_do_quadro(imagem: Image) -> Array:
	var largura = imagem.get_width()
	var altura = imagem.get_height()
	var visto = {}
	var resultado = []
	for y in altura:
		for x in largura:
			var inicio = Vector2i(x, y)
			if visto.has(inicio) or imagem.get_pixelv(inicio).a <= 0:
				continue
			visto[inicio] = true
			var pixels = []
			var fila = [inicio]
			while not fila.is_empty():
				var ponto = fila.pop_back()
				pixels.append(ponto)
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var vizinho = ponto + Vector2i(dx, dy)
						if vizinho.x < 0 or vizinho.y < 0 or vizinho.x >= largura or vizinho.y >= altura:
							continue
						if visto.has(vizinho) or imagem.get_pixelv(vizinho).a <= 0:
							continue
						visto[vizinho] = true
						fila.append(vizinho)
			resultado.append(montar_peca(imagem, pixels))
	return resultado

# Uma peça: a imagem do tamanho do retângulo dela, transparente fora dos pixels dela
static func montar_peca(imagem: Image, pixels: Array) -> Dictionary:
	var menor = pixels[0]
	var maior = pixels[0]
	for ponto in pixels:
		menor = menor.min(ponto)
		maior = maior.max(ponto)
	var retangulo = Rect2i(menor, maior - menor + Vector2i.ONE)
	var recorte = Image.create_empty(retangulo.size.x, retangulo.size.y, false, Image.FORMAT_RGBA8)
	for ponto in pixels:
		recorte.set_pixelv(ponto - menor, imagem.get_pixelv(ponto))
	return {"imagem": recorte, "textura": ImageTexture.create_from_image(recorte), "retangulo": retangulo}

# Toca o som e agenda os dois golpes (contados do início do som)
func comecar():
	cancelar()
	Sons.tocar(SOM)
	agendar(DADOS.tempo_partir, partir)
	agendar(DADOS.tempo_estourar, estourar)

# Chama 'funcao' daqui a 'segundos' s em tempo real (0 = na hora)
func agendar(segundos, funcao):
	if segundos <= 0:
		funcao.call()
		return
	var relogio = Timer.new()
	relogio.one_shot = true
	relogio.ignore_time_scale = true
	relogio.timeout.connect(funcao)
	relogio.timeout.connect(relogio.queue_free)
	add_child(relogio)
	relogio.start(segundos)
	relogios.append(relogio)

# 1º golpe: aparece a nave partida
func partir():
	quadro_partido.visible = true
	partiu.emit()

# 2º golpe: a nave partida some e cada peça voa para longe do centro, girando, e some no fim
func estourar():
	quadro_partido.visible = false
	if pecas.is_empty():
		terminou.emit()
		return
	var centro_nave = DADOS.posicao_quadro + centro_pecas
	var fade = clampf(DADOS.fade_cacos, 0.0, DADOS.duracao_cacos)
	tween_cacos = create_tween().set_ignore_time_scale()
	for peca in pecas:
		var retangulo: Rect2i = peca.retangulo
		var caco = Sprite2D.new()
		caco.texture = peca.textura
		var inicio = DADOS.posicao_quadro + Vector2(retangulo.position) + Vector2(retangulo.size) / 2.0
		caco.position = inicio
		cacos.add_child(caco)
		var direcao = inicio - centro_nave
		var angulo = direcao.angle() if direcao.length() >= 0.5 else randf_range(-PI, PI)
		angulo += deg_to_rad(randf_range(-DADOS.espalhar_graus / 2.0, DADOS.espalhar_graus / 2.0))
		var velocidade = Vector2.from_angle(angulo) * randf_range(DADOS.velocidade_min, DADOS.velocidade_max)
		var giro = deg_to_rad(randf_range(0.0, DADOS.giro_max)) * (1 if randf() < 0.5 else -1)
		tween_cacos.parallel().tween_method(mover_caco.bind(caco, inicio, velocidade, giro), 0.0,
				DADOS.duracao_cacos, DADOS.duracao_cacos)
		tween_cacos.parallel().tween_property(caco, "modulate:a", 0.0, fade).set_delay(DADOS.duracao_cacos - fade)
	tween_cacos.finished.connect(terminou.emit)

# Posição e giro de um caco 't' s depois do estouro
func mover_caco(t, caco, inicio, velocidade, giro):
	caco.position = inicio + velocidade * t + Vector2(0, DADOS.gravidade * t * t / 2.0)
	caco.rotation = giro * t

# Interrompe tudo (o R do LAB): relógios, voo, som, cacos e a nave partida
func cancelar():
	for relogio in relogios:
		if is_instance_valid(relogio):
			relogio.stop()
			relogio.queue_free()
	relogios.clear()
	if tween_cacos != null:
		tween_cacos.kill()
		tween_cacos = null
	Sons.cortar(SOM)
	for caco in cacos.get_children():
		caco.queue_free()
	quadro_partido.visible = false
