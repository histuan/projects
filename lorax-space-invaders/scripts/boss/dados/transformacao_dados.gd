# Dados da transformação do boss (a cutscene entre a fase 2 e a fase 3).
# Mesma fase_transformacao.gd, números e momentos aqui.
class_name TransformacaoDados
extends Resource

## Fase da luta enquanto a transformação toca (2 até o pico do pilar; decide o retrato das falas)
@export var numero_fase := 0
## Animações da cutscene (cutscene.tres)
@export var animacoes: ConjuntoAnimacoes

@export_group("Momentos")
## Derrota com raiva: tocado no 1º quadro da derrota_raiva, com a duração dela
@export var momento_raiva := &""
## Cada batida do símbolo de raiva (quadros_pulso da derrota_raiva)
@export var momento_raiva_pulso := &""
## Quadro de evento da derrota_raiva (a respiração antes do despertar)
@export var momento_raiva_respira := &""

@export_group("Música")
## Quanto a música abaixa (dB, negativo) quando a cutscene começa; 0 = não abaixa
@export var musica_abaixar_db := 0.0
## Em quantos segundos ela abaixa
@export var musica_abaixar_tempo := 0.0

@export_group("Cheat")
## Onde o boss aparece quando a transformação começa direto (onde a fase 2 o deixa)
@export var posicao_direta := Vector2.ZERO
## Textura dos corações cheios do boss quando a transformação começa direto (a da fase 2)
@export var coracao_boss: Texture2D
