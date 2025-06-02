extends Node

enum CharacterRelationship {
	SELF,
	ALLY,
	NEUTRAL,
	ENEMY,
}

enum TargetingType {
	SINGLE,
	AREA_CONE,
	AREA_LINE,
	AREA_SPHERE,
}

enum Effect_type {
	DAMAGE,
	STATUS,
	HEAL,
}

class Status:
	var status_name: String
	var duration: int
	
	static func create(new_name: String, new_duration: int) -> Status:
		var instance = Status.new()
		instance.status_name = new_name
		instance.duration = new_duration
		return instance
