# Barra do power-up ativo na HUD: ícone + tempo restante, piscando nos últimos 2 s.
extends Node2D

const LARGURA = 40
const ALTURA = 4
const PISCAR_EM = 2.0

@onready var player = $"../../player"

# Decide a piscada e pede um novo desenho
func _process(_delta):
	var restante = player.timer_power.time_left
	if player.powerup_ativo != null and restante <= PISCAR_EM:
		modulate.a = 1.0 if int(restante * 8) % 2 == 0 else 0.25
	else:
		modulate.a = 1.0
	queue_redraw()

# Desenha o 1º quadro do sprite como ícone e, ao lado, a barra proporcional ao tempo
func _draw():
	var pu = player.powerup_ativo
	if pu == null:
		return
	var t = player.timer_power
	var lado = float(pu.sprite.get_width()) / pu.quadros
	var regiao = Rect2(0, 0, lado, pu.sprite.get_height())
	draw_texture_rect_region(pu.sprite, Rect2(Vector2.ZERO, regiao.size), regiao)
	var y = round((regiao.size.y - ALTURA) / 2.0)
	draw_rect(Rect2(lado + 3, y, LARGURA, ALTURA), Color(0.15, 0.15, 0.15))
	var fracao = t.time_left / t.wait_time
	draw_rect(Rect2(lado + 3, y, round(LARGURA * fracao), ALTURA), pu.cor_barra)
