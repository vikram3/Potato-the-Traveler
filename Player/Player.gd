extends CharacterBody2D

const ACCELERATION = 500
const MAX_SPEED = 80
const Friction = 500

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE

#Initializes and grabs the animation player and tree
@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")

func _ready():
	animationTree.active = true

func _process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			pass
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
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		
		#Lets player attack whilst moving.
		if Input.is_action_just_pressed("attack"):
			state = ATTACK
	else:
		animationState.travel("Idle")
		#Slow us down when we are stopping movement.
		velocity = velocity.move_toward(Vector2.ZERO, Friction * delta)
		
		#Lets player attack during idle.
		if Input.is_action_just_pressed("attack"):
			state = ATTACK
		
	move_and_slide()

func attack_state():
	#Stops the player from sliding cause they were moving.
	velocity = Vector2.ZERO
	
	animationState.travel("Attack")
	
func attack_animation_finished():
	state = MOVE
