extends Node2D

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		#Load Scene
		var GrassEffect = load("res://Effects/grass_effect.tscn")
		#Instance the Scene
		var grassEffect = GrassEffect.instantiate()
	
		# Get access to the world, add it as a child and set the position.
		var world = get_tree().current_scene
		world.add_child(grassEffect)
		grassEffect.global_position = global_position
		
		queue_free()
