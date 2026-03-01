extends CharacterBody2D

const SPEED = 220.0
const JUMP_VELOCITY = -320.0

var current_gesture = "None"

@onready var anim = $AnimatedSprite2D

func _ready():
	GestureManager.gesture_up.connect(_on_gesture_up)
	GestureManager.gesture_left.connect(_on_gesture_left)
	GestureManager.gesture_right.connect(_on_gesture_right)
	GestureManager.gesture_none.connect(_on_gesture_none)

func _on_gesture_up():
	current_gesture = "Up"

func _on_gesture_left():
	current_gesture = "Left"

func _on_gesture_right():
	current_gesture = "Right"

func _on_gesture_none():
	current_gesture = "None"

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += 800 * delta

	# Movement - stops instantly when hand drops
	if current_gesture == "Right":
		velocity.x = SPEED
	elif current_gesture == "Left":
		velocity.x = -SPEED
	else:
		velocity.x = 0.0

	# Jump continuously while Up is held
	if current_gesture == "Up" and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	update_animation()

func update_animation():
	if velocity.x > 10:
		anim.flip_h = false
	elif velocity.x < -10:
		anim.flip_h = true

	if not is_on_floor():
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")
	elif abs(velocity.x) > 10:
		anim.play("run")
	else:
		anim.play("idle")
