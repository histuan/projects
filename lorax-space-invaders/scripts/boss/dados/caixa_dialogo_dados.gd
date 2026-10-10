# Números da caixa de diálogo (caixa_dialogo.tres): ritmo do texto, música abaixando,
# folhas de retrato de cada personagem e o layout da caixa.
# Os padrões daqui são neutros e não mudam: os valores moram no .tres.
class_name CaixaDialogoDados
extends Resource

@export_group("Texto")
## Máquina de escrever: letras que aparecem por segundo
@export var letras_por_segundo := 0.0
## Pausa (s) em cada ponto de "..." ("…" vale 3 pontos)
@export var pausa_ponto := 0.0
## Segundos entre abrir e fechar a boca do retrato enquanto o texto aparece
@export var boca_intervalo := 0.0

@export_group("Ritmo (estilo Undertale)")
## Pausa (s) a mais depois de cada espaço (separa as palavras)
@export var pausa_espaco := 0.0
## Pausa (s) a mais em vírgula, ponto e vírgula e dois-pontos
@export var pausa_virgula := 0.0
## Pausa (s) a mais em fim de frase: . ! ? (fora das reticências)
@export var pausa_frase := 0.0
## Chance (0 a 1) de uma palavra sair numa rajada, mais rápida
@export var rajada_chance := 0.0
## Quantas vezes mais rápida é a palavra da rajada
@export var rajada_velocidade := 0.0
## Frases até este tamanho (letras) falam no ritmo normal
@export var frase_curta_letras := 0
## Frases deste tamanho (letras) para cima falam no ritmo mais rápido
@export var frase_longa_letras := 0
## Quantas vezes mais rápida é a frase longa (entre a curta e a longa, aumenta aos poucos)
@export var frase_longa_velocidade := 0.0
## Segundos mínimos entre dois sons da voz: com as letras mais rápidas que isso, várias
## letras saem num som só (cada som novo corta o anterior)
@export var voz_intervalo_min := 0.0

@export_group("Seta")
## Quantos px a seta ▼ sobe e desce quando o texto acaba
@export var seta_pulo_px := 0
## Segundos de um pulo inteiro (sobe e desce)
@export var seta_pulo_periodo := 0.0

@export_group("Música")
## Quanto a música abaixa (dB, negativo) enquanto a caixa está aberta
@export var musica_abaixa_db := 0.0
## Segundos para abaixar quando a caixa abre
@export var musica_abaixa_entrada := 0.0
## Segundos para voltar quando a caixa fecha
@export var musica_abaixa_saida := 0.0

@export_group("Retratos")
## Folhas de retrato: quadros quadrados (lado = altura da folha), em pares (normal, falando)
## por expressão
@export var retrato_lorax_antigo: Texture2D
@export var retrato_fase1: Texture2D
@export var retrato_fase2: Texture2D
@export var retrato_instinto: Texture2D

@export_group("Layout")
## Lado do espaço do retrato (px); o retrato fica centralizado nele, sem escalar
@export var espaco_retrato := 0
## Px entre a borda da caixa e o conteúdo
@export var margem := 0
## Px entre a caixa e as bordas da tela
@export var distancia_tela := 0
@export var tamanho_fonte := 0
## Linhas de texto que cabem na caixa
@export var linhas := 0
