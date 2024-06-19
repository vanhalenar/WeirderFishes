extends RigidBody2D

var is_held = false

enum MOTION_STATE {idle, moving, held}
var motion_state: MOTION_STATE = MOTION_STATE.idle

enum IDLE_ANIMS {idle, idle_fast, idle_slower, idle_slow}
var idle_anims_list = ["idle", "idle_fast", "idle_slower", "idle_slow"]

var last_velocity

var mat = ShaderMaterial.new()

var shader = preload("res://shaders/squash.gdshader")

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var area = $Area2D
@onready var move_timer = $MoveTimer
@onready var idle_timer = $IdleTimer

@export var idle_min: float = 1
@export var idle_max: float = 6
@export var move_min: float = 0.5
@export var move_max: float = 4
@export var idle_anim: IDLE_ANIMS
@export var speed: int = 10000

func _ready():
	animation_player.play(idle_anims_list[idle_anim])
	idle_timer.start(randf_range(idle_min, idle_max))
	
	mat.shader = shader
	sprite.material = mat


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
	mat.set_shader_parameter("deformation", deformation_scale)

func move():
	var direction = Vector2(randf_range(-0.7, 0.7), randf_range(-0.3, 0.3)).normalized()
	if area.has_overlapping_areas():
		var bodies = area.get_overlapping_areas()
		for i in bodies:
			match i.name:
				"Right":
					direction.x = abs(direction.x) * -1
				"Left":
					direction.x = abs(direction.x)
				"Top":
					direction.y = abs(direction.y)
				"Bottom":
					direction.y = abs(direction.y) * -1
				
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	add_constant_central_force(direction * speed)
	move_timer.start(randf_range(move_min, move_max))

func idle():
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

func _on_idle_timer_timeout():
	move()

func _on_move_timer_timeout():
	idle()
	
