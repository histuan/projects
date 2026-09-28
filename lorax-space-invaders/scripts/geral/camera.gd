# Câmera fixa da partida: tremor de tela e hit-stop (congelar o tempo por um instante).
extends Camera2D

# Força atual do tremor e quanto ela diminui por segundo
var forca_tremor = 0.0
var queda_tremor = 20.0

# Começa um tremor. Um mais fraco não substitui um mais forte que ainda está rolando.
# duracao > 0: zera em 'duracao' segundos; senão cai 20 por segundo
func tremer(forca, duracao = 0.0):
	if forca < forca_tremor:
		return
	forca_tremor = forca
	if duracao > 0:
		queda_tremor = forca / duracao
	else:
		queda_tremor = 20.0

# Desloca a câmera aleatoriamente e diminui a força a cada frame
func _process(delta):
	if forca_tremor > 0:
		offset = Vector2(randf_range(-forca_tremor, forca_tremor), randf_range(-forca_tremor, forca_tremor)).round()
		forca_tremor = move_toward(forca_tremor, 0, queda_tremor * delta)
	else:
		offset = Vector2.ZERO

# Hit-stop: para o tempo do jogo por um instante.
# O último true do create_timer faz ele ignorar o time_scale (senão nunca terminaria)
func congelar(duracao):
	Engine.time_scale = 0.0
	await get_tree().create_timer(duracao, true, false, true).timeout
	Engine.time_scale = 1.0

# Garante que o tempo volte ao normal se a cena trocar durante um congelamento
func _exit_tree():
	Engine.time_scale = 1.0
