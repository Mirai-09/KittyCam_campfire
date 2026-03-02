extends Control

@onready var score_label = %endscore # replace with your actual label node path

func _ready():
	score_label.text = "Score: " + str(GameManager.score)
