extends MultiMeshInstance3D

@export var terrain: Terrain3D
@export var player: Node3D 
@export var grass_id: int = 0 
@export var scatter_range: float = 250.0 

# Scale controls to make the grass look thicker
@export var base_scale: float = 1.0     
@export var random_scale: float = 0.5   

func _ready():
	await get_tree().process_frame
	
	if not terrain or not player or not multimesh:
		return
	
	# Using 'data' property directly to avoid the red error in your screenshot
	var tr_data = terrain.data
	var mm = multimesh
	var center = player.global_position 
	
	for i in range(mm.instance_count):
		var found = false
		var final_pos = Vector3.ZERO
		
		# INCREASED ATTEMPTS: Give each blade 50 tries to find a green spot
		for attempt in range(50):
			var offset = Vector3(
				randf_range(-scatter_range, scatter_range), 
				0, 
				randf_range(-scatter_range, scatter_range)
			)
			var test_pos = center + offset
			
			if int(tr_data.get_texture_id(test_pos).x) == grass_id:
				final_pos = test_pos
				final_pos.y = tr_data.get_height(final_pos)
				found = true
				break
		
		if found:
			# Randomized scale makes it look way more dense
			var s_var = randf_range(base_scale - random_scale, base_scale + random_scale)
			var basis = Basis().rotated(Vector3.UP, randf_range(0, TAU)).scaled(Vector3(s_var, s_var, s_var))
			mm.set_instance_transform(i, Transform3D(basis, final_pos))
		else:
			# Hide if no grass was found after 50 tries
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
