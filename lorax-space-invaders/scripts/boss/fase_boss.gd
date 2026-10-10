# Base de toda fase da batalha final. A fase é o "cérebro": manda no corpo do boss
# enquanto está ativa e emite 'terminou' quando acaba. Cada fase faz "extends FaseBoss".
class_name FaseBoss
extends Node

signal terminou

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

# Qual fase da luta esta é (1, 2 ou 3; 0 = não informada). Cada fase devolve a dela
func numero_fase():
	return 0
