extends Control

var hearts = 4:
	set = set_hearts
var max_hearts = 4:
	set = set_max_hearts
	
@onready var label = $Label
@onready var heartUIFull = $HeartUIFull
@onready var heartUIEmpty = $HeartUIEmpty

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
	

