# LAB DE EFEITOS (opção do cheat): dispara cada efeito da tabela do efeitos.md com os
# valores do efeitos_boss.tres, para sentir e afinar sem jogar a luta.
# Teclas e layout: PainelLab. Partes sem número aparecem como "SEM VALOR" e partes que
# dependem de uma peça da luta (squash, nome do boss, arena...) aparecem com a etapa em que entram.
extends PainelLab

const IDLE_LORAX = preload("res://meus sprites/lorax boss battle/fase1/fase1 idle.png")
const FAISCA = preload("res://cenas/efeitos/faisca.tscn")
const POEIRA = preload("res://cenas/efeitos/poeira.tscn")
const FOLHINHAS = preload("res://cenas/efeitos/folhinhas.tscn")
const KI_SUBINDO = preload("res://cenas/efeitos/ki_subindo.tscn")
const Particula = preload("res://scripts/efeitos/particula.gd")

# O boneco fica onde o Lorax luta: altura e meio do vai e vem da fase 1
const DADOS_FASE1 = preload("res://recursos/boss/classica1.tres")

# Meia altura do quadro de 32 px do boneco
const MEIO_BONECO = 16
# Pés do boneco: linha 28 do quadro de 32 px centrado = 12 px abaixo do centro
const PES_BONECO = 12
# Só para mostrar o afterimage: o boneco desliza esta distância e volta
const DEMO_ESQUIVA_PX = 40
# Poeira da folha no bloco: à esquerda do boneco, na altura dos pés (fora do painel e
# do lado oposto ao do teleporte)
const LADO_BLOCO_PX = 40
# Letras de "FINISH HIM" (cada uma treme)
const LETRAS_FINISH_HIM = 9
# Teste da regra de segurança: 4 flashes com este intervalo (s)
const TESTE_FLASH_INTERVALO = 0.1

var camera
var tela
var estrelas
var e: EfeitosDados
var mundo
var boneco: Node2D
var flash_boneco: FlashSprite
var rastro: Afterimage
var ki: Node = null
var tween_boneco: Tween = null

var letterbox_ligado = false
# O boneco fica no alto (como na luta); a lista começa embaixo dele
var posicao_boneco = Vector2.ZERO

# Recebe da main quem ela vai controlar e monta o boneco, o texto e as páginas
func preparar(cam, efeitos_tela, campo_estrelas, dados, pai_do_boneco):
	camera = cam
	tela = efeitos_tela
	estrelas = campo_estrelas
	e = dados
	mundo = pai_do_boneco
	dica = "APERTE 1-0 PARA DISPARAR UM EFEITO"
	posicao_boneco = Vector2((DADOS_FASE1.limite_esq + DADOS_FASE1.limite_dir) / 2.0, DADOS_FASE1.altura)
	iniciar()
	criar_boneco()

# Páginas da tabela 4 do efeitos.md
func montar_paginas():
	return [
		pagina_estrelas(), pagina_estrelas_2(), pagina_wave10(), pagina_fase1(),
		pagina_fase2_trocas(), pagina_transformacao(), pagina_fase3(), pagina_fase3_2(),
		pagina_desfecho(), pagina_ferramentas(),
	]

# Boneco parado do Lorax 2.0 no mundo, com flash e afterimage (o afterimage vem antes
# do sprite para as cópias ficarem atrás)
func criar_boneco():
	boneco = Node2D.new()
	boneco.position = posicao_boneco
	rastro = Afterimage.new()
	rastro.sprite = NodePath("../Sprite2D")
	boneco.add_child(rastro)
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = IDLE_LORAX
	sprite.hframes = 4
	boneco.add_child(sprite)
	flash_boneco = FlashSprite.new()
	sprite.add_child(flash_boneco)
	mundo.add_child(boneco)

# A lista começa logo abaixo do boneco
func topo_da_lista():
	return posicao_boneco.y + MEIO_BONECO + FOLGA

# Efeitos que ficam ligados até o R (zoom sem volta, tremor contínuo, estrelas, barras...)
func estado_ligado():
	var itens = []
	if not camera.zoom.is_equal_approx(Vector2.ONE):
		itens.append("ZOOM " + n(camera.zoom.x))
	if camera.forca_continua > 0:
		itens.append("TREMOR CONTINUO")
	if not is_equal_approx(estrelas.velocidade_mult, 1.0):
		itens.append("ESTRELAS x" + n(estrelas.velocidade_mult))
	if estrelas.tem_apagadas():
		itens.append("ESTRELAS APAGADAS")
	if estrelas.cor != Color.WHITE:
		itens.append("ESTRELAS COLORIDAS")
	if tela.letterbox_visivel():
		itens.append("LETTERBOX")
	if tela.bordas_visiveis():
		itens.append("BORDAS")
	if ki != null and is_instance_valid(ki) and ki.emitting:
		itens.append("KI")
	if itens.is_empty():
		return "LIGADO: NADA"
	return "LIGADO: " + ", ".join(itens)

