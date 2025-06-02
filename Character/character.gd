class_name Character

extends Node3D

enum CharacterBody {
	BARBARIAN,
	KNIGHT,
	MAGE,
	ROGUE,
}

@export var character_name: String
@export var relationship: Globals.CharacterRelationship = Globals.CharacterRelationship.NEUTRAL

# Health and Status
var active_status_array: Array[Globals.Status]
@export var max_health: float = 100.0
@export var health: float = 100.0:
	set(value):
		var previous_health = health
		health = clamp(value, 0, max_health)
		
		if health < previous_health:
			print(character_name + " took " + str(previous_health - health) + " damage")
			if health == 0:
				print(character_name + " died!")
				character_died()
		elif health > previous_health:
			print(character_name + " was healed " + str(health - previous_health) + " health")

@export var is_current_player_character: bool = false
var is_character_alive: bool = true
var valid_for_targeting: bool = false

# Markers
var marker: Node3D
var range_marker_instance: MeshInstance3D
var range_marker = preload("res://Camera/Markers/range_marker.tscn")
var sphere_marker = preload("res://Camera/Markers/sphere_marker.tscn")
var line_marker = preload("res://Camera/Markers/line_marker.tscn")
var cone_marker = preload("res://Camera/Markers/cone_marker.tscn")
@export var camera: Camera3D

# Body and Material
@export var selected_material_hover: StandardMaterial3D
@export var character_body: CharacterBody = CharacterBody.KNIGHT
var selected_body: Node3D
@export var barbarian_body: Node3D
@export var knight_body: Node3D
@export var mage_body: Node3D
@export var rogue_body: Node3D

# Skills
@export var skills_parent: Node
var skill_being_cast: Skill
var character_skills: Array[Skill]

# Connects signals between characters and Camera & UI
signal connect_character_to_signal(character: Character)
# Send the Camera and the UI the player skill data
signal send_player_skills(skill_data: Array[Skill])
# Signal all characters the target/s that have been selected
signal targets_selected(targets: Array[Character])

func _ready() -> void:
	connect_character_to_signal.emit(self)
	
	# Skills
	var skills = skills_parent.get_children()
	for skillNode in skills:
		var skill = skillNode as Skill
		skill.skill_caster = self
		character_skills.append(skill)
	
	if is_current_player_character:
		send_player_skills.emit(character_skills)
	
	# Character body
	match character_body:
		CharacterBody.BARBARIAN:
			selected_body = barbarian_body
		CharacterBody.KNIGHT:
			selected_body = knight_body
		CharacterBody.MAGE:
			selected_body = mage_body
		CharacterBody.ROGUE:
			selected_body = rogue_body
		_:
			print("Error: No body was selected!")
	
	selected_body.show()
	
func _process(_delta: float) -> void:
	# Update markers if active
	if is_current_player_character && skill_being_cast != null && marker != null:
		var final_position: Vector3 = camera.shoot_ray()
		if skill_being_cast.targeting_type == Globals.TargetingType.AREA_SPHERE:
			if final_position == Vector3.ZERO:
				final_position = marker.position
			var origin_position = skill_being_cast.skill_caster.position
			marker.position = origin_position.move_toward(final_position,skill_being_cast.skill_range)
		elif final_position != Vector3.ZERO:
			# Locking Y position in order to lock the rotation in the XZ axis
			final_position.y = marker.position.y
			marker.transform = marker.transform.looking_at(final_position)
		await get_tree().create_timer(0.01).timeout

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Click"):
		if skill_being_cast == null || marker == null:
			return
			
		print("no longer targeting")
		
		if is_current_player_character:
			select_marker_targets()
		
		done_targeting()

func done_targeting() -> void:
	skill_being_cast = null
	valid_for_targeting = false
	
	if range_marker_instance != null:
		range_marker_instance.queue_free()
		range_marker_instance = null
	
	if marker == null:
		return
	marker.queue_free()
	marker = null

func select_marker_targets() -> void:
	var marker_area = marker.get_child(0).get_child(0) as Area3D
	var marker_areas = marker_area.get_overlapping_areas()
	if marker_areas.size() == 0:
		return
		
	var target_areas = marker_areas.filter(func(area): return area.is_in_group("character"))
	if target_areas.size() == 0:
		return
	
	# Get targets from marker
	var targets: Array[Character]
	for area in target_areas:
		var character_node = area.get_parent()
		if character_node:
			var character = character_node as Character
			targets.append(character)
	
	if marker_area.is_in_group("marker_not_self"):
		targets.remove_at(targets.find(self))
	
	var alive_targets = targets.filter(func(target): return target.is_character_alive)
	targets_selected.emit(alive_targets)

func _on_selection_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# If the player clicks while the mouse is within the area of a character
	# Only that character will do this code
	if event.is_action_pressed("Click"):
		if !valid_for_targeting:
			return
			
		print("Selected target " + character_name)
		var array: Array[Character]
		array.append(self)
		targets_selected.emit(array)

func _on_selection_area_mouse_entered() -> void:
	if !valid_for_targeting:
		return
	
	print("MOUSE ENTERED")
	set_material(true)

func _on_selection_area_mouse_exited() -> void:
	if !valid_for_targeting:
		return
	
	print("MOUSE EXITED")
	set_material(false)

