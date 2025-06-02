class_name  Skill

extends Node

@export var skill_name: String
@export var skill_icon: CompressedTexture2D
@export var skill_caster: Character
@export var skill_range: float

# Targeting
@export var targeting_type: Globals.TargetingType = Globals.TargetingType.SINGLE
@export var targeting_filters: Array[Globals.CharacterRelationship]

# Effect
@export var effect: Globals.Effect_type = Globals.Effect_type.DAMAGE
@export var effect_amount: float = 1.0 # damage or heal amount, if status = 1
@export var status_name: String
@export var status_duration: int = 1
