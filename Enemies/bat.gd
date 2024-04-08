extends CharacterBody2D

const EnemyDeathEffect = preload("res://Effects/enemy_death_effect.tscn")


@export var ACCELERATION = 300
@export var MAX_SPEED = 50
@export var FRICTION = 200

@onready var hurtbox = $Hurtbox
@onready var softCollision = $SoftCollision
@onready var animationPlayer = $AnimationPlayer

@export var WANDER_TARGET_RANGE = 4

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
@onready var wanderController = $WanderController

func _ready():
	state = pick_random_state([IDLE, WANDER])

func _physics_process(delta):
	update_healthbar()
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wanderController.target_position, delta)
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE
	
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	move_and_slide()
	
func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(randf_range(1,3))
		
func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0		
	
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
			
func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()
	
func _on_hurtbox_area_entered(area):
	stats.health -= area.damage
	velocity = area.knockback_vector * 150
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)
	
func _on_stats_no_health():
	queue_free()
	
	#checks the enemy and gets their position
	var enemyDeathEffect = EnemyDeathEffect.instantiate()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func _on_hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_hurtbox_invincibility_ended():
	animationPlayer.play("Stop")
	
func update_healthbar():
	var healthbar = $HealthBar
	var LOW_HEALTH = stats.max_health * 0.3
	var HALF_HEALTH = stats.max_health * 0.5
	
	healthbar.max_value = stats.max_health
	healthbar.value = stats.health
	
	if stats.health >= stats.max_health:
		healthbar.visible = false
	else:
		healthbar.visible = true
		
	if stats.health <= HALF_HEALTH and stats.health > LOW_HEALTH:
		#Much hp has been lost turn yellow
		healthbar.modulate = Color(1,1,0)
	elif stats.health <= LOW_HEALTH:
		#Health is critical, turn red
		healthbar.modulate = Color(1, 0, 0)
