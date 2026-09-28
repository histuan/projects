# Fundo estrelado com parallax, desenhado pixel a pixel em _draw().
extends Node2D

const qtdEstrelas = 40;
const larg=254;
const alt=256;

var estrelas = [];
var tempo = 0.0;

# Desenha 1 pixel cinza com o brilho dado
func pixel(p,brilho):
	draw_rect(Rect2(p.floor(),Vector2(1,1)),Color(brilho,brilho,brilho))
	
# Estrela: pixel central + cruz mais fraca; as grandes (tam 2) ganham mais um anel
func aura(p, b, tam):
	pixel(p, b)
	pixel(p + Vector2(0,-1), b*0.8)
	pixel(p + Vector2(0,1), b*0.8)
	pixel(p + Vector2(-1,0), b*0.8)
	pixel(p + Vector2(1,0), b*0.8)
	if tam == 2:
		pixel(p + Vector2(-1,-1), b*0.6)
		pixel(p + Vector2(1,-1), b*0.6)
		pixel(p + Vector2(-1,1), b*0.6)
		pixel(p + Vector2(1,1), b*0.6)
		pixel(p + Vector2(0,-2), b*0.5)
		pixel(p + Vector2(0,2), b*0.5)
		pixel(p + Vector2(-2,0), b*0.5)
		pixel(p + Vector2(2,0), b*0.5)
		
# Cria uma estrela. A 'profundidade' define junto velocidade, tamanho e brilho
# (as mais próximas são mais rápidas e mais claras)
func novaEst(y):
	var profundidade = randf()
	return {
		"pos": Vector2(randf_range(0,larg),y),
		"vel": lerp(100.0,200.0, profundidade),
		"tam": 2 if profundidade > 0.85 else 1,
		"brilho": lerp(0.4, 1.0, profundidade),
		"fase": randf()* TAU
	}

func _ready():
	for i in range(qtdEstrelas):
		estrelas.append(novaEst(randf_range(0,alt)))

# Move as estrelas; a que sai por baixo renasce no topo. queue_redraw() pede um novo _draw()
func _process(delta):
	tempo +=delta
	for i in range(estrelas.size()):
		estrelas[i]["pos"].y += estrelas[i]["vel"] * delta
		if estrelas[i]["pos"].y > alt:
			estrelas[i] = novaEst(0)
	queue_redraw()

# Cintilação: cada estrela oscila o brilho com a sua fase
func _draw():
	for estrela in estrelas:
		var cintila = sin(tempo * 2.5 + estrela["fase"]) * 0.5 + 0.5
		var b = estrela["brilho"] * (0.6 + 0.4 * cintila)
		aura(estrela["pos"], b, estrela["tam"])
