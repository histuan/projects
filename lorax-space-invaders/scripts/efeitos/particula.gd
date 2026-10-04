# Partícula reaproveitável (CPUParticles2D, 1 px cada): começa a emitir ao entrar na
# cena e, se for de um disparo só (one_shot), se apaga sozinha quando termina.
# O comportamento (vida, gravidade, direção, cor) fica na cena; o "quanto" de cada
# momento vem do efeitos_boss.tres por configurar() ou definir_taxa().
extends CPUParticles2D

# Grupo de todas as partículas soltas (o R do LAB apaga as que estão no mundo)
const GRUPO = &"particulas"

# Liga a emissão; a de disparo único some no fim
func _ready():
	add_to_group(GRUPO)
	emitting = true
	if one_shot:
		finished.connect(queue_free)

# Quantidade e alcance: a velocidade máxima é a distância dividida pela vida, para
# nenhuma partícula passar de 'distancia' px (0 = mantém a velocidade da cena)
func configurar(quantidade, distancia = 0.0):
	amount = int(quantidade)
	if distancia > 0:
		initial_velocity_min = 0.0
		initial_velocity_max = distancia / lifetime

# Emissão contínua: partículas por segundo viram a quantidade viva ao mesmo tempo
func definir_taxa(por_segundo):
	amount = maxi(1, roundi(por_segundo * lifetime))
