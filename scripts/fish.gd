extends RigidBody2D

const RAY_LENGTH = 400
var screen_size

var is_held = false

enum MOTION_STATE {idle, moving, held}
var motion_state: MOTION_STATE = MOTION_STATE.idle

enum NATURE {dumb, passive, aggressive, frantic}

enum IDLE_ANIMS {idle, idle_fast, idle_slower, idle_slow}
var idle_anims_list = ["idle", "idle_fast", "idle_slower", "idle_slow"]

var last_velocity

var collision_shape

var shader_material = ShaderMaterial.new()

var shader = preload("res://shaders/squash.gdshader")

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var area = $Area2D
@onready var move_timer = $MoveTimer
@onready var idle_timer = $IdleTimer
@onready var raycast = $RayCast2D

@export var idle_min: float = 1
@export var idle_max: float = 6
var move_min: float = 0.5
var move_max: float = 4
@export var idle_anim: IDLE_ANIMS
@export var speed: float = 10000
@export var nature: NATURE = NATURE.dumb

func _ready():
	animation_player.play(idle_anims_list[idle_anim])
	idle_timer.start(randf_range(idle_min, idle_max))
	
	shader_material.shader = shader
	sprite.material = shader_material
	
	move_min = 5000/speed
	move_max = 40000/speed
	
	screen_size = get_viewport_rect().size
	
	if has_node("CollisionPolygon2D"):
		collision_shape = $CollisionPolygon2D
	else:
		collision_shape = $CollisionShape2D

func _physics_process(_delta):
	last_velocity = linear_velocity


func _integrate_forces(state):
	var lv = state.get_linear_velocity()
	
	if is_held:
		lv = (get_global_mouse_position() - global_position) * 16
	
	state.set_linear_velocity(lv)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				is_held = false

func deform(direction, strength):
	var tween = get_tree().create_tween()
	var deformationStrength = clamp((strength)/1000, 0.01, 0.5)
	var deformationDirection = direction
	var deformationScale = 0.5 * deformationDirection * deformationStrength
	
	tween.tween_method(set_shader_squash, Vector2.ZERO, deformationScale, 0.15)
	tween.tween_method(set_shader_squash, deformationScale, Vector2.ZERO, 0.35)

func set_shader_squash(deformation_scale):
	shader_material.set_shader_parameter("deformation", deformation_scale)

func move():
	motion_state = MOTION_STATE.moving
	var direction = Vector2(randf_range(-0.7, 0.7), randf_range(-0.3, 0.3)).normalized()
	
	#move away from borders
	if global_position.x > 0.8*screen_size.x:
		direction.x = abs(direction.x) * -1
	elif global_position.x < 0.2*screen_size.x:
		direction.x = abs(direction.x)
	
	if global_position.y > 0.8*screen_size.y:
		direction.y = abs(direction.y) * -1
	elif global_position.y < 0.2*screen_size.y:
		direction.y = abs(direction.y)
	
	if direction.x < 0:
		sprite.flip_h = true
		collision_shape.scale.x = -1
	else:
		sprite.flip_h = false
		collision_shape.scale.x = 1
	
	add_constant_central_force(direction * speed)
	if move_timer.is_stopped():
		move_timer.start(randf_range(move_min, move_max))

func idle():
	motion_state = MOTION_STATE.idle
	constant_force = Vector2.ZERO
	idle_timer.start(randf_range(idle_min, idle_max))


# SIGNALS
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_held = true

func _on_body_entered(_body):
	var strength = abs(linear_velocity.length() - last_velocity.length())
	var direction = last_velocity.normalized()
	
	deform(direction, strength)
	
	if motion_state == MOTION_STATE.moving:
		match nature:
			NATURE.dumb:
				pass
			NATURE.passive:
				move_timer.stop()
				idle()
			NATURE.aggressive:
				pass
			NATURE.frantic:
				constant_force = Vector2.ZERO
				move()

func _on_idle_timer_timeout():
	move()

func _on_move_timer_timeout():
	idle()
	
