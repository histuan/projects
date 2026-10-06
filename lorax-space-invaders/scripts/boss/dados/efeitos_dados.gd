# Ferramentas dos efeitos da boss fight (efeitos.md) num Inspector só: regras, cores, tela,
# partículas e vibração. Os números de cada MOMENTO da luta moram no momentos_boss.tres.
# Tipos: partículas = Vector2(quantidade, distância px).
# Os padrões daqui são neutros e não mudam: os valores oficiais moram no efeitos_boss.tres.
class_name EfeitosDados
extends Resource

# Cores que os passos dos momentos citam pelo nome (gravado como número: só acrescente no fim)
enum Cor {
	NENHUMA, BRANCO, DANO, CARGA, RAIVA, POEIRA, AVISO, CORACAO_FASE1, CORACAO_FASE2,
	CORACAO_FASE3, ESTRELAS_FASE2, TRUFULA, AFTERIMAGE,
}

@export_group("Geral")
## Desligado: zoom_para e zoom_punch da câmera não fazem nada
@export var zoom_ligado := false

@export_group("Reduzir efeitos")
## Multiplica a força de todo tremor (e da vibração) quando "reduzir efeitos" está ligado
@export var fator_tremor_reduzido := 0.0
## Multiplica o alfa dos flashes de tela quando "reduzir efeitos" está ligado
@export var fator_flash_reduzido := 0.0
## Alfa máximo de um flash de tela quando "reduzir efeitos" está ligado
@export var alfa_maximo_flash_reduzido := 0.0
## Segundos do fade das bases sob o flash do pilar (em vez do corte seco)
@export var fade_bases_reduzido := 0.0

@export_group("Regras")
## Segurança: flashes de TELA permitidos por segundo
@export var flashes_tela_por_segundo := 0
## Segundos mínimos entre dois tremores do mesmo tipo (golpes repetidos não somam)
@export var intervalo_tremor_repetido := 0.0
## Tremores a partir desta força vibram o gamepad
@export var vibracao_tremor_minimo := 0.0
## Força do maior tremor do jogo (vibração = força ÷ este valor)
@export var vibracao_tremor_maximo := 0.0
## Segundos de vibração quando o tremor não tem duração
@export var vibracao_duracao_padrao := 0.0

@export_group("Cores")
@export var cor_branco := Color()
## Dano no player / bordas
@export var cor_dano := Color()
## Brilho de carga do Lorax 2.0 (pelo amarelo)
@export var cor_carga := Color()
## Raiva / olhos da fase 2
@export var cor_raiva := Color()
## Ki: afterimage, partículas, onda (do mais claro ao mais escuro)
@export var cores_ki := PackedColorArray()
@export var cor_poeira := Color()
## Avisos da fase 3 (o alfa da cor é o alfa do aviso)
@export var cor_aviso := Color()
@export var cor_coracao_fase1 := Color()
@export var cor_coracao_fase2 := Color()
@export var cor_coracao_fase3 := Color()
## Tinta das estrelas na fase 2
@export var cor_estrelas_fase2 := Color()
## Estrelas novas do final bom
@export var cor_trufula := Color()
## Cópias do teleporte / esquiva
@export var cor_afterimage := Color()

@export_group("Tela")
## A HUD treme junto com a tela (só o deslocamento do tremor, nunca o zoom)
@export var hud_treme := false
## Altura das barras do letterbox (px)
@export var letterbox_barras := 0
## Segundos para as barras entrarem/saírem
@export var letterbox_duracao := 0.0
## Largura do degradê das bordas (px)
@export var bordas_largura := 0
## Largura do anel da onda de choque (px)
@export var onda_largura := 0.0
## Aberração cromática: (mínimo, máximo) em px; o valor de cada pico é decidido no momento
@export var aberracao_px := Vector2.ZERO
## Segundos para a aberração voltar ao normal
@export var aberracao_volta := 0.0

@export_group("Partículas")
## Faísca do hit no Lorax 2.0: (quantidade, distância px)
@export var faisca_hit := Vector2.ZERO
## Poeira do pouso, POR LADO: (quantidade, distância px)
@export var poeira_pouso := Vector2.ZERO
## Poeira da folha acertando o bloco: (quantidade, distância px)
@export var poeira_bloco := Vector2.ZERO
## Folhinhas ao perder coração: (mínimo, máximo) de partículas
@export var folhinhas_quantidade := Vector2.ZERO
## Ki do hit no Lorax da fase 3: (quantidade, distância px)
@export var ki_hit := Vector2.ZERO
## Vida (s) do ki do hit (usa a cena da faísca, que vive menos)
@export var ki_hit_vida := 0.0
## Ki subindo do corpo (aura): partículas por segundo
@export var ki_subindo_por_segundo := 0.0

# A cor de um passo de momento (Cor.NENHUMA = transparente)
func cor(qual):
	match qual:
		Cor.BRANCO:
			return cor_branco
		Cor.DANO:
			return cor_dano
		Cor.CARGA:
			return cor_carga
		Cor.RAIVA:
			return cor_raiva
		Cor.POEIRA:
			return cor_poeira
		Cor.AVISO:
			return cor_aviso
		Cor.CORACAO_FASE1:
			return cor_coracao_fase1
		Cor.CORACAO_FASE2:
			return cor_coracao_fase2
		Cor.CORACAO_FASE3:
			return cor_coracao_fase3
		Cor.ESTRELAS_FASE2:
			return cor_estrelas_fase2
		Cor.TRUFULA:
			return cor_trufula
		Cor.AFTERIMAGE:
			return cor_afterimage
	return Color.TRANSPARENT
