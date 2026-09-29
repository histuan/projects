# Míssil dos aliens: desce reto; fere o player ou danifica o bloco que acertar.
# Se passar do chão, a AreaGameOver cuida dele (grupo "misseis" na cena).
extends Projetil

func _init():
	velocidade = 150.0
	direcao = Vector2.DOWN
	grupos_alvo = ["tanque", "blocos"]
	# Folga maior: a AreaGameOver, logo abaixo do chão, precisa pegá-lo antes dele sumir
	margem_tela = 40.0
