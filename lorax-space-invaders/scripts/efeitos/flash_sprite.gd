# Flash de cor num Sprite2D (flash de hit, brilho de carga, olhos vermelhos), pelo
# flash.gdshader. Fica como filho do sprite (ou aponte 'sprite' para ele).
class_name FlashSprite
extends Node

const MATERIAL_FLASH = preload("res://recursos/efeitos/flash_material.tres")

## O Sprite2D que pisca
@export var sprite: NodePath = ^".."

var material_flash: ShaderMaterial
var tween: Tween = null

# Dá ao sprite uma cópia própria do material: dada por código, a mesma instância
# seria compartilhada e todos os sprites piscariam juntos
func _ready():
	material_flash = MATERIAL_FLASH.duplicate()
	get_node(sprite).material = material_flash

# Acende a cor em 'alfa' e apaga até 0 em 'duracao' segundos (tempo real)
func flash(cor, alfa, duracao):
	comecar(cor)
	tween.tween_method(definir_intensidade, alfa, 0.0, duracao)

# Pulsa entre 0 e 'maximo' a cada 'periodo' segundos, até parar()
func pulsar(cor, maximo, periodo):
	comecar(cor)
	tween.set_loops()
	tween.tween_method(definir_intensidade, 0.0, maximo, periodo / 2.0)
	tween.tween_method(definir_intensidade, maximo, 0.0, periodo / 2.0)

# Desliga na hora
func parar():
	if tween != null:
		tween.kill()
	definir_intensidade(0.0)

# Mata o efeito anterior, troca a cor e prepara um tween novo em tempo real
func comecar(cor):
	if tween != null:
		tween.kill()
	material_flash.set_shader_parameter("cor_flash", cor)
	tween = create_tween().set_ignore_time_scale()

# Quanto da cor cobre o sprite (0 a 1)
func definir_intensidade(valor):
	material_flash.set_shader_parameter("intensidade", valor)
