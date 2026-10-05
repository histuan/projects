# Números dos efeitos da boss fight (efeitos.md) num Inspector só.
# Tipos: tremor = Vector2(força, segundos) · tremor contínuo = Vector2(de, até) ·
# hit-stop = segundos · câmera lenta = Vector2(escala, segundos reais) ·
# zoom = Vector2(fator, segundos) · flash = Vector2(alfa, segundos) (a cor vem de Cores) ·
# onda de choque = Vector3(raio px, segundos, força) · partículas = Vector2(quantidade, distância px).
# Os padrões daqui são neutros e não mudam: os valores oficiais moram no efeitos_boss.tres.
class_name EfeitosDados
extends Resource

@export_group("Geral")
## Desligado: zoom_para e zoom_punch da câmera não fazem nada
@export var zoom_ligado := false

@export_group("Reduzir efeitos")
## Multiplica a força de todo tremor (e da vibração) quando "reduzir efeitos" está ligado
@export var fator_tremor_reduzido := 0.0
## Multiplica o alfa dos flashes de tela quando "reduzir efeitos" está ligado
@export var fator_flash_reduzido := 0.0
## Alfa máximo de um flash de tela quando "reduzir efeitos" está ligado
@export var alfa_maximo_flash_reduzido := 0.0
## Segundos do fade das bases sob o flash do pilar (em vez do corte seco)
@export var fade_bases_reduzido := 0.0

@export_group("Regras")
## Segurança: flashes de TELA permitidos por segundo
@export var flashes_tela_por_segundo := 0
## Segundos mínimos entre dois tremores do mesmo tipo (golpes repetidos não somam)
@export var intervalo_tremor_repetido := 0.0
## Tremores a partir desta força vibram o gamepad
@export var vibracao_tremor_minimo := 0.0
## Força do maior tremor do jogo (vibração = força ÷ este valor)
@export var vibracao_tremor_maximo := 0.0
## Segundos de vibração quando o tremor não tem duração
@export var vibracao_duracao_padrao := 0.0

@export_group("Cores")
@export var cor_branco := Color()
## Dano no player / bordas
@export var cor_dano := Color()
## Brilho de carga do Lorax 2.0 (pelo amarelo)
@export var cor_carga := Color()
## Raiva / olhos da fase 2
@export var cor_raiva := Color()
## Ki: afterimage, partículas, onda (do mais claro ao mais escuro)
@export var cores_ki := PackedColorArray()
@export var cor_poeira := Color()
## Avisos da fase 3 (o alfa da cor é o alfa do aviso)
@export var cor_aviso := Color()
@export var cor_coracao_fase1 := Color()
@export var cor_coracao_fase2 := Color()
@export var cor_coracao_fase3 := Color()
## Tinta das estrelas na fase 2
@export var cor_estrelas_fase2 := Color()
## Estrelas novas do final bom
@export var cor_trufula := Color()

@export_group("Tela")
## A HUD treme junto com a tela (só o deslocamento do tremor, nunca o zoom)
@export var hud_treme := false
## Altura das barras do letterbox (px)
@export var letterbox_barras := 0
## Segundos para as barras entrarem/saírem
@export var letterbox_duracao := 0.0
## Largura do degradê das bordas (px)
@export var bordas_largura := 0
## Largura do anel da onda de choque (px)
@export var onda_largura := 0.0
## Aberração cromática: (mínimo, máximo) em px; o valor de cada pico é decidido no uso
@export var aberracao_px := Vector2.ZERO
## Segundos para a aberração voltar ao normal
@export var aberracao_volta := 0.0

@export_group("Partículas")
## Faísca do hit no Lorax 2.0: (quantidade, distância px)
@export var faisca_hit := Vector2.ZERO
## Poeira do pouso, POR LADO: (quantidade, distância px)
@export var poeira_pouso := Vector2.ZERO
## Poeira da folha acertando o bloco: (quantidade, distância px)
@export var poeira_bloco := Vector2.ZERO
## Folhinhas ao perder coração: (mínimo, máximo) de partículas
@export var folhinhas_quantidade := Vector2.ZERO
## Ki do hit no Lorax da fase 3: (quantidade, distância px)
@export var ki_hit := Vector2.ZERO
## Vida (s) do ki do hit (usa a cena da faísca, que vive menos)
@export var ki_hit_vida := 0.0

@export_group("Estrelas")
@export var estrelas_normal := 0.0
@export var estrelas_silencio := 0.0
@export var estrelas_fase1 := 0.0
@export var estrelas_fase2 := 0.0
@export var estrelas_derrota_fase2 := 0.0
## Derrota com raiva: alvo do ×0 → ×? "devagar" (a duração ainda não tem valor)
@export var estrelas_raiva_alvo := 0.0
## Despertar → aura: (de, até); dura o despertar
@export var estrelas_despertar := Vector2.ZERO
## Pico do pilar: (multiplicador, segundos)
@export var estrelas_pico := Vector2.ZERO
## Resto do pilar: (alvo, segundos), partindo do pico
@export var estrelas_resto_pilar := Vector2.ZERO
@export var estrelas_arena := 0.0
@export var estrelas_fase3a := 0.0
@export var estrelas_virada := 0.0
@export var estrelas_desespero := 0.0
@export var estrelas_tonto := 0.0
## Final ruim: segundos para todas apagarem, uma a uma
@export var estrelas_apagar := 0.0
## Música tensa da wave 10 entra: (alvo, segundos)
@export var estrelas_volta_wave10 := Vector2.ZERO

