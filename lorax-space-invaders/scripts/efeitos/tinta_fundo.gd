# Tinta sobre o fundo (estrelas e névoa) e abaixo do resto do mundo: o tom vermelho da fase 2 e,
# depois, o escurecer da transformação. A main a cria logo depois do nó 'fundo'. Tem 32 px de
# sobra em cada lado para o tremor da câmera não mostrar a borda. Pausa com o jogo.
class_name TintaFundo
extends ColorRect

const SOBRA = 32

var tween: Tween = null

# Cobre a tela com sobra, transparente, sem pegar o mouse, e ouve os pedidos dos momentos
func _ready():
	var tela = get_viewport().get_visible_rect().size
	position = Vector2(-SOBRA, -SOBRA)
	size = tela + Vector2(2 * SOBRA, 2 * SOBRA)
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Momentos.pedido.connect(_on_pedido)

# tom_vermelho: vai para 'cor' com 'alfa' em 'duracao' s
func _on_pedido(nome, parametros, _alvo):
	if nome == &"tom_vermelho":
		tingir(parametros.get("cor", Color.BLACK), parametros.get("alfa", 0.0), parametros.get("duracao", 0.0))

# Muda a tinta para 'cor' com 'alfa' em 'duracao' s (0 = na hora)
func tingir(cor: Color, alfa, duracao):
	if tween != null:
		tween.kill()
	var alvo = Color(cor, alfa)
	if duracao <= 0:
		color = alvo
		return
	tween = create_tween()
	tween.tween_property(self, "color", alvo, duracao)

# Volta a ficar transparente na hora
func limpar():
	if tween != null:
		tween.kill()
	color = Color(0, 0, 0, 0)
