# Um passo de um Momento (momentos_boss.tres): o que acontece, em que segundo e com que números.
# O Inspector mostra só os campos do tipo escolhido (por isso @tool; o script é só dado).
# Os padrões daqui são neutros e não mudam: os valores moram no momentos_boss.tres.
# Os enums são gravados como número no .tres: só acrescente valores NO FIM deles.
@tool
class_name Passo
extends Resource

enum Tipo {
	NENHUM, TREMER, TREMER_CONTINUO, PARAR_TREMOR_CONTINUO, ZOOM, ZOOM_PUNCH, CONGELAR,
	CAMERA_LENTA, FLASH_TELA, FLASH_CORPO, LETTERBOX, ONDA, ABERRACAO, BORDAS,
	ESTRELAS_VELOCIDADE, ESTRELAS_COR, ESTRELAS_BRILHO, ESTRELAS_RISCO, ESTRELAS_EMPURRAR,
	ESTRELAS_APAGAR, ESTRELAS_ACENDER, PARTICULA, AFTERIMAGE, SOM, SINAL, MOMENTO,
}

enum Particula { NENHUMA, FAISCA, POEIRA_POUSO, POEIRA_BLOCO, FOLHINHAS, KI_HIT, KI_SUBINDO }

# Campos que todo passo tem (sempre visíveis no Inspector)
const COMUNS = ["tempo", "tipo", "repetir", "repetir_a_cada", "pendente", "rotulo"]
# Campos que cada tipo usa (os outros ficam escondidos no Inspector)
const CAMPOS = {
	Tipo.TREMER: ["forca", "duracao"],
	Tipo.TREMER_CONTINUO: ["de", "ate", "duracao", "da_animacao", "fica_ligado"],
	Tipo.PARAR_TREMOR_CONTINUO: ["duracao"],
	Tipo.ZOOM: ["fator", "duracao", "focar_alvo"],
	Tipo.ZOOM_PUNCH: ["fator", "duracao"],
	Tipo.CONGELAR: ["duracao"],
	Tipo.CAMERA_LENTA: ["escala", "duracao"],
	Tipo.FLASH_TELA: ["cor", "alfa", "duracao"],
	Tipo.FLASH_CORPO: ["cor", "alfa", "duracao", "pulsar"],
	Tipo.LETTERBOX: ["ligar"],
	Tipo.ONDA: ["raio", "duracao", "forca"],
	Tipo.ABERRACAO: ["px"],
	Tipo.BORDAS: ["ligar", "cor", "alfa", "pulsar", "vezes"],
	Tipo.ESTRELAS_VELOCIDADE: ["fator", "duracao", "da_animacao"],
	Tipo.ESTRELAS_COR: ["cor", "duracao"],
	Tipo.ESTRELAS_BRILHO: ["fator", "duracao"],
	Tipo.ESTRELAS_RISCO: ["ligar", "fator", "limiar"],
	Tipo.ESTRELAS_EMPURRAR: ["forca", "duracao"],
	Tipo.ESTRELAS_APAGAR: ["duracao"],
	Tipo.ESTRELAS_ACENDER: ["cor", "quantidade", "duracao"],
	Tipo.PARTICULA: ["particula", "deslocamento", "direcao", "espalhar", "duracao", "da_animacao"],
	Tipo.AFTERIMAGE: ["copias", "intervalo", "vida", "cor", "alfa"],
	Tipo.SOM: ["nome"],
	Tipo.SINAL: ["nome", "parametros"],
	Tipo.MOMENTO: ["nome"],
}

## Segundos (tempo real) depois do início do momento
@export var tempo := 0.0
@export var tipo := Tipo.NENHUM:
	set(valor):
		tipo = valor
		notify_property_list_changed()
## Quantas vezes o passo acontece (0 ou 1 = uma vez)
@export var repetir := 0
## Segundos entre uma repetição e outra
@export var repetir_a_cada := 0.0
## Ainda não roda: "SEM VALOR", "NA F1"... O LAB mostra o passo com esta marca
@export var pendente := ""
## Texto do LAB no lugar do automático
@export var rotulo := ""