@export_group("Wave 10")
## Segundos entre as letras do letreiro FINAL WAVE
@export var wave10_letra_intervalo := 0.0
## Tremor de cada letra (px)
@export var wave10_letra_tremor_px := 0
@export var wave10_bordas_piscadas := 0
## Segundos aceso/apagado das bordas do alarme
@export var wave10_bordas_pisca := 0.0
@export var wave10_bordas_alfa := 0.0
@export var wave10_alarme_tremor := Vector2.ZERO
## Letreiro FINAL WAVE: segundos aceso/apagado enquanto o alarme toca (o mesmo ritmo das
## bordas do alarme, efeitos.md 4.1)
@export var wave10_letreiro_pisca := 0.0
## Letreiro FINAL WAVE: segundos do fade quando o alarme termina. VALOR DE TESTE: não está
## no efeitos.md (0,8 s = o fade do letreiro WAVE de sempre)
@export var wave10_letreiro_fade := 0.0

@export_group("Fase 1")
## Descida do Lorax 2.0
@export var descida_tremor_continuo := Vector2.ZERO
@export var pouso_tremor := Vector2.ZERO
## Escala do squash no pouso (x, y), voltando a (1, 1)
@export var pouso_squash := Vector2.ZERO
@export var pouso_squash_duracao := 0.0
## Nome do boss: segundos de fade-in
@export var nome_fade_in := 0.0
## Espaçamento das letras: (de, até) px
@export var nome_espacamento := Vector2.ZERO
## Segundos que o nome fica na tela
@export var nome_tempo := 0.0
@export var nome_fade_out := 0.0
## Flash branco do hit no corpo
@export var hit_flash := Vector2.ZERO
## Recuo do corpo ao levar hit (px)
@export var hit_recuo_px := 0
## Recuo: (segundos subindo, segundos voltando)
@export var hit_recuo_tempos := Vector2.ZERO
## Boss perdeu um coração (menos o último)
@export var coracao_boss_tremor := Vector2.ZERO
## Boss perdeu um coração (menos o último): hit-stop em segundos
@export var coracao_boss_hitstop := 0.0
## Coração da hud que quebra: escala (de, até)
@export var coracao_hud_escala := Vector2.ZERO
@export var coracao_hud_escala_duracao := 0.0
## Tremor do coração da hud (px)
@export var coracao_hud_tremor_px := 0
## Último coração pulsando: escala (de, até)
@export var ultimo_coracao_escala := Vector2.ZERO
## Segundos de cada pulso do último coração
@export var ultimo_coracao_periodo := 0.0
## Alfa máximo do brilho amarelo pulsando na carga
@export var carga_alfa_maximo := 0.0
## Soltar as folhas (quadro do evento)
@export var soltar_tremor := Vector2.ZERO
## Rastro da folha: largura (px)
@export var folha_rastro_px := 0
## Rastro da folha: alfa inicial (some até 0)
@export var folha_rastro_alfa := 0.0

@export_group("Fase 2")
## Carga das árvores (a duração é a da carga, ainda sem valor)
@export var f2_carga_tremor_continuo := Vector2.ZERO
## Olhos vermelhos: alfa do flash
@export var f2_olhos_alfa := 0.0
## Olhos vermelhos: segundos antes de soltar
@export var f2_olhos_antecedencia := 0.0
## Marcador no chão: segundos antes de a árvore cair
@export var f2_marcador_antecedencia := 0.0
@export var f2_arvore_tremor := Vector2.ZERO
## Segundos parado "respirando" depois de perder coração
@export var f2_respira := 0.0
## Último coração: alfa da tinta vermelha nas bordas
@export var f2_desespero_alfa := 0.0

@export_group("Trocas de fase")
@export var ultimo_hit_f1_hitstop := 0.0
@export var ultimo_hit_f1_camera_lenta := Vector2.ZERO
@export var ultimo_hit_f1_flash := Vector2.ZERO
@export var ultimo_hit_f1_tremor := Vector2.ZERO
## Duração da animação da transição 1→2 (PROVISÓRIA: a animação real é quem manda)
@export var transicao_duracao := 0.0
@export var transicao_zoom := Vector2.ZERO
@export var transicao_tremor_continuo := Vector2.ZERO
@export var transicao_tremor := Vector2.ZERO
@export var transicao_hitstop := 0.0
@export var transicao_flash := Vector2.ZERO
## Onda pequena da transição: raio (px); a força ainda não tem valor
@export var transicao_onda_raio := 0.0
@export var transicao_onda_duracao := 0.0
## Segundos para o zoom voltar a 1,0
@export var transicao_zoom_volta := 0.0
## Segundos do tom vermelho entrando no fundo (a intensidade ainda não tem valor)
@export var transicao_tom_duracao := 0.0
## Segundos entre um coração e outro reenchendo
@export var transicao_coracoes_intervalo := 0.0
@export var derrota_f2_hitstop := 0.0
@export var derrota_f2_camera_lenta := Vector2.ZERO
@export var derrota_f2_flash := Vector2.ZERO
@export var derrota_f2_tremor := Vector2.ZERO

