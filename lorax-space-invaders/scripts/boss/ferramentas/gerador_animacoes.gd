# Gerador das animações do boss final: abra este script no Script editor e use File → Run.
# Varre as folhas de lorax_ui_final, cria um AnimacaoDados por folha e salva os conjuntos
# (ConjuntoAnimacoes) em recursos/boss/animacoes/. Re-executável: animação que já está no
# .tres NÃO é tocada (o que foi ajustado no Inspector fica); só entram as que faltam.
# Nunca apaga nada. O resumo e os avisos saem no Output.
@tool
extends EditorScript

const PASTA_SPRITES = "res://meus sprites/lorax boss battle/lorax_ui_final/"
const PASTA_DESTINO = "res://recursos/boss/animacoes/"

# Animações para refazer do zero na próxima execução: "nome" (em todos os conjuntos) ou
# "conjunto/nome". Ex.: ["cutscene/despertar"] depois de mudar os tempos dela aqui embaixo
const RECRIAR = []

# Conjunto → pasta varrida (relativa a PASTA_SPRITES), se entra nas subpastas, arquivos
# ignorados (sem o .png) e se as folhas dele deveriam ter tempos em TEMPOS
const CONJUNTOS = {
	"cutscene": {"pasta": "cutscene", "subpastas": false, "ignorar": ["cutscene_completa"], "com_tempos": true},
	"pilar_alto": {"pasta": "cutscene/8_pilar_alto", "subpastas": false, "ignorar": [], "com_tempos": true},
	"finais": {"pasta": "final", "subpastas": false, "ignorar": ["semente_brotando", "finish_him"], "com_tempos": true},
	"batalha_ui1": {"pasta": "batalha/UI-fase1", "subpastas": true, "ignorar": [], "com_tempos": false},
	"batalha_ui2": {"pasta": "batalha/UI-fase2", "subpastas": true, "ignorar": [], "com_tempos": false},
	"batalha_comum": {"pasta": "batalha/comum", "subpastas": true, "ignorar": [], "com_tempos": false},
}

# Animações que não são uma folha inteira: conjunto, nome, folha, quadros, tempos, repetir.
# O FINISH HIM da luta é o letreiro (momento finish_him); estas duas são só a prévia do LAB
const ESPECIAIS = [
	["previa_finish_him", "finish_him_entrada", "final/finish_him.png", [0], [0.18], false],
	["previa_finish_him", "finish_him", "final/finish_him.png", [1, 2], [0.25, 0.25], true],
]

# Folhas de quadro não quadrado (largura do quadro em px); as outras usam a altura do PNG
const LARGURA_QUADRO = {"8_pilar_alto": 64, "finish_him": 118}

# Folhas da cutscene sem tempos de propósito: tocam no padrão do AnimacaoDados (0,2 s)
const SEM_TEMPOS = ["puxao", "invocar_jaula"]

# Batalha da fase 3: as ações usam o padrão (0,2 s por quadro); a respiração é mais lenta
const TEMPO_RESPIRACAO = 0.5
const RESPIRACAO = ["postura", "meditando"]

# Velocidade das animações novas (1 = tempos como escritos aqui; 1.5 = 50% mais rápidas).
# Fica no campo 'velocidade' de cada animação: dá para ajustar uma a uma no Inspector.
# As da lista SEM_ACELERAR ficam em 1 (respiração e finais: o ritmo lento é de propósito)
const VELOCIDADE_PADRAO = 1.5
const SEM_ACELERAR = ["parado", "postura", "meditando", "lorax_finalizar", "lorax_poupar", "finish_him_entrada", "finish_him"]

const REPETIR = ["parado", "postura", "meditando", "desliza_dir", "desliza_esq", "tonto"]

# Quadro de evento (posição a partir de 0). Os da fase 3 são SUGESTÃO, a confirmar no LAB;
# o do lorax_poupar é a semente saindo da mão
const EVENTOS = {
	"mao_dir": 1, "mao_esq": 1, "abre_os_dois": 1,
	"orbe_dir": 4, "orbe_esq": 4,
	"pancada": 3, "raio": 4, "esfera": 5,
	"chamar_folhas": 4, "lancar_folhas": 3,
	"lorax_poupar": 13,
}

