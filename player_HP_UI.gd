extends Node

#HealthUI
@onready var LOW_HEALTH = PlayerStats.max_health * 0.25
@onready var HALF_HEALTH = PlayerStats.max_health * 0.5
@onready var timer = $HealthBarTimer
@onready var healthbar = $HealthBar

func ready():
	timer = $HealthBarTimer
	
func _physics_process(delta):
	update_healthbar() 

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
		
	print(PlayerStats.health)
		
	if timer.is_stopped() == true:
		timer.start()

func _on_health_bar_timer_timeout():
	if PlayerStats.health != PlayerStats.max_health:
		PlayerStats.health += 1 # Regen HP
		healthbar.visible = false