@export_group("Transformação")
## Duração da "derrota com raiva" (PROVISÓRIA: na E4 a duração real da animação manda)
@export var raiva_duracao := 0.0
## Duração do despertar (PROVISÓRIA: na E4 a duração real da animação manda)
@export var despertar_duracao := 0.0
## Duração da aura (PROVISÓRIA: na E4 a duração real da animação manda)
@export var aura_duracao := 0.0
@export var raiva_tremor_continuo := Vector2.ZERO
## Escurecimento da tela: (de, até) em fração
@export var despertar_escuro := Vector2.ZERO
@export var despertar_zoom := Vector2.ZERO
@export var despertar_tremor_continuo := Vector2.ZERO
@export var aura_tremor_continuo := Vector2.ZERO
## Partículas de ki subindo por segundo
@export var aura_ki_por_segundo := 0.0
@export var pico_hitstop := 0.0
@export var pico_tremor := Vector2.ZERO
@export var pico_flash := Vector2.ZERO
@export var pico_onda := Vector3.ZERO
## Resto do pilar (a duração ainda não tem valor)
@export var resto_tremor_continuo := Vector2.ZERO
## Reparo (a duração ainda não tem valor)
@export var reparo_tremor_continuo := Vector2.ZERO
## Segundos para o zoom voltar a 1,0 no reparo
@export var reparo_zoom_volta := 0.0
@export var chapeu_tremor := Vector2.ZERO
@export var puxao_tremor_continuo := Vector2.ZERO
## Largura do fio de ki (px)
@export var puxao_fio_px := 0
@export var nave_chega_tremor := Vector2.ZERO
## Arena nascendo: (segundos ponto → linha, segundos linha → caixa)
@export var arena_etapas := Vector2.ZERO
@export var arena_tremor := Vector2.ZERO
## Escurecimento quando a arena nasce: (de, até) em fração
@export var arena_escuro := Vector2.ZERO
@export var arena_escuro_duracao := 0.0

@export_group("Fase 3")
## Segundos aceso/apagado do aviso
@export var aviso_pisca := 0.0
@export var raio_tremor := Vector2.ZERO
@export var cortina_tremor := Vector2.ZERO
## Carga do raio direto
@export var raio_direto_zoom := Vector2.ZERO
@export var raio_direto_tremor := Vector2.ZERO
@export var pancada_tremor := Vector2.ZERO
## Tremor da arena na pancada: (px, segundos)
@export var pancada_arena_tremor := Vector2.ZERO
@export var esfera_tremor := Vector2.ZERO
@export var esfera_flash := Vector2.ZERO
@export var afterimage_copias := 0
## Segundos entre uma cópia e outra
@export var afterimage_intervalo := 0.0
## Segundos que cada cópia leva para sumir
@export var afterimage_vida := 0.0
@export var afterimage_cor := Color()
@export var afterimage_alfa := 0.0
## Janela de ataque abrindo: piscadas da borda da arena
@export var janela_piscadas := 0
@export var janela_pisca := 0.0
## Hit no Lorax da fase 3: duração do flash (o alfa ainda não tem valor)
@export var hit_ui_flash_duracao := 0.0
@export var hit_ui_recuo_px := 0
@export var player_hit_tremor := Vector2.ZERO
@export var player_hit_hitstop := 0.0
## Segundos das bordas vermelhas no hit (o alfa ainda não tem valor)
@export var player_hit_bordas_duracao := 0.0
@export var virada_hitstop := 0.0
@export var virada_tremor := Vector2.ZERO
@export var virada_onda := Vector3.ZERO
## Desespero (a duração ainda não tem valor)
@export var desespero_tremor_continuo := Vector2.ZERO
## Câmera "respirando": (px, segundos do período)
@export var respirando := Vector2.ZERO

@export_group("Desfecho")
## Segundos entre as letras do FINISH HIM
@export var finish_letra_intervalo := 0.0
@export var finish_letra_tremor := Vector2.ZERO
## Escala de cada letra: (de, até)
@export var finish_letra_escala := Vector2.ZERO
@export var golpe_hitstop := 0.0
@export var golpe_zoom_punch := Vector2.ZERO
@export var golpe_flash := Vector2.ZERO
@export var golpe_tremor := Vector2.ZERO
@export var golpe_camera_lenta := Vector2.ZERO
## Final bom: escuro (de, até) em fração
@export var poupar_escuro := Vector2.ZERO
@export var poupar_escuro_duracao := 0.0