# Tempo (s) de cada quadro, na ordem da folha
const TEMPOS = {
	"derrota_raiva": [
		0.50, 0.26, 0.26, 0.26, 0.26, 0.26, 0.26, 0.26, 0.26, 0.26,
		0.26, 0.26, 0.26, 0.40, 0.50, 0.50, 0.40, 0.60, 0.50, 0.60],
	"despertar": [
		0.50, 0.50, 0.50, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25,
		0.25, 0.30, 0.25, 0.25, 0.25, 0.35],
	"aura": [
		0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.28, 0.22,
		0.22, 0.22, 0.22, 0.25],
	"pilar": [
		0.25, 0.25, 0.25, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
		0.20, 0.20, 0.20, 0.20, 0.20, 0.25, 0.25, 0.25, 0.25, 0.25,
		0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
		0.20, 0.20, 0.20, 0.20, 0.25, 0.25],
	"reparo": [
		0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22,
		0.22, 0.22, 0.22, 0.22, 0.60],
	"chapeu": [
		0.22, 0.22, 0.25, 0.22, 0.22, 0.22, 0.20, 0.20, 0.20, 0.20,
		0.20, 0.25],
	"parado": [0.50, 0.50],
	"piscada": [0.16, 0.20, 0.16],
	# Os do pilar + os 2 primeiros do reparo (toca junto com eles, atrás do corpo)
	"pilar_alto": [
		0.25, 0.25, 0.25, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
		0.20, 0.20, 0.20, 0.20, 0.20, 0.25, 0.25, 0.25, 0.25, 0.25,
		0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
		0.20, 0.20, 0.20, 0.20, 0.25, 0.25, 0.22, 0.22],
	"lorax_finalizar": [
		0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.16, 0.16,
		0.20, 0.18, 0.18, 0.60, 0.28, 0.28, 0.28, 0.28, 0.28, 0.40,
		0.40, 0.40, 1.00, 0.60, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24,
		0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24,
		0.24, 0.24, 0.24, 0.90],
	"lorax_poupar": [
		0.25, 0.25, 0.25, 0.20, 0.20, 0.70, 0.70, 1.10, 0.40, 0.60,
		0.20, 0.20, 0.20, 0.70, 0.70, 0.70, 0.70, 0.90, 0.25, 0.50,
		0.60, 0.90, 0.50, 0.40, 1.00, 0.50, 0.70, 1.70, 0.32, 0.32,
		0.32, 0.32, 0.90, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24,
		0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24,
		0.24, 0.24, 0.24, 0.24, 0.24, 1.30],
}

var criadas = 0
var refeitas = 0
var mantidas = 0
var avisos = []

# Monta as animações de cada conjunto (pastas + especiais), atualiza os .tres e mostra o resumo
func _run():
	criadas = 0
	refeitas = 0
	mantidas = 0
	avisos = []
	DirAccess.make_dir_recursive_absolute(PASTA_DESTINO)
	var receitas = {}
	for conjunto in CONJUNTOS:
		receitas[conjunto] = receitas_da_pasta(conjunto)
	for especial in ESPECIAIS:
		if not receitas.has(especial[0]):
			receitas[especial[0]] = []
		var dados = receita_especial(especial)
		if dados != null:
			receitas[especial[0]].append(dados)
	for conjunto in receitas:
		atualizar_conjunto(conjunto, receitas[conjunto])
	EditorInterface.get_resource_filesystem().scan()
	print("Animações do boss: %d criadas, %d refeitas, %d mantidas, %d avisos" % [criadas, refeitas, mantidas, avisos.size()])
	for aviso in avisos:
		print("  AVISO: ", aviso)

# Uma animação nova (com os valores iniciais) para cada folha da pasta do conjunto
func receitas_da_pasta(conjunto):
	var regra = CONJUNTOS[conjunto]
	var lista = []
	for caminho in folhas(PASTA_SPRITES + regra["pasta"], regra["subpastas"]):
		var arquivo = caminho.get_file().get_basename()
		if arquivo in regra["ignorar"]:
			continue
		var dados = nova_animacao(nome_da_animacao(arquivo), caminho, LARGURA_QUADRO.get(arquivo, 0))
		if dados == null:
			continue
		if regra["com_tempos"] and dados.tempos.is_empty() and not dados.nome in SEM_TEMPOS:
			avisar("%s/%s: folha nova sem tempos em TEMPOS (toca a %s s por quadro)" % [conjunto, dados.nome, dados.tempo_por_quadro])
		lista.append(dados)
	return lista

# Uma animação de ESPECIAIS: só alguns quadros da folha, com tempos próprios
func receita_especial(especial):
	var arquivo = especial[2].get_file().get_basename()
	var dados = nova_animacao(especial[1], PASTA_SPRITES + especial[2], LARGURA_QUADRO.get(arquivo, 0))
	if dados == null:
		return null
	dados.quadros.assign(especial[3])
	dados.tempos.assign(especial[4])
	dados.repetir = especial[5]
	return dados

