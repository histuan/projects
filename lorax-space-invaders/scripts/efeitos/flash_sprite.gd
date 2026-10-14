# Flash de cor num Sprite2D (flash de hit, brilho de carga, olhos vermelhos), pelo
# flash.gdshader. Fica como filho do sprite (ou aponte 'sprite' para ele). É o dono do
# material do sprite: a inclinação (suavizar a borda do sprite girado, ou o lean em fileiras
# inteiras) também passa por aqui.
class_name FlashSprite
extends Node

const MATERIAL_FLASH = preload("res://recursos/efeitos/flash_material.tres")

## O Sprite2D que pisca
@export var sprite: NodePath = ^".."

var material_flash: ShaderMaterial
var tween: Tween = null
# Pulso em andamento ({cor, maximo, periodo, fim}; fim em ms, -1 = sem fim). Um flash por
# cima dele não o apaga: quando o flash acaba, o pulso volta pelo tempo que falta
var pulso = null
# Estado da inclinação no material (aplicar_material junta tudo)
var lean_px := 0.0
var margem_lean := 0.0
var pes_px := 12.0
var suavizar := false

# Dá ao sprite uma cópia própria do material: dada por código, a mesma instância
# seria compartilhada e todos os sprites piscariam juntos
func _ready():
	material_flash = MATERIAL_FLASH.duplicate()
	get_node(sprite).material = material_flash

# Acende a cor em 'alfa' e apaga até 0 em 'duracao' segundos (tempo real); havendo um
# pulso, ele volta depois
func flash(cor, alfa, duracao):
	comecar(cor)
	tween.tween_method(definir_intensidade, alfa, 0.0, duracao)
	if pulso != null:
		tween.tween_callback(tocar_pulso)

# Pulsa entre 0 e 'maximo' a cada 'periodo' segundos por 'duracao' s (0 = até parar())
func pulsar(cor, maximo, periodo, duracao = 0.0):
	var fim = Time.get_ticks_msec() + duracao * 1000.0 if duracao > 0 else -1.0
	pulso = {"cor": cor, "maximo": maximo, "periodo": periodo, "fim": fim}
	tocar_pulso()

# (Re)começa o pulso guardado pelo tempo que falta; acabou o tempo, apaga
func tocar_pulso():
	if pulso == null:
		return
	var restante = (pulso.fim - Time.get_ticks_msec()) / 1000.0
	if pulso.fim >= 0 and restante <= 0:
		parar()
		return
	comecar(pulso.cor)
	if pulso.fim < 0:
		tween.set_loops()
		tween.tween_method(definir_intensidade, 0.0, pulso.maximo, pulso.periodo / 2.0)
		tween.tween_method(definir_intensidade, pulso.maximo, 0.0, pulso.periodo / 2.0)
		return
	tween.tween_method(definir_onda.bind(pulso.maximo, pulso.periodo), 0.0, restante, restante)
	tween.tween_callback(parar)

# Intensidade do pulso no instante 't': sobe de 0 a 'maximo' e desce a cada 'periodo'
func definir_onda(t, maximo, periodo):
	var fase = fmod(t, periodo) / periodo
	definir_intensidade(maximo * (1.0 - absf(2.0 * fase - 1.0)))

# Desliga na hora (e esquece o pulso)
func parar():
	pulso = null
	if tween != null:
		tween.kill()
	definir_intensidade(0.0)

# Mata o efeito anterior, troca a cor e prepara um tween novo em tempo real
func comecar(cor):
	if tween != null:
		tween.kill()
	material_flash.set_shader_parameter("cor_flash", cor)
	tween = create_tween().set_ignore_time_scale()

# Lean do shader: o topo desloca 'px' (arredondado por fileira), com 'margem' px de quad
# a mais de cada lado e os pés a 'pes' px do centro
func definir_lean(px, margem, pes):
	lean_px = px
	margem_lean = margem
	pes_px = pes
	aplicar_material()

# Sprite girado: liga/desliga a borda suavizada (1 px de quad a mais em volta para o contorno
# misturado não ser cortado)
func definir_suavizar(ligado):
	if ligado != suavizar:
		suavizar = ligado
		aplicar_material()

# Passa o estado da inclinação (e o offset atual do sprite) para o shader
func aplicar_material():
	var borda = 1.0 if suavizar else 0.0
	material_flash.set_shader_parameter("suavizar_borda", suavizar)
	material_flash.set_shader_parameter("lean_px", lean_px)
	material_flash.set_shader_parameter("margem_px", Vector2(maxf(margem_lean, borda), borda))
	material_flash.set_shader_parameter("pes_px", pes_px)
	material_flash.set_shader_parameter("offset_px", get_node(sprite).offset)

# Quanto da cor cobre o sprite (0 a 1)
func definir_intensidade(valor):
	material_flash.set_shader_parameter("intensidade", valor)
