# Dados de uma animação tirada de uma folha horizontal (um PNG por animação):
# toca os quadros da folha em ordem (todos, ou só os de 'quadros'). Sabe virar uma Animation
# do Godot. Os padrões daqui não mudam: o classica1.tres depende deles.
@tool
class_name AnimacaoDados
extends Resource

## Nome pelo qual a fase pede a animação (ex.: "parado", "dano", "ataque")
@export var nome := ""
@export var folha: Texture2D
@export var largura_quadro := 32
@export var tempo_por_quadro := 0.2
@export var repetir := false
## Posição (na animação, a partir de 0) em que o corpo emite evento_animacao (ex.: soltar o
## projétil). Com 'quadros' preenchido é a posição dentro da lista, não o índice na folha. -1 = sem evento
@export var quadro_evento := -1
## Tempo (s) de cada quadro, na ordem em que tocam. Vazio = tempo_por_quadro em todos
@export var tempos: Array[float] = []
## Quadros da folha que tocam, em ordem (índice a partir de 0). Vazio = a folha inteira
@export var quadros: Array[int] = []
## Velocidade de toda a animação: 1 = tempos como escritos, 1.5 = 50% mais rápida, 0.5 = metade.
## Divide todos os tempos (tempo_por_quadro e tempos), então o evento acompanha
@export var velocidade := 1.0
## Posições (como quadro_evento) em que o corpo emite pulso_animacao (ex.: as batidas do símbolo de
## raiva). Vazio = sem pulsos
@export var quadros_pulso: Array[int] = []

# Quantos quadros cabem na folha
func total_quadros():
	return int(folha.get_width() / float(largura_quadro))

# Índices da folha que tocam, em ordem; sem tempo para todos, fica só com os que têm tempo
func quadros_tocados() -> Array:
	var lista = quadros.duplicate() if not quadros.is_empty() else range(total_quadros())
	if not tempos.is_empty() and tempos.size() < lista.size():
		lista = lista.slice(0, tempos.size())
	return lista

# Tempo (s) do quadro na posição 'i' da animação, já dividido pela velocidade
func tempo_do_quadro(i):
	var base = tempos[i] if not tempos.is_empty() else tempo_por_quadro
	return base / maxf(velocidade, 0.01)

# Instante (s) em que a posição 'i' começa (com i = total, o fim da animação)
func instante_do_quadro(i):
	if tempos.is_empty():
		return i * tempo_do_quadro(0)
	var instante = 0.0
	for j in range(i):
		instante += tempo_do_quadro(j)
	return instante

# Duração total (s)
func duracao():
	return instante_do_quadro(quadros_tocados().size())

# Biblioteca de animações (a padrão, "") com uma Animation por AnimacaoDados da lista
static func criar_biblioteca(lista) -> AnimationLibrary:
	var biblioteca = AnimationLibrary.new()
	for dados in lista:
		biblioteca.add_animation(dados.nome, dados.criar_animacao())
	return biblioteca

# Monta a Animation: troca a folha e o hframes no instante 0 (cada animação vem de um
# PNG diferente) e põe cada quadro no instante acumulado dos tempos
func criar_animacao() -> Animation:
	conferir()
	var lista = quadros_tocados()
	var instantes = []
	for i in range(lista.size()):
		instantes.append(instante_do_quadro(i))
	var animacao = Animation.new()
	animacao.length = duracao()
	animacao.loop_mode = Animation.LOOP_LINEAR if repetir else Animation.LOOP_NONE
	criar_faixa(animacao, "Sprite2D:texture", [folha], [0.0])
	criar_faixa(animacao, "Sprite2D:hframes", [total_quadros()], [0.0])
	criar_faixa(animacao, "Sprite2D:frame", lista, instantes)
	if quadro_evento >= 0 and quadro_evento < lista.size():
		criar_faixa_metodo(animacao, &"avisar_evento", [instantes[quadro_evento]])
	var pulsos = []
	for posicao in quadros_pulso:
		if posicao >= 0 and posicao < lista.size():
			pulsos.append(instantes[posicao])
	if not pulsos.is_empty():
		criar_faixa_metodo(animacao, &"avisar_pulso", pulsos)
	return animacao

# Faixa que chama 'metodo' do corpo (sem argumentos) em cada um dos 'instantes'
func criar_faixa_metodo(animacao: Animation, metodo: StringName, instantes: Array):
	var faixa = animacao.add_track(Animation.TYPE_METHOD)
	animacao.track_set_path(faixa, NodePath("."))
	for instante in instantes:
		animacao.track_insert_key(faixa, instante, {"method": metodo, "args": []})

# Erros de dado com o nome da animação: tempos que não batem com os quadros, quadro fora
# da folha, evento fora da animação (nunca inventa tempo: anima só os quadros que têm tempo)
func conferir():
	var total = total_quadros()
	var lista = quadros if not quadros.is_empty() else range(total)
	if not tempos.is_empty() and tempos.size() < lista.size():
		push_error("Animação '%s': %d quadros e só %d tempos; toca só os %d primeiros" % [nome, lista.size(), tempos.size(), tempos.size()])
	elif tempos.size() > lista.size():
		push_error("Animação '%s': %d tempos para %d quadros; a sobra é ignorada" % [nome, tempos.size(), lista.size()])
	for indice in quadros:
		if indice < 0 or indice >= total:
			push_error("Animação '%s': quadro %d fora da folha (%d quadros)" % [nome, indice, total])
	if quadro_evento >= quadros_tocados().size():
		push_error("Animação '%s': quadro_evento %d fora da animação" % [nome, quadro_evento])
	for posicao in quadros_pulso:
		if posicao < 0 or posicao >= quadros_tocados().size():
			push_error("Animação '%s': quadro de pulso %d fora da animação" % [nome, posicao])

# Faixa de valor sem interpolação (troca seca): valores[i] no instante instantes[i]
func criar_faixa(animacao: Animation, caminho: String, valores: Array, instantes: Array):
	var faixa = animacao.add_track(Animation.TYPE_VALUE)
	animacao.track_set_path(faixa, NodePath(caminho))
	animacao.value_track_set_update_mode(faixa, Animation.UPDATE_DISCRETE)
	for i in range(valores.size()):
		animacao.track_insert_key(faixa, instantes[i], valores[i])
