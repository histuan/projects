# Fundo estrelado com parallax, desenhado pixel a pixel em _draw().
# Também é o "termômetro da tensão" da boss fight (efeitos.md 4.0): velocidade, brilho,
# cor, riscos, empurrão, apagar e acender mudam por estas funções, com tween em tempo real.
extends Node2D

const qtdEstrelas = 50;
const larg=254;
const alt=256;

var estrelas = [];
var tempo = 0.0;

# Termômetro: multiplicadores aplicados a todas as estrelas
var velocidade_mult = 1.0
var brilho = 1.0
var cor = Color.WHITE
# Riscos: acima do limiar de velocidade (px/s), a estrela vira linha de comprimento vel × fator
var risco_ligado = false
var risco_fator = 0.0
var risco_limiar = 0.0
# Empurrão: força em px (negativa = sugadas) e quanto dela ainda resta (1 → 0)
var forca_empurrao = 0.0
var resta_empurrao = 0.0

var tween_velocidade: Tween = null
var tween_brilho: Tween = null
var tween_cor: Tween = null
var tween_empurrao: Tween = null

# Desenha 1 pixel na cor dada
func pixel(p, c):
	draw_rect(Rect2(p.floor(),Vector2(1,1)),c)

# Estrela: 1 pixel; as próximas (tam 2) ganham uma cruz mais fraca em volta
func aura(p, c, tam):
	pixel(p, c)
	if tam == 2:
		var fraca = Color(c.r*0.6, c.g*0.6, c.b*0.6)
		pixel(p + Vector2(0,-1), fraca)
		pixel(p + Vector2(0,1), fraca)
		pixel(p + Vector2(-1,0), fraca)
		pixel(p + Vector2(1,0), fraca)

# Cria uma estrela. A 'profundidade' define junto velocidade, tamanho e brilho
# (as mais próximas são mais rápidas e mais claras). 'cor_propria' = estrela nova colorida
func novaEst(y, cor_propria = null):
	var profundidade = randf()
	return {
		"pos": Vector2(randf_range(0,larg),y),
		"vel": lerp(40.0,120.0, profundidade),
		"tam": 2 if profundidade > 0.9 else 1,
		"brilho": lerp(0.3, 0.8, profundidade),
		"fase": randf()* TAU,
		"cor": cor_propria,
		"apagada": false,
		"apaga_em": -1,
		"acende_em": -1,
		"empurrao": Vector2.ZERO
	}

# Começa com o céu cheio
func _ready():
	criar_estrelas()

# Céu inicial: qtdEstrelas espalhadas pela tela
func criar_estrelas():
	estrelas.clear()
	for i in range(qtdEstrelas):
		estrelas.append(novaEst(randf_range(0,alt)))

# Move as estrelas; a que sai por baixo renasce no topo (menos as apagadas).
# queue_redraw() pede um novo _draw()
func _process(delta):
	tempo +=delta
	var agora = Time.get_ticks_msec()
	for i in range(estrelas.size()):
		var estrela = estrelas[i]
		if estrela["apaga_em"] >= 0 and agora >= estrela["apaga_em"]:
			estrela["apagada"] = true
		estrela["pos"].y += estrela["vel"] * velocidade_mult * delta
		if estrela["pos"].y > alt and not estrela["apagada"]:
			estrelas[i] = novaEst(0, estrela["cor"])
	queue_redraw()

# Cintilação: cada estrela oscila o brilho com a sua fase. Em modo risco, as rápidas
# viram linha vertical para cima
func _draw():
	var agora = Time.get_ticks_msec()
	for estrela in estrelas:
		if estrela["apagada"] or agora < estrela["acende_em"]:
			continue
		var cintila = sin(tempo * 2.5 + estrela["fase"]) * 0.5 + 0.5
		var b = estrela["brilho"] * (0.6 + 0.4 * cintila) * brilho
		var c = cor_da_estrela(estrela, b)
		var p = estrela["pos"] + estrela["empurrao"] * forca_empurrao * resta_empurrao
		var vel = estrela["vel"] * velocidade_mult
		if risco_ligado and vel > risco_limiar:
			var comprimento = round(vel * risco_fator)
			draw_rect(Rect2(p.floor() - Vector2(0, comprimento), Vector2(1, comprimento + 1)), c)
		else:
			aura(p, c, estrela["tam"])

