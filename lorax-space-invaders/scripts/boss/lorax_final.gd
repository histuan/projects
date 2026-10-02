# Corpo do boss final: anima, leva dano e sinaliza. Não decide nada: quem manda nele
# é a fase da vez (vida, animações, posição, invulnerabilidade).
extends Inimigo

signal vida_mudou(vida, vida_max)
signal invulneravel_mudou(ligado)
signal ferido
signal vida_acabou
# Quadro marcado (quadro_evento) da animação 'nome'
signal evento_animacao(nome)
signal animacao_terminou(nome)

var vida_max := 1
var invulneravel := false

# Não dá pontos (o placar some na wave do boss). Trúfula: 2 rajadas por golpe
func _init():
	valor_pontos = 0
	rajadas_por_dano = {"trufula": 2}

# Liga por código o fim das animações (na cena o AnimationPlayer não tem conexões)
func _ready():
	$AnimationPlayer.animation_finished.connect(_on_animacao_terminou)

# Enche a vida para uma fase nova (e revive: a vida anterior pode ter zerado)
func definir_vida(valor):
	vida_max = valor
	vidas = valor
	vivo = true
	vida_mudou.emit(vidas, vida_max)

# Invulnerável: os tiros batem e somem sem tirar vida
func ficar_invulneravel(ligado):
	invulneravel = ligado
	invulneravel_mudou.emit(ligado)

# Troca o conjunto de animações (lista de AnimacaoDados) pelo da fase atual
func carregar_animacoes(lista):
	var anim = $AnimationPlayer
	anim.stop()
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	var biblioteca = AnimationLibrary.new()
	for dados in lista:
		biblioteca.add_animation(dados.nome, dados.criar_animacao())
	anim.add_animation_library("", biblioteca)

# Toca uma animação do conjunto carregado (pedir a que já está tocando não reinicia)
func tocar(nome):
	$AnimationPlayer.play(nome)

# Chamada pela faixa de método das animações que têm quadro_evento
func avisar_evento():
	evento_animacao.emit($AnimationPlayer.current_animation)

# Repassa o fim de uma animação sem loop para a fase
func _on_animacao_terminou(nome):
	animacao_terminou.emit(nome)

# Invulnerável ignora o golpe; senão vale o receber_dano do Inimigo
func receber_dano(quantidade = 1, fonte = "tiro"):
	if invulneravel:
		return
	super(quantidade, fonte)

# Sobreviveu: som e piscada (padrão) e avisa a hud e a fase
func ao_ferir(fonte):
	super(fonte)
	vida_mudou.emit(vidas, vida_max)
	ferido.emit()

# Vida no zero: não some, só avisa. A fase decide o que acontece com ele
func morrer(_fonte):
	vida_mudou.emit(0, vida_max)
	vida_acabou.emit()
