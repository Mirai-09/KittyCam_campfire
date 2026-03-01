extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	JavaScriptBridge.eval("console.log('Godot connected to JS');")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var result = JavaScriptBridge.eval("getGesture();")
	if result == "Up":
		print("Up")
