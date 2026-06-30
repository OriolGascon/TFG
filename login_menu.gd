extends Control

@onready var username_field = $username
@onready var password_field = $password
@onready var error_label = $ErrorLabel
@onready var http_request = $HTTPRequest
@onready var game_state = get_node("/root/GameState")

var auth_url = "http://192.168.1.126:8000/token"

func _ready():
	error_label.text = ""
	http_request.request_completed.connect(_on_http_request_request_completed)

func _on_login_button_down():
	# Validar campos
	var username = username_field.text.strip_edges()
	var password = password_field.text
	
	if username.is_empty():
		_show_error("Por favor ingresa un usuario")
		return
	
	if password.is_empty():
		_show_error("Por favor ingresa una contraseña")
		return
	
	# Limpiar mensajes previos
	error_label.text = ""
	
	# Preparar datos para enviar en formato urlencoded
	var body = "username=" + username.uri_encode() + "&password=" + password.uri_encode()
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	
	# Realizar solicitud HTTP
	http_request.request(auth_url, headers, HTTPClient.METHOD_POST, body)

func _on_http_request_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		_show_error("Error de conexión. Intenta de nuevo.")
		return
	
	if response_code != 200:
		# El servidor respondió con un código de error
		var error_message = _parse_error_response(body)
		_show_error(error_message)
		return
	
	# Login exitoso
	_clear_error()
	_handle_login_success(body)

func _parse_error_response(body):
	# Intentar parsear la respuesta JSON para obtener el mensaje de error
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	
	if error == OK:
		var response = json.get_data()
		if response.has("message"):
			return response["message"]
		elif response.has("error"):
			return response["error"]
	
	return "Usuario o contraseña incorrecta"

func _show_error(message: String):
	error_label.text = message
	error_label.show()
	print("[Login Error] " + message)

func _clear_error():
	error_label.text = ""
	error_label.hide()

func _handle_login_success(body):
	print("Login exitoso")
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		var response = json.get_data()
		if response.has("access_token"):
			var token = response["access_token"]
			var username = username_field.text.strip_edges()
			print("Access token recibido: ", token)
			
			# Guardar el token globalmente
			game_state.set_token(token, username)

	# Cambiar a la pantalla del selector de planetas
	get_tree().change_scene_to_file("res://Planet_selector.tscn")
