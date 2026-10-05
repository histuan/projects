# Biblioteca de sons da boss fight (um arquivo só: sons_boss.tres): evento → SomDados,
# a compensação de volume de cada arquivo e os números das sequências de áudio.
# Os padrões daqui são neutros e não mudam: os valores moram no .tres.
class_name BibliotecaSons
extends Resource

@export_group("Eventos")
@export var eventos: Dictionary[StringName, SomDados] = {}

@export_group("Arquivos")
## Ganho (dB) de cada arquivo para todos partirem do mesmo pico (-3 dB); a mixagem de
## ouvido vai no volume_db do evento. Trocar um arquivo = medir o pico e mudar só o ganho dele
@export var ganhos: Dictionary[String, float] = {}

@export_group("Wave 10")
## Segundos para a música do jogo sumir quando a wave 10 chega
@export var wave10_fade_musica := 0.0
## Segundos de silêncio total depois de ela sumir, antes do alarme
@export var wave10_silencio := 0.0

@export_group("Fase 3")
## Troca final_fight1 → final_fight2: a 2 começa esta quantidade de segundos antes
## da posição em que a 1 está
@export var recuo_troca_fase3 := 0.0

@export_group("Câmera lenta")
## Com o tempo do jogo nesta escala ou abaixo, os efeitos tocam mais graves
@export var escala_camera_lenta := 0.0
## Multiplicador do pitch dos efeitos durante a câmera lenta
@export var pitch_camera_lenta := 0.0

@export_group("Abafar (low-pass da música)")
## Despertar da transformação: corte (Hz) e segundos para chegar nele
@export var abafar_despertar_hz := 0.0
@export var abafar_despertar_duracao := 0.0
## Arena nasce: segundos para "destampar" a música (voltar ao corte aberto)
@export var destampar_duracao := 0.0
## Player com 1 vida: corte (Hz)
@export var abafar_vida_baixa_hz := 0.0
