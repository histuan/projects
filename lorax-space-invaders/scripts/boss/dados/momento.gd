# Um momento da luta (momentos_boss.tres): os passos de efeito que acontecem juntos, cada
# um no seu segundo. Quem toca é Momentos.tocar(&"nome", alvo): a luta e o LAB DE EFEITOS
# tocam o mesmo dado. Os padrões daqui são neutros e não mudam.
class_name Momento
extends Resource

## Nome da linha no LAB DE EFEITOS
@export var titulo := ""
@export var passos: Array[Passo] = []
## Momento que a fase toca no quadro de evento seguinte (ou no fim da animação); o LAB
## toca ele depois de duracao_animacao_lab
@export var seguinte := &""
## PROVISÓRIO, só o LAB usa: segundos que a animação "dura" para os passos da_animacao e
## para tocar o seguinte. Na luta quem manda é a animação de verdade
@export var duracao_animacao_lab := 0.0
