# Folha das bases: some no primeiro golpe.
extends StaticBody2D

var golpes = 0

func _ready():
	comprovar_golpes()
	
# Some na hora (explosão da árvore)
func quebrar():
	queue_free()
	
func destruir():
	golpes +=1
	comprovar_golpes()

func comprovar_golpes():
	if golpes == 1:
		queue_free()
