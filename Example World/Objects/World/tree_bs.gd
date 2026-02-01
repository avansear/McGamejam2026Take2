extends Node3D

@export_dir var tree_folder: String = "res://Assets/Trees/"
@export var terrain: Terrain3D
@export var player: Node3D
@export var total_trees: int = 50
@export var scatter_range: float = 250.0
@export var min_distance: float = 15.0 
@export var bury_depth: float = 5.0
@export var tree_scale: float = 1.0

var spawned_positions = [] 

func _ready():
	# SAFETY: Delete any trees leftover from previous editor runs
	for child in get_children():
		child.queue_free()
	
	# Wait for the engine to initialize positions
	await get_tree().process_frame
	
	if not terrain or not player: 
		print("DEBUG: Missing Terrain or Player in the Inspector!")
		return
	
	var tree_paths = _scan_folder(tree_folder)
	if tree_paths.size() == 0:
		print("DEBUG: No .glb files found in: ", tree_folder)
		return
		
	var tr_data = terrain.data
	var center = player.global_position
	spawned_positions.clear()
	
	for i in range(total_trees):
		var path = tree_paths[i % tree_paths.size()]
		var found = false
		var final_pos = Vector3.ZERO
		
		# Give the script 75 tries to find a valid, non-crowded spot
		for attempt in range(75): 
			var offset = Vector3(
				randf_range(-scatter_range, scatter_range), 
				0, 
				randf_range(-scatter_range, scatter_range)
			)
			var test_pos = center + offset
			
			# 1. Check if the painted texture is Grass (ID 0)
			if int(tr_data.get_texture_id(test_pos).x) == 0:
				
				# 2. Check Distance from other already-spawned trees
				var too_close = false
				for pos in spawned_positions:
					if test_pos.distance_to(pos) < min_distance:
						too_close = true
						break
				
				if not too_close:
					final_pos = test_pos
					# Snaps to height and applies the bury offset
					final_pos.y = tr_data.get_height(final_pos) - bury_depth
					found = true
					break
		
		if found:
			spawned_positions.append(final_pos) 
			var tree_scene = load(path).instantiate()
			_place_tree_with_collision(tree_scene, final_pos)

func _place_tree_with_collision(tree, pos):
	add_child(tree)
	tree.global_position = pos
	# Apply the tree_scale with a slight random variation for realism
	tree.scale = Vector3.ONE * randf_range(tree_scale * 0.8, tree_scale * 1.2)
	tree.rotate_y(randf_range(0, TAU))
	
	# CREATE COLLISION: Adds a physical hitbox to the trunk
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	
	# Adjust these if the hitbox feels too small or large
	shape.height = 12.0
	shape.radius = 1.2 
	
	col.shape = shape
	sb.add_child(col)
	tree.add_child(sb)
	
	# Keep the hitbox at ground level even if the tree is buried
	col.position.y = (shape.height / 2.0) + bury_depth

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
