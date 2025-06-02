extends Button

@export var selected: TextureRect
@export var character_name: String

signal on_character_button_pressed(character_name: String)

func _on_toggled(toggled_on: bool) -> void:
	if selected == null:
		return
	
	if toggled_on:
		selected.show()
		on_character_button_pressed.emit(character_name)
		return
	
	selected.hide()
