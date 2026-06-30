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

	# UI
	var panel = PanelContainer.new()
	add_child(panel)

	vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 380)
	panel.add_child(vbox)

	# Título
	var title_section = Label.new()
	title_section.text = "Título:"
	title_section.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_section)

	title_label = Label.new()
	title_label.text = "Cargando ejercicio..."
	vbox.add_child(title_label)

	# Descripción
	var desc_section = Label.new()
	desc_section.text = "Descripción:"
	desc_section.add_theme_font_size_override("font_size", 18)
	vbox.add_child(desc_section)

	desc_label = Label.new()
	desc_label.text = ""
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# File select
	var upload_section = Label.new()
	upload_section.text = "Subir archivo:"
	upload_section.add_theme_font_size_override("font_size", 18)
	vbox.add_child(upload_section)

	var file_box = HBoxContainer.new()
	vbox.add_child(file_box)

	file_path_label = Label.new()
	file_path_label.text = "Ningún archivo seleccionado"
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
	vbox.add_child(upload_status_label)

	# File dialog
	var file_dialog = FileDialog.new()
	file_dialog.name = "FileDialog"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)

	fetch_exercise()


func fetch_exercise():
	var url = "http://192.168.1.126:8000/exercises"

	var headers = []
	if game_state.is_logged_in():
		headers.append("Authorization: Bearer " + game_state.get_token())

	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	print("Fetch error:", error)

func _on_fetch_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()

	if response_code == 200:
		var json = JSON.new()
		if json.parse(text) == OK:
			var exercises = json.get_data()
			if exercises.size() > 0:
				current_exercise = exercises[randi() % exercises.size()]
				print(current_exercise)
				title_label.text = current_exercise.get("title", "Sin título")
				desc_label.text = current_exercise.get("description", "Sin descripción")
	else:
		print("Error fetch:", response_code, text)


func _on_select_file_pressed():
	$FileDialog.popup_centered()

func _on_file_selected(path: String):
	selected_file_path = path
	file_path_label.text = path
	upload_status_label.text = "Archivo seleccionado"


func _on_send_file_pressed():
	if selected_file_path == "":
		upload_status_label.text = "Selecciona un archivo"
		return

	if current_exercise == {}:
		upload_status_label.text = "No hay ejercicio activo"
		return

	var exercise_id = int(current_exercise.get("id"))

	var file = FileAccess.open(selected_file_path, FileAccess.READ)
	if file == null:
		upload_status_label.text = "No se pudo abrir archivo"
		return

	var file_data = file.get_buffer(file.get_length())
	file.close()

	var boundary = "----GodotBoundary" + str(Time.get_unix_time_from_system())

	var body_bytes = PackedByteArray()

	# -------------------------
	# exercise_id field
	# -------------------------
	body_bytes.append_array(("--" + boundary + "\r\n").to_utf8_buffer())

	body_bytes.append_array(
		("Content-Disposition: form-data; name=\"exercise_id\"\r\n\r\n").to_utf8_buffer()
	)

	body_bytes.append_array(str(exercise_id).to_utf8_buffer())
	body_bytes.append_array("\r\n".to_utf8_buffer())

	# -------------------------
	# file field
	# -------------------------
	body_bytes.append_array(("--" + boundary + "\r\n").to_utf8_buffer())

	body_bytes.append_array(
		("Content-Disposition: form-data; name=\"file\"; filename=\"" +
		selected_file_path.get_file() + "\"\r\n").to_utf8_buffer()
	)

	body_bytes.append_array("Content-Type: application/octet-stream\r\n\r\n".to_utf8_buffer())

	body_bytes.append_array(file_data)

	body_bytes.append_array("\r\n".to_utf8_buffer())

	# -------------------------
	# end boundary
	# -------------------------
	body_bytes.append_array(("--" + boundary + "--\r\n").to_utf8_buffer())

	var url = "http://192.168.1.126:8000/submissions"

	var headers = [
		"Content-Type: multipart/form-data; boundary=" + boundary
	]

	if game_state.is_logged_in():
		headers.append("Authorization: Bearer " + game_state.get_token())

	upload_status_label.text = "Enviando..."

	var error = upload_request.request_raw(
		url,
		headers,
		HTTPClient.METHOD_POST,
		body_bytes
	)

	print("Upload error:", error)

func _on_upload_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()

	if response_code == 200 or response_code == 201:
		upload_status_label.text = "Archivo enviado correctamente"
	else:
		upload_status_label.text = "Error upload: " + str(response_code)
		print(text)

func _on_close_pressed():
	queue_free()
