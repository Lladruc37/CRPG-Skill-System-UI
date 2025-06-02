class_name UI

extends CanvasLayer

@export var skill_buttons_holder: HBoxContainer
var player_skills: Array[Skill]

# Once the skill button has been pressed
signal on_skill_button_pressed(skill_name: String)
# Once the character button has been pressed
signal on_character_button_pressed(character_name: String)
# Once the skill targeting has ended
signal on_done_targeting

func _ready() -> void:
	var buttonsNodes = skill_buttons_holder.get_children()
	for button in buttonsNodes:
		button.connect("skill_pressed",self._on_skill_button_pressed)

func _on_character_send_player_skills(skill_data: Array[Skill]) -> void:
	# The player sends their skill info to fill the hotbar
	player_skills = skill_data
	var buttonsNodes = skill_buttons_holder.get_children()
	for i: int in buttonsNodes.size():
		var button = buttonsNodes[i]
		button = button as SkillButton
		button.reset_button()
	
	for i: int in skill_data.size():
		var button = buttonsNodes[i]
		button = button as SkillButton
		button.disabled = false
		button.skill_name = skill_data[i].skill_name
		button.skill_icon.texture = skill_data[i].skill_icon
	
	print("skills added")
	
	# Focus
	var first_button = skill_buttons_holder.get_children().front() as Button
	var last_button = skill_buttons_holder.get_children().back() as Button
	first_button.focus_neighbor_left = last_button.get_path()
	last_button.focus_neighbor_right = first_button.get_path()

func _on_skill_button_pressed(skill_name: String) -> void:
	print(skill_name + " was pressed")
	on_skill_button_pressed.emit(player_skills.filter(func(skill): return skill.skill_name == skill_name).front())

func _on_targets_selected(_targets: Array[Character]) -> void:
	print("RESET BUTTONS")
	# Reset buttons
	var buttons = skill_buttons_holder.get_children() as Array[Button]
	for button in buttons:
		button.button_pressed = false
	
	on_done_targeting.emit()

func _on_connect_character_to_signal(character: Character) -> void:
	# Connect all character signals to UI
	self.connect("on_skill_button_pressed",character._on_ui_skill_button_pressed)
	self.connect("on_character_button_pressed",character._on_ui_character_button_pressed)
	self.connect("on_done_targeting",character.done_targeting)

func _on_character_button_pressed(character_name: String) -> void:
	print("Character button pressed")
	_on_targets_selected([])
	on_character_button_pressed.emit(character_name)
