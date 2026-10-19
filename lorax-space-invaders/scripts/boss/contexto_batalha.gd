# Pacote de referências que a BatalhaFinal entrega a cada fase, para a fase
# não precisar procurar nada na árvore.
class_name ContextoBatalha
extends RefCounted

# O Lorax (lorax_final.gd): a fase manda nele
var corpo
# Node2D onde nascem os projéteis do boss
var ataques: Node
var player
# A caixa de diálogo da main (falas da luta)
var dialogo: CaixaDialogo
# O pilar de luz alto atrás do corpo (pilar_alto.gd)
var pilar_alto
