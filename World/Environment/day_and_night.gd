extends StaticBody2D

var state = "night"

var change_state = false
@onready var weatherUI = $WeatherUI

#Length of the day is based on the current timer's length
# 5 minutes a day (300 seconds)
func _ready():
	if state == "day":
		weatherUI.get_child(0).visible = true
		weatherUI.get_child(1).visible = false
		$AnimationPlayer.play("Transition to Day")
	elif state == "night":
		#$AnimationPlayer.play("Transition to Night")
		weatherUI.get_child(0).visible = false
		weatherUI.get_child(1).visible = true

func _on_timer_timeout():
	if state == "day":
		state = "night"
	elif state == "night":
		state = "day"
		
	change_state = true
	
func _process(_delta):
	if change_state == true:
		change_state = false
		if state == "day":
			changeToDay()
		elif state == "night":
			changeToNight()
			
func changeToDay():
	weatherUI.get_child(0).visible = true
	weatherUI.get_child(1).visible = false
	$AnimationPlayer.play("Transition to Day")
	$Timer.start()
	
func changeToNight():
	weatherUI.get_child(0).visible = false
	weatherUI.get_child(1).visible = true
	$AnimationPlayer.play("Transition to Night")
	$Timer.start()
