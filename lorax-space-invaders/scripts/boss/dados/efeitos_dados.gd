# Números dos efeitos da boss fight (tremor, hit-stop, zoom...) num Inspector só.
# Tipos: tremor = Vector2(força, segundos) · tremor contínuo = Vector2(de, até) ·
# hit-stop = segundos · câmera lenta = Vector2(escala, segundos reais) ·
# zoom = Vector2(fator, segundos) · flash = Color + Vector2(alfa, segundos).
# Os padrões daqui são neutros e não mudam: os valores oficiais moram no efeitos_boss.tres.
class_name EfeitosDados
extends Resource

@export_group("Geral")
## Desligado: zoom_para e zoom_punch da câmera não fazem nada
@export var zoom_ligado := false

@export_group("Reduzir efeitos")
## Multiplica a força de todo tremor quando "reduzir efeitos" está ligado
@export var fator_tremor_reduzido := 0.0

@export_group("Fases clássicas")
## Boss perdeu um coração (menos o último): (força, segundos)
@export var coracao_boss_tremor := Vector2.ZERO
## Boss perdeu um coração (menos o último): hit-stop em segundos
@export var coracao_boss_hitstop := 0.0
