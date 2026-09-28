# Chão: cria uma fileira de blocos de ferro (4 px cada) na base da tela.
extends Node

var Bloco = preload("res://cenas/geral/bloco.tscn")


func _ready():
	var largura_da_tela = 254
	var altura_da_tela = 256
	var n_blocos = ceili(largura_da_tela / 4.0)
	
	for i in range(n_blocos):
		var bloco = Bloco.instantiate()
		bloco.virar_ferro()
		bloco.global_position = Vector2(1+i*4, altura_da_tela-2)
		add_child(bloco)
