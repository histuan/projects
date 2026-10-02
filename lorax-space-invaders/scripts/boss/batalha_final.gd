# Orquestrador da batalha final: só sabe a ORDEM das fases (os filhos de $Fases, de cima
# para baixo). Quando uma termina, começa a próxima. Repassa para a main o que a hud
# precisa saber do boss.
extends Node

signal vida_boss_mudou(vida, vida_max)
signal boss_invulneravel(ligado)
# Acabaram as fases
signal terminou

var ctx: ContextoBatalha
var indice_fase := -1

# Repassa os sinais do corpo para cima e ouve o 'terminou' de cada fase
func _ready():
	$LoraxFinal.vida_mudou.connect(vida_boss_mudou.emit)
	$LoraxFinal.invulneravel_mudou.connect(boss_invulneravel.emit)
	for fase in $Fases.get_children():
		fase.terminou.connect(proxima_fase)

# Chamada pela main (depois de conectar os sinais): monta o contexto e começa a 1ª fase
func comecar(player):
	ctx = ContextoBatalha.new()
	ctx.corpo = $LoraxFinal
	ctx.ataques = $Ataques
	ctx.player = player
	proxima_fase()

# Começa o próximo filho de $Fases; se não há mais nenhum, avisa a main
func proxima_fase():
	indice_fase += 1
	var fases = $Fases.get_children()
	if indice_fase >= fases.size():
		terminou.emit()
		return
	fases[indice_fase].comecar(ctx)
