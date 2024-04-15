extends CharacterBody2D

const PlayerHurtSound = preload("res://Player/player_hurt_sound.tscn")

#Speed
@export var ACCELERATION = 500
@export var MAX_SPEED = 100
@export var ROLL_SPEED = 125
@export var Friction = 500

enum {
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
var state = MOVE

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

#HealthUI
@onready var LOW_HEALTH = PlayerStats.max_health * 0.25
@onready var HALF_HEALTH = PlayerStats.max_health * 0.5
@onready var timer = $HealthBarTimer
@onready var healthbar = $HealthBar

#Debugging
@onready var debug = $debug

func _ready():
	timer = $HealthBarTimer
	randomize() # Generates a new seed for every time the game is opened.
	self.stats.connect("no_health", queue_free)
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector
	baseDMG += swordHitbox.damage
	aimIndicator.visible = false

func _physics_process(delta):
	update_healthbar() 
	
	mouse_loc_from_player = get_global_mouse_position() - self.position
	
	debug.text = enum_to_string(state) + ' DMG: ' + str(swordHitbox.damage) + ' | Timer: ' + str(attackTimer.time_left)
	
	match state:
		MOVE:
			calculateDmg(baseDMG)
			move_state(delta)
		ROLL:
			roll_state()
		ATTACK:
			calculateDmg(baseDMG)
			attack_state()
		ATTACK_COMBO:
			var comboDMG = 4
			calculateDmg(baseDMG + comboDMG)
			attack_combo()
		ATTACK_COMBO2:
			var comboDMG2 = 10
			calculateDmg(baseDMG + comboDMG2)
			attack_combo2()
		BOW_READY:
			syncArrowToPointer()
			animationState.travel("Bow_Ready")
		BOW_AIM:
			syncArrowToPointer()
			animationState.travel("Bow_Aim")
		BOW_FIRE:
			syncArrowToPointer()
			activateCrosshair()
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
			elif Input.is_action_just_pressed("Move_Right") or Input.is_action_just_pressed("Move_Left") or Input.is_action_just_pressed("Move_Down") or Input.is_action_just_pressed("Move_Up") or Input.is_action_pressed("Move_Down") or Input.is_action_pressed("Move_Right") or Input.is_action_pressed("Move_Left") or Input.is_action_pressed("Move_Up"):
				aimIndicator.visible = false
				state = MOVE
				
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
		state = MOVE
		
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
		state = MOVE

func attack_state():
	stayInPlace()
	var aim_direction = (get_global_mouse_position() - global_position).normalized()
	animationTree.set("parameters/Attack/BlendSpace2D/blend_position", aim_direction)
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
		state = ATTACK	
	elif Input.is_action_just_pressed("roll"):
		state = ROLL
	elif Input.is_action_pressed("bow_attack") and bow_equipped and bow_cooldown:
		state = BOW_READY
	
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
	aimIndicator.visible = false
	state = ATTACK_COMBO2
	
func bow_ready_finished():
	state = BOW_AIM

func bow_aim_finished():
	state = BOW_FIRE
	
func bow_fire_finished():
	state = MOVE
	
func attack_combo2_animation_finished():
	aimIndicator.visible = false
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
	aimIndicator.visible = false
	
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
		BOW_READY:
			return "BOW_READY"
		BOW_AIM:
			return "BOW_AIM"
		BOW_FIRE:
			return "BOW_FIRE"
		_:
			return "Unknown"
