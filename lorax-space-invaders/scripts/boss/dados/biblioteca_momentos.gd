# Biblioteca de momentos da boss fight (um arquivo só: momentos_boss.tres): nome → Momento.
# Os padrões daqui são neutros e não mudam: os valores moram no .tres.
class_name BibliotecaMomentos
extends Resource

@export var momentos: Dictionary[StringName, Momento] = {}
