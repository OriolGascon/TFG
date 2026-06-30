extends Area2D

var exercise_scene = preload("res://exercise_question.tscn")
var has_triggered = false

func _ready():
	# Conectar señales de área
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area):
	print("Area entered: ", area.name)
	if (area.name == "Player" or area.is_in_group("player")) and not has_triggered:
		print("Opening question scene")
		has_triggered = true
		open_question()

func _on_area_exited(area):
	if area.name == "Player" or area.is_in_group("player"):
		has_triggered = false

func open_question():
	get_tree().change_scene_to_packed(exercise_scene)
