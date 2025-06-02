extends Camera3D

func shoot_ray() -> Vector3:
	var mouse_position = get_viewport().get_mouse_position()
	var ray_length = 1000
	var from = project_ray_origin(mouse_position)
	var to = from + project_ray_normal(mouse_position) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var raycast_result = space.intersect_ray(ray_query)
	
	if !raycast_result.is_empty():
		return raycast_result["position"]
	
	return Vector3.ZERO
