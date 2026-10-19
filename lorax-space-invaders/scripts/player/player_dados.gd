# Números do player que o jogo ajusta pelo Inspector (recursos/player/player_dados.tres):
# i-frames e modo arena.
# Os padrões daqui são neutros e não mudam: os valores moram no .tres.
class_name PlayerDados
extends Resource

@export_group("I-frames")
## Segundos sem levar dano depois de ser atingido (vale no jogo todo)
@export var iframes_duracao := 0.0
## Segundos de cada meia piscada (apagado ou aceso) durante os i-frames
@export var iframes_pisca := 0.0
## Alfa do player na parte apagada da piscada
@export var iframes_alfa := 0.0

@export_group("Modo arena")
## Velocidade (px/s) andando em 8 direções na arena
@export var velocidade_arena := 0.0
## Tamanho (px) da área que leva dano na arena
@export var hurtbox := Vector2.ZERO
## A nave pequena em relação à origem do player (medida no player-mini.png): na arena,
## esta caixa inteira fica dentro do limite
@export var caixa_sprite := Rect2()
## Segundos de cada quadro da chama da nave pequena
@export var mini_tempo_quadro := 0.0
