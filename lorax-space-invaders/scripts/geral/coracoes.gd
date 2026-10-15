# Corações na tela (do player e do boss): cheio/vazio, efeitos de piscar, o coração que
# acabou de esvaziar (cresce, treme e pisca), a batida do último e o encher um a um. Tudo
# pausa com o jogo.
extends Node2D

# Terminou o encher_aos_poucos (todos cheios)
signal encheu

@export var cheio: Texture2D = preload("res://meus sprites/geral/coracao.png")
@export var vazio: Texture2D = preload("res://meus sprites/geral/coracao_vazio.png")

@onready var coracoes = []
# Quantos estão cheios agora (a troca de textura redesenha com ele)
var cheios = 0
# Por coração: o FlashSprite e o tween do "perdeu" (mesma ordem de 'coracoes')
var flashes = []
var tweens_perdeu = []
# Batida do último coração (null = parado)
var tween_pulso: Tween = null
# Enchendo um a um (null = não)
var tween_encher: Tween = null

# Junta os Sprite2D dos filhos (coracao1, coracao2...) na ordem da cena e dá a cada um
# um FlashSprite (criado por código; a cor da fase continua só na textura)
func _ready():
	for filho in get_children():
		var s = filho.get_node_or_null("Sprite2D")
		if s != null:
			coracoes.append(s)
			var flash = FlashSprite.new()
			s.add_child(flash)
			flashes.append(flash)
			tweens_perdeu.append(null)
	cheios = coracoes.size()

# Os n primeiros ficam cheios, o resto vazio. Com 0 ou mais de 1 cheio a batida do último para
func set_vidas(n):
	cheios = n
	for i in range(coracoes.size()):
		coracoes[i].texture = cheio if i < n else vazio
	if n != 1:
		parar_pulso()

# O coração 'indice' acabou de esvaziar: nasce em 'escala' e volta a 1 em 'duracao' s, treme
# 'tremor_px' px (inteiros) por 'tremor_duracao' s e pisca 'cor' em 'alfa' por 'duracao_flash' s
func perdeu(indice, escala, duracao, tremor_px, tremor_duracao, cor, alfa, duracao_flash):
	if indice < 0 or indice >= coracoes.size():
		return
	if duracao <= 0:
		push_error("Coracoes: coracao_da_hud sem duracao")
		return
	var s = coracoes[indice]
	if tweens_perdeu[indice] != null:
		tweens_perdeu[indice].kill()
	var t = create_tween().set_parallel(true)
	tweens_perdeu[indice] = t
	s.scale = Vector2(escala, escala)
	t.tween_property(s, "scale", Vector2.ONE, duracao)
	if tremor_px > 0 and tremor_duracao > 0:
		t.tween_method(tremer.bind(s, tremor_px), 0.0, 1.0, tremor_duracao)
		t.chain().tween_property(s, "position", Vector2.ZERO, 0.0)
	if alfa > 0 and duracao_flash > 0:
		flashes[indice].flash(cor, alfa, duracao_flash)

# Um quadro do tremor do coração: posição sorteada em px inteiros
func tremer(_progresso, s, px):
	s.position = Vector2(randi_range(-px, px), randi_range(-px, px))

# O último coração (o primeiro da lista) bate a cada 'periodo' s: cresce até 'escala' e volta
# em 'batida' s (curta: escala não inteira só por pouco tempo, efeitos.md 2b.11c) e toca 'som'
func pulsar_ultimo(escala, periodo, batida, som):
	parar_pulso()
	if periodo <= 0 or batida <= 0 or coracoes.is_empty():
		push_error("Coracoes: coracao_pulsa sem periodo ou batida")
		return
	var s = coracoes[0]
	tween_pulso = create_tween().set_loops()
	if som != &"":
		tween_pulso.tween_callback(Sons.tocar.bind(som))
	tween_pulso.tween_property(s, "scale", Vector2(escala, escala), batida / 2.0)
	tween_pulso.tween_property(s, "scale", Vector2.ONE, batida / 2.0)
	tween_pulso.tween_interval(maxf(periodo - batida, 0.0))

# Para a batida do último coração (ele volta ao tamanho normal)
func parar_pulso():
	if tween_pulso != null:
		tween_pulso.kill()
		tween_pulso = null
		if not coracoes.is_empty():
			coracoes[0].scale = Vector2.ONE

# O último coração está batendo
func pulsando():
	return tween_pulso != null

# Esvazia todos e enche do primeiro ao último, um a cada 'intervalo' s, tocando 'som' na escala
# (uma nota mais aguda por coração); no fim emite 'encheu'. Fica "enchendo" desde a chamada
func encher_aos_poucos(intervalo, som):
	if intervalo <= 0:
		push_error("Coracoes: coracoes_reenchem sem intervalo")
		return
	if tween_encher != null:
		tween_encher.kill()
	set_vidas(0)
	tween_encher = create_tween()
	for i in range(coracoes.size()):
		tween_encher.tween_interval(intervalo)
		tween_encher.tween_callback(encher_um.bind(i + 1, som))
	tween_encher.tween_callback(terminar_de_encher)

# Mais um coração cheio no encher_aos_poucos (n = quantos ficam cheios)
func encher_um(n, som):
	set_vidas(n)
	if som != &"":
		Sons.tocar_na_escala(som, n - 1)

# Fim do encher_aos_poucos
func terminar_de_encher():
	tween_encher = null
	encheu.emit()

# O encher_aos_poucos está em andamento
func enchendo():
	return tween_encher != null

# Troca a textura do coração cheio (cor da fase do boss) e redesenha
func trocar_cheio(textura):
	cheio = textura
	set_vidas(cheios)

var tween_piscada: Tween = null

# Pisca sem parar (enquanto o boss desce)
func piscar_ate_parar():
	if tween_piscada != null:
		tween_piscada.kill()
	tween_piscada = create_tween().set_loops()
	tween_piscada.tween_property(self, "modulate:a", 0.2, 0.15)
	tween_piscada.tween_property(self, "modulate:a", 1.0, 0.15)

func parar_piscada():
	if tween_piscada != null:
		tween_piscada.kill()
		tween_piscada = null
	modulate.a = 1.0
	
# Piscadas cada vez mais rápidas e depois esconde (boss morreu)
func sumir_piscando():
	parar_pulso()
	if tween_piscada != null:
		tween_piscada.kill()
	modulate.a = 1.0
	tween_piscada = create_tween()
	var d = 0.15
	for i in range(8):
		tween_piscada.tween_property(self, "modulate:a", 0.2, d)
		tween_piscada.tween_property(self, "modulate:a", 1.0, d)
		d *= 0.75
	tween_piscada.tween_callback(hide)
