extends Control

@onready var label = $Label
@onready var LOW_HEALTH = PlayerStats.max_health * 0.25
@onready var HALF_HEALTH = PlayerStats.max_health * 0.5

func _physics_process(_delta):
	update_healthbar()

func update_healthbar(): # This controls the Healthbar UI that is on the canvas.
	var healthbar = $HealthBar
	healthbar.max_value = PlayerStats.max_health
	healthbar.value = PlayerStats.health
	#healthbar.visible = true
	
	if PlayerStats.health > HALF_HEALTH:
		healthbar.modulate = Color(0, 1.2, 0) #Green		
	elif PlayerStats.health <= HALF_HEALTH and PlayerStats.health > LOW_HEALTH:
		healthbar.modulate = Color(1,1,0)
	elif PlayerStats.health <= LOW_HEALTH:
		#Health is critical, turn red
		healthbar.modulate = Color(1, 0, 0)
		
	if label != null:
		label.text = "HP: " + str(PlayerStats.health)
	

