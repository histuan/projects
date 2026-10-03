# Preferências do jogador (autoload "Configuracoes"), salvas em user://configuracoes.cfg.
# Os volumes só ficam guardados aqui; quem os aplica nos buses de áudio é a E3c.
extends Node

const ARQUIVO = "user://configuracoes.cfg"

# Tremores e flashes mais fracos (câmera lenta e hit-stop continuam iguais)
var reduzir_efeitos = false
# Volumes de 0 a 1 (1 = sem mudança)
var volume_geral = 1.0
var volume_musica = 1.0
var volume_efeitos = 1.0
var volume_voz = 1.0

# Lê o arquivo ao abrir o jogo
func _ready():
	carregar()

# Lê as preferências; sem arquivo, cria um com os valores padrão
func carregar():
	var cfg = ConfigFile.new()
	if cfg.load(ARQUIVO) != OK:
		salvar()
		return
	reduzir_efeitos = cfg.get_value("efeitos", "reduzir_efeitos", reduzir_efeitos)
	volume_geral = cfg.get_value("volumes", "geral", volume_geral)
	volume_musica = cfg.get_value("volumes", "musica", volume_musica)
	volume_efeitos = cfg.get_value("volumes", "efeitos", volume_efeitos)
	volume_voz = cfg.get_value("volumes", "voz", volume_voz)

# Grava as preferências atuais
func salvar():
	var cfg = ConfigFile.new()
	cfg.set_value("efeitos", "reduzir_efeitos", reduzir_efeitos)
	cfg.set_value("volumes", "geral", volume_geral)
	cfg.set_value("volumes", "musica", volume_musica)
	cfg.set_value("volumes", "efeitos", volume_efeitos)
	cfg.set_value("volumes", "voz", volume_voz)
	cfg.save(ARQUIVO)

# Liga/desliga a redução de efeitos e salva
func definir_reduzir_efeitos(ligado):
	reduzir_efeitos = ligado
	salvar()