# Tudo volta ao normal na hora: tempo, câmera, tela, estrelas e boneco
func ao_resetar():
	TempoJogo.limpar()
	camera.restaurar()
	tela.limpar()
	estrelas.restaurar()
	flash_boneco.parar()
	rastro.parar()
	for particula in get_tree().get_nodes_in_group(Particula.GRUPO):
		particula.queue_free()
	if tween_boneco != null:
		tween_boneco.kill()
	boneco.position = posicao_boneco
	if ki != null:
		ki.queue_free()
		ki = null
	letterbox_ligado = false

# ---------- ferramentas usadas pelas linhas ----------

# Tremor no formato do .tres: Vector2(força, segundos)
func tremer(valor):
	camera.tremer(valor.x, valor.y)

# Flash de tela no formato do .tres: Vector2(alfa, segundos); avisa se a regra barrou
func piscar(cor, valor):
	if not tela.flash_tela(cor, valor.x, valor.y):
		aviso = "FLASH BARRADO: LIMITE DE %d POR SEGUNDO" % e.flashes_tela_por_segundo
		mostrar()

# Hit-stop e, só depois dele, a câmera lenta (Vector2(escala, segundos))
func congelar_e_desacelerar(hitstop, camera_lenta):
	TempoJogo.congelar(hitstop)
	if await esperar(hitstop):
		TempoJogo.camera_lenta(camera_lenta.x, camera_lenta.y)

# Solta uma partícula no mundo; 'ajuste' mexe na partícula antes de ela entrar na cena
func soltar(cena, posicao, quantidade, distancia = 0.0, ajuste = Callable()):
	var particula = cena.instantiate()
	particula.position = posicao
	if ajuste.is_valid():
		ajuste.call(particula)
	particula.configurar(quantidade, distancia)
	mundo.add_child(particula)

# Gradiente de cores sorteadas (uma por partícula) a partir de uma lista
func gradiente(cores):
	var g = Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var posicoes = PackedFloat32Array()
	for i in range(cores.size()):
		posicoes.append(float(i) / cores.size())
	g.offsets = posicoes
	g.colors = cores
	return g

# "T(força;s)"
func txt_t(valor):
	return "T(%s;%s)" % [n(valor.x), n(valor.y)]

# "TC(de->até)"
func txt_tc(valor):
	return "TC(%s->%s)" % [n(valor.x), n(valor.y)]

# "F alfa/segundos"
func txt_f(valor):
	return "F %s/%s S" % [n(valor.x), n(valor.y)]

# "CL(escala;s)"
func txt_cl(valor):
	return "CL(%s;%s)" % [n(valor.x), n(valor.y)]

# "Z(fator;s)"
func txt_z(valor):
	return "Z(%s;%s)" % [n(valor.x), n(valor.y)]

# ---------- páginas (efeitos.md, tabela 4) ----------

# 4.0 Estrelas: velocidade e cor
func pagina_estrelas():
	return nova_pagina("ESTRELAS", [
		linha("JOGO NORMAL", ["x" + n(e.estrelas_normal)],
			func(): estrelas.mudar_velocidade(e.estrelas_normal)),
		linha("SILENCIO", ["x" + n(e.estrelas_silencio)],
			func(): estrelas.mudar_velocidade(e.estrelas_silencio)),
		linha("FASE 1", ["x" + n(e.estrelas_fase1)],
			func(): estrelas.mudar_velocidade(e.estrelas_fase1)),
		linha("FASE 2", ["x" + n(e.estrelas_fase2), "COR PUXA PARA VERMELHO"], estrelas_fase2),
		linha("DERROTA DA FASE 2", ["x" + n(e.estrelas_derrota_fase2) + " (CONGELAM)"],
			func(): estrelas.mudar_velocidade(e.estrelas_derrota_fase2)),
		linha("DESPERTAR -> AURA", ["x%s -> x%s EM %s S (PROVISORIO)" % [n(e.estrelas_despertar.x), n(e.estrelas_despertar.y), n(e.despertar_duracao)], "BRILHO SOBE: SEM VALOR"], estrelas_despertar),
		linha("PICO DO PILAR", ["x%s POR %s S, DEPOIS x%s EM %s S" % [n(e.estrelas_pico.x), n(e.estrelas_pico.y), n(e.estrelas_resto_pilar.x), n(e.estrelas_resto_pilar.y)], "RISCOS: SEM VALOR", "EMPURRAR: SEM VALOR"], estrelas_pilar),
		linha("ARENA / FASE 3A", ["x" + n(e.estrelas_arena), "BRILHO E COR LAVANDA: SEM VALOR"],
			func(): estrelas.mudar_velocidade(e.estrelas_arena)),
		linha("VIRADA 3A->3B", ["x" + n(e.estrelas_virada), "EMPURRAO: SEM VALOR"],
			func(): estrelas.mudar_velocidade(e.estrelas_virada)),
		linha("DESESPERO", ["x" + n(e.estrelas_desespero), "RISCOS: SEM VALOR"],
			func(): estrelas.mudar_velocidade(e.estrelas_desespero)),
	])