func apply_skill_effects(targets: Array[Character]) -> void:
	for character in targets:
		print(character.character_name + " was affected by the skill " + skill_being_cast.skill_name)
		match skill_being_cast.effect:
			Globals.Effect_type.DAMAGE:
				character.health -= skill_being_cast.effect_amount
			Globals.Effect_type.HEAL:
				character.health += skill_being_cast.effect_amount
			Globals.Effect_type.STATUS:
				var status: Globals.Status = Globals.Status.create(skill_being_cast.status_name, skill_being_cast.status_duration)
				add_status(status)
	
	done_targeting()
	
func _on_selection_area_area_entered(area: Area3D) -> void:
	if !is_character_alive || skill_being_cast == null:
		return
		
	# If marker is set to ignore self and self is the player skip
	if skill_being_cast.skill_caster == self && area.is_in_group("marker_not_self"):
		return
	
	if area.is_in_group("marker") || area.is_in_group("marker_not_self"):
		set_material(true)

func _on_selection_area_area_exited(area: Area3D) -> void:
	if area.is_in_group("marker") || area.is_in_group("marker_not_self") || !is_character_alive:
		set_material(false)

func set_material(is_valid_for_targeting: bool) -> void:
	var material: StandardMaterial3D = selected_material_hover if is_valid_for_targeting else null
	var children = selected_body.find_children("","MeshInstance3D")
	for child in children:
		child.material_override = material

func _on_ui_skill_button_pressed(skill: Skill) -> void:
	# Skill being cast
	# All characters are notified a skill is being cast and prepare to be the target
	# In the case of the player they also in charge of spawning the markers
	if !is_character_alive:
		return
	
	done_targeting()
	skill_being_cast = skill
	
	print(skill.skill_name + " filters:")
	for filter in skill.targeting_filters:
		print(Globals.CharacterRelationship.keys()[filter])
	
	if is_current_player_character:
		create_range_marker()

	if skill.targeting_type == Globals.TargetingType.SINGLE:
		validate_character_for_targeting()
	elif is_current_player_character:
		follow_mouse()
	
func create_range_marker() -> void:
	range_marker_instance = range_marker.instantiate()
	range_marker_instance.position = position
	
	# Create a cylinder with the skill range
	var cylinder = CylinderMesh.new()
	cylinder.bottom_radius = skill_being_cast.skill_range
	cylinder.top_radius = skill_being_cast.skill_range
	cylinder.height = 0.01
	range_marker_instance.mesh = cylinder
	$'../'.add_child(range_marker_instance)
	
func _on_ui_character_button_pressed(new_player_name: String) -> void:
	# New player character selected
	done_targeting()
	
	if character_name == new_player_name:
		is_current_player_character = true
		send_player_skills.emit(character_skills)
		relationship = Globals.CharacterRelationship.SELF
		print(character_name + " is now the active player")
	elif is_current_player_character:
		is_current_player_character = false
		relationship = Globals.CharacterRelationship.ALLY
		print(character_name + " is now an ally")
	
func add_status(status_to_add: Globals.Status) -> void:
	if !is_character_alive:
		return
	
	print(character_name + " gained " + str(status_to_add.duration) + " turns of " + status_to_add.status_name)
	
	for status in active_status_array:
		if status.status_name == status_to_add.status_name:
			status.duration += status_to_add.duration
			return
	
	active_status_array.append(status_to_add)
	
func character_died() -> void:
	is_character_alive = false
	selected_body.hide()

func validate_character_for_targeting() -> void:
	# Decide if the character is valid for targeting according to skill range from the caster and skill filters
	var distance_from_origin: float = position.distance_to(skill_being_cast.skill_caster.position)
	
	print(character_name + " is " + str(distance_from_origin) + " away from caster")
	if distance_from_origin > skill_being_cast.skill_range:
		valid_for_targeting = false
		print(character_name + " is not valid for targeting, out of range!")
		return
	
	if skill_being_cast.targeting_filters.any(func(filter): return filter == relationship):
		valid_for_targeting = true
		print(character_name + " is valid for targeting!")
		return
	
	valid_for_targeting = false
	print(character_name + " is not valid for targeting due to skill filters!")

func _on_targets_selected(targets: Array[Character]) -> void:
	# Once the target/s have been chosen noone is valid for targeting anymore
	# This code is run for the selected target if SINGLE or the player in any other case
	print("TARGETS SELECTED")
	print(character_name + " is applying the skill effects...")
	set_material(false)
	apply_skill_effects(targets)

func follow_mouse() -> void:
	marker = spawn_marker()

func spawn_marker() -> Node3D:
	var final_position: Vector3 = camera.shoot_ray()
	var instance = null
	match skill_being_cast.targeting_type:
		Globals.TargetingType.AREA_CONE:
			instance = cone_marker.instantiate()
			instance.position = position
			instance.transform = instance.transform.looking_at(final_position)
		Globals.TargetingType.AREA_LINE:
			instance = line_marker.instantiate()
			instance.position = position
			instance.transform = instance.transform.looking_at(final_position)
		Globals.TargetingType.AREA_SPHERE:
			instance = sphere_marker.instantiate()
			instance.position = final_position
		_:
			print("Error: Unhandled targeting type")

	print("Added " + (Globals.TargetingType.keys()[skill_being_cast.targeting_type]) + " marker")
	$'../'.add_child(instance)
	return instance
