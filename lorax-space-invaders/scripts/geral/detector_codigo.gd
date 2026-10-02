# Detecta o código Konami e avisa com um sinal; não sabe o que acontece depois.
extends Node

signal codigo_digitado

const SEQUENCIA = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]

# Desligado enquanto outra coisa (o seletor) usa o teclado
var ativo = true
# Últimas teclas apertadas (janela deslizante do tamanho da sequência)
var recentes = []

# Compara as últimas teclas com a sequência a cada tecla nova
func _unhandled_input(event):
	if not ativo or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	recentes.push_back(event.physical_keycode)
	if recentes.size() > SEQUENCIA.size():
		recentes.pop_front()
	if recentes == SEQUENCIA:
		recentes.clear()
		codigo_digitado.emit()
