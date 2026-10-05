# Dono único do Engine.time_scale (autoload "TempoJogo"). Cada efeito faz um pedido com
# nome e vale o mais lento ativo: congelar (0) > câmera lenta > normal (1).
# Nenhum outro script escreve o time_scale.
extends Node

# Nome do pedido → escala pedida
var pedidos = {}
var contador = 0

# Registra (ou troca) um pedido e recalcula a escala
func pedir(nome, escala):
	pedidos[nome] = escala
	aplicar()

# Tira um pedido e recalcula; sem pedidos, o jogo volta à velocidade normal
func liberar(nome):
	pedidos.erase(nome)
	aplicar()

# Hit-stop: para o jogo por 'duracao' segundos reais
func congelar(duracao):
	segurar(0.0, duracao)

# Câmera lenta: o jogo roda a 'escala' por 'duracao' segundos reais
func camera_lenta(escala, duracao):
	segurar(escala, duracao)

# Apaga todos os pedidos (a main chama ao sair da cena)
func limpar():
	pedidos.clear()
	aplicar()

# Pedido com nome único que se libera sozinho depois de 'duracao' segundos reais.
# O último true do create_timer faz ele ignorar o time_scale (senão nunca terminaria)
func segurar(escala, duracao):
	contador += 1
	var nome = "temporario_%d" % contador
	pedir(nome, escala)
	await get_tree().create_timer(duracao, true, false, true).timeout
	liberar(nome)

# Está em câmera lenta: o jogo anda, mas na 'escala_maxima' ou mais devagar.
# Hit-stop (escala 0) NÃO conta: o jogo está parado, não lento
func em_camera_lenta(escala_maxima):
	return Engine.time_scale > 0.0 and Engine.time_scale <= escala_maxima

# Aplica a menor escala pedida (1,0 quando não há pedido)
func aplicar():
	var escala = 1.0
	for valor in pedidos.values():
		escala = minf(escala, valor)
	Engine.time_scale = escala
