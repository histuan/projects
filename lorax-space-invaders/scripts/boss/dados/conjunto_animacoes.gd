# Um conjunto de animações do mesmo assunto (cutscene, finais, batalha da fase 3...): é o que
# a fase entrega ao corpo com carregar_animacoes. Os .tres são criados pelo gerador_animacoes.gd
# e depois ajustados à mão no Inspector (o gerador não mexe no que já existe).
@tool
class_name ConjuntoAnimacoes
extends Resource

@export var animacoes: Array[AnimacaoDados] = []

# A animação de nome 'nome' (null se não existe)
func dados(nome):
	for animacao in animacoes:
		if animacao.nome == nome:
			return animacao
	return null
