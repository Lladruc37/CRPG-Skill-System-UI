class_name SkillButton

extends Button

var input: int = 0
var skill_name: String
@export var skill_icon: TextureRect
@export var selected: TextureRect

signal skill_pressed(skill_name: String)

func _ready() -> void:
	var child_index = get_parent().get_children().find(self)
	input = (child_index + 1) % 10
	print(str(input) + " input")
	if (child_index + 1) > 10:
		print("Error: Unhandled number of skills in hotbar!")
	
func _on_toggled(toggled_on: bool) -> void:
	if selected == null:
		return
	
	if toggled_on:
		selected.show()
		skill_pressed.emit(skill_name)
		return
	
	selected.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(str(input)):
		print(input)
		button_pressed = true
		grab_focus()

func reset_button() -> void:
	skill_name = ""
	skill_icon.texture = null
	disabled = true
	