# 4.0 Estrelas: apagar, acender e o que ainda não tem número
func pagina_estrelas_2():
	return nova_pagina("ESTRELAS 2", [
		linha("TONTO / FINISH HIM", ["x" + n(e.estrelas_tonto)],
			func(): estrelas.mudar_velocidade(e.estrelas_tonto)),
		linha("FINAL RUIM: APAGAM", ["UMA A UMA EM %s S, PARADAS" % n(e.estrelas_apagar)], estrelas_apagar),
		linha("DERROTA COM RAIVA", ["x0 -> x%s DEVAGAR: DURACAO SEM VALOR" % n(e.estrelas_raiva_alvo)]),
		linha("REPARO", ["x3 -> x1: DURACAO SEM VALOR"]),
		linha("POUPAR", ["VOLTAM A x1: DURACAO SEM VALOR", "ESTRELAS NOVAS: QUANTIDADE SEM VALOR", "CONSTELACAO: NA F7"]),
		linha("PUXAO", ["RISCOS VERTICAIS: SEM VALOR"]),
		linha("ANTES DE ATAQUE GRANDE", ["SUGAR E REPELIR: SEM VALOR"]),
	])

# 4.1 Wave 10 (o resto é som e letreiro: B1, B3 e F1)
func pagina_wave10():
	return nova_pagina("WAVE 10", [
		linha("SILENCIO", ["ESTRELAS x" + n(e.estrelas_silencio), "MUSICA SOME: NA F1"],
			func(): estrelas.mudar_velocidade(e.estrelas_silencio)),
		linha("ALARME FINAL WAVE", ["BORDAS %dx %s S ALFA %s" % [e.wave10_bordas_piscadas, n(e.wave10_bordas_pisca), n(e.wave10_bordas_alfa)], txt_t(e.wave10_alarme_tremor), "LETREIRO (%s S/LETRA, %d PX): NA F1" % [n(e.wave10_letra_intervalo), e.wave10_letra_tremor_px]], wave10_alarme),
		linha("MUSICA TENSA ENTRA", ["ESTRELAS x%s EM %s S" % [n(e.estrelas_volta_wave10.x), n(e.estrelas_volta_wave10.y)], "CROSSFADE: NA B1"],
			func(): estrelas.mudar_velocidade(e.estrelas_volta_wave10.x, e.estrelas_volta_wave10.y)),
	])

# 4.2 Fase 1
func pagina_fase1():
	return nova_pagina("FASE 1", [
		linha("DESCIDA", [txt_tc(e.descida_tremor_continuo) + " (FICA ATE O R)"],
			func(): camera.tremer_continuo(e.descida_tremor_continuo.x, e.descida_tremor_continuo.y, 0.0)),
		linha("POUSO", [txt_t(e.pouso_tremor), "POEIRA %s DE CADA LADO, %s PX" % [n(e.poeira_pouso.x), n(e.poeira_pouso.y)], "SQUASH (%s;%s) %s S: NA F1" % [n(e.pouso_squash.x), n(e.pouso_squash.y), n(e.pouso_squash_duracao)]], pouso),
		linha("NOME DO BOSS", ["FADE %s S, LETRAS %s->%s PX, FICA %s S, SAI %s S: NA F1" % [n(e.nome_fade_in), n(e.nome_espacamento.x), n(e.nome_espacamento.y), n(e.nome_tempo), n(e.nome_fade_out)]]),
		linha("HIT COMUM", ["FLASH NO CORPO " + txt_f(e.hit_flash), "FAISCA %s, %s PX" % [n(e.faisca_hit.x), n(e.faisca_hit.y)], "RECUO %d PX: NA F1" % e.hit_recuo_px], hit_comum),
		linha("PERDEU UM CORACAO", [txt_t(e.coracao_boss_tremor) + " + HS " + n(e.coracao_boss_hitstop), "FOLHINHAS %s-%s" % [n(e.folhinhas_quantidade.x), n(e.folhinhas_quantidade.y)], "CORACAO DA HUD: NA F1 (FLASH SEM VALOR)"], perdeu_coracao),
		linha("ULTIMO CORACAO", ["PULSA %s->%s A CADA %s S: NA F1" % [n(e.ultimo_coracao_escala.x), n(e.ultimo_coracao_escala.y), n(e.ultimo_coracao_periodo)]]),
		linha("CARGA DO ATAQUE", ["AMARELO 0->%s: PERIODO SEM VALOR" % n(e.carga_alfa_maximo)]),
		linha("SOLTAR FOLHAS", [txt_t(e.soltar_tremor)], func(): tremer(e.soltar_tremor)),
		linha("FOLHA ACERTA BLOCO", ["POEIRA %s, %s PX" % [n(e.poeira_bloco.x), n(e.poeira_bloco.y)], "RASTRO %d PX ALFA %s: NA F1" % [e.folha_rastro_px, n(e.folha_rastro_alfa)]], folha_no_bloco),
	])

