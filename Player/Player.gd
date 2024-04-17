extends CharacterBody2D

const PlayerHurtSound = preload("res://Player/player_hurt_sound.tscn")

#Speed
@export var ACCELERATION = 500
@export var MAX_SPEED = 100
@export var ROLL_SPEED = 125
@export var Friction = 500

enum PlayerState {
	MOVE,
	ROLL,
	ATTACK,
	ATTACK_COMBO,
	ATTACK_COMBO2,
	BOW_READY,
	BOW_AIM,
	BOW_FIRE
}

#Starting State
var state = PlayerState.MOVE

#Base state for rolling
var roll_vector = Vector2.DOWN

var stats = PlayerStats

#Bow
var bow_equipped = true
var bow_cooldown = true
var arrow = preload("res://Player/arrow.tscn")
var mouse_loc_from_player = null
@onready var aimIndicator = $AimIndicator
@onready var arrowProjectile = $ArrowProjectile

#Stat Multipliers
var baseDMG = 0

#General
@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")

#Melee Attack
@onready var swordHitbox = $HitboxPivot/SwordHitbox
@onready var attackTimer = $AttackTimer

#Hurtbox
@onready var hurtbox = $Hurtbox
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer

#Debugging
@onready var debug = $debug

func _ready():
	randomize() # Generates a new seed for every time the game is opened.
	self.stats.connect("no_health", queue_free)
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector
	baseDMG += swordHitbox.damage
	aimIndicator.visible = false

func _physics_process(delta):
	mouse_loc_from_player = get_global_mouse_position() - self.position
	# Assuming attackTimer.time_left is a float value representing time in seconds
	debug.text = enum_to_string(state) + ' | Continue ATK: %.2f' % attackTimer.time_left + ' STR: ' + str(swordHitbox.damage)

	
	match state:
		PlayerState.MOVE:
			calculateDmg(baseDMG)
			move_state(delta)
		PlayerState.ROLL:
			roll_state()
		PlayerState.ATTACK:
			calculateDmg(baseDMG)
			attack_state()
		PlayerState.ATTACK_COMBO:
			var comboDMG = 4
			calculateDmg(baseDMG + comboDMG)
			attack_combo()
		PlayerState.ATTACK_COMBO2:
			var comboDMG2 = 10
			calculateDmg(baseDMG + comboDMG2)
			attack_combo2()
		PlayerState.BOW_READY:
			syncArrowToPointer()
			animationState.travel("Bow_Ready")
		PlayerState.BOW_AIM:
			syncArrowToPointer()
			animationState.travel("Bow_Aim")
		PlayerState.BOW_FIRE:
			syncArrowToPointer()
			activateCrosshair()
			bow_fire_state()
			
func activateCrosshair():
	aimIndicator.global_position = get_global_mouse_position()
	aimIndicator.position = mouse_loc_from_player
	aimIndicator.visible = true
				
func syncArrowToPointer():
	var mouse_pos = get_global_mouse_position()
	arrowProjectile.look_at(mouse_pos)

func calculateDmg(dmgBoostStat):
	swordHitbox.damage = dmgBoostStat
			
func attack_combo():
	activateCrosshair()
	if attackTimer.is_stopped(): 
		attackTimer.start()

	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		attackTimer.stop()
		stayInPlace()
		var aim_direction = (get_global_mouse_position() - global_position).normalized()
		animationTree.set("parameters/Attack_Combo/BlendSpace2D/blend_position", aim_direction)
		animationState.travel("Attack_Combo")
		attackTimer.start()
	elif Input.is_action_just_pressed("Move_Right") or Input.is_action_just_pressed("Move_Left") or Input.is_action_just_pressed("Move_Down") or Input.is_action_just_pressed("Move_Up") or Input.is_action_pressed("Move_Down") or Input.is_action_pressed("Move_Right") or Input.is_action_pressed("Move_Left") or Input.is_action_pressed("Move_Up"):
		await animationTree.animation_finished
		state = PlayerState.MOVE
		
