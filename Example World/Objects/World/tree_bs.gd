extends Node3D

@export_dir var tree_folder: String = "res://Assets/Trees/"
@export var terrain: Terrain3D
@export var player: Node3D
@export var total_trees: int = 15 
@export var scatter_range: float = 400.0
@export var tree_scale: float = 5.0 # Lowered slightly for visibility

func _ready():
	await get_tree().process_frame
	if not terrain or not player: 
		print("DEBUG: Missing Terrain or Player!")
		return
	
	var tree_paths = _scan_folder(tree_folder)
	print("DEBUG: Found ", tree_paths.size(), " glb files in folder.")
	
	var tr_data = terrain.data
	var center = player.global_position
	
	for i in range(total_trees):
		var path = tree_paths[i % tree_paths.size()]
		var tree_scene = load(path).instantiate()
		
		var found = false
		var final_pos = Vector3.ZERO
		
		# Increased attempts to 100 to ensure we find a spot
		for attempt in range(100):
			var offset = Vector3(
				randf_range(-scatter_range, scatter_range), 
				0, 
				randf_range(-scatter_range, scatter_range)
			)
			var test_pos = center + offset
			
			# Check texture and height
			var tex_info = tr_data.get_texture_id(test_pos)
			if int(tex_info.x) == 0: # Check if this is your Grass index
				final_pos = test_pos
				final_pos.y = tr_data.get_height(final_pos)
				found = true
				break
		
		if found:
			print("DEBUG: Spawning tree at ", final_pos)
			_place_tree_with_collision(tree_scene, final_pos)
		else:
			print("DEBUG: Failed to find a grass spot for tree #", i)
			tree_scene.queue_free() # Clean up unused memory

func _place_tree_with_collision(tree, pos):
	add_child(tree)
	tree.global_position = pos
	tree.scale = Vector3.ONE * tree_scale
	tree.rotate_y(randf_range(0, TAU))
	
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = 10.0
	shape.radius = 1.0 
	
	col.shape = shape
	sb.add_child(col)
	tree.add_child(sb)
	col.position.y = shape.height / 2.0

func _scan_folder(path):
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".glb"):
				files.append(path + "/" + file_name)
			file_name = dir.get_next()
	return files
