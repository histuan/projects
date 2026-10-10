# Uma caixa de fala (falas_boss.tres): o texto, quem fala (o retrato), a expressão e a voz.
# Uma conversa = falas ligadas pelo 'seguinte'.
# Os padrões daqui são neutros e não mudam: os valores moram no .tres.
# Os enums são gravados como número no .tres: só acrescente valores NO FIM deles.
class_name Fala
extends Resource

# AUTO = o Lorax da fase atual da luta (Partida.fase_luta)
enum Personagem { AUTO, LORAX_ANTIGO, FASE1, FASE2, INSTINTO }
# Expressão que a folha de retratos não tem = a primeira dela
enum Expressao { CALMO, SERIO, SORRISO }

## Texto com bbcode: [shake]...[/shake] e [wave]...[/wave] funcionam
@export_multiline var texto := ""
@export var personagem := Personagem.AUTO
@export var expressao := Expressao.CALMO
## Evento do sons_boss.tres tocado a cada letra (vazio = sem voz)
@export var voz := &""
## Fala que vem depois desta, na mesma caixa (vazio = a caixa fecha)
@export var seguinte := &""
## Tamanho da fonte só desta fala (0 = o da caixa)
@export var tamanho_fonte := 0
## Letras por segundo só desta fala (0 = o da caixa)
@export var letras_por_segundo := 0.0
