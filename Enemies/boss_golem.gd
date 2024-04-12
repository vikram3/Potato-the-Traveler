extends CharacterBody2D
 
@onready var player = get_parent().find_child("Player")
@onready var sprite = $Sprite2D
@onready var progress_bar = $UI/BossHPBar
@onready var animationPlayer = $AnimationPlayer
@onready var hurtbox = $Hurtbox
@export var KNOCKOUT_RANGE = 100
@export var bossHP = 50

@onready var meleeAttackDir = $FiniteStateMachine/MeleeAttack/MeleeAOE

var direction : Vector2
var DEF = 0
 
var health = bossHP:
	set(value):
		health = value
		progress_bar.max_value = bossHP
		progress_bar.value = value
		if value <= 0:
			progress_bar.visible = false
			find_child("FiniteStateMachine").change_state("Death")
		elif value <= progress_bar.max_value / 2 and DEF == 0: # Phase two of the fight he gets tankier
			DEF = 5
			find_child("FiniteStateMachine").change_state("ArmorBuff") 
 
func _ready():
	set_physics_process(false)
 
func _process(_delta):
	if player != null:
		direction = player.position - position
 
	if direction.x < 0:
		sprite.flip_h = true
		meleeAttackDir.position.x = -31
	else:
		sprite.flip_h = false
		meleeAttackDir.position.x = 17
 
func _physics_process(delta):
	velocity = direction.normalized() * 40
	move_and_collide(velocity * delta)
 
func take_damage(area):
	if area.damage - DEF > 0:
		health -= area.damage - DEF
	else:
		health -= area.damage
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func _on_hurtbox_area_entered(area):
	velocity = area.knockback_vector * KNOCKOUT_RANGE
	move_and_slide()
	if health > 0:
		take_damage(area)
	
func _on_hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_hurtbox_invincibility_ended():
	animationPlayer.play("Stop")

func _on_timer_timeout():
	pass # Replace with function body.