# 4.2 Fase 2 e as trocas de fase
func pagina_fase2_trocas():
	return nova_pagina("FASE 2 E TROCAS", [
		linha("F2: CARGA DAS ARVORES", [txt_tc(e.f2_carga_tremor_continuo) + ": DURACAO SEM VALOR", "OLHOS ALFA %s: DURACAO SEM VALOR" % n(e.f2_olhos_alfa), "MARCADOR %s S ANTES: NA F2" % n(e.f2_marcador_antecedencia)]),
		linha("F2: ARVORE EXPLODE", [txt_t(e.f2_arvore_tremor)], func(): tremer(e.f2_arvore_tremor)),
		linha("F2: RESPIRA", ["%s S PARADO: NA F2" % n(e.f2_respira)]),
		linha("F2: DESESPERO", ["BORDAS VERMELHAS %s (FICA ATE O R)" % n(e.f2_desespero_alfa)],
			func(): tela.bordas(e.cor_dano, e.f2_desespero_alfa)),
		linha("ULTIMO HIT DA FASE 1", ["HS %s -> %s" % [n(e.ultimo_hit_f1_hitstop), txt_cl(e.ultimo_hit_f1_camera_lenta)], "BRANCO " + txt_f(e.ultimo_hit_f1_flash), txt_t(e.ultimo_hit_f1_tremor), "LIMPEZA DE PROJETEIS: NA F2"], ultimo_hit_fase1),
		linha("TRANSICAO 1->2", [txt_z(e.transicao_zoom) + " NO LORAX", txt_tc(e.transicao_tremor_continuo) + " EM %s S (PROVISORIO)" % n(e.transicao_duracao), "PICO: %s + HS %s + VERMELHO %s" % [txt_t(e.transicao_tremor), n(e.transicao_hitstop), txt_f(e.transicao_flash)], "Z VOLTA %s S" % n(e.transicao_zoom_volta), "ONDA PEQUENA E TOM VERMELHO: SEM VALOR", "CORACOES %s S CADA: NA F2" % n(e.transicao_coracoes_intervalo)], transicao),
		linha("DERROTA DA FASE 2", ["HS %s -> %s" % [n(e.derrota_f2_hitstop), txt_cl(e.derrota_f2_camera_lenta)], "BRANCO " + txt_f(e.derrota_f2_flash), txt_t(e.derrota_f2_tremor)], derrota_fase2),
	])

