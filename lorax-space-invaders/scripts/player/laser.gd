# Tiro reto do player (laser e arvore de Trúfula): sobe e acerta um único inimigo.
extends Projetil

# Entra no grupo dos tiros do player (a transformação faz todos sumirem)
func _ready():
	add_to_group(&"tiros_player")
