# Bloco das bases e do chão: aguenta 2 golpes (o 1º troca para o sprite danificado).
# O ferro é só visual.
extends StaticBody2D

@export var madeira: Texture2D = preload("res://meus sprites/geral/bloque.png")
@export var ferro: Texture2D = preload("res://meus sprites/geral/ferro.png")

var golpes = 0
var eh_ferro = false
@onready var anim = $AnimationPlayer


func _ready():
	comprovar_golpes()
	
# Chamada por míssil, árvore e alien que encosta
func receber_dano(quantidade = 1, _fonte = ""):
	golpes += quantidade
	comprovar_golpes()

# Atualiza o visual pelos golpes recebidos (2 = some)
func comprovar_golpes():
	if golpes == 0:
		anim.play("normal")
	elif golpes == 1:
		anim.play("danificado")
	elif golpes >= 2:
		queue_free()

# Usada pelo chão antes do add_child (funciona: o Sprite2D já existe após o instantiate)
func virar_ferro():
	eh_ferro = true
	$Sprite2D.texture = ferro
