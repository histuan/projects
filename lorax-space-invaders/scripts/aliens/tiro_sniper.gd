# Bala do sniper: linha reta na direção travada pelo sniper (ele define tiro.direcao).
# Não entra em "misseis" de propósito (não tira vida ao passar do chão) e atravessa os
# blocos (o único alvo é o player). Fica só em "tiros_inimigos" (a wave 10 espera ele sumir).
extends Projetil

func _init():
	velocidade = 120.0
	direcao = Vector2.DOWN
	grupos_alvo = ["tanque"]
	add_to_group("tiros_inimigos")
