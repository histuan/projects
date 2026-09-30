# Névoa de poluição do fundo: começa limpa e fica mais forte a cada wave.
extends Sprite2D

const POR_WAVE = 0.1
const MAXIMO = 0.7
const DURACAO = 3.0

# Começa no nível da wave atual e passa a escutar a Partida
func _ready():
	modulate.a = alvo(Partida.wave)
	Partida.wave_mudou.connect(atualizar)

# Transparência da névoa na wave n (a wave 1 é limpa)
func alvo(n):
	return clampf((n - 1) * POR_WAVE, 0.0, MAXIMO)

# Escurece aos poucos até o nível da nova wave
func atualizar(n):
	create_tween().tween_property(self, "modulate:a", alvo(n), DURACAO)
