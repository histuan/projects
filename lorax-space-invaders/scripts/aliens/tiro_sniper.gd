# Bala do sniper: linha reta na direção travada pelo sniper (ele define tiro.direcao).
# Sem grupo de propósito: não entra em "misseis" (não tira vida ao passar do chão)
# e atravessa os blocos (o único alvo é o player).
extends Projetil

func _init():
	velocidade = 120.0
	direcao = Vector2.DOWN
	grupos_alvo = ["tanque"]
