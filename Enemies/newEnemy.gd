extends "res://Enemies/Enemy.gd"

@export var bullet_node: PackedScene
@export var ATTACK_RANGE = 10
@onready var debug = $Debug
@onready var pivot = $pivot
@onready var animation_player = $AnimationPlayer2

enum {
	RANGE, 
	LASER
}

func _physics_process(delta):
	super._physics_process(delta) # Call the parent class's _physics_process function
	debug.text = str(state)
	# Continue with the rest of the logic based on the current state
	match state:
		IDLE:
			animationPlayer.play("Idle")
		WANDER:
			animationPlayer.play("Walk")
		CHASE:
			if playerDetectionZone.can_see_player() and global_position.distance_to(playerDetectionZone.player.global_position) < ATTACK_RANGE:
				animationPlayer.play("Walk") #attack while close
			else:
				#Randomize laser or range
				state = LASER
		RANGE:
			if playerDetectionZone.can_see_player() and global_position.distance_to(playerDetectionZone.player.global_position) > ATTACK_RANGE:
				if ATTACK_RANGE < 30:
					animationPlayer.play("Walk") #attack while close
					shoot()
				else:
					state = IDLE 
		LASER:
			await play_animation("laser_cast")
			await play_animation("laser")
			#state = IDLE
			
func shoot():
	var bullet = bullet_node.instantiate()
	bullet.position = owner.position
	get_tree().current_scene.add_child(bullet)
	
func set_target():
	pivot.rotation = (owner.direction - pivot.position).angle()
	
func play_animation(anim_name):
	animation_player.play(anim_name)
	await animation_player.animation_finished
