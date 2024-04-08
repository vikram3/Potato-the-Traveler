extends Control

var hearts = 4:
	set = set_hearts
var max_hearts = 4:
	set = set_max_hearts
	
@onready var label = $Label
@onready var heartUIFull = $HeartUIFull
@onready var heartUIEmpty = $HeartUIEmpty
@onready var LOW_HEALTH = PlayerStats.max_health * 0.25
@onready var HALF_HEALTH = PlayerStats.max_health * 0.5

func _physics_process(delta):
	update_healthbar()

func update_healthbar():
	var healthbar = $HealthBar
	healthbar.max_value = PlayerStats.max_health
	healthbar.value = PlayerStats.health
	healthbar.visible = true
	
	if PlayerStats.health <= HALF_HEALTH and PlayerStats.health > LOW_HEALTH:
		#Much hp has been lost turn yellow
		healthbar.modulate = Color(1,1,0)
	elif PlayerStats.health <= LOW_HEALTH:
		#Health is critical, turn red
		healthbar.modulate = Color(1, 0, 0)

func set_hearts(value):
	hearts = clampi(value, 0, max_hearts)
	if heartUIFull != null:
		heartUIFull.size.x = hearts * 15
	if label != null:
		label.text = "HP: " + str(hearts)
	
func set_max_hearts(value):
	max_hearts = max(value, 1)
	self.hearts = min(hearts, max_hearts)
	if heartUIEmpty != null:
		heartUIEmpty.size.x = max_hearts * 15
		
func _ready():
	self.max_hearts = PlayerStats.max_health
	self.hearts = PlayerStats.health
	PlayerStats.health_changed.connect(set_hearts)
	PlayerStats.max_health_changed.connect(set_max_hearts)
	

