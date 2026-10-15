# Orquestrador da batalha final: só sabe a ORDEM das fases (os filhos de $Fases, de cima
# para baixo). Quando uma termina, começa a próxima. Repassa para a main o que a hud
# precisa saber do boss.
extends Node

signal vida_boss_mudou(vida, vida_max)
signal boss_invulneravel(ligado)
# Começou a fase 'nome' (o nó dela em $Fases) da luta 'numero' (1, 2, 3);
# "FIM" e 0 quando acabam as fases
signal fase_mudou(nome, numero)
# Acabaram as fases
signal terminou
# O boss terminou de entrar (repassado da fase)
signal boss_entrou
# A fase pediu outra textura de coração cheio (repassado para a hud)
signal coracoes_boss_trocados(textura)

var ctx: ContextoBatalha
var indice_fase := -1

# Repassa os sinais do corpo e das fases para cima e ouve o 'terminou' de cada fase
func _ready():
	$LoraxFinal.vida_mudou.connect(vida_boss_mudou.emit)
	$LoraxFinal.invulneravel_mudou.connect(boss_invulneravel.emit)
	for fase in $Fases.get_children():
		fase.terminou.connect(proxima_fase)
		fase.entrou.connect(boss_entrou.emit)
		fase.trocar_coracoes.connect(coracoes_boss_trocados.emit)

# Chamada pela main (depois de conectar os sinais): monta o contexto e começa a 1ª fase
func comecar(player, dialogo):
	ctx = ContextoBatalha.new()
	ctx.corpo = $LoraxFinal
	ctx.ataques = $Ataques
	ctx.player = player
	ctx.dialogo = dialogo
	proxima_fase()

# O corpo do boss (alvo dos momentos que a main toca: coração perdido, último coração)
func corpo():
	return $LoraxFinal

# O boss para de tremer de desespero (o player morreu com ele no último coração)
func parar_desespero():
	$LoraxFinal.parar_desespero()

# O player morreu: a fase da vez para (o boss para de andar e de atacar)
func parar_luta():
	var fases = $Fases.get_children()
	if indice_fase >= 0 and indice_fase < fases.size():
		fases[indice_fase].parar()

# Limpa os projéteis que sobraram e começa o próximo filho de $Fases; se não há mais
# nenhum, avisa a main. A limpeza vem antes de tudo: não apaga o que a nova fase cria
func proxima_fase():
	LimpezaProjeteis.limpar($Ataques, self)
	indice_fase += 1
	var fases = $Fases.get_children()
	if indice_fase >= fases.size():
		fase_mudou.emit(&"FIM", 0)
		terminou.emit()
		return
	fase_mudou.emit(fases[indice_fase].name, fases[indice_fase].numero_fase())
	fases[indice_fase].comecar(ctx)
