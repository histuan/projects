# Spawner: faz cair power-ups e corações e passa planetas no fundo, cada um no seu timer.
# Tudo que ele cria vai para a main (mesma camada de desenho de antes).
extends Node

var ItemPowerUp = preload("res://cenas/player/item_powerup.tscn")
var Planeta = preload("res://cenas/geral/planeta.tscn")
var Coracao = preload("res://cenas/player/coracao_item.tscn")
# Power-ups que podem cair (para um novo: criar o .tres e pôr aqui)
const POWERUPS = [
	preload("res://recursos/powerups/motosserra.tres"),
	preload("res://recursos/powerups/trufula.tres"),
]

@onready var main = get_parent()

# Sorteia o primeiro spawn de cada um (os três timers são one shot)
func _ready():
	$TimerSpawnPowerUp.start(randf_range(7, 14))
	$TimerPlaneta.start(randf_range(5, 10))
	$TimerSpawnCoracao.start(randf_range(1, 2))

# Power-up aleatório no topo, em x aleatório; agenda o próximo
func _on_timer_spawn_power_up_timeout():
	var item = ItemPowerUp.instantiate()
	item.powerup = POWERUPS.pick_random()
	item.global_position = Vector2(randf_range(20, 234), 0)
	main.add_child(item)
	$TimerSpawnPowerUp.start(randf_range(8, 16))

# Planeta dentro de "fundo" (desenhado logo depois das estrelas, atrás de tudo)
func _on_timer_planeta_timeout():
	main.get_node("fundo").add_child(Planeta.instantiate())
	$TimerPlaneta.start(randf_range(45, 70))

# Wave do boss: nenhum planeta novo (o que já está descendo termina de sair)
func parar_planeta():
	$TimerPlaneta.stop()

# Só cria coração se faltar vida; o timer é reagendado sempre
func _on_timer_spawn_coracao_timeout():
	if Partida.pode_ganhar_vida():
		var c = Coracao.instantiate()
		c.global_position = Vector2(randf_range(20, 234), 0)
		main.add_child(c)
	$TimerSpawnCoracao.start(randf_range(10, 15))
