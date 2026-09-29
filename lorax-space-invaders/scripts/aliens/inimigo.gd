# Base de todo inimigo: vidas, pontos, a interface de dano (receber_dano), piscada
# e sons que continuam tocando depois da morte. Cada inimigo faz "extends Inimigo"
# e sobrescreve só o que é dele: ao_ferir() e/ou morrer().
class_name Inimigo
extends CharacterBody2D

@export var vidas := 1
@export var valor_pontos := 100
# Caminhos dos sons dentro do inimigo; se o nó não existir, fica em silêncio
@export var som_dano := "sons/dano"
@export var som_morte := "sons/morte"

var vivo := true
var tween_pisca: Tween = null

# Interface única de dano. Com vida sobrando chama ao_ferir(); no zero, morrer()
func receber_dano(quantidade = 1, fonte = "tiro"):
	if not vivo:
		return
	vidas -= quantidade
	if vidas > 0:
		ao_ferir(fonte)
	else:
		vivo = false
		morrer(fonte)

# Padrão ao levar dano sem morrer: som de dano + piscada.
# Quem sobrescreve e quer manter isso chama super(fonte)
func ao_ferir(_fonte):
	tocar_som(som_dano)
	piscar()

# Padrão de morte: som, pontos e some na hora.
# Inimigos com animação de morte sobrescrevem (e dão os pontos no fim dela)
func morrer(_fonte):
	soltar_som(som_morte)
	dar_pontos()
	queue_free()

# Soma os pontos deste inimigo na Partida (o hud mostra o "+N" onde ele está)
func dar_pontos(tamanho = 8):
	Partida.somar_pontos(valor_pontos, global_position, tamanho)

# Toca um som do próprio inimigo, se ele existir
func tocar_som(caminho):
	if has_node(caminho):
		get_node(caminho).play()

# Som que precisa continuar depois que o inimigo sumir: sai dele e vai para a cena principal
func soltar_som(caminho):
	if not has_node(caminho):
		return
	var som = get_node(caminho)
	som.reparent(get_tree().current_scene)
	som.play()
	som.finished.connect(som.queue_free)

# Pisca 3 vezes; mata a piscada anterior para não acumular tweens
func piscar():
	if tween_pisca != null:
		tween_pisca.kill()
	modulate.a = 1.0
	tween_pisca = create_tween()
	for i in range(3):
		tween_pisca.tween_property(self, "modulate:a", 0.2, 0.08)
		tween_pisca.tween_property(self, "modulate:a", 1.0, 0.08)
