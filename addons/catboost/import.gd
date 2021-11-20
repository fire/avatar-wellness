@tool
extends EditorScenePostImport


func _post_import(scene):
	_write_test(scene)
	return scene

var catboost = load("res://addons/catboost/catboost.gd")

func _write_test(scene):	
	var file = File.new()
	file.open(catboost.train_description_path, File.WRITE)
	var init_dict = catboost.bone_create()
	var description : PackedStringArray = init_dict.description
	var file_string : String
	for string in description:
		file_string += string + "\n"
	file.store_string(file_string)
	var file_description = File.new()
	file.open(catboost.train_path, File.WRITE)
	var vrm_extension = scene
	var bone_map : Dictionary
	var human_map : Dictionary
	if vrm_extension.get("vrm_meta"):
		human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
	var keys = human_map.keys()
	for key in keys:
		bone_map[human_map[key]] = key
	var queue : Array # Node
	queue.push_back(scene)
	while not queue.is_empty():
		var front = queue.front()
		var node = front
		if node is AnimationPlayer:
			var ap : AnimationPlayer = node
			var anims = node.get_animation_list()
			for anim_i in anims:
				var animation = node.get_animation(anim_i)
				ap.play(animation.resource_name)
				ap.stop(true)
				var anim_length : float = animation.length
				for vrm_def_bone_name in catboost.vrm_humanoid_bones:
					for track_i in animation.get_track_count():
						var path : String = animation.track_get_path(track_i)
						if str(path).find(":") == -1:
							continue
						var bone_name = path.split(":")[1]
						var new_path = path.split(":")[0]
						var skeleton_node = scene.get_node(new_path)
						if not skeleton_node is Skeleton3D:
							continue
						var skeleton : Skeleton3D = skeleton_node
						var fps : int = 30
						var count : int = anim_length * fps
						for count_i in count:
							ap.seek(float(count_i) / fps, true)
							var bone_i = skeleton.find_bone(bone_name)
							var title : String
							var author : String
							var columns_description : PackedStringArray
							var first : bool = true
							var bone : Dictionary = catboost.bone_create().bone
							bone["BONE"] = bone_name
							if catboost.vrm_humanoid_bones.has(bone_name):
								bone["VRM_BONE"] = bone_name
							else:
								bone["VRM_BONE"] = vrm_def_bone_name
								bone["Lable"] = 0
							var bone_pose = skeleton.get_bone_global_pose(bone_i)
							bone["Bone X global location in meters"] = bone_pose.origin.x
							bone["Bone Y global location in meters"] = bone_pose.origin.y
							bone["Bone Z global location in meters"] = bone_pose.origin.z
							var basis = bone_pose.basis.orthonormalized()
							bone["Bone truncated normalized basis axis x 0"] = basis.x.x
							bone["Bone truncated normalized basis axis x 1"] = basis.x.y
							bone["Bone truncated normalized basis axis x 2"] = basis.x.z
							bone["Bone truncated normalized basis axis y 0"] = basis.y.x
							bone["Bone truncated normalized basis axis y 1"] = basis.y.y
							bone["Bone truncated normalized basis axis y 2"] = basis.y.z
							var scale = bone_pose.basis.get_scale()
							bone["Bone X global scale in meters"] = scale.x
							bone["Bone Y global scale in meters"] = scale.y
							bone["Bone Z global scale in meters"] = scale.z
							var bone_parent = skeleton.get_bone_parent(bone_i)
							if bone_parent != -1:
								var bone_parent_pose = skeleton.get_bone_global_pose(bone_parent)
								bone["Bone Parent X global location in meters"] = bone_pose.origin.x
								bone["Bone Parent Y global location in meters"] = bone_pose.origin.y
								bone["Bone Parent Z global location in meters"] = bone_pose.origin.z
								var parent_basis = bone_parent_pose.basis.orthonormalized()
								bone["Bone Parent truncated normalized basis axis x 0"] = parent_basis.x.x
								bone["Bone Parent truncated normalized basis axis x 1"] = parent_basis.x.y
								bone["Bone Parent truncated normalized basis axis x 2"] = parent_basis.x.z
								bone["Bone Parent truncated normalized basis axis y 0"] = parent_basis.y.x
								bone["Bone Parent truncated normalized basis axis y 1"] = parent_basis.y.y
								bone["Bone Parent truncated normalized basis axis y 2"] = parent_basis.y.z
								var parent_scale = bone_parent_pose.basis.get_scale()
								bone["Bone Parent X global scale in meters"] = parent_scale.x
								bone["Bone Parent Y global scale in meters"] = parent_scale.y
								bone["Bone Parent Z global scale in meters"] = parent_scale.z
							bone["Animation Time"] = float(count_i) / fps
							bone["Label"] = 1
							var bone_parent_key = "BONE_PARENT"
							var parent_bone = skeleton.get_bone_name(bone_parent)
							if not parent_bone.is_empty():
								bone[bone_parent_key] = parent_bone
							file.store_csv_line(bone.values(), "\t")
		elif node is Skeleton3D:
			var skeleton : Skeleton3D = node
			var title : String = vrm_extension["vrm_meta"].get("title")
			var author : String = vrm_extension["vrm_meta"].get("author")
			for vrm_def_bone_name in catboost.vrm_humanoid_bones:
				for bone_i in skeleton.get_bone_count():
					var bone : Dictionary = catboost.bone_create().bone
					var bone_pose = skeleton.get_bone_global_pose(bone_i)
					bone["Bone X global location in meters"] = bone_pose.origin.x
					bone["Bone Y global location in meters"] = bone_pose.origin.y
					bone["Bone Z global location in meters"] = bone_pose.origin.z
					var basis = bone_pose.basis.orthonormalized()
					bone["Bone truncated normalized basis axis x 0"] = basis.x.x
					bone["Bone truncated normalized basis axis x 1"] = basis.x.y
					bone["Bone truncated normalized basis axis x 2"] = basis.x.z
					bone["Bone truncated normalized basis axis y 0"] = basis.y.x
					bone["Bone truncated normalized basis axis y 1"] = basis.y.y
					bone["Bone truncated normalized basis axis y 2"] = basis.y.z
					var scale = bone_pose.basis.get_scale()
					bone["Bone X global scale in meters"] = scale.x
					bone["Bone Y global scale in meters"] = scale.y
					bone["Bone Z global scale in meters"] = scale.z
					var bone_parent = skeleton.get_bone_parent(bone_i)
					if bone_parent != -1:
						var bone_parent_pose = skeleton.get_bone_global_pose(bone_parent)
						bone["Bone parent X global location in meters"] = bone_pose.origin.x
						bone["Bone parent Y global location in meters"] = bone_pose.origin.y
						bone["Bone parent Z global location in meters"] = bone_pose.origin.z
						var parent_basis = bone_parent_pose.basis.orthonormalized()
						bone["Bone parent truncated normalized basis axis x 0"] = parent_basis.x.x
						bone["Bone parent truncated normalized basis axis x 1"] = parent_basis.x.y
						bone["Bone parent truncated normalized basis axis x 2"] = parent_basis.x.z
						bone["Bone parent truncated normalized basis axis y 0"] = parent_basis.y.x
						bone["Bone parent truncated normalized basis axis y 1"] = parent_basis.y.y
						bone["Bone parent truncated normalized basis axis y 2"] = parent_basis.y.z
						var parent_scale = bone_parent_pose.basis.get_scale()
						bone["Bone parent X global scale in meters"] = parent_scale.x
						bone["Bone parent Y global scale in meters"] = parent_scale.y
						bone["Bone parent Z global scale in meters"] = parent_scale.z
					bone["BONE"] = skeleton.get_bone_name(bone_i)
					var parent_bone = skeleton.get_bone_name(bone_parent)
					if not parent_bone.is_empty():
						bone[ "BONE_PARENT"] = parent_bone
					var version = vrm_extension["vrm_meta"].get("specVersion")
					if version == null:
						version = ""
					bone["SPECIFICATION_VERSION"] = version
					bone["ANIMATION"] = "VRM Character in T-Pose"
					if bone_map.has(bone["BONE"]):						
						bone["VRM_BONE"] = bone_map[bone["BONE"]]
						bone["Label"] = 1
					else:
						bone["VRM_BONE"] = vrm_def_bone_name
						bone["Label"] = 0
					file.store_csv_line(bone.values(), "\t")
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
	file.close()
