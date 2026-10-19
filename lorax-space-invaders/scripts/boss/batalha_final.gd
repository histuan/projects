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
# A fase pediu o player travado (true) ou solto (false) (repassado para a main)
signal player_travado(ligado)
# A fase pediu a tela limpa: itens, tiros do player e planeta somem, nada novo cai (para a main)
signal tela_limpa_pedida
# A fase pediu o cenário fora: bases, chão e paredes somem (para a main)
signal cenario_limpo_pedido

# Corações do boss na hud (só para a tecla K de debug saber quanto é um coração)
const CORACOES_BOSS = 5

var ctx: ContextoBatalha
var indice_fase := -1
# A luta parou (o player morreu): nenhuma fase nova começa
var parada := false

# Repassa os sinais do corpo e das fases para cima e ouve o 'terminou' de cada fase. A
# limpeza do vida_acabou é ligada antes das fases: os projéteis somem no último hit, antes
# de a fase reagir
func _ready():
	$LoraxFinal.vida_mudou.connect(vida_boss_mudou.emit)
	$LoraxFinal.invulneravel_mudou.connect(boss_invulneravel.emit)
	$LoraxFinal.vida_acabou.connect(limpar_projeteis)
	for fase in $Fases.get_children():
		fase.terminou.connect(proxima_fase)
		fase.entrou.connect(boss_entrou.emit)
		fase.trocar_coracoes.connect(coracoes_boss_trocados.emit)
		fase.travar_player.connect(player_travado.emit)
		fase.limpar_tela.connect(tela_limpa_pedida.emit)
		fase.limpar_cenario.connect(cenario_limpo_pedido.emit)
		fase.fase_luta_mudou.connect(repassar_fase_luta.bind(fase))

# Chamada pela main (depois de conectar os sinais): monta o contexto e começa a 1ª fase
func comecar(player, dialogo):
	montar_contexto(player, dialogo)
	proxima_fase()

# Cheat: começa já na fase 'nome_fase' (um filho de $Fases), sem a entrada dela
func comecar_direto(player, dialogo, nome_fase: StringName):
	montar_contexto(player, dialogo)
	var fase = $Fases.get_node(NodePath(nome_fase))
	indice_fase = fase.get_index()
	fase_mudou.emit(fase.name, fase.numero_fase())
	fase.comecar_direto(ctx)

# A fase da luta mudou no meio de uma fase: avisa como uma troca de fase (mesmo sinal que a main ouve)
func repassar_fase_luta(numero, fase):
	fase_mudou.emit(fase.name, numero)

# O que as fases recebem: corpo, pilar alto, ataques, player e caixa de diálogo
func montar_contexto(player, dialogo):
	ctx = ContextoBatalha.new()
	ctx.corpo = $LoraxFinal
	ctx.pilar_alto = $PilarAlto
	ctx.ataques = $Ataques
	ctx.player = player
	ctx.dialogo = dialogo

# O corpo do boss (alvo dos momentos que a main toca: coração perdido, último coração)
func corpo():
	return $LoraxFinal

# O boss para de tremer de desespero (o player morreu com ele no último coração)
func parar_desespero():
	$LoraxFinal.parar_desespero()

# Sobrou o último coração do boss: a fase da vez reage (com a luta parada, nada)
func ultimo_coracao():
	if parada:
		return
	var fases = $Fases.get_children()
	if indice_fase >= 0 and indice_fase < fases.size():
		fases[indice_fase].ultimo_coracao()

# O player morreu: a fase da vez para (o boss para de andar e de atacar) e nenhuma outra começa
func parar_luta():
	parada = true
	var fases = $Fases.get_children()
	if indice_fase >= 0 and indice_fase < fases.size():
		fases[indice_fase].parar()

# Os projéteis do boss viram faísca (último hit de uma fase e troca de fase)
func limpar_projeteis():
	LimpezaProjeteis.limpar($Ataques, self)

# Debug (tecla K): tira a vida até o limiar do coração de baixo, como tiros de verdade (a
# mesma conta de corações da hud; invulnerável, nada acontece)
func tirar_coracao():
	var corpo = $LoraxFinal
	if not corpo.vivo:
		return
	var por_coracao = corpo.vida_max / float(CORACOES_BOSS)
	var cheios = ceili(corpo.vidas * float(CORACOES_BOSS) / corpo.vida_max)
	var dano = corpo.vidas - roundi((cheios - 1) * por_coracao)
	if dano > 0:
		corpo.receber_dano(dano, "debug")

# Debug (tecla J): a fase da vez pula a entrada e já luta (com a luta parada, nada)
func pular_intro():
	if parada:
		return
	var fases = $Fases.get_children()
	if indice_fase >= 0 and indice_fase < fases.size():
		fases[indice_fase].pular_intro()

# Limpa os projéteis que sobraram e começa o próximo filho de $Fases; se não há mais
# nenhum, avisa a main. A limpeza vem antes de tudo: não apaga o que a nova fase cria.
# Com a luta parada (player morto), só limpa
func proxima_fase():
	limpar_projeteis()
	if parada:
		return
	indice_fase += 1
	var fases = $Fases.get_children()
	if indice_fase >= fases.size():
		fase_mudou.emit(&"FIM", 0)
		terminou.emit()
		return
	fase_mudou.emit(fases[indice_fase].name, fases[indice_fase].numero_fase())
	fases[indice_fase].comecar(ctx)
