extends SceneTree

class Background extends "res://scripts/game_view.gd":
	var map := "frontyard"
	var extended := false
	func is_wildland_level() -> bool: return map=="wildland"
	func is_wasteland_level() -> bool: return map!="frontyard"
	func _draw() -> void: draw_world_static(extended)

func _init() -> void: call_deferred("bake")

func bake() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/backgrounds")
	for map in ["frontyard","wasteland","wildland"]:
		for extended in [false,true]:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(1930 if extended else 1280,720)
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			root.add_child(viewport)
			var background := Background.new()
			background.map = map
			background.extended = extended
			viewport.add_child(background)
			await process_frame
			await RenderingServer.frame_post_draw
			var key: String = map+("_extended" if extended else "")
			assert(viewport.get_texture().get_image().save_png("res://assets/backgrounds/"+key+".png")==OK)
			viewport.queue_free()
	print("BACKGROUND_BAKE_OK")
	quit()
