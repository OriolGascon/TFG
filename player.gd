extends Area2D

@export var speed = 200
var animated_sprite: AnimatedSprite2D

func _ready():
	# Obtener referencia al AnimatedSprite2D hijo
	animated_sprite = $AnimatedSprite2D
	
	# Configurar animaciones
	var sprite_frames = SpriteFrames.new()
	var texture = load("res://sprites/Player/Astronaut-Sheet.png") as Texture2D
	
	# Animación idle (primera fila, frames de 16x16)
	sprite_frames.add_animation("idle")
	var idle_frame1 = AtlasTexture.new()
	idle_frame1.atlas = texture
	idle_frame1.region = Rect2(0, 0, 16, 16)
	
	var idle_frame2 = AtlasTexture.new()
	idle_frame2.atlas = texture
	idle_frame2.region = Rect2(16, 0, 16, 16)
	
	var idle_frame3 = AtlasTexture.new()
	idle_frame3.atlas = texture
	idle_frame3.region = Rect2(32, 0, 16, 16)
	
	var idle_frame4 = AtlasTexture.new()
	idle_frame4.atlas = texture
	idle_frame4.region = Rect2(48, 0, 16, 16)
	
	sprite_frames.add_frame("idle", idle_frame1)
	sprite_frames.add_frame("idle", idle_frame2)
	sprite_frames.add_frame("idle", idle_frame3)
	sprite_frames.add_frame("idle", idle_frame4)
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", 5.0)
	
	# Animación walk (segunda fila, frames de 16x16)
	sprite_frames.add_animation("walk")
	var walk_frame1 = AtlasTexture.new()
	walk_frame1.atlas = texture
	walk_frame1.region = Rect2(0, 16, 16, 16)
	
	var walk_frame2 = AtlasTexture.new()
	walk_frame2.atlas = texture
	walk_frame2.region = Rect2(16, 16, 16, 16)
	
	var walk_frame3 = AtlasTexture.new()
	walk_frame3.atlas = texture
	walk_frame3.region = Rect2(32, 16, 16, 16)
	
	var walk_frame4 = AtlasTexture.new()
	walk_frame4.atlas = texture
	walk_frame4.region = Rect2(48, 16, 16, 16)
	
	sprite_frames.add_frame("walk", walk_frame1)
	sprite_frames.add_frame("walk", walk_frame2)
	sprite_frames.add_frame("walk", walk_frame3)
	sprite_frames.add_frame("walk", walk_frame4)
	sprite_frames.set_animation_loop("walk", true)
	sprite_frames.set_animation_speed("walk", 8.0)
	
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.play("idle")

func _process(delta):
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
		animated_sprite.play("walk")
		animated_sprite.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= 1
		animated_sprite.play("walk")
		animated_sprite.flip_h = true
	elif Input.is_action_pressed("ui_down"):
		velocity.y += 1
		animated_sprite.play("walk")
	elif Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	# Calcular nueva posición
	var new_position = position + velocity * delta
	
	# Obtener límites de la cámara
	var camera = get_viewport().get_camera_2d()
	if camera:
		var viewport_size = get_viewport_rect().size / camera.zoom
		var camera_pos = camera.position
		var half_viewport = viewport_size / 2
		
		# Calcular límites considerando el tamaño del sprite (16x16 con zoom 2x = 32x32)
		var sprite_size = Vector2(32, 32)  # 16x16 * zoom 2
		
		# Limitar posición dentro de los límites de la cámara
		new_position.x = clamp(new_position.x, camera_pos.x - half_viewport.x + sprite_size.x/2, camera_pos.x + half_viewport.x - sprite_size.x/2)
		new_position.y = clamp(new_position.y, camera_pos.y - half_viewport.y + sprite_size.y/2, camera_pos.y + half_viewport.y - sprite_size.y/2)
	
	position = new_position