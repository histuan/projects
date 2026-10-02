# Dados de uma animação tirada de uma folha horizontal (um PNG por animação):
# toca todos os quadros da folha, em ordem. Sabe virar uma Animation do Godot.
class_name AnimacaoDados
extends Resource

## Nome pelo qual a fase pede a animação (ex.: "parado", "dano", "ataque")
@export var nome := ""
@export var folha: Texture2D
@export var largura_quadro := 32
@export var tempo_por_quadro := 0.2
@export var repetir := false
## Quadro em que o corpo emite evento_animacao (ex.: soltar o projétil). -1 = sem evento
@export var quadro_evento := -1

# Quantos quadros cabem na folha
func total_quadros():
	return int(folha.get_width() / float(largura_quadro))

# Monta a Animation: troca a folha e o hframes no instante 0 (cada animação vem de um
# PNG diferente) e avança um quadro a cada tempo_por_quadro
func criar_animacao() -> Animation:
	var total = total_quadros()
	var animacao = Animation.new()
	animacao.length = total * tempo_por_quadro
	animacao.loop_mode = Animation.LOOP_LINEAR if repetir else Animation.LOOP_NONE
	criar_faixa(animacao, "Sprite2D:texture", [folha])
	criar_faixa(animacao, "Sprite2D:hframes", [total])
	criar_faixa(animacao, "Sprite2D:frame", range(total))
	if quadro_evento >= 0:
		var faixa = animacao.add_track(Animation.TYPE_METHOD)
		animacao.track_set_path(faixa, NodePath("."))
		animacao.track_insert_key(faixa, quadro_evento * tempo_por_quadro,
				{"method": &"avisar_evento", "args": []})
	return animacao

# Faixa de valor sem interpolação: um valor da lista a cada tempo_por_quadro
func criar_faixa(animacao: Animation, caminho: String, valores: Array):
	var faixa = animacao.add_track(Animation.TYPE_VALUE)
	animacao.track_set_path(faixa, NodePath(caminho))
	animacao.value_track_set_update_mode(faixa, Animation.UPDATE_DISCRETE)
	for i in range(valores.size()):
		animacao.track_insert_key(faixa, i * tempo_por_quadro, valores[i])