# 4.3 Transformação (durações dos momentos provisórias até a B4)
func pagina_transformacao():
	return nova_pagina("TRANSFORMACAO", [
		linha("DERROTA COM RAIVA", ["LETTERBOX %d PX %s S" % [e.letterbox_barras, n(e.letterbox_duracao)], txt_tc(e.raiva_tremor_continuo) + " EM %s S (PROVISORIO)" % n(e.raiva_duracao)], raiva),
		linha("DESPERTAR", [txt_z(e.despertar_zoom) + " NO LORAX", txt_tc(e.despertar_tremor_continuo) + " EM %s S (PROVISORIO)" % n(e.despertar_duracao), "ESTRELAS x%s->x%s" % [n(e.estrelas_despertar.x), n(e.estrelas_despertar.y)], "ESCURO %s->%s: NA F3" % [n(e.despertar_escuro.x), n(e.despertar_escuro.y)], "LOW-PASS: NA B1"], despertar),
		linha("AURA", [txt_tc(e.aura_tremor_continuo) + " EM %s S (PROVISORIO)" % n(e.aura_duracao), "KI SUBINDO %s/S" % n(e.aura_ki_por_segundo)], aura),
		linha("PICO DO PILAR", ["HS %s + %s + BRANCO %s" % [n(e.pico_hitstop), txt_t(e.pico_tremor), txt_f(e.pico_flash)], "ONDA %s PX %s S FORCA %s" % [n(e.pico_onda.x), n(e.pico_onda.y), n(e.pico_onda.z)], "ESTRELAS x%s" % n(e.estrelas_pico.x), "ABERRACAO DO PICO: SEM VALOR", "BASES SOMEM: NA F3"], pico_do_pilar),
		linha("RESTO DO PILAR", [txt_tc(e.resto_tremor_continuo) + ": DURACAO SEM VALOR", "ESTRELAS x%s EM %s S" % [n(e.estrelas_resto_pilar.x), n(e.estrelas_resto_pilar.y)]],
			func(): estrelas.mudar_velocidade(e.estrelas_resto_pilar.x, e.estrelas_resto_pilar.y)),
		linha("REPARO", [txt_tc(e.reparo_tremor_continuo) + ": DURACAO SEM VALOR", "Z VOLTA A 1 EM %s S" % n(e.reparo_zoom_volta)],
			func(): camera.zoom_para(1.0, e.reparo_zoom_volta)),
		linha("CHAPEU JOGADO", [txt_t(e.chapeu_tremor)], func(): tremer(e.chapeu_tremor)),
		linha("PUXAO", [txt_tc(e.puxao_tremor_continuo) + " (FICA ATE A NAVE CHEGAR)", "FIO DE KI %d PX: NA F3" % e.puxao_fio_px, "RISCOS: SEM VALOR"],
			func(): camera.tremer_continuo(e.puxao_tremor_continuo.x, e.puxao_tremor_continuo.y, 0.0)),
		linha("NAVE CHEGA", [txt_t(e.nave_chega_tremor) + " (PARA O TC)"], nave_chega),
		linha("ARENA NASCE", [txt_t(e.arena_tremor), "LETTERBOX SAI %s S" % n(e.letterbox_duracao), "ESTRELAS x" + n(e.estrelas_arena), "PONTO/LINHA/CAIXA %s+%s S: NA F3" % [n(e.arena_etapas.x), n(e.arena_etapas.y)], "ESCURO %s->%s EM %s S: NA F3" % [n(e.arena_escuro.x), n(e.arena_escuro.y), n(e.arena_escuro_duracao)], "FLASH NA BORDA: SEM VALOR"], arena_nasce),
	])

# 4.4 Fase 3
func pagina_fase3():
	return nova_pagina("FASE 3", [
		linha("AVISO", ["PISCA %s S, ALFA %s: NA B5" % [n(e.aviso_pisca), n(e.cor_aviso.a)]]),
		linha("RAIO COMUM", [txt_t(e.raio_tremor), "MINIMO %s S ENTRE TREMORES: NA B5" % n(e.intervalo_tremor_repetido)], func(): tremer(e.raio_tremor)),
		linha("CORTINA TODOS JUNTOS", [txt_t(e.cortina_tremor)], func(): tremer(e.cortina_tremor)),
		linha("RAIO DIRETO", ["CARGA " + txt_z(e.raio_direto_zoom), "DISPARO " + txt_t(e.raio_direto_tremor), "Z VOLTA: SEM VALOR (R VOLTA)"], raio_direto),
		linha("PANCADA", [txt_t(e.pancada_tremor), "ARENA TREME %s PX %s S: NA B5" % [n(e.pancada_arena_tremor.x), n(e.pancada_arena_tremor.y)]], func(): tremer(e.pancada_tremor)),
		linha("ESFERA ESTOURA", [txt_t(e.esfera_tremor), "BRANCO " + txt_f(e.esfera_flash)], esfera),
		linha("TELEPORTE / ESQUIVA", ["AFTERIMAGE %d COPIAS, %s S, VIDA %s S, ALFA %s" % [e.afterimage_copias, n(e.afterimage_intervalo), n(e.afterimage_vida), n(e.afterimage_alfa)]], teleporte),
		linha("HIT NO LORAX UI", ["KI %s, %s PX, VIDA %s S" % [n(e.ki_hit.x), n(e.ki_hit.y), n(e.ki_hit_vida)], "FLASH %s S: ALFA SEM VALOR" % n(e.hit_ui_flash_duracao), "RECUO %d PX: NA F4" % e.hit_ui_recuo_px], hit_lorax_ui),
		linha("PLAYER LEVA HIT", [txt_t(e.player_hit_tremor) + " + HS " + n(e.player_hit_hitstop), "BORDAS %s S: ALFA SEM VALOR" % n(e.player_hit_bordas_duracao)], player_leva_hit),
		linha("VIRADA 3A->3B", ["HS %s + %s" % [n(e.virada_hitstop), txt_t(e.virada_tremor)], "ONDA %s PX %s S FORCA %s" % [n(e.virada_onda.x), n(e.virada_onda.y), n(e.virada_onda.z)], "ESTRELAS x" + n(e.estrelas_virada), "ARENA ENCOLHE: NA F5"], virada),
	])

