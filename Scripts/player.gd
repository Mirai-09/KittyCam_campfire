extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -200.0
const HOLD_FRAMES = 8

var gesture_candidate = "None"
var gesture_hold_count = 0
var confirmed_gesture = "None"
var was_jumping = false

@onready var anim = $AnimatedSprite2D

func get_dominant_gesture() -> String:
	var raw_left  = JavaScriptBridge.eval("(typeof getGestureProb !== 'undefined') ? getGestureProb('Left') : 0;")
	var raw_right = JavaScriptBridge.eval("(typeof getGestureProb !== 'undefined') ? getGestureProb('Right') : 0;")
	var raw_up    = JavaScriptBridge.eval("(typeof getGestureProb !== 'undefined') ? getGestureProb('Up') : 0;")

	if raw_left  == null: raw_left  = 0.0
	if raw_right == null: raw_right = 0.0
	if raw_up    == null: raw_up    = 0.0

	if Engine.get_process_frames() % 60 == 0:
		print("RAW -> L: %.2f | R: %.2f | U: %.2f" % [raw_left, raw_right, raw_up])

	var highest_val = max(raw_left, max(raw_right, raw_up))
	if highest_val < 0.75:
		return "None"

	if raw_left == highest_val:
		return "Left"
	elif raw_right == highest_val:
		return "Right"
	elif raw_up == highest_val:
		return "Up"

	return "None"

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += 500 * delta

	var raw_dominant = get_dominant_gesture()

	if raw_dominant == gesture_candidate and raw_dominant != "None":
		gesture_hold_count += 1
		if gesture_hold_count >= HOLD_FRAMES:
			if confirmed_gesture != gesture_candidate:
				confirmed_gesture = gesture_candidate
				print("✅ Confirmed gesture: ", confirmed_gesture)
	elif raw_dominant == "None":
		gesture_hold_count -= 1
		if gesture_hold_count <= 0:
			gesture_hold_count = 0
			gesture_candidate = "None"
			confirmed_gesture = "None"
	else:
		gesture_candidate = raw_dominant
		gesture_hold_count = 1

	if confirmed_gesture == "Right":
		velocity.x = SPEED
	elif confirmed_gesture == "Left":
		velocity.x = -SPEED
	else:
		velocity.x = 0.0

	if confirmed_gesture == "Up" and is_on_floor() and not was_jumping:
		velocity.y = JUMP_VELOCITY
		was_jumping = true
	if confirmed_gesture != "Up":
		was_jumping = false

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
