extends Node2D

var current_scene = "world"
var transition_scene = false

var player_exit_boss_posx = 143
var player_exit_boss_posy = -25

var player_start_posx = 153
var player_start_posy = 107

var game_first_loadin = true

func finish_changescenes():
	if transition_scene == true:
		transition_scene = false
		if current_scene == "world":
			current_scene = "boss_room"
		else:
			current_scene = "world"