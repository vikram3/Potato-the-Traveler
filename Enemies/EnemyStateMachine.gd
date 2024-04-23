extends Node2D
 
var current_state: EnemyState
var previous_state: EnemyState
@onready var start_position = global_position
@onready var target_position = global_position
 
func _ready():
	current_state = get_child(0) as EnemyState
	previous_state = current_state
	current_state.enter()
 
func change_state(state):
	current_state = find_child(state) as EnemyState
	current_state.enter()
 
	previous_state.exit()
	previous_state = current_state

