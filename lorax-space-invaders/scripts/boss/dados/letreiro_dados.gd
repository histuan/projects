# Estilo de um letreiro (um .tres por estilo em recursos/boss/letreiros/): como o texto (ou
# o sprite) aparece, fica e some. O conteúdo (texto, subtítulo) vem de quem mostra.
# Os padrões daqui são neutros e não mudam: os valores moram nos .tres.
class_name LetreiroDados
extends Resource

@export_group("Aparência")
## Sprite no lugar do texto (ex.: FINAL WAVE)
@export var textura: Texture2D
## Vários sprites lado a lado (ex.: teclas W e S); cada um mostra o quadro 0
@export var texturas: Array[Texture2D] = []
## Quadros em cada sprite de 'texturas' (o quadro é a largura ÷ quadros)
@export var quadros_por_textura := 0
## Px entre os sprites de 'texturas'
@export var espaco_texturas := 0.0
## Centro do letreiro na tela (px)
@export var posicao := Vector2.ZERO
@export var tamanho_fonte := 0
@export var tamanho_subtitulo := 0
## Px entre o centro do texto e o centro do subtítulo (embaixo)
@export var distancia_subtitulo := 0.0
## Cor do texto (letra por letra e contagem também)
@export var cor := Color.WHITE
@export var cor_subtitulo := Color.WHITE
@export var contorno_cor := Color.BLACK
## Espessura do contorno em px (0 = sem contorno)
@export var contorno_px := 0
## Pulso do texto principal: quanto a cor vai em direção ao branco no pico (0 = sem pulso)
@export var pulso_claro := 0.0
## Segundos de um pulso inteiro (clareia e volta)
@export var pulso_periodo := 0.0

@export_group("Entrada")
## Segundos para aparecer (0 = na hora)
@export var fade_in := 0.0
## Espaço extra entre as letras: (de, até) px, durante o fade_in
@export var espacamento := Vector2.ZERO
## Segundos entre uma letra e a próxima (0 = o texto entra inteiro)
@export var letra_intervalo := 0.0
## Escala de cada letra ao entrar: (de, até), no tempo do letra_intervalo
@export var letra_escala := Vector2.ZERO

@export_group("Permanência")
## Segundos na tela depois de entrar (quem mostra pode passar outro tempo)
@export var tempo := 0.0
## Segundos aceso/apagado enquanto fica na tela (0 = fixo)
@export var pisca := 0.0
## Quantas vezes o ciclo entra-fica-some acontece (0 ou 1 = uma vez)
@export var vezes := 0
## Fica na tela até alguém chamar esconder()
@export var fica := false

@export_group("Saída")
## Segundos para sumir (0 = some na hora)
@export var fade_out := 0.0

@export_group("Extras")
## Momento (momentos_boss.tres) tocado a cada letra que entra (ou a cada tique da contagem)
@export var momento_por_letra := &""
## O texto é um número que conta de 0 até ele (tela final)
@export var contagem := false
## Segundos da contagem de 0 até o número
@export var contagem_duracao := 0.0
## Aviso mostrado no LAB (ex.: valores de layout provisórios)
@export var nota := ""
