extends Node2D

@onready var earth = $Earth
@onready var earth_area = $Earth/EarthArea
@onready var hover_outline = $Earth/HoverOutline
@onready var description_label = $UI/DescriptionLabel

func _ready() -> void:
	description_label.visible = false
	hover_outline.visible = false
	earth.connect("mouse_entered", Callable(self, "_on_earth_mouse_entered"))
	earth.connect("mouse_exited", Callable(self, "_on_earth_mouse_exited"))
	earth_area.connect("input_event", Callable(self, "_on_earth_input_event"))

func _on_earth_mouse_entered() -> void:
	earth.modulate = Color(0.7, 1, 0.7, 1)
	hover_outline.visible = true
	description_label.text = "Planeta Tierra: hogar de la vida y atmósfera respirable."
	description_label.visible = true

func _on_earth_mouse_exited() -> void:
	earth.modulate = Color(1, 1, 1, 1)
	hover_outline.visible = false
	description_label.visible = false

func _on_earth_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Cambiar a la escena del planeta Tierra
		get_tree().change_scene_to_file("res://planeta_terra_probes.tscn")
