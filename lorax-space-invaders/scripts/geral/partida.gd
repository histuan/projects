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
enum Etapa { NENHUMA, WAVE_BOSS }
const NOMES_ETAPAS = {
	Etapa.WAVE_BOSS: "WAVE DO BOSS",
}
var etapa_inicial = Etapa.NENHUMA

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

# Só vale ganhar vida com o player vivo e abaixo do máximo
func pode_ganhar_vida():
	return vidas > 0 and vidas < MAX_VIDAS

# Chamada pelo groupAlien ao criar uma horda; devolve o número da nova wave
func avancar_wave():
	wave += 1
	wave_mudou.emit(wave)
	return wave
