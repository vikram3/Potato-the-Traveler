extends StaticBody2D

var state = "night"

var change_state = false

var length_of_day = 15
var length_of_night = 8

func _ready():
	if state == "day":
		$AnimationPlayer.play("Transition to Day")
	elif state == "night":
		$AnimationPlayer.play("Transition to Night")

func _on_timer_timeout():
	if state == "day":
		state = "night"
	elif state == "night":
		state = "day"
		
	change_state = true
	
func _process(delta):
	if change_state == true:
		change_state = false
		if state == "day":
			changeToDay()
		elif state == "night":
			changeToNight()
			
func changeToDay():
	$AnimationPlayer.play("Transition to Day")
	$Timer.start()
	
func changeToNight():
	$AnimationPlayer.play("Transition to Night")
	$Timer.start()
