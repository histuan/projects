# Dados de uma fase clássica do boss (vai e vem + ataque em leque).
# Mesma fase_classica.gd, um .tres por fase.
class_name FaseClassicaDados
extends Resource

@export_group("Vida")
## Golpes que o boss aguenta nesta fase (a hud reparte isso nos corações)
@export var vida := 15

@export_group("Movimento")
@export var velocidade := 50.0
## Altura em que ele fica indo e vindo
@export var altura := 48.0
@export var limite_esq := 37.0
@export var limite_dir := 217.0
## Velocidade com que chega até a altura no começo da fase
@export var vel_entrada := 40.0

@export_group("Ataque")
## Segundos entre o fim de um ataque e o começo do próximo, com a vida cheia
@export var intervalo_ataque := 2.5
## O mesmo intervalo quando resta 1 de vida (entre os dois, diminui proporcionalmente)
@export var intervalo_minimo := 2.5
@export var projetil: PackedScene
@export var quantidade := 1
## Graus entre dois projéteis vizinhos (só importa com quantidade > 1)
@export var angulo_leque := 0.0
## De onde o projétil sai, em relação ao centro do boss
@export var origem_tiro := Vector2(0, 12)
@export var para_ao_atacar := true

@export_group("Animações")
## Precisa ter "parado", "dano" e "ataque" (o ataque com quadro_evento)
@export var animacoes: Array[AnimacaoDados] = []

@export_group("Sons")
## Eventos do sons_boss.tres (vazio = sem som nesse momento)
## No começo da descida
@export var som_chegada := &""
## No fim da descida
@export var som_pouso := &""
## No começo da animação de ataque (carga)
@export var som_ataque := &""
## No quadro de evento do ataque, quando os projéteis nascem
@export var sons_disparo: Array[StringName] = []
## A cada golpe que tira vida
@export var som_dano := &""
