extends CharacterBody2D

const EnemyDeathEffect = preload("res://Effects/enemy_death_effect.tscn")

@onready var player = get_parent().find_child("Player")
@onready var sprite = $Sprite2D
@onready var animationPlayer = $AnimationPlayer
@onready var hurtbox = $Hurtbox
@onready var meleeAttackDir = $FiniteStateMachine/MeleeAttack/MeleeAOE
@export var KNOCKOUT_RANGE = 600
@onready var bossHealthbar = $UI/BossHealthbar
@onready var healthbar = $Healthbar
@onready var damage_numbers_origin = $DamageNumbersOrigin
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer
@onready var stats = $Stats

var direction : Vector2
 
func _ready():
	set_physics_process(false)
	healthbar.max_value = stats.health
	bossHealthbar.max_value = stats.health
	healthbar.init_health(stats.health)  # Corrected function name
	bossHealthbar.init_health(stats.health)

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
	velocity = direction.normalized() * 45
	move_and_collide(velocity * delta)
 
func take_damage(area):
	var is_critical = false
	var damage_taken

	if area.damage - stats.DEF > 0:
		damage_taken = (area.damage - stats.DEF)
	else:
		damage_taken = area.damage

	var critical_chance = randf()

	if critical_chance <= 0.10:
		is_critical = true
		var critical_multiplier = randf_range(1.2, 2)
		damage_taken *= critical_multiplier

	stats.health -= damage_taken
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)
	DamageNumbers.display_number(damage_taken, damage_numbers_origin.global_position, is_critical)

func _on_hurtbox_area_entered(area):
	if stats.health > 0:
		take_damage(area)
	if stats.health < 0:
		# Handle health reaching zero or below
		find_child("FiniteStateMachine").change_state("Death")
		var enemyDeathEffect = EnemyDeathEffect.instantiate()
		get_parent().add_child(enemyDeathEffect)
		enemyDeathEffect.global_position = global_position
	elif stats.health <= stats.max_health / 2  and stats.DEF == 0:  # Phase two of the fight he gets tankier
		stats.DEF = 5
		find_child("FiniteStateMachine").change_state("ArmorBuff") 
		
	healthbar.health = stats.health 
	bossHealthbar.health = stats.health
	
	var direction = ( position - area.owner.position ).normalized()
	var knockback = direction * KNOCKOUT_RANGE
	velocity = knockback
	move_and_slide()
	
func _on_hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