## Tremor: força em px. Onda: força da distorção. Empurrar estrelas: px (negativa = sugadas)
@export var forca := 0.0
## Tremor contínuo: força inicial
@export var de := 0.0
## Tremor contínuo: força final (fica nela até ser parado)
@export var ate := 0.0
## Zoom e zoom punch: fator. Estrelas: multiplicador de velocidade, brilho (0 a 1) ou fator do risco
@export var fator := 0.0
## Câmera lenta: escala do tempo do jogo
@export var escala := 0.0
@export var duracao := 0.0
## A duração é a da animação que quem toca o momento informa (nunca um número copiado)
@export var da_animacao := false
## Tremor contínuo sem fim: fica até um PARAR_TREMOR_CONTINUO (ou o R do LAB)
@export var fica_ligado := false
## Zoom: aproxima no alvo (sem isso, no meio da tela)
@export var focar_alvo := false
## A cor mora no efeitos_boss.tres
@export var cor := EfeitosDados.Cor.NENHUMA
@export var alfa := 0.0
## Flash no corpo: segundos de cada pulso (0 = flash único). Bordas: segundos aceso/apagado
@export var pulsar := 0.0
## Bordas: quantas piscadas (0 = até a próxima chamada)
@export var vezes := 0
## Letterbox, bordas e riscos: liga (marcado) ou desliga
@export var ligar := false
## Onda: raio final (px)
@export var raio := 0.0
## Aberração: separação das cores (px)
@export var px := 0.0
## Riscos: velocidade (px/s) a partir da qual a estrela vira risco
@export var limiar := 0.0
## Estrelas novas: quantas
@export var quantidade := 0
## Quantidade, distância e vida vêm de Partículas do efeitos_boss.tres
@export var particula := Particula.NENHUMA
## Partícula: px a partir do alvo
@export var deslocamento := Vector2.ZERO
## Partícula: direção (zero = a da cena)
@export var direcao := Vector2.ZERO
## Partícula: abertura em graus (0 = a da cena)
@export var espalhar := 0.0
## Afterimage: cópias, segundos entre elas e segundos que cada uma leva para sumir
@export var copias := 0
@export var intervalo := 0.0
@export var vida := 0.0
## Som: evento do sons_boss.tres. Sinal: nome do pedido. Momento: nome do momento
@export var nome := &""
## Sinal: números que a fase usa (chaves em texto)
@export var parametros := {}

# Esconde no Inspector os campos que o tipo atual não usa (eles continuam salvos)
func _validate_property(property):
	if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
		return
	if property.name in COMUNS or property.name in CAMPOS.get(tipo, []):
		return
	property.usage &= ~PROPERTY_USAGE_EDITOR

# Nome do primeiro campo obrigatório zerado ou vazio ("" = o passo pode rodar).
# Onde 0 é um valor de verdade (estrelas paradas, tremor contínuo até 0) não há cobrança
func campo_faltando():
	match tipo:
		Tipo.NENHUM:
			return "tipo"
		Tipo.TREMER:
			return zerado({"forca": forca})
		Tipo.TREMER_CONTINUO:
			if duracao <= 0 and not da_animacao and not fica_ligado:
				return "duracao"
		Tipo.ZOOM:
			return zerado({"fator": fator})
		Tipo.ZOOM_PUNCH:
			return zerado({"fator": fator, "duracao": duracao})
		Tipo.CONGELAR:
			return zerado({"duracao": duracao})
		Tipo.CAMERA_LENTA:
			return zerado({"escala": escala, "duracao": duracao})
		Tipo.FLASH_TELA:
			return zerado({"cor": cor, "alfa": alfa, "duracao": duracao})
		Tipo.FLASH_CORPO:
			var falta = zerado({"cor": cor, "alfa": alfa})
			if falta == "" and duracao <= 0 and pulsar <= 0:
				return "duracao"
			return falta
		Tipo.ONDA:
			return zerado({"raio": raio, "duracao": duracao, "forca": forca})
		Tipo.ABERRACAO:
			return zerado({"px": px})
		Tipo.BORDAS:
			if ligar:
				return zerado({"cor": cor, "alfa": alfa})
		Tipo.ESTRELAS_COR:
			return zerado({"cor": cor})
		Tipo.ESTRELAS_RISCO:
			if ligar:
				return zerado({"fator": fator})
		Tipo.ESTRELAS_EMPURRAR:
			if forca == 0:
				return "forca"
			return zerado({"duracao": duracao})
		Tipo.ESTRELAS_APAGAR:
			return zerado({"duracao": duracao})
		Tipo.ESTRELAS_ACENDER:
			return zerado({"cor": cor, "quantidade": quantidade, "duracao": duracao})
		Tipo.PARTICULA:
			if particula == Particula.KI_SUBINDO and duracao <= 0 and not da_animacao:
				return "duracao"
			return zerado({"particula": particula})
		Tipo.AFTERIMAGE:
			return zerado({"cor": cor, "copias": copias, "vida": vida, "alfa": alfa})
		Tipo.SOM, Tipo.SINAL, Tipo.MOMENTO:
			return zerado({"nome": nome})
	return ""

# O primeiro campo da lista que está em 0 (ou vazio); "" se todos têm valor
func zerado(campos):
	for campo in campos:
		var valor = campos[campo]
		if valor is StringName or valor is String:
			if valor.is_empty():
				return campo
		elif valor <= 0:
			return campo
	return ""
