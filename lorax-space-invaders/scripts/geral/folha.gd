# Folha das bases: some no primeiro golpe.
extends StaticBody2D

var golpes = 0

func _ready():
	comprovar_golpes()
	
# Chamada por míssil, árvore e alien que encosta
func receber_dano(quantidade = 1, _fonte = ""):
	golpes += quantidade
	comprovar_golpes()

func comprovar_golpes():
	if golpes >= 1:
		queue_free()