# Cor final: a própria (estrela nova) ou o azulado de sempre, tingida pela cor do termômetro
func cor_da_estrela(estrela, b):
	var base = Color(b*0.85, b*0.8, b)
	if estrela["cor"] != null:
		base = Color(estrela["cor"].r * b, estrela["cor"].g * b, estrela["cor"].b * b)
	return Color(base.r * cor.r, base.g * cor.g, base.b * cor.b)

# Multiplicador de velocidade de todas as estrelas (0 = param); com duração, chega aos poucos
func mudar_velocidade(mult, duracao = 0.0):
	tween_velocidade = animar(tween_velocidade, "velocidade_mult", mult, duracao)

# Multiplicador de brilho de todas as estrelas (0 a 1)
func mudar_brilho(valor, duracao = 0.0):
	tween_brilho = animar(tween_brilho, "brilho", valor, duracao)

# Tinta aplicada a todas as estrelas (branco = cor normal)
func mudar_cor(nova_cor, duracao = 0.0):
	tween_cor = animar(tween_cor, "cor", nova_cor, duracao)

# Liga/desliga os riscos: acima de 'limiar' px/s a estrela vira linha de vel × 'fator'
func modo_risco(ligado, fator = 0.0, limiar = 0.0):
	risco_ligado = ligado
	risco_fator = fator
	risco_limiar = limiar

# Empurra as estrelas 'forca' px para fora de 'centro' (negativa = sugadas para ele);
# elas voltam ao lugar em 'duracao' segundos
func empurrar(centro, forca, duracao):
	for estrela in estrelas:
		estrela["empurrao"] = (estrela["pos"] - centro).normalized()
	forca_empurrao = forca
	resta_empurrao = 1.0
	tween_empurrao = animar(tween_empurrao, "resta_empurrao", 0.0, duracao)

# Cada estrela apaga num instante sorteado dentro de 'duracao' s; apagada não renasce
func apagar_uma_a_uma(duracao):
	var agora = Time.get_ticks_msec()
	for estrela in estrelas:
		if not estrela["apagada"]:
			estrela["apaga_em"] = agora + randf() * duracao * 1000.0

# Alguma estrela já apagou ou está marcada para apagar
func tem_apagadas():
	for estrela in estrelas:
		if estrela["apagada"] or estrela["apaga_em"] >= 0:
			return true
	return false

# Estrelas novas de 'nova_cor' acendem ao longo de 'duracao' s e mantêm a cor ao renascer
func acender_novas(nova_cor, quantidade, duracao):
	var agora = Time.get_ticks_msec()
	for i in range(quantidade):
		var estrela = novaEst(randf_range(0, alt), nova_cor)
		estrela["acende_em"] = agora + randf() * duracao * 1000.0
		estrelas.append(estrela)

# Tudo volta ao normal na hora: céu novo, sem tinta, sem riscos, velocidade ×1
func restaurar():
	for tween in [tween_velocidade, tween_brilho, tween_cor, tween_empurrao]:
		if tween != null:
			tween.kill()
	velocidade_mult = 1.0
	brilho = 1.0
	cor = Color.WHITE
	risco_ligado = false
	resta_empurrao = 0.0
	criar_estrelas()

# Leva uma propriedade ao valor na hora (duração 0) ou por tween em tempo real;
# mata o tween anterior da mesma propriedade e devolve o novo
func animar(tween_antigo, propriedade, valor, duracao):
	if tween_antigo != null:
		tween_antigo.kill()
	if duracao <= 0:
		set(propriedade, valor)
		return null
	var tween = create_tween().set_ignore_time_scale()
	tween.tween_property(self, propriedade, valor, duracao)
	return tween
