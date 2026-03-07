extends Area2D

@onready var timer = $Timer

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	timer.timeout.connect(_on_timer_timeout)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("You died!")
		timer.start()

func _on_timer_timeout():
	get_tree().reload_current_scene()
