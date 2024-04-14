extends CharacterBody2D

const PlayerHurtSound = preload("res://Player/player_hurt_sound.tscn")
@export var ACCELERATION = 500
@export var MAX_SPEED = 100
@export var ROLL_SPEED = 125
@export var Friction = 500

enum {
	MOVE,
	ROLL,
	ATTACK,
	ATTACK_COMBO,
	ATTACK_COMBO2
}

var state = MOVE
var roll_vector = Vector2.DOWN
var stats = PlayerStats
var atkCount = 0

@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var swordHitbox = $HitboxPivot/SwordHitbox
@onready var hurtbox = $Hurtbox
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer
@onready var LOW_HEALTH = PlayerStats.max_health * 0.25
@onready var HALF_HEALTH = PlayerStats.max_health * 0.5
@onready var timer = $HealthBarTimer
@onready var healthbar = $HealthBar
@onready var attackTimer = $AttackTimer
@onready var debug = $debug

func _ready():
	timer = $HealthBarTimer
	randomize() # Generates a new seed for every time the game is opened.
	self.stats.connect("no_health", queue_free)
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func _physics_process(delta):
	update_healthbar() 
	
	debug.text = enum_to_string(state) + '| Timer: ' + str(attackTimer.time_left)
	
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state()
		ATTACK:
			attack_state()
		ATTACK_COMBO:
			attack_combo()
		ATTACK_COMBO2:
			attack_combo2()
			
func attack_combo():
	if attackTimer.is_stopped(): 
		attackTimer.start()

	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		attackTimer.stop()
		stayInPlace()
		animationState.travel("Attack_Combo")
		attackTimer.start
	elif Input.is_action_just_pressed("Move_Right") or Input.is_action_just_pressed("Move_Left") or Input.is_action_just_pressed("Move_Down") or Input.is_action_just_pressed("Move_Up") or Input.is_action_pressed("Move_Down") or Input.is_action_pressed("Move_Right") or Input.is_action_pressed("Move_Left") or Input.is_action_pressed("Move_Up"):
		await animationTree.animation_finished
		state = MOVE

func attack_combo2():
	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		attackTimer.stop()
		stayInPlace()
		animationState.travel("Attack_Combo2")
	elif Input.is_action_just_pressed("Move_Right") or Input.is_action_just_pressed("Move_Left") or Input.is_action_just_pressed("Move_Down") or Input.is_action_just_pressed("Move_Up") or Input.is_action_pressed("Move_Down") or Input.is_action_pressed("Move_Right") or Input.is_action_pressed("Move_Left") or Input.is_action_pressed("Move_Up"):
		await animationTree.animation_finished
		state = MOVE
	
func attack_state():
	stayInPlace()
	animationState.travel("Attack")
	await animationTree.animation_finished
	
func move_state(delta):
	#This smooths out movements when player is moving in two directions at once.
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Move_Right") - Input.get_action_strength("Move_Left")
	input_vector.y = Input.get_action_strength("Move_Down") - Input.get_action_strength("Move_Up")
	
	input_vector = input_vector.normalized()
	
	#Gain speed as we move
	if input_vector != Vector2.ZERO:
		#Switches to the proper animations based on our position with blend trees.
		roll_vector = input_vector # Roll direction is in the direction I am facing.
		swordHitbox.knockback_vector = input_vector # Sword hitbox is in the direction we are facing
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/BlendSpace2D/blend_position", input_vector)
		animationTree.set("parameters/Attack_Combo/BlendSpace2D/blend_position", input_vector)
		animationTree.set("parameters/Attack_Combo2/BlendSpace2D/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta) # This will be the direction we move to
		move_and_slide()
		update_state_after_input()
	else:
		animationState.travel("Idle")
		#Slow us down when we are stopping movement.
		velocity = velocity.move_toward(Vector2.ZERO, Friction * delta)
		move_and_slide()
		update_state_after_input()

func update_state_after_input(): # Updates the state machine with the proper state after detecting input.
	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state = ATTACK	
	elif Input.is_action_just_pressed("roll"):
		state = ROLL
	
func roll_state(): #
	#Prevents player from rolling after getting attack and getting iframe animation.
	blinkAnimationPlayer.play("Stop")
	
	#Roll Iframe Length
	hurtbox.start_invincibility(.6)

	#Set the velocity to include our roll speed.
	velocity = roll_vector * ROLL_SPEED
	
	animationState.travel("Roll")
	move_and_slide()
	
func roll_animation_finished():
	state = MOVE
	
func attack_animation_finished():
	state = ATTACK_COMBO
	
func attack_combo_animation_finished():
	state = ATTACK_COMBO2
	
func attack_combo2_animation_finished():
	state = MOVE
	
func _on_hurtbox_area_entered(area):
	takeDamage(area)
	
	if area.has_method("projectile"):
		area.queue_free()
	
	#Invincibility and hit effect	
	hurtbox.start_invincibility(.6)
	hurtbox.create_hit_effect()

	#Hurtbox Sound
	var playerHurtSound = PlayerHurtSound.instantiate()
	get_tree().current_scene.add_child(playerHurtSound)

func _on_hurtbox_invincibility_started():
	if state != ROLL: #IF check because I don't want blink animations on my iframe.
		blinkAnimationPlayer.play("Start")

func _on_hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
	
func update_healthbar():
	healthbar.max_value = PlayerStats.max_health
	healthbar.value = PlayerStats.health
	
	if PlayerStats.health >= PlayerStats.max_health:
		healthbar.visible = false
	else:
		healthbar.visible = true
	
	if PlayerStats.health > HALF_HEALTH:
		healthbar.modulate = Color(0, 1, 0) #Green		
	elif PlayerStats.health <= HALF_HEALTH and PlayerStats.health > LOW_HEALTH:
		healthbar.modulate = Color(1,1,0)
	elif PlayerStats.health <= LOW_HEALTH:
		#Health is critical, turn red
		healthbar.modulate = Color(1, 0, 0)
		
	if timer.is_stopped() == true:
		timer.start()

func _on_health_timer_timeout():
	if PlayerStats.health != PlayerStats.max_health:
		PlayerStats.health += 1 # Regen HP
	healthbar.visible = false
	
func player():
	pass

func takeDamage(area):
	stats.health -= area.damage
	
func stayInPlace():
	velocity = Vector2.ZERO #Stops the player from sliding cause they were moving.	

func _on_attack_timer_timeout():
	state = MOVE
	
func enum_to_string(value):
	match value:
		MOVE:
			return "MOVE"
		ROLL:
			return "ROLL"
		ATTACK:
			return "ATTACK"
		ATTACK_COMBO:
			return "ATTACK_COMBO"
		ATTACK_COMBO2:
			return "ATTACK_COMBO2"
		_:
			return "Unknown"
