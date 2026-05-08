extends Control

var current_exercise = {}
var http_request: HTTPRequest
var upload_request: HTTPRequest
var vbox: VBoxContainer
var title_label: Label
var desc_label: Label
var file_path_label: Label
var upload_status_label: Label
var selected_file_path: String = ""
@onready var game_state = get_node("/root/GameState")

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_fetch_request_completed)

	upload_request = HTTPRequest.new()
	add_child(upload_request)
	upload_request.request_completed.connect(_on_upload_request_completed)
	
	# Crear la UI para mostrar la pregunta
	var panel = PanelContainer.new()
	panel.add_to_group("exercise_panel")
	add_child(panel)
	
	vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 380)
	panel.add_child(vbox)
	
	# Sección de título
	var title_section = Label.new()
	title_section.text = "Título:"
	title_section.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_section)
	
	title_label = Label.new()
	title_label.text = "Cargando ejercicio..."
	title_label.custom_minimum_size = Vector2(460, 0)
	vbox.add_child(title_label)
	
	# Sección de descripción
	var desc_section = Label.new()
	desc_section.text = "Descripción:"
	desc_section.add_theme_font_size_override("font_size", 18)
	vbox.add_child(desc_section)
	
	desc_label = Label.new()
	desc_label.text = ""
	desc_label.custom_minimum_size = Vector2(460, 150)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Sección de subida de archivo
	var upload_section = Label.new()
	upload_section.text = "Subir archivo:"
	upload_section.add_theme_font_size_override("font_size", 18)
	vbox.add_child(upload_section)
	
	var file_box = HBoxContainer.new()
	file_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(file_box)
	
	file_path_label = Label.new()
	file_path_label.text = "Ningún archivo seleccionado"
	file_path_label.custom_minimum_size = Vector2(340, 0)
	file_box.add_child(file_path_label)
	
	var select_button = Button.new()
	select_button.text = "Seleccionar"
	select_button.pressed.connect(_on_select_file_pressed)
	file_box.add_child(select_button)
	
	var send_button = Button.new()
	send_button.text = "Enviar archivo"
	send_button.pressed.connect(_on_send_file_pressed)
	vbox.add_child(send_button)
	
	upload_status_label = Label.new()
	upload_status_label.text = ""
	vbox.add_child(upload_status_label)
	
	# Diálogo para seleccionar archivos
	var file_dialog = FileDialog.new()
	file_dialog.name = "FileDialog"
	file_dialog.mode = FileDialog.Mode.OPEN_FILE
	file_dialog.access = FileDialog.Access.FILE_SYSTEM
	file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	add_child(file_dialog)
	
	# Posicionar en el centro
	anchor_left = 0.5
	anchor_top = 0.5
	offset_left = -250
	offset_top = -190
	
	# Hacer petición al API
	fetch_exercise()

func fetch_exercise():
	var url = "http://192.168.1.126:8000/exercises"
	print("Intentando conectar a: ", url)

	var headers = []
	if game_state.is_logged_in():
		var token = game_state.get_token()
		headers.append("Authorization: Bearer " + token)
		print("Token enviado: ", token)
	else:
		print("Advertencia: No hay token disponible")

	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	print("Error de petición: ", error)

func _on_fetch_request_completed(result, response_code, headers, body):
	print("Resultado fetch: ", result, " | Código: ", response_code)
	if response_code == 200:
		var json = JSON.new()
		var response_text = body.get_string_from_utf8()
		print("Respuesta del API: ", response_text)
		var parse_result = json.parse(response_text)
		var exercises = []
		if parse_result == OK:
			exercises = json.get_data()
		else:
			print("Error parseando JSON: ", json.get_error_message())
		
		if exercises and exercises is Array and exercises.size() > 0:
			var random_exercise = exercises[randi() % exercises.size()]
			current_exercise = random_exercise
			title_label.text = current_exercise.get("title", "Sin título")
			desc_label.text = current_exercise.get("description", "Sin descripción")
		else:
			title_label.text = "Ejercicio no encontrado"
			desc_label.text = "No se encontraron ejercicios"
			print("No exercises found")
	else:
		var response_text = body.get_string_from_utf8()
		title_label.text = "Error al cargar el ejercicio"
		desc_label.text = "Error al cargar el ejercicio (código: " + str(response_code) + ")"
		print("Error fetching exercises: ", response_code)
		print("Body: ", response_text)

func _on_select_file_pressed():
	var dialog = $FileDialog
	if dialog:
		dialog.popup_centered()

func _on_file_selected(path: String):
	selected_file_path = path
	file_path_label.text = path
	upload_status_label.text = "Archivo seleccionado"

func _on_send_file_pressed():
	if selected_file_path == "":
		upload_status_label.text = "Selecciona un archivo antes de enviar"
		return
	
	var file = FileAccess.open(selected_file_path, FileAccess.READ)
	if file == null:
		upload_status_label.text = "No se pudo abrir el archivo"
		return
	
	var file_data = file.get_buffer(file.get_length())
	file.close()
	
	var boundary = "----GodotBoundary" + str(OS.get_unix_time())
	var body_bytes = PackedByteArray()
	body_bytes.append_array(("--" + boundary + "\r\n").to_utf8())
	body_bytes.append_array(("Content-Disposition: form-data; name=\"file\"; filename=\"" + selected_file_path.get_file() + "\"\r\n").to_utf8())
	body_bytes.append_array("Content-Type: application/octet-stream\r\n\r\n".to_utf8())
	body_bytes.append_array(file_data)
	body_bytes.append_array("\r\n".to_utf8())
	body_bytes.append_array(("--" + boundary + "--\r\n").to_utf8())
	
	var url = "http://192.168.1.126:8000/exercises/upload"
	var headers = ["Content-Type: multipart/form-data; boundary=" + boundary]
	if game_state.is_logged_in():
		var token = game_state.get_token()
		headers.append("Authorization: Bearer " + token)
		print("Token enviado en upload: ", token)

	upload_status_label.text = "Enviando archivo..."
	var error = upload_request.request(url, headers, HTTPClient.METHOD_POST, body_bytes)
	print("Error de petición upload: ", error)

func _on_upload_request_completed(result, response_code, headers, body):
	print("Resultado upload: ", result, " | Código: ", response_code)
	var response_text = body.get_string_from_utf8()
	print("Respuesta upload: ", response_text)
	if response_code == 200 or response_code == 201:
		upload_status_label.text = "Archivo enviado correctamente"
	else:
		upload_status_label.text = "Error al enviar archivo (código: " + str(response_code) + ")"
		print("Error upload: ", response_code)
		print("Body: ", response_text)

func _on_close_pressed():
	queue_free()
