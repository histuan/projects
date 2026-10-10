# Limpeza dos projéteis do boss na troca de fase: cada filho do nó de ataques vira faísca
# inofensiva e some, com UM som por limpeza (nenhum se não havia projétil). A luta
# (BatalhaFinal.proxima_fase) e o LAB DE EFEITOS chamam esta mesma função.
# Os números (faísca, teto) moram no efeitos_boss.tres; o som é o evento projeteis_limpam.
class_name LimpezaProjeteis
extends RefCounted

const EFEITOS = preload("res://recursos/boss/efeitos_boss.tres")
const FAISCA = preload("res://cenas/efeitos/faisca.tscn")

# Limpa os filhos de 'pai'; as faíscas nascem em 'destino' (fora de 'pai', para a próxima
# limpeza não pegá-las). Devolve quantos projéteis limpou
static func limpar(pai: Node, destino: Node) -> int:
	var projeteis = []
	for filho in pai.get_children():
		if not filho.is_queued_for_deletion():
			projeteis.append(filho)
	if projeteis.is_empty():
		return 0
	for i in projeteis.size():
		var projetil = projeteis[i]
		desarmar(projetil)
		if ganha_faisca(i) and projetil is Node2D:
			soltar_faisca(projetil.global_position, destino)
		projetil.queue_free()
	Sons.tocar(&"projeteis_limpam")
	return projeteis.size()

# Deixa o projétil inofensivo antes de qualquer efeito: sem colisão, sem grupos, parado
static func desarmar(projetil: Node):
	if projetil is Area2D:
		projetil.set_deferred("monitoring", false)
		projetil.set_deferred("monitorable", false)
	if projetil is Projetil:
		projetil.acertou = true
	for grupo in projetil.get_groups():
		projetil.remove_from_group(grupo)
	projetil.set_process(false)
	projetil.set_physics_process(false)

# Até o teto, todo projétil ganha faísca; depois, só 1 a cada 'limpeza_faisca_a_cada'
static func ganha_faisca(indice) -> bool:
	if indice < EFEITOS.limpeza_teto:
		return true
	return EFEITOS.limpeza_faisca_a_cada > 0 and (indice - EFEITOS.limpeza_teto) % EFEITOS.limpeza_faisca_a_cada == 0

# Uma faísca (cena da faísca do hit) no ponto do projétil. A posição vem ANTES do add_child:
# a partícula solta a rajada no _ready, no lugar onde estiver
static func soltar_faisca(ponto: Vector2, destino: Node):
	var faisca = FAISCA.instantiate()
	faisca.configurar(EFEITOS.limpeza_faisca.x, EFEITOS.limpeza_faisca.y)
	faisca.position = destino.to_local(ponto) if destino is Node2D else ponto
	destino.add_child(faisca)
