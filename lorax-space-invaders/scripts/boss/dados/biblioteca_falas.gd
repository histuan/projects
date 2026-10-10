# Biblioteca de falas da boss fight (um arquivo só: falas_boss.tres): nome → Fala.
# Os padrões daqui são neutros e não mudam: os valores moram no .tres.
class_name BibliotecaFalas
extends Resource

@export var falas: Dictionary[StringName, Fala] = {}
