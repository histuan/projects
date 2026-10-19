# Números da morte da nave na arena (recursos/player/morte_arena.tres): a nave parte no 1º golpe
# do som e estoura em cacos no 2º. Tempos contados do início do som.
# Os padrões daqui são neutros e não mudam: os valores moram no .tres.
class_name MorteArenaDados
extends Resource

@export_group("Arte")
## Folha da morte: quadro 1 = a nave partida, quadro 2 = os pedaços separados (vira os cacos)
@export var textura: Texture2D
## Tamanho (px) de cada quadro da folha
@export var tamanho_quadro := Vector2i.ZERO
## Canto de cima à esquerda do quadro em relação à origem do player
@export var posicao_quadro := Vector2.ZERO

@export_group("Tempos")
## Segundos do início do som até a nave partir (1º golpe)
@export var tempo_partir := 0.0
## Segundos do início do som até a nave estourar em cacos (2º golpe)
@export var tempo_estourar := 0.0

@export_group("Cacos")
## Sorteio (graus, total) em volta da direção do centro da nave ao centro do caco
@export var espalhar_graus := 0.0
## Velocidade (px/s) sorteada entre min e max
@export var velocidade_min := 0.0
@export var velocidade_max := 0.0
## Giro (graus/s) sorteado entre 0 e este valor, com o sentido sorteado
@export var giro_max := 0.0
## Gravidade (px/s²) puxando os cacos para baixo
@export var gravidade := 0.0
## Segundos de voo dos cacos; no fim a morte termina
@export var duracao_cacos := 0.0
## Segundos do fade no fim do voo
@export var fade_cacos := 0.0

@export_group("Mundo")
## A música é cortada seca quando a nave morre na arena
@export var cortar_musica := false