# 4.4 Fase 3: o que depende da arena
func pagina_fase3_2():
	return nova_pagina("FASE 3 (2)", [
		linha("DESESPERO", [txt_tc(e.desespero_tremor_continuo) + ": DURACAO SEM VALOR", "FAISCAS NA MOLDURA: NA F5"]),
		linha("JANELA DE ATAQUE", ["BORDA DA ARENA PISCA %dx %s S: NA B5" % [e.janela_piscadas, n(e.janela_pisca)]]),
		linha("CAMERA RESPIRANDO", ["%s PX, PERIODO %s S: NA F4" % [n(e.respirando.x), n(e.respirando.y)]]),
	])

# 4.5 Desfecho
func pagina_desfecho():
	return nova_pagina("DESFECHO", [
		linha("FINISH HIM", ["%d LETRAS, %s S CADA, %s" % [LETRAS_FINISH_HIM, n(e.finish_letra_intervalo), txt_t(e.finish_letra_tremor)], "LETRAS E ESCALA %s->%s: NA F6" % [n(e.finish_letra_escala.x), n(e.finish_letra_escala.y)]], finish_him),
		linha("GOLPE FINAL", ["HS %s -> %s" % [n(e.golpe_hitstop), txt_cl(e.golpe_camera_lenta)], "ZOOM PUNCH " + txt_z(e.golpe_zoom_punch), "BRANCO %s + %s" % [txt_f(e.golpe_flash), txt_t(e.golpe_tremor)], "MUSICA CORTADA: NA B1"], golpe_final),
		linha("POUPAR", ["ESCURO %s->%s EM %s S: NA F7" % [n(e.poupar_escuro.x), n(e.poupar_escuro.y), n(e.poupar_escuro_duracao)]]),
	])

# Ferramentas soltas, para testar cada uma
func pagina_ferramentas():
	return nova_pagina("FERRAMENTAS", [
		linha("ABERRACAO MINIMA", ["%s PX, VOLTA EM %s S" % [n(e.aberracao_px.x), n(e.aberracao_volta)]],
			func(): tela.aberracao(e.aberracao_px.x, e.aberracao_volta)),
		linha("ABERRACAO MAXIMA", ["%s PX, VOLTA EM %s S" % [n(e.aberracao_px.y), n(e.aberracao_volta)]],
			func(): tela.aberracao(e.aberracao_px.y, e.aberracao_volta)),
		linha("LETTERBOX LIGA/DESLIGA", ["%d PX EM %s S" % [e.letterbox_barras, n(e.letterbox_duracao)]], alternar_letterbox),
		linha("BORDAS LIGA/DESLIGA", ["DEGRADE %d PX, ALARME PISCANDO SEM PARAR" % e.bordas_largura], alternar_bordas),
		linha("4 FLASHES SEGUIDOS", ["TESTA A REGRA: NO MAXIMO %d POR SEGUNDO" % e.flashes_tela_por_segundo], quatro_flashes),
	])

# ---------- ações com mais de um passo ----------

# Fase 2: velocidade e tinta vermelha
func estrelas_fase2():
	estrelas.mudar_velocidade(e.estrelas_fase2)
	estrelas.mudar_cor(e.cor_estrelas_fase2)

# Despertar → aura: começa devagar e acelera ao longo do despertar
func estrelas_despertar():
	estrelas.mudar_velocidade(e.estrelas_despertar.x)
	estrelas.mudar_velocidade(e.estrelas_despertar.y, e.despertar_duracao)

# Pico do pilar: ×6 por um instante, depois cai para ×3
func estrelas_pilar():
	estrelas.mudar_velocidade(e.estrelas_pico.x)
	if await esperar(e.estrelas_pico.y):
		estrelas.mudar_velocidade(e.estrelas_resto_pilar.x, e.estrelas_resto_pilar.y)

# Final ruim: congelam e apagam uma a uma
func estrelas_apagar():
	estrelas.mudar_velocidade(e.estrelas_tonto)
	estrelas.apagar_uma_a_uma(e.estrelas_apagar)

