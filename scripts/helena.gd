extends "res://scripts/fish.gd"

@onready var animsprite = $Sprite2D
@onready var timer = $PuffTimer
@onready var defaultcollision = $CollisionShape2D
@onready var puffedcollision = $PuffedCollisionShape2D

func _on_body_entered(body):
	if body is RigidBody2D:
		inflate()


func _on_puff_timer_timeout():
	deflate()


func inflate():
	animsprite.frame = 1
	timer.start()
	defaultcollision.set_deferred("disabled", true)
	puffedcollision.set_deferred("disabled", false)
	
func deflate():
	animsprite.frame = 0
	defaultcollision.set_deferred("disabled", false)
	puffedcollision.set_deferred("disabled", true)
