extends CharacterBody2D

const EnemyDeathEffect = preload("res://Effects/enemy_death_effect.tscn")

@onready var player = get_parent().find_child("Player")
@onready var sprite = $Sprite2D
@onready var progress_bar = $UI/BossHPBar
@onready var animationPlayer = $AnimationPlayer
@onready var hurtbox = $Hurtbox
@export var KNOCKOUT_RANGE = 100
@export var bossHP = 50
@onready var meleeAttackDir = $FiniteStateMachine/MeleeAttack/MeleeAOE
@onready var stats = $Stats

var direction : Vector2
var DEF = 0
 
func _ready():
	set_physics_process(false)
 
func _process(_delta):
	update_healthbar()
	
	if stats.health <= 0:
		progress_bar.visible = false
		find_child("FiniteStateMachine").change_state("Death")
	elif stats.health <= progress_bar.max_value / 2 and DEF == 0: # Phase two of the fight he gets tankier
		DEF = 5
		find_child("FiniteStateMachine").change_state("ArmorBuff") 
		
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
		stats.health -= area.damage - DEF
	else:
		stats.health -= area.damage
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func _on_hurtbox_area_entered(area):
	if stats.health > 0:
		take_damage(area)
	
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
	
	progress_bar.max_value = stats.max_health
	progress_bar.value = stats.health
	
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

func _on_stats_no_health():
	queue_free()
	#Puts the death effect where the enemy died.
	var enemyDeathEffect = EnemyDeathEffect.instantiate()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
