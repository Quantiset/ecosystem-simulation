extends TextureProgressBar

var green = preload("res://Assets/barHorizontal_green_mid 200.png")
var yellow = preload("res://Assets/barHorizontal_yellow_mid 200.png")

func _ready():
	texture_progress = green
	$TextureProgressBar.texture_progress = yellow

func updateHealth(amount1, amount2):
	value = amount1
	$TextureProgressBar.value = amount2
