# Base de toda fase da batalha final. A fase é o "cérebro": manda no corpo do boss
# enquanto está ativa e emite 'terminou' quando acaba. Cada fase faz "extends FaseBoss".
class_name FaseBoss
extends Node

signal terminou
# O boss terminou de entrar e está em cena (o Pause passa a mostrar a fala)
signal entrou
# Os corações do boss passam a usar esta textura de "cheio"
signal trocar_coracoes(textura)
# O player para de andar e de atirar (true) ou volta a jogar (false)
signal travar_player(ligado)
# Tudo que não é player, boss ou cenário some da tela e nada novo cai
signal limpar_tela

var ctx: ContextoBatalha

# Fluxo normal: começa a fase com a entrada completa
func comecar(contexto: ContextoBatalha):
	ctx = contexto

# Começa com o mundo já montado, sem entrada (cheat e checkpoint)
func comecar_direto(contexto: ContextoBatalha):
	comecar(contexto)

# Interrompe a fase: para relógios e solta o corpo
func parar():
	pass

# Sobrou o último coração do boss (fase sem reação a isso: nada)
func ultimo_coracao():
	pass

# Debug (tecla J): pula a entrada e já luta (fase sem entrada: nada)
func pular_intro():
	pass

# Qual fase da luta esta é (1, 2 ou 3; 0 = não informada). Cada fase devolve a dela
func numero_fase():
	return 0
