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
# Squash, recuo, inclinação e o flash de cor do sprite (criados por código no _ready)
var reacoes: ReacoesCorpo
var flash: FlashSprite

# Não dá pontos (o placar some na wave do boss). Trúfula: 2 rajadas por golpe
func _init():
	valor_pontos = 0
	rajadas_por_dano = {"trufula": 2}

# Liga por código o fim das animações (na cena o AnimationPlayer não tem conexões) e cria
# o ReacoesCorpo e o FlashSprite (a cena não precisa saber deles)
func _ready():
	$AnimationPlayer.animation_finished.connect(_on_animacao_terminou)
	reacoes = ReacoesCorpo.new()
	add_child(reacoes)
	flash = FlashSprite.new()
	$Sprite2D.add_child(flash)

# Enche a vida para uma fase nova (e revive: a vida anterior pode ter zerado); o sprite
# volta ao normal
func definir_vida(valor):
	reacoes.parar()
	flash.parar()
	vida_max = valor
	vidas = valor
	vivo = true
	vida_mudou.emit(vidas, vida_max)

# Invulnerável: os tiros batem e somem sem tirar vida
func ficar_invulneravel(ligado):
	invulneravel = ligado
	invulneravel_mudou.emit(ligado)

# Gira o sprite até 'graus' em 'tempo' s, em torno dos pés, com a borda suavizada (0 = de pé)
func inclinar(graus, tempo):
	reacoes.inclinar(graus, tempo)

# Põe a rotação em 'graus' na hora (o vai e vem progressivo calcula a cada quadro)
func definir_inclinacao(graus):
	reacoes.definir_inclinacao(graus)

# Alternativa: inclina em fileiras inteiras até o topo deslocar 'px' em 'tempo' s (0 = de pé)
func inclinar_lean(px, tempo):
	reacoes.inclinar_lean(px, tempo)

# Desloca o sprite 'px' para o lado em 'tempo' s (alternativa à inclinação)
func deslocar(px, tempo):
	reacoes.deslocar(px, tempo)

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

# Sobreviveu: pisca e avisa a hud e a fase (o som do dano é da fase, pelo sons_boss.tres;
# o corpo não tem nós de som)
func ao_ferir(_fonte):
	piscar()
	vida_mudou.emit(vidas, vida_max)
	ferido.emit()

# Vida no zero: não some, só avisa. A fase decide o que acontece com ele
func morrer(_fonte):
	reacoes.parar()
	flash.parar()
	vida_mudou.emit(0, vida_max)
	vida_acabou.emit()
