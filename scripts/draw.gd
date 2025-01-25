extends Node2D

var mi_pos:Array = []
var poly_pos:Array = []
var poly_buf:Array = []
const DIST_THRESHOLD = 100.0
@onready var dummies = $Dummies

func check_poly(points_array:Array) -> bool:
	return points_array.front().distance_to(points_array.back()) < DIST_THRESHOLD

func check_objects(polygon:Array):
	for obj in dummies.get_children():
		print(obj.global_position)
		if Geometry2D.is_point_in_polygon(obj.global_position, polygon):
			obj.queue_free()

func _input(event:InputEvent):
	if Input.is_action_just_released("click"):
		# if there is a polygon, draw it
		if poly_buf.size() >= 2:
			poly_pos.append(poly_buf.duplicate())
			check_objects(poly_buf)
			poly_buf.clear()
			var timer: Timer = Timer.new()
			add_child(timer)
			timer.wait_time = 1.5
			timer.one_shot = true
			timer.timeout.connect(timer_timeout)
			timer.start()
		mi_pos.clear()
		queue_redraw()
		return
		
	if not Input.is_action_pressed("click"):
		return

	# point is not first
	if (not mi_pos.is_empty()):
		if (event.position.distance_to(mi_pos.back())>20.0):
			mi_pos.append(event.position)
			queue_redraw()
			poly_buf.append(event.position)
			poly_buf.append(mi_pos.front())
			# check if triangulates, if not, remove point
			if Geometry2D.triangulate_polygon(poly_buf).is_empty():
				poly_buf.pop_back()
				poly_buf.pop_back()
			poly_buf.pop_back()
	# point is first
	else:
		mi_pos.append(event.position)
		poly_buf.append(event.position)
		queue_redraw()

func _draw():
	if (mi_pos.size() >= 2):
		draw_polyline(mi_pos, Color.RED, 2.0)
	
	if not poly_pos.is_empty():
		for poly in poly_pos:
			draw_colored_polygon(poly, Color.BLUE)

func timer_timeout():
	poly_pos.pop_front()
	queue_redraw()
