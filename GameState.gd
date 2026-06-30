extends Node

# Variable global para almacenar el token del jugador
var player_token: String = ""
var player_username: String = ""

func _ready():
	# Hacer que este nodo persista entre escenas
	pass

func set_token(token: String, username: String = ""):
	player_token = token
	player_username = username
	print("Token guardado: ", token)
	print("Usuario: ", username)

func get_token() -> String:
	return player_token

func get_username() -> String:
	return player_username

func is_logged_in() -> bool:
	return player_token != ""

func clear_session():
	player_token = ""
	player_username = ""
	print("Sesión cerrada")
