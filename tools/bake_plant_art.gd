extends SceneTree

# 开发期生成透明部件图集；不在玩家游戏内创建截图或写文件。
const Art := preload("res://scripts/garden_art.gd")
const Batch := preload("res://scripts/plant_batch2_art.gd")
const Third := preload("res://scripts/plant_batch3_art.gd")
const Fourth := preload("res://scripts/plant_batch4_art.gd")
const CELL := 256
const COLUMNS := 16

class Recorder extends RefCounted:
	var art_parent_transform := Transform2D.IDENTITY
	var transform := Transform2D.IDENTITY
	var force_blink := false
	var sections: Array = []
	var current := "body"
	var previous := "body"
	func begin_art_part(name: String) -> void:
		current = name
		sections.append({"name":name,"commands":[]})
	func push_eye_part() -> void:
		previous = current
		begin_art_part(current+"/eye")
	func pop_eye_part() -> void:
		begin_art_part(previous)
	func record(method: String, args: Array) -> void:
		if sections.is_empty(): begin_art_part("body")
		sections[-1].commands.append([transform,method,args])
	func draw_set_transform_matrix(value: Transform2D) -> void: transform = value
	func draw_colored_polygon(p, c) -> void: record("draw_colored_polygon",[p,c])
	func draw_polyline(p,c,w,a=false) -> void: record("draw_polyline",[p,c,w,a])
	func draw_line(a,b,c,w=1.0,aa=false) -> void: record("draw_line",[a,b,c,w,aa])
	func draw_arc(p,r,a,b,n,c,w=1.0,aa=false) -> void: record("draw_arc",[p,r,a,b,n,c,w,aa])
	func draw_style_box(s,r) -> void: record("draw_style_box",[s,r])

class Sheet extends Node2D:
	var cells: Array = []
	func _draw() -> void:
		for i in cells.size():
			var base := Transform2D(Vector2(2,0),Vector2(0,2),Vector2((i%16)*256+128,int(i/16)*256+128))
			for command in cells[i]:
				draw_set_transform_matrix(base*command[0])
				callv(command[1],command[2])

func _init() -> void: call_deferred("bake")

func bake() -> void:
	var sheet := Sheet.new()
	var metadata := {}
	for kind in Art.KINDS+Batch.KINDS+["mine_hidden","yam_minion"]+Third.KINDS+Fourth.BAKE_KINDS:
		var open := Recorder.new()
		var closed := Recorder.new()
		closed.force_blink = true
		for recorder in [open,closed]:
			if kind in Art.KINDS: Art.plant(recorder,kind,Vector2.ZERO,1)
			elif kind in Third.KINDS: Third.draw(recorder,kind,Vector2.ZERO,1)
			elif kind in Fourth.BAKE_KINDS: Fourth.draw(recorder,kind,Vector2.ZERO,1)
			else: Batch.draw(recorder,kind,Vector2.ZERO,1)
		var entries: Array = []
		assert(open.sections.size()==closed.sections.size())
		for i in open.sections.size():
			var section: Dictionary = open.sections[i]
			if section.commands.is_empty() or section.name=="effect": continue
			var index := sheet.cells.size()
			var region := Rect2((index%COLUMNS)*CELL,int(index/COLUMNS)*CELL,CELL,CELL)
			sheet.cells.append(section.commands)
			var closed_region := region
			if String(section.name).ends_with("/eye"):
				index = sheet.cells.size()
				closed_region = Rect2((index%COLUMNS)*CELL,int(index/COLUMNS)*CELL,CELL,CELL)
				sheet.cells.append(closed.sections[i].commands)
			entries.append({"name":section.name,"region":region,"closed":closed_region})
		metadata[kind] = entries
	var viewport := SubViewport.new()
	viewport.size = Vector2i(COLUMNS*CELL,ceili(sheet.cells.size()/float(COLUMNS))*CELL)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(viewport)
	viewport.add_child(sheet)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://assets/plants")
	# 裁掉透明空白后紧凑排布，减少显存和透明像素的重复绘制。
	var source := viewport.get_texture().get_image()
	var crops: Array = []
	var mapping := {}
	var cursor := Vector2i.ZERO
	var row_height := 0
	for i in sheet.cells.size():
		var old := Rect2i((i%COLUMNS)*CELL,int(i/COLUMNS)*CELL,CELL,CELL)
		var cell := source.get_region(old)
		var used := cell.get_used_rect().grow(2).intersection(Rect2i(0,0,CELL,CELL))
		assert(used.has_area())
		if cursor.x+used.size.x>1024:
			cursor = Vector2i(0,cursor.y+row_height+2)
			row_height = 0
		var region := Rect2i(cursor,used.size)
		mapping[Rect2(old)] = {"region":Rect2(region),"dest":Rect2(Vector2(used.position)/2-Vector2(64,64),Vector2(used.size)/2)}
		crops.append([cell.get_region(used),cursor])
		cursor.x += used.size.x+2
		row_height = maxi(row_height,used.size.y)
	var packed := Image.create(1024,cursor.y+row_height,false,Image.FORMAT_RGBA8)
	for crop in crops: packed.blit_rect(crop[0],Rect2i(Vector2i.ZERO,crop[0].get_size()),crop[1])
	# 透明视口读回的是预乘颜色；PNG 按直通 alpha 存储，防止描边二次变暗。
	for y in packed.get_height():
		for x in packed.get_width():
			var color := packed.get_pixel(x,y)
			if color.a>0.0 and color.a<1.0:
				packed.set_pixel(x,y,Color(minf(color.r/color.a,1),minf(color.g/color.a,1),minf(color.b/color.a,1),color.a))
	for entries in metadata.values():
		for entry in entries:
			var normal: Dictionary = mapping[entry.region]
			var shut: Dictionary = mapping[entry.closed]
			entry.region = normal.region
			entry.dest = normal.dest
			entry.closed = shut.region
			entry.closed_dest = shut.dest
	assert(packed.save_png("res://assets/plants/parts.png")==OK)
	var data := Resource.new()
	data.set_meta("parts",metadata)
	assert(ResourceSaver.save(data,"res://assets/plants/parts.tres")==OK)
	print("PLANT_BAKE_OK cells=",sheet.cells.size()," size=",packed.get_size())
	quit()
