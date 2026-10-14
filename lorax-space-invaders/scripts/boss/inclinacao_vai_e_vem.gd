# Inclinação progressiva do vai e vem (modo ROTACAO_AA): a cada quadro calcula o ângulo pela
# distância percorrida desde a borda de onde ele saiu (0 na borda, o máximo no meio do trajeto).
# O ângulo real segue esse alvo com velocidade limitada (vira na borda sem salto) e sai em
# passos. A fase e o LAB usam a mesma conta.
class_name InclinacaoVaiEVem
extends RefCounted

var graus_max := 0.0
# Segundos para ir do máximo a 0 (a velocidade limite)
var tempo := 0.0
var passo := 0.0
var depois_do_meio := FaseClassicaDados.DepoisDoMeio.MANTER
var limite_esq := 0.0
var limite_dir := 0.0
# Ângulo real (antes do passo), a borda de onde saiu e o último sentido em que andou
var atual := 0.0
var borda := 0.0
var direcao_anterior := 0

# Pega os números do .tres
func _init(dados: FaseClassicaDados):
	graus_max = dados.inclinacao_graus
	tempo = dados.inclinacao_tempo
	passo = dados.inclinacao_passo_graus
	depois_do_meio = dados.inclinacao_depois_do_meio
	limite_esq = dados.limite_esq
	limite_dir = dados.limite_dir

# Ângulo (graus, já em passos) neste quadro; 'direcao' = 1/-1 andando, 0 = parado (endireita)
func atualizar(x, direcao, delta):
	if direcao != 0 and direcao != direcao_anterior:
		borda = limite_esq if direcao > 0 else limite_dir
		direcao_anterior = direcao
	var alvo = 0.0
	if direcao != 0:
		var progresso = absf(x - borda) / ((limite_dir - limite_esq) / 2.0)
		var fator = clampf(progresso, 0.0, 1.0)
		if depois_do_meio == FaseClassicaDados.DepoisDoMeio.SINO and progresso > 1.0:
			fator = clampf(2.0 - progresso, 0.0, 1.0)
		alvo = direcao * graus_max * fator
	var velocidade = graus_max / tempo if tempo > 0 else INF
	atual = move_toward(atual, alvo, velocidade * delta)
	if passo > 0:
		return roundf(atual / passo) * passo
	return atual
