extends "res://Enemies/Enemy.gd"

@export var ATTACK_RANGE = 30
@onready var debug = $Debug

func _physics_process(delta):
	super._physics_process(delta) # Call the parent class's _physics_process function
	
	# Continue with the rest of the logic based on the current state
	match state:
		IDLE:
			animationPlayer.play("Idle")
		WANDER:
			animationPlayer.play("Walk")
		CHASE:
			if playerDetectionZone.can_see_player() and global_position.distance_to(playerDetectionZone.player.global_position) < 10:
				animationPlayer.play("Walk") #attack while close
			
	debug.text = str(state)
