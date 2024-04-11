extends CharacterBody2D
 
@onready var player = get_parent().find_child("Player")
@onready var sprite = $Sprite2D
@onready var progress_bar = $UI/BossHPBar
@onready var animationPlayer = $AnimationPlayer
@onready var hurtbox = $Hurtbox
 
var direction : Vector2
var DEF = 0
 
var health = 100:
	set(value):
		health = value
		progress_bar.value = value
		if value <= 0:
			progress_bar.visible = false
			find_child("FiniteStateMachine").change_state("Death")
		elif value <= progress_bar.max_value / 2 and DEF == 0:
			DEF = 5
			find_child("FiniteStateMachine").change_state("ArmorBuff") 
 
func _ready():
	set_physics_process(false)
 
func _process(_delta):
	direction = player.position - position
 
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
 
func _physics_process(delta):
	velocity = direction.normalized() * 40
	move_and_collide(velocity * delta)
 
func take_damage():
	print("hp depleting")
	health -= 10 - DEF
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func _on_hurtbox_area_entered(area):
	print("detected")
	take_damage()
	
func _on_hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_hurtbox_invincibility_ended():
	animationPlayer.play("Stop")

func _on_timer_timeout():
	pass # Replace with function body.