func attack_combo2():
	activateCrosshair()
	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		attackTimer.stop()
		stayInPlace()
		var aim_direction = (get_global_mouse_position() - global_position).normalized()
		animationTree.set("parameters/Attack_Combo2/BlendSpace2D/blend_position", aim_direction)
		animationState.travel("Attack_Combo2")
	elif Input.is_action_just_pressed("Move_Right") or Input.is_action_just_pressed("Move_Left") or Input.is_action_just_pressed("Move_Down") or Input.is_action_just_pressed("Move_Up") or Input.is_action_pressed("Move_Down") or Input.is_action_pressed("Move_Right") or Input.is_action_pressed("Move_Left") or Input.is_action_pressed("Move_Up"):
		await animationTree.animation_finished
		state = PlayerState.MOVE

func attack_state():
	stayInPlace()
	var aim_direction = (get_global_mouse_position() - global_position).normalized()
	animationTree.set("parameters/Attack/BlendSpace2D/blend_position", aim_direction)
	animationState.travel("Attack")
	await animationTree.animation_finished
	
func bow_fire_state():
	var aim_direction = (get_global_mouse_position() - global_position).normalized() # Make player face the mouse
	animationTree.set("parameters/Bow_Aim/BlendSpace2D/blend_position", aim_direction)
	
	if bow_equipped and bow_cooldown and Input.is_action_just_released("bow_attack"):
		animationState.travel("Bow_Fire")
		bow_cooldown = false
		var arrow_instance = arrow.instantiate()
		arrow_instance.rotation = arrowProjectile.rotation
		arrow_instance.global_position = arrowProjectile.global_position
		add_child(arrow_instance)
		await get_tree().create_timer(0.4).timeout
		bow_cooldown = true
		aimIndicator.visible = false
	
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
		animationTree.set("parameters/Bow_Ready/BlendSpace2D/blend_position", input_vector)
		animationTree.set("parameters/Bow_Aim/BlendSpace2D/blend_position", input_vector)
		animationTree.set("parameters/Bow_Fire/BlendSpace2D/blend_position", input_vector)
		animationTree.set("parameters/Roll/Blendspace2D/blend_position", input_vector)
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
		state = PlayerState.ATTACK    
	elif Input.is_action_just_pressed("roll"):
		state = PlayerState.ROLL
	elif Input.is_action_pressed("bow_attack") and bow_equipped and bow_cooldown:
		state = PlayerState.BOW_READY
	
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
	state = PlayerState.MOVE
	
func attack_animation_finished():
	state = PlayerState.ATTACK_COMBO
	
func attack_combo_animation_finished():
	aimIndicator.visible = false
	state = PlayerState.ATTACK_COMBO2
	
func bow_ready_finished():
	state = PlayerState.BOW_AIM

func bow_aim_finished():
	state = PlayerState.BOW_FIRE
	
func bow_fire_finished():
	state = PlayerState.MOVE
	
func attack_combo2_animation_finished():
	aimIndicator.visible = false
	state = PlayerState.MOVE
	
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
	if state != PlayerState.ROLL: #IF check because I don't want blink animations on my iframe.
		blinkAnimationPlayer.play("Start")

func _on_hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")

func takeDamage(area):
	stats.health -= area.damage
	
func stayInPlace():
	velocity = Vector2.ZERO #Stops the player from sliding cause they were moving.    

func _on_attack_timer_timeout():
	state = PlayerState.MOVE
	aimIndicator.visible = false
	
func player():
	pass
	
func enum_to_string(value):
	match value:
		PlayerState.MOVE:
			return "MOVE"
		PlayerState.ROLL:
			return "ROLL"
		PlayerState.ATTACK:
			return "ATTACK"
		PlayerState.ATTACK_COMBO:
			return "ATTACK_1"
		PlayerState.ATTACK_COMBO2:
			return "ATTACK_2"
		PlayerState.BOW_READY:
			return "BOW_READY"
		PlayerState.BOW_AIM:
			return "BOW_AIM"
		PlayerState.BOW_FIRE:
			return "BOW_FIRE"
		_:
			return "Unknown"