# Alarme da wave 10: bordas vermelhas piscando + tremor do primeiro toque
func wave10_alarme():
	tela.bordas(e.cor_dano, e.wave10_bordas_alfa, e.wave10_bordas_pisca, e.wave10_bordas_piscadas)
	tremer(e.wave10_alarme_tremor)

# Pouso: tremor e poeira saindo dos dois lados dos pés
func pouso():
	tremer(e.pouso_tremor)
	var pes = boneco.position + Vector2(0, PES_BONECO)
	for lado in [Vector2.LEFT, Vector2.RIGHT]:
		soltar(POEIRA, pes, e.poeira_pouso.x, e.poeira_pouso.y, func(p): p.direction = lado)

# Hit comum: flash branco no corpo e faísca onde o tiro bate (embaixo do corpo)
func hit_comum():
	flash_boneco.flash(e.cor_branco, e.hit_flash.x, e.hit_flash.y)
	soltar(FAISCA, boneco.position + Vector2(0, PES_BONECO), e.faisca_hit.x, e.faisca_hit.y)

# Perdeu um coração: tremor, hit-stop e folhinhas do pelo
func perdeu_coracao():
	tremer(e.coracao_boss_tremor)
	TempoJogo.congelar(e.coracao_boss_hitstop)
	var quantidade = randi_range(int(e.folhinhas_quantidade.x), int(e.folhinhas_quantidade.y))
	soltar(FOLHINHAS, boneco.position, quantidade)

# Folha acertando o bloco: poeira subindo ao lado do boneco (onde dá para ver)
func folha_no_bloco():
	var ponto = posicao_boneco + Vector2(-LADO_BLOCO_PX, PES_BONECO)
	soltar(POEIRA, ponto, e.poeira_bloco.x, e.poeira_bloco.y, poeira_para_cima)

# Poeira em meio círculo para cima (a cena sai, por padrão, para um lado só)
func poeira_para_cima(particula):
	particula.direction = Vector2.UP
	particula.spread = 90.0

# Último hit da fase 1: hit-stop → câmera lenta, flash branco e tremor forte
func ultimo_hit_fase1():
	piscar(e.cor_branco, e.ultimo_hit_f1_flash)
	tremer(e.ultimo_hit_f1_tremor)
	congelar_e_desacelerar(e.ultimo_hit_f1_hitstop, e.ultimo_hit_f1_camera_lenta)

# Transição 1→2: zoom no Lorax e tremor subindo durante a animação; no fim, o pico
func transicao():
	camera.zoom_para(e.transicao_zoom.x, e.transicao_zoom.y, boneco.global_position)
	camera.tremer_continuo(e.transicao_tremor_continuo.x, e.transicao_tremor_continuo.y, e.transicao_duracao)
	if not await esperar(e.transicao_duracao):
		return
	camera.parar_tremor_continuo()
	tremer(e.transicao_tremor)
	TempoJogo.congelar(e.transicao_hitstop)
	piscar(e.cor_raiva, e.transicao_flash)
	camera.zoom_para(1.0, e.transicao_zoom_volta)

# Derrota da fase 2: hit-stop → câmera lenta, flash branco e tremor brutal
func derrota_fase2():
	piscar(e.cor_branco, e.derrota_f2_flash)
	tremer(e.derrota_f2_tremor)
	congelar_e_desacelerar(e.derrota_f2_hitstop, e.derrota_f2_camera_lenta)

# Derrota com raiva: entram as barras e o tremor começa a subir
func raiva():
	tela.letterbox(true, e.letterbox_duracao)
	letterbox_ligado = true
	camera.tremer_continuo(e.raiva_tremor_continuo.x, e.raiva_tremor_continuo.y, e.raiva_duracao)

# Despertar: zoom lento no Lorax, tremor subindo e estrelas acelerando
func despertar():
	camera.zoom_para(e.despertar_zoom.x, e.despertar_zoom.y, boneco.global_position)
	camera.tremer_continuo(e.despertar_tremor_continuo.x, e.despertar_tremor_continuo.y, e.despertar_duracao)
	estrelas_despertar()

# Aura: tremor subindo e ki saindo do corpo enquanto ela dura
func aura():
	camera.tremer_continuo(e.aura_tremor_continuo.x, e.aura_tremor_continuo.y, e.aura_duracao)
	if ki != null:
		ki.queue_free()
	ki = KI_SUBINDO.instantiate()
	ki.definir_taxa(e.aura_ki_por_segundo)
	boneco.add_child(ki)
	var meu_ki = ki
	var continua = await esperar(e.aura_duracao)
	if continua and is_instance_valid(meu_ki):
		meu_ki.emitting = false

