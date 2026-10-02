# Corações na tela (do player e do boss): cheio/vazio e efeitos de piscar.
extends Node2D

@export var cheio: Texture2D = preload("res://meus sprites/geral/coracao.png")
@export var vazio: Texture2D = preload("res://meus sprites/geral/coracao_vazio.png")

@onready var coracoes = []

# Junta os Sprite2D dos filhos (coracao1, coracao2...) na ordem da cena
func _ready():
	for filho in get_children():
		var s = filho.get_node_or_null("Sprite2D")
		if s != null:
			coracoes.append(s)
			
# Os n primeiros ficam cheios, o resto vazio
func set_vidas(n):
	for i in range(coracoes.size()):
		coracoes[i].texture = cheio if i < n else vazio

var tween_piscada: Tween = null

# Pisca sem parar (enquanto o boss desce)
func piscar_ate_parar():
	# Mata o tween anterior: o sumir_piscando() termina num hide() que esconderia tudo
	if tween_piscada != null:
		tween_piscada.kill()
	tween_piscada = create_tween().set_loops()
	tween_piscada.tween_property(self, "modulate:a", 0.2, 0.15)
	tween_piscada.tween_property(self, "modulate:a", 1.0, 0.15)

func parar_piscada():
	if tween_piscada != null:
		tween_piscada.kill()
		tween_piscada = null
	modulate.a = 1.0
	
# Piscadas cada vez mais rápidas e depois esconde (boss morreu)
func sumir_piscando():
	if tween_piscada != null:
		tween_piscada.kill()
	modulate.a = 1.0
	tween_piscada = create_tween()
	var d = 0.15
	for i in range(8):
		tween_piscada.tween_property(self, "modulate:a", 0.2, d)
		tween_piscada.tween_property(self, "modulate:a", 1.0, d)
		d *= 0.75
	tween_piscada.tween_callback(hide)
