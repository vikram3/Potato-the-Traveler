extends CharacterBody2D

const EnemyDeathEffect = preload("res://Effects/enemy_death_effect.tscn")

@export var ACCELERATION = 300
@export var MAX_SPEED = 50
@export var FRICTION = 200

enum {
	IDLE,
	WANDER,
	CHASE
}
var state = CHASE

@onready var sprite = $AnimatedSprite
@onready var stats = $Stats
@onready var playerDetectionZone = $PlayerDetection
@onready var startPosition = get_global_transform().origin

func _physics_process(delta):
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
		WANDER:
			pass
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				var direction = global_position.direction_to(player.global_position)
				velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION)
				print("IM CHASIN")
			else:
				state = IDLE
				#velocity = velocity.move_toward(startPosition * MAX_SPEED, ACCELERATION)
				print("DONE CHASIN")
			sprite.flip_h = velocity.x < 0		
	
	move_and_slide()
		
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
		print("I SEE YOU")
			
func _on_hurtbox_area_entered(area):
	stats.health -= area.damage
	velocity = area.knockback_vector * 120
	
func _on_stats_no_health():
	queue_free()
	
	#checks the enemy and gets their position
	var enemyDeathEffect = EnemyDeathEffect.instantiate()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
