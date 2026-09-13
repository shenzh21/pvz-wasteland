extends SceneTree

const Art := preload("res://scripts/garden_art.gd")
const Batch := preload("res://scripts/plant_batch2_art.gd")
const Third := preload("res://scripts/plant_batch3_art.gd")
const Fourth := preload("res://scripts/plant_batch4_art.gd")

class Plant extends Node2D:
	var art_parent_transform := Transform2D.IDENTITY
	var kind := "pea"
	var time := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0,0,256,256),Color("#e5edcd"))
		if kind in Art.KINDS: Art.plant(self,kind,Vector2(128,135),2,time)
		elif kind in Third.KINDS: Third.draw(self,kind,Vector2(128,135),2,time)
		elif kind in Fourth.KINDS: Fourth.draw(self,kind,Vector2(128,135),2,time)
		else: Batch.draw(self,kind,Vector2(128,135),2,time)

class Source extends Plant:
	var force_blink := false
	func begin_art_part(_name: String) -> void: pass
	func push_eye_part() -> void: pass
	func pop_eye_part() -> void: pass

class Background extends "res://scripts/game_view.gd":
	var map := "frontyard"
	var cached := false
	func is_wildland_level() -> bool: return map=="wildland"
	func is_wasteland_level() -> bool: return map!="frontyard"
	func _draw() -> void:
		set_world_draw_offset(Vector2(-400,0))
		if cached: draw_texture(CachedBackground.get_texture(map,true),Vector2.ZERO)
		else: draw_world_static(true)
		set_world_draw_offset(Vector2.ZERO)

func _init() -> void: call_deferred("test")

func capture(node: Node2D, size: Vector2i) -> Image:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(viewport)
	viewport.add_child(node)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	viewport.queue_free()
	return result

func error(a: Image,b: Image) -> float:
	var total := 0.0
	for y in range(0,a.get_height(),2):
		for x in range(0,a.get_width(),2):
			var first := a.get_pixel(x,y)
			var second := b.get_pixel(x,y)
			total += absf(first.r-second.r)+absf(first.g-second.g)+absf(first.b-second.b)
	return total/(a.get_width()*a.get_height()*0.75)

func test() -> void:
	var kinds: Array = Art.KINDS+Batch.KINDS+["mine_hidden","yam_minion"]+Third.KINDS+Fourth.KINDS
	var sheet := Image.create(6*256,ceili(kinds.size()/6.0)*512,false,Image.FORMAT_RGBA8)
	for i in kinds.size():
		var source := Source.new()
		source.kind = kinds[i]
		var cached := Plant.new()
		cached.kind = kinds[i]
		var original := await capture(source,Vector2i(256,256))
		var optimized := await capture(cached,Vector2i(256,256))
		var diff := error(original,optimized)
		assert(diff<0.001,"静态造型变化过大: "+kinds[i])
		print("ART_COMPARE ",kinds[i]," mean_rgb_error=",diff)
		sheet.blit_rect(original,Rect2i(0,0,256,256),Vector2i(i%6*256,int(i/6)*512))
		sheet.blit_rect(optimized,Rect2i(0,0,256,256),Vector2i(i%6*256,int(i/6)*512+256))
		var animated := Plant.new()
		animated.kind = kinds[i]
		animated.time = 4.8 if i>=6 else 4.6
		var animation := await capture(animated,Vector2i(256,256))
		if kinds[i]!="mine_hidden": assert(error(optimized,animation)>0.00001)
	for map in ["frontyard","wasteland","wildland"]:
		var source := Background.new()
		source.map = map
		var cached := Background.new()
		cached.map = map
		cached.cached = true
		var original := await capture(source,Vector2i(1280,720))
		var optimized := await capture(cached,Vector2i(1280,720))
		var diff := error(original,optimized)
		assert(diff<0.003,"背景/镜头偏移变化过大: "+map)
		print("BACKGROUND_COMPARE ",map," mean_rgb_error=",diff)
	assert(sheet.save_png("res://dist/cache-art-comparison.png")==OK)
	print("CACHED_ART_TEST_OK")
	quit()