# Pico do pilar: hit-stop, tremor brutal, flash, onda de choque e estrelas disparando
func pico_do_pilar():
	TempoJogo.congelar(e.pico_hitstop)
	tremer(e.pico_tremor)
	piscar(e.cor_branco, e.pico_flash)
	tela.onda_choque(boneco.global_position, e.pico_onda.x, e.pico_onda.y, e.pico_onda.z)
	estrelas_pilar()

# Nave chega no fim do puxão: acaba o tremor contínuo e vem uma batida
func nave_chega():
	camera.parar_tremor_continuo()
	tremer(e.nave_chega_tremor)

# Arena nasce: batida, as barras saem e as estrelas desaceleram
func arena_nasce():
	tremer(e.arena_tremor)
	tela.letterbox(false, e.letterbox_duracao)
	letterbox_ligado = false
	estrelas.mudar_velocidade(e.estrelas_arena)

# Raio direto: zoom de carga e, quando ele chega, o disparo
func raio_direto():
	camera.zoom_para(e.raio_direto_zoom.x, e.raio_direto_zoom.y, boneco.global_position)
	if await esperar(e.raio_direto_zoom.y):
		tremer(e.raio_direto_tremor)

# Esfera estoura: tremor forte e flash branco
func esfera():
	tremer(e.esfera_tremor)
	piscar(e.cor_branco, e.esfera_flash)

# Teleporte: o boneco desliza enquanto solta as cópias e depois volta
func teleporte():
	rastro.soltar(e.afterimage_copias, e.afterimage_intervalo, e.afterimage_vida, e.afterimage_cor, e.afterimage_alfa)
	if tween_boneco != null:
		tween_boneco.kill()
	var ida = e.afterimage_copias * e.afterimage_intervalo
	tween_boneco = boneco.create_tween().set_ignore_time_scale()
	tween_boneco.tween_property(boneco, "position:x", posicao_boneco.x + DEMO_ESQUIVA_PX, ida)
	tween_boneco.tween_interval(e.afterimage_vida)
	tween_boneco.tween_property(boneco, "position", posicao_boneco, ida)

# Hit no Lorax da fase 3: ki saindo do ponto do tiro
func hit_lorax_ui():
	soltar(FAISCA, boneco.position + Vector2(0, PES_BONECO), e.ki_hit.x, e.ki_hit.y, faisca_de_ki)

# A faísca vira ki: vida do ki e as cores do ki sorteadas por partícula
func faisca_de_ki(particula):
	particula.lifetime = e.ki_hit_vida
	particula.color_initial_ramp = gradiente(e.cores_ki)

# Player leva hit na arena: tremor e hit-stop
func player_leva_hit():
	tremer(e.player_hit_tremor)
	TempoJogo.congelar(e.player_hit_hitstop)

# Virada 3A→3B: hit-stop, tremor brutal, onda de choque e estrelas aceleram
func virada():
	TempoJogo.congelar(e.virada_hitstop)
	tremer(e.virada_tremor)
	tela.onda_choque(boneco.global_position, e.virada_onda.x, e.virada_onda.y, e.virada_onda.z)
	estrelas.mudar_velocidade(e.estrelas_virada)

# FINISH HIM: um tremorzinho por letra
func finish_him():
	for i in range(LETRAS_FINISH_HIM):
		tremer(e.finish_letra_tremor)
		if not await esperar(e.finish_letra_intervalo):
			return

# Golpe final: zoom punch, flash, tremor máximo e hit-stop → câmera lenta
func golpe_final():
	camera.zoom_punch(e.golpe_zoom_punch.x, e.golpe_zoom_punch.y)
	piscar(e.cor_branco, e.golpe_flash)
	tremer(e.golpe_tremor)
	congelar_e_desacelerar(e.golpe_hitstop, e.golpe_camera_lenta)

# Liga/desliga as barras de cinema
func alternar_letterbox():
	letterbox_ligado = not letterbox_ligado
	tela.letterbox(letterbox_ligado, e.letterbox_duracao)

# Liga/desliga as bordas do alarme, piscando sem parar
func alternar_bordas():
	if tela.bordas_visiveis():
		tela.bordas(e.cor_dano, 0.0)
	else:
		tela.bordas(e.cor_dano, e.wave10_bordas_alfa, e.wave10_bordas_pisca)

# Quatro flashes em menos de 1 s: o quarto tem que ser barrado
func quatro_flashes():
	for i in range(4):
		piscar(e.cor_branco, e.esfera_flash)
		if not await esperar(TESTE_FLASH_INTERVALO):
			return
