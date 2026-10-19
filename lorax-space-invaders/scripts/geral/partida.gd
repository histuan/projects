# Estado da partida atual: pontos, vidas e wave. É um AUTOLOAD (nome global "Partida"),
extends Node

signal pontos_mudaram(total)
signal pontos_ganhos(valor, posicao, tamanho)
signal vidas_mudaram(vidas)
signal vida_perdida
signal vida_ganha
signal morreu
signal wave_mudou(wave)

const MAX_VIDAS = 3
var pontos = 0
var vidas = MAX_VIDAS
var wave = 0

# Etapas do cheat code (o seletor da tela inicial lista NOMES_ETAPAS).
# etapa_inicial sobrevive ao nova_partida(): é ela que o "Reiniciar" mantém
enum Etapa { NENHUMA, WAVE_BOSS, LAB_EFEITOS, LAB_SONS, LAB_TEXTOS, FASE_2, TRANSFORMACAO }
const NOMES_ETAPAS = {
	Etapa.WAVE_BOSS: "WAVE DO BOSS",
	Etapa.FASE_2: "FASE 2",
	Etapa.TRANSFORMACAO: "TRANSFORMAÇÃO",
	Etapa.LAB_EFEITOS: "LAB DE EFEITOS",
	Etapa.LAB_SONS: "LAB DE SONS",
	Etapa.LAB_TEXTOS: "LAB DE TEXTOS",
}
var etapa_inicial = Etapa.NENHUMA

# A wave do boss começou (o Pause mostra a fala, o batimento de 1 vida passa a valer)
var em_luta_boss = false
# Fase da luta do boss: 0 = fora dela, 1, 2 ou 3 (o retrato AUTO das falas usa)
var fase_luta = 0
# O boss terminou de entrar e está em cena (o Pause mostra a fala só a partir daqui)
var boss_em_cena = false

# Guarda a etapa em que a próxima partida deve começar
func escolher_etapa(etapa):
	etapa_inicial = etapa

# Volta ao normal (chamada pela tela inicial)
func limpar_etapa():
	etapa_inicial = Etapa.NENHUMA

# Pula direto para uma wave (sem emitir sinal; o avancar_wave() seguinte emite)
func definir_wave(valor):
	wave = valor

# Zera tudo para uma partida nova
func nova_partida():
	pontos = 0
	vidas = MAX_VIDAS
	wave = 0
	em_luta_boss = false
	fase_luta = 0
	boss_em_cena = false

# A wave do boss chegou
func comecar_luta_boss():
	em_luta_boss = true

# O boss pousou (ou já começou em cena): a partir daqui o Pause mostra a fala
func marcar_boss_em_cena():
	boss_em_cena = true

# Começou uma fase da luta (1, 2 ou 3)
func definir_fase_luta(numero):
	fase_luta = numero

# Soma pontos de algo que morreu em 'posicao' (o hud mostra o "+N" ali)
func somar_pontos(valor, posicao, tamanho = 8):
	pontos += valor
	pontos_mudaram.emit(pontos)
	pontos_ganhos.emit(valor, posicao, tamanho)

# Tira 1 vida; na última avisa "morreu". Com o player já morto, ignora
func perder_vida():
	if vidas <= 0:
		return
	vidas -= 1
	vidas_mudaram.emit(vidas)
	vida_perdida.emit()
	if vidas <= 0:
		morreu.emit()

# +1 vida se couber (usada pelo coração que cai)
func ganhar_vida():
	if not pode_ganhar_vida():
		return
	vidas += 1
	vidas_mudaram.emit(vidas)
	vida_ganha.emit()

# Vidas de volta ao máximo, mesmo com 0 (só o R do LAB, depois de o player morrer)
func restaurar_vidas():
	vidas = MAX_VIDAS
	vidas_mudaram.emit(vidas)

# Só vale ganhar vida com o player vivo e abaixo do máximo
func pode_ganhar_vida():
	return vidas > 0 and vidas < MAX_VIDAS

# Chamada pelo groupAlien ao criar uma horda; devolve o número da nova wave
func avancar_wave():
	wave += 1
	wave_mudou.emit(wave)
	return wave