# AnimacaoDados com os valores iniciais das tabelas daqui (largura 0 = a altura do PNG)
func nova_animacao(nome, caminho, largura):
	var folha = load(caminho) as Texture2D
	if folha == null:
		avisar("%s: não abriu %s (o Godot já importou o PNG?)" % [nome, caminho])
		return null
	var dados = AnimacaoDados.new()
	dados.nome = nome
	dados.folha = folha
	dados.largura_quadro = largura if largura > 0 else folha.get_height()
	if TEMPOS.has(nome):
		dados.tempos.assign(TEMPOS[nome])
	elif nome in RESPIRACAO:
		dados.tempo_por_quadro = TEMPO_RESPIRACAO
	dados.repetir = nome in REPETIR
	dados.quadro_evento = EVENTOS.get(nome, -1)
	if not nome in SEM_ACELERAR:
		dados.velocidade = VELOCIDADE_PADRAO
	return dados

# Abre (ou cria) o .tres do conjunto, acrescenta as animações que faltam, refaz as de
# RECRIAR, avisa as que perderam a folha e confere todas. Só salva se algo mudou
func atualizar_conjunto(conjunto, receitas):
	var caminho = PASTA_DESTINO + conjunto + ".tres"
	var dados_conjunto: ConjuntoAnimacoes
	var mudou = false
	if ResourceLoader.exists(caminho):
		dados_conjunto = load(caminho) as ConjuntoAnimacoes
		if dados_conjunto == null:
			avisar("%s não é um ConjuntoAnimacoes: nada foi mudado nele" % caminho)
			return
	else:
		dados_conjunto = ConjuntoAnimacoes.new()
		mudou = true
	var nomes = []
	for receita in receitas:
		nomes.append(receita.nome)
		var atual = dados_conjunto.dados(receita.nome)
		if atual == null:
			dados_conjunto.animacoes.append(receita)
			criadas += 1
			mudou = true
		elif receita.nome in RECRIAR or (conjunto + "/" + receita.nome) in RECRIAR:
			dados_conjunto.animacoes[dados_conjunto.animacoes.find(atual)] = receita
			refeitas += 1
			mudou = true
		else:
			mantidas += 1
	for animacao in dados_conjunto.animacoes:
		if not animacao.nome in nomes:
			avisar("%s/%s: a folha sumiu da pasta (a animação continua no .tres)" % [conjunto, animacao.nome])
		conferir(conjunto, animacao)
	if mudou:
		var erro = ResourceSaver.save(dados_conjunto, caminho)
		if erro != OK:
			avisar("não salvou %s (erro %d)" % [caminho, erro])

# Avisos de dado: largura que não divide, tempos ≠ quadros, quadro fora da folha, evento
# fora da animação
func conferir(conjunto, animacao):
	var rotulo = conjunto + "/" + animacao.nome
	if animacao.folha == null:
		avisar(rotulo + ": sem folha")
		return
	if animacao.folha.get_width() % animacao.largura_quadro != 0:
		avisar("%s: folha de %d px não divide em quadros de %d px" % [rotulo, animacao.folha.get_width(), animacao.largura_quadro])
	var total = animacao.total_quadros()
	var tocados = animacao.quadros.size() if not animacao.quadros.is_empty() else total
	if not animacao.tempos.is_empty() and animacao.tempos.size() != tocados:
		avisar("%s: %d quadros e %d tempos" % [rotulo, tocados, animacao.tempos.size()])
	for indice in animacao.quadros:
		if indice < 0 or indice >= total:
			avisar("%s: quadro %d fora da folha (%d quadros)" % [rotulo, indice, total])
	if animacao.quadro_evento >= tocados:
		avisar("%s: quadro_evento %d fora da animação (%d quadros)" % [rotulo, animacao.quadro_evento, tocados])

# Caminhos dos PNG da pasta (e das subpastas, se pedido), em ordem alfabética
func folhas(pasta, subpastas):
	var lista = []
	if not DirAccess.dir_exists_absolute(pasta):
		avisar("pasta não encontrada: " + pasta)
		return lista
	for arquivo in DirAccess.get_files_at(pasta):
		if arquivo.get_extension().to_lower() == "png":
			lista.append(pasta.path_join(arquivo))
	if subpastas:
		for sub in DirAccess.get_directories_at(pasta):
			lista.append_array(folhas(pasta.path_join(sub), true))
	lista.sort()
	return lista

# Nome do arquivo sem o número da frente ("1_despertar" → "despertar")
func nome_da_animacao(arquivo):
	return RegEx.create_from_string("^\\d+_").sub(arquivo, "")

# Guarda o aviso para o resumo e mostra no Output
func avisar(texto):
	avisos.append(texto)
	push_warning(texto)
