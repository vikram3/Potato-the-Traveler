extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_parent().find_child("Player")
@onready var playerLastLoc = null

@export var damage = 1
 
var acceleration: Vector2 = Vector2.ZERO 
var velocity: Vector2 = Vector2.ZERO
 
func _physics_process(delta):
	if player != null:
		playerLastLoc = player.position
		acceleration = (playerLastLoc - position).normalized() * 700
 
	velocity += acceleration * delta
	rotation = velocity.angle()
 
	velocity = velocity.limit_length(150)
 
	position += velocity * delta
	 
func _on_body_entered(body):
	queue_free()
