# Painel de debug (F3 mostra/esconde): etapa, fase e vida do boss, tempo do jogo e pedidos do
# TempoJogo, momentos, sons e música tocando. A main só cria este painel em build de debug:
# no jogo exportado ele não existe. Fica acima de tudo (até do Pause) e funciona pausado.
extends CanvasLayer

const FONTE = preload("res://fonts/atari-classic-font/AtariClassic-gry3.ttf")
# Acima do Pause (10) e do letterbox (7)
const LAYER_DEBUG = 11
const MARGEM_TEXTO = 2
const ALFA_FUNDO = 0.6

var fundo: ColorRect
var texto: Label

# Preenchidos pela main com os sinais da BatalhaFinal ("-" antes da luta)
var fase = "-"
var vida_boss = "-"
var boss_invulneravel = false

# Monta o fundo e o texto no topo da tela, escondido até a primeira F3
func _ready():
	layer = LAYER_DEBUG
	process_mode = Node.PROCESS_MODE_ALWAYS
	var largura = get_viewport().get_visible_rect().size.x
	fundo = ColorRect.new()
	fundo.color = Color(0, 0, 0, ALFA_FUNDO)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.size.x = largura
	add_child(fundo)
	texto = Label.new()
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.add_theme_font_override("font", FONTE)
	texto.add_theme_font_size_override("font_size", 8)
	texto.add_theme_constant_override("line_spacing", 0)
	texto.add_theme_constant_override("outline_size", 2)
	texto.add_theme_color_override("font_outline_color", Color.BLACK)
	texto.position = Vector2(MARGEM_TEXTO, MARGEM_TEXTO)
	texto.size.x = largura - 2 * MARGEM_TEXTO
	add_child(texto)
	visible = false

# F3 mostra/esconde (no _input: vale com o Pause aberto e antes do LAB e do player)
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		visible = not visible
		get_viewport().set_input_as_handled()

# Fase da batalha que começou (a main liga no fase_mudou da BatalhaFinal)
func mostrar_fase(nome):
	fase = String(nome)

# Vida do boss (a main liga no vida_boss_mudou da BatalhaFinal)
func mostrar_vida_boss(vida, vida_max):
	vida_boss = "%d/%d" % [vida, vida_max]

# Boss invulnerável ou não (a main liga no boss_invulneravel da BatalhaFinal)
func mostrar_invulneravel(ligado):
	boss_invulneravel = ligado

# Reescreve o texto a cada quadro, e o fundo acompanha a altura dele
func _process(_delta):
	if not visible:
		return
	var linhas = [
		"ETAPA: %s  WAVE %d" % [Partida.NOMES_ETAPAS.get(Partida.etapa_inicial, "JOGO"), Partida.wave],
		"FASE: " + fase,
		"BOSS: " + vida_boss + (" INVULNERAVEL" if boss_invulneravel else ""),
		"TEMPO: x%s  PEDIDOS: %s" % [numero(Engine.time_scale), pedidos_do_tempo()],
		"MOMENTOS: " + lista(Momentos.tocando_agora()),
		"SONS: " + lista(Sons.eventos_tocando()),
		"MUSICA: " + (Musica.nome_atual() if Musica.nome_atual() != "" else "-"),
	]
	texto.text = "\n".join(linhas)
	fundo.size.y = texto.get_line_count() * texto.get_line_height() + 2 * MARGEM_TEXTO
	texto.size.y = fundo.size.y - 2 * MARGEM_TEXTO

# "nome=escala" de cada pedido ativo no TempoJogo
func pedidos_do_tempo():
	var partes = []
	for nome in TempoJogo.pedidos:
		partes.append("%s=%s" % [nome, numero(TempoJogo.pedidos[nome])])
	return lista(partes)

# Nomes separados por vírgula, sem repetir ("-" se não há nenhum)
func lista(nomes):
	var unicos = []
	for nome in nomes:
		if not String(nome) in unicos:
			unicos.append(String(nome))
	if unicos.is_empty():
		return "-"
	return ", ".join(unicos)

# Número no jeito brasileiro: 0.25 → "0,25", 1.0 → "1"
func numero(valor):
	if is_equal_approx(valor, roundf(valor)):
		return str(int(roundf(valor)))
	return str(snappedf(valor, 0.01)).replace(".", ",")
