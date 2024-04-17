extends State
 
@onready var collision = $"../../PlayerDetection/CollisionShape2D"
@onready var progress_bar = owner.find_child("BossHealthbar")
@onready var overhead_health_bar = owner.find_child("Healthbar")
 
var player_entered: bool = false:
	set(value):
		player_entered = value
		collision.set_deferred("disabled", value)
		progress_bar.set_deferred("visible",value)
		overhead_health_bar.set_deferred("visible",value)
		
func transition():
	if player_entered:
		get_parent().change_state("Follow")
 
func _on_player_detection_body_entered(body):
	if body.has_method("player"):
		print("player in detection zone")
		player_entered = true


