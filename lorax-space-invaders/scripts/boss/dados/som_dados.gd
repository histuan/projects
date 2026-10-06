# Um evento de som da boss fight: qual arquivo toca, com que pitch, volume e bus.
# O evento é "o que acontece"; o arquivo é só dado (vários eventos podem usar o mesmo).
# Os padrões daqui são neutros e não mudam: os valores moram no sons_boss.tres.
class_name SomDados
extends Resource

## Caminhos res:// dos arquivos; com mais de um, sorteia sem repetir o anterior
@export var arquivos: Array[String] = []
@export var pitch := 1.0
## Variação: 1,08 sorteia o pitch entre 1/1,08 e 1,08 vezes o pitch (1 = sem variação)
@export var pitch_aleatorio := 1.0
## Pitch ao fim de um deslize (0 = não desliza); quem toca decide a duração
@export var pitch_final := 0.0
## Ajuste de mixagem do evento, de ouvido (parte de 0); a compensação do arquivo vem dos
## ganhos da BibliotecaSons
@export var volume_db := 0.0
@export var bus := &"Master"
## Segundos de espera antes de tocar (camadas)
@export var atraso := 0.0
## Toca sem parar até Sons.parar(evento)
@export var loop := false
## Músicas: segundos de crossfade ao entrar (0 = entra na hora)
@export var crossfade := 0.0
## Músicas: segundos em que começam a tocar (pula um começo lento/silencioso)
@export var inicio := 0.0
## Outros sons tocados junto com este, cada um com pitch, volume e atraso próprios
@export var camadas: Array[SomDados] = []
