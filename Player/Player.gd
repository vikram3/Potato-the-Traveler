extends CharacterBody2D

const PlayerHurtSound = preload("res://Player/player_hurt_sound.tscn")
@export var ACCELERATION = 500
@export var MAX_SPEED = 100
@export var ROLL_SPEED = 125
@export var Friction = 500

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var roll_vector = Vector2.DOWN
var stats = PlayerStats

#Initializes and grabs the animation player and tree
@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var swordHitbox = $HitboxPivot/SwordHitbox
@onready var hurtbox = $Hurtbox
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	randomize() # Generates a new seed for every time the game is opened.
	self.stats.connect("no_health", queue_free)
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func _physics_process(delta):
	update_healthbar()
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state()
		ATTACK:
			attack_state()

func move_state(delta):
	#This smooths out movements when player is moving in two directions at once.
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Move_Right") - Input.get_action_strength("Move_Left")
	input_vector.y = Input.get_action_strength("Move_Down") - Input.get_action_strength("Move_Up")
	input_vector = input_vector.normalized()
	
	#Gain speed as we move
	if input_vector != Vector2.ZERO:
		#Switches to the proper animations based on our position with blend trees.
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		
		move()
		#Can activate these states while moving
		if Input.is_action_just_pressed("attack"):
			state = ATTACK	
		elif Input.is_action_just_pressed("roll"):
			state = ROLL
	else:
		animationState.travel("Idle")
		#Slow us down when we are stopping movement.
		velocity = velocity.move_toward(Vector2.ZERO, Friction * delta)
		
		move()
	
		if Input.is_action_just_pressed("roll"):
			state = ROLL
			
		#Lets player attack during idle.
		if Input.is_action_just_pressed("attack"):
			state = ATTACK
	
func roll_state():
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()

func attack_state():
	#Stops the player from sliding cause they were moving.
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func move():
	move_and_slide()
	
func roll_animation_finished():
	state = MOVE
	
func attack_animation_finished():
	state = MOVE

func _on_hurtbox_area_entered(area):
	print("Player has taken damage")
	stats.health -= area.damage
	hurtbox.start_invincibility(.6)
	hurtbox.create_hit_effect()
	var playerHurtSound = PlayerHurtSound.instantiate()
	get_tree().current_scene.add_child(playerHurtSound)

func _on_hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
	
func update_healthbar():
	var healthbar = $HealthBar
	healthbar.value = PlayerStats.health * 10
	
	if PlayerStats.health >= PlayerStats.max_health:
		healthbar.visible = false
	else:
		healthbar.visible = true
