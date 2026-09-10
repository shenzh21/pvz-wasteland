class_name GameView
extends Node2D

const ImpArt := preload("res://scripts/imp_art.gd")

var art_parent_transform := Transform2D.IDENTITY

func set_world_draw_offset(offset: Vector2) -> void:
	art_parent_transform = Transform2D(0.0,offset)
	draw_set_transform_matrix(art_parent_transform)

const ZombieArt := preload("res://scripts/zombie_art.gd")

const GameData := preload("res://scripts/game_data.gd")
const W := GameData.W
const H := GameData.H
const BOARD_X := GameData.BOARD_X
const BOARD_Y := GameData.BOARD_Y
const CELL_W := GameData.CELL_W
const CELL_H := GameData.CELL_H
const ROWS := GameData.ROWS
const COLS := GameData.COLS
const ZOMBIE_DPS := GameData.ZOMBIE_DPS
const SUNFLOWER_INTERVAL := GameData.SUNFLOWER_INTERVAL
const ZOMBIE_POINTS := GameData.ZOMBIE_POINTS
const PLANT_DATA := GameData.PLANT_DATA
const PLANT_INFO := GameData.PLANT_INFO
const ZOMBIE_INFO := GameData.ZOMBIE_INFO
const LEVEL_DATA := GameData.LEVEL_DATA
const ITEM_DATA := GameData.ITEM_DATA

# 快捷键绑定卡槽而不是植物。以后更换出战阵容时只需修改这个列表，
# 对应卡槽的快捷键会自动选择新的植物。
var equipped_plants: Array[String] = ["sunflower", "pea", "wall", "mine"]

var game_state := "title"
var paused := false
var game_time := 0.0
var sun_points := 150
var selected := ""
var hover_cell := Vector2i(-1, -1)
var hover_card := -1
var plants: Array = []
var zombies: Array = []
var next_zombie_id := 1
var projectiles: Array = []
var suns: Array = []
var coins: Array = []
var particles: Array = []
var yam_minions: Array = []
var detached_arms: Array = []
var dropped_armor: Array = []
var mowers: Array = []
var cooldowns := {}
var spawn_clock := 0.0
var spawn_clock_start := 0.0
var current_wave := 0
var wave_plan: Array = []
var big_wave_warning := false
var sky_sun_clock := 4.0
var final_wave_sent := false
var current_level := 1
var unlocked_level := 1
var wave_banner_time := 0.0
var shake := 0.0
var flash := 0.0
var message := ""
var message_time := 0.0
var rng := RandomNumberGenerator.new()
var high_score := 0
var game_speed := 1.0
var music_volume := 0.45
var sfx_volume := 0.75
var sound_enabled := true
var auto_collect_sun := false
var show_health_bars := true
var fullscreen_enabled := false
var speed_options := [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
var music_player: AudioStreamPlayer
var music_cache := {}
var current_music_track := ""
var music_prewarm_thread: Thread
var sfx_cache := {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_cursor := 0
var pause_page := "main"
var almanac_tab := "plants"
var almanac_selected := 0
var almanac_row_offset := 0
var binding_target := -99
var fullscreen_notice := ""
var prepare_time := 0.0
var prepare_camera_x := 0.0
var prepare_returning := false
var available_plants: Array[String] = []
var preview_zombies: Array = []
var prepare_pool_row_offset := 0
var level_select_offset := 0
const PREPARE_POOL_COLUMNS := 3
const PREPARE_POOL_VISIBLE_ROWS := 4
const LEVEL_SELECT_VISIBLE_COUNT := 5
const ALMANAC_COLUMNS := 2
const ALMANAC_VISIBLE_ROWS := 4
var plant_keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_Q, KEY_W, KEY_E, KEY_R]
var shovel_key := KEY_D
const SETTINGS_PATH := "user://garden_settings.cfg"
const SAVE_PATH := "user://pixel_garden_save.cfg"
var campaign_completed := false
var saved_loadouts := {}
var money := 0
var item_inventory := {"air_bomb":0,"sun_pack":0}
var claimed_money_bags := {}
var level_money_earned := 0
var mower_bonus_count := 0
var reward_bag_awarded := false

func key_name(keycode: int) -> String:
	var result := OS.get_keycode_string(keycode)
	return result if result != "" else "未设置"

func cell_center(col: int, row: int) -> Vector2:
	return Vector2(BOARD_X + col * CELL_W + CELL_W/2.0, BOARD_Y + row * CELL_H + CELL_H/2.0)

func level_title(level: int) -> String:
	var data: Dictionary = LEVEL_DATA[level]
	return "%s-第%d关" % [data.world, data.stage]

func is_wasteland_level() -> bool:
	var data: Dictionary = LEVEL_DATA[current_level]
	var default_map := "wasteland" if data.world=="荒地" else "frontyard"
	return String(data.get("map",default_map))=="wasteland"

func has_fixed_loadout() -> bool:
	return bool(LEVEL_DATA[current_level].get("fixed_loadout",false))

func is_plantable_cell(row: int) -> bool:
	return not is_wasteland_level() or row % 2 == 0

func prepare_card_rect(index: int) -> Rect2:
	var visible_row := int(index / PREPARE_POOL_COLUMNS)-prepare_pool_row_offset
	return Rect2(190.0+(index%PREPARE_POOL_COLUMNS)*180.0,150.0+visible_row*88.0,170.0,82.0)

func prepare_pool_max_offset() -> int:
	var row_count := ceili(float(available_plants.size())/PREPARE_POOL_COLUMNS)
	return maxi(0,row_count-PREPARE_POOL_VISIBLE_ROWS)

func scroll_prepare_pool(direction: int) -> void:
	prepare_pool_row_offset = clampi(prepare_pool_row_offset+direction,0,prepare_pool_max_offset())

func level_select_max_offset() -> int:
	return maxi(0,LEVEL_DATA.size()-LEVEL_SELECT_VISIBLE_COUNT)

func scroll_level_select(direction: int) -> void:
	level_select_offset = clampi(level_select_offset+direction,0,level_select_max_offset())

func almanac_entry_count() -> int:
	return PLANT_DATA.size() if almanac_tab=="plants" else ZOMBIE_INFO.size()

func almanac_max_offset() -> int:
	var row_count := ceili(float(almanac_entry_count())/ALMANAC_COLUMNS)
	return maxi(0,row_count-ALMANAC_VISIBLE_ROWS)

func scroll_almanac(direction: int) -> void:
	almanac_row_offset = clampi(almanac_row_offset+direction,0,almanac_max_offset())

func almanac_item_rect(index: int) -> Rect2:
	var visible_row := int(index/ALMANAC_COLUMNS)-almanac_row_offset
	return Rect2(70+(index%ALMANAC_COLUMNS)*255,160+visible_row*112,235,96)

func get_plant(col: int, row: int):
	for p in plants:
		if not p.dead and p.col == col and p.row == row: return p
	return null

func card_rect(index: int) -> Rect2:
	return Rect2(7, 86 + index*78, 146, 72)

func item_rect(index: int) -> Rect2:
	return Rect2(448+index*82,12,74,66)

func _draw() -> void:
	if game_state == "title": draw_title_screen(); return
	if game_state == "settings":
		draw_title_screen()
		draw_pause_overlay()
		return
	if game_state == "level_select": draw_level_select_screen(); return
	if game_state == "almanac": draw_almanac_screen(); return
	if game_state == "shop": draw_shop_screen(); return
	if game_state == "prepare": draw_prepare_screen(); return
	var offset := Vector2(rng.randf_range(-4,4),rng.randf_range(-3,3)) if shake > 0 else Vector2.ZERO
	set_world_draw_offset(offset)
	draw_world()
	set_world_draw_offset(Vector2.ZERO)
	draw_ui()
	if paused: draw_pause_overlay()
	if game_state == "win" or game_state == "lose": draw_end_overlay()
	if flash > 0: draw_rect(Rect2(0,0,W,H),Color(1,0.75,0.25,flash*0.22))

func draw_title_screen() -> void:
	draw_rect(Rect2(0,0,W,H),Color("#172f34"))
	for y in range(0,720,32):
		for x in range(0,1280,32):
			if (x/32+y/32 as int)%2==0: draw_rect(Rect2(x,y,32,32),Color("#1b3839"))
	draw_circle(Vector2(1100,110),72,Color("#ffe279"))
	draw_circle(Vector2(1125,95),72,Color("#172f34"))
	draw_string(ThemeDB.fallback_font,Vector2(250,210),"pvz:wasteland",HORIZONTAL_ALIGNMENT_CENTER,780,68,Color("#ffe064"))
	draw_title_plant(Vector2(330,390))
	draw_title_zombie(Vector2(950,390))
	draw_string(ThemeDB.fallback_font,Vector2(640,320),"种植  •  防守  •  生存",HORIZONTAL_ALIGNMENT_CENTER,500,24,Color("#d5e9bb"))
	draw_panel(Rect2(175,480,200,72),Color("#76b947"),Color("#d8ed74"),5)
	draw_string(ThemeDB.fallback_font,Vector2(175,528),"冒险模式",HORIZONTAL_ALIGNMENT_CENTER,200,27,Color("#17351f"))
	draw_panel(Rect2(395,480,200,72),Color("#4c8f79"),Color("#a8dfc0"),5)
	draw_string(ThemeDB.fallback_font,Vector2(395,528),"图鉴",HORIZONTAL_ALIGNMENT_CENTER,200,27,Color.WHITE)
	var shop_unlocked := unlocked_level>=4
	draw_panel(Rect2(615,480,200,72),Color("#b17b3f") if shop_unlocked else Color("#3c4c48"),Color("#f0ce73") if shop_unlocked else Color("#667873"),5)
	draw_string(ThemeDB.fallback_font,Vector2(615,521),"商店" if shop_unlocked else "商店未解锁",HORIZONTAL_ALIGNMENT_CENTER,200,25,Color.WHITE if shop_unlocked else Color("#9aa9a4"))
	if not shop_unlocked:
		draw_string(ThemeDB.fallback_font,Vector2(615,542),"完成前院后开放",HORIZONTAL_ALIGNMENT_CENTER,200,13,Color("#84958f"))
	draw_panel(Rect2(835,480,200,72),Color("#596f78"),Color("#a9c9d2"),5)
	draw_string(ThemeDB.fallback_font,Vector2(835,528),"设置",HORIZONTAL_ALIGNMENT_CENTER,200,27,Color.WHITE)
	draw_coin_icon(Vector2(1100,518),"gold",0.72)
	draw_string(ThemeDB.fallback_font,Vector2(1130,526),str(money),HORIZONTAL_ALIGNMENT_LEFT,120,22,Color("#ffe489"))
	draw_string(ThemeDB.fallback_font,Vector2(0,602),"冒险进度：%s" % level_title(unlocked_level),HORIZONTAL_ALIGNMENT_CENTER,1280,19,Color("#d7e49b"))
	draw_string(ThemeDB.fallback_font,Vector2(0,640),"所有画面与特效均由代码实时绘制",HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#829b8d"))
	draw_string(ThemeDB.fallback_font,Vector2(0,674),"1 2 3 4 Q W E R 选择植物  •  A / S 道具  •  D 铲子  •  P / Esc 暂停",HORIZONTAL_ALIGNMENT_CENTER,1280,16,Color("#66847a"))

func draw_shop_screen() -> void:
	draw_rect(Rect2(0,0,W,H),Color("#243a35"))
	for y in range(0,720,40):
		for x in range(0,1280,40):
			if int(x/40+y/40)%2==0:
				draw_rect(Rect2(x,y,40,40),Color("#29423a"))
	draw_string(ThemeDB.fallback_font,Vector2(0,72),"商店",HORIZONTAL_ALIGNMENT_CENTER,1280,44,Color("#ffe17a"))
	draw_coin_icon(Vector2(1040,58),"gold",0.8)
	draw_string(ThemeDB.fallback_font,Vector2(1075,67),"资金  %d"%money,HORIZONTAL_ALIGNMENT_LEFT,180,24,Color("#ffe8a0"))
	var kinds := ["air_bomb","sun_pack"]
	for i in kinds.size():
		var kind: String = kinds[i]
		var data: Dictionary = ITEM_DATA[kind]
		var rect := Rect2(210+i*450,180,410,320)
		var owned := int(item_inventory.get(kind,0))
		var full := owned>=int(data.max_owned)
		var affordable := money>=int(data.price)
		draw_panel(rect,Color("#385c4c"),Color("#d8c36f"),5)
		draw_item_icon(kind,Vector2(rect.position.x+205,rect.position.y+78),1.5)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+154),data.name,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,30,Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+35,rect.position.y+194),data.summary,HORIZONTAL_ALIGNMENT_CENTER,340,16,Color("#c9ddd0"))
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+222),"单价：%d"%int(data.price),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,20,Color("#ffd765"))
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+246),"持有：%d%s"%[owned," / 3" if kind=="air_bomb" else ""],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,17,Color("#e6eedf"))
		var button := Rect2(rect.position.x+90,rect.position.y+264,230,48)
		draw_panel(button,Color("#40514b") if full or not affordable else Color("#a86c38"),Color("#e4c878"),3)
		var label := "已达到持有上限" if full else ("资金不足" if not affordable else "购买")
		draw_string(ThemeDB.fallback_font,Vector2(button.position.x,button.position.y+32),label,HORIZONTAL_ALIGNMENT_CENTER,button.size.x,19,Color.WHITE if not full else Color("#aeb9b4"))
	draw_panel(Rect2(50,635,190,58),Color("#496b60"),Color("#9abcb0"),3)
	draw_string(ThemeDB.fallback_font,Vector2(50,673),"返回主菜单",HORIZONTAL_ALIGNMENT_CENTER,190,22,Color.WHITE)
	if message_time>0.0:
		draw_string(ThemeDB.fallback_font,Vector2(280,590),message,HORIZONTAL_ALIGNMENT_CENTER,720,20,Color("#fff0a0"))

func level_select_rect(index: int) -> Rect2:
	return Rect2(35.0+(index-level_select_offset)*240.0,250.0,210.0,190.0)

func draw_level_select_screen() -> void:
	draw_rect(Rect2(0,0,W,H),Color("#1b3533"))
	# 世界背景随关卡数据一起横向移动，不依赖固定的关卡数量。
	for i in LEVEL_DATA.size():
		var segment_x := 20.0+(i-level_select_offset)*240.0
		if segment_x >= W or segment_x+240.0 <= 0.0:
			continue
		var world := String(LEVEL_DATA[i+1].world)
		var base_color := Color("#b78a4e") if world=="荒地" else Color("#76bd4b")
		draw_rect(Rect2(segment_x,120,240,510),base_color)
		for row in 5:
			if world=="荒地" and row%2==0:
				draw_rect(Rect2(segment_x,120+row*102,240,102),Color("#c69b58"))
			elif world!="荒地" and (row+i)%2==0:
				draw_rect(Rect2(segment_x,120+row*102,240,102),Color(0.12,0.25,0.06,0.08))
	draw_rect(Rect2(0,0,W,120),Color("#203e38"))
	draw_rect(Rect2(0,114,W,6),Color("#dcc86e"))
	draw_string(ThemeDB.fallback_font,Vector2(0,62),"冒险地图",HORIZONTAL_ALIGNMENT_CENTER,1280,40,Color("#ffe879"))
	draw_string(ThemeDB.fallback_font,Vector2(0,99),"选择关卡",HORIZONTAL_ALIGNMENT_CENTER,1280,19,Color("#bcd8c4"))
	draw_level_world_headers()
	for i in LEVEL_DATA.size():
		var rect := level_select_rect(i)
		if rect.end.x <= 20.0 or rect.position.x >= W-20.0:
			continue
		var level := i+1
		var unlocked := level <= unlocked_level
		var completed := level < unlocked_level or campaign_completed
		draw_panel(rect,Color("#507a50") if unlocked else Color("#46504a"),Color("#ffe278") if level==unlocked_level else Color("#91aa83"),5 if level==unlocked_level else 3)
		draw_circle(Vector2(rect.position.x+rect.size.x/2,rect.position.y+62),38,Color("#f0cf59") if unlocked else Color("#68736d"))
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+76),str(LEVEL_DATA[level].stage) if unlocked else "锁",HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,30,Color("#28412d") if unlocked else Color("#b6c0ba"))
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+128),level_title(level),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,24,Color.WHITE if unlocked else Color("#9aa59f"))
		var status := "已完成" if completed else ("可进入" if unlocked else "未解锁")
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+164),status,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,16,Color("#e9e59a") if unlocked else Color("#818c86"))
	draw_panel(Rect2(50,635,190,58),Color("#496b60"),Color("#9abcb0"),3)
	draw_string(ThemeDB.fallback_font,Vector2(50,673),"返回主菜单",HORIZONTAL_ALIGNMENT_CENTER,190,22,Color.WHITE)
	draw_panel(Rect2(1040,635,70,58),Color("#496b60") if level_select_offset>0 else Color("#354942"),Color("#9abcb0"),3)
	draw_string(ThemeDB.fallback_font,Vector2(1040,674),"‹",HORIZONTAL_ALIGNMENT_CENTER,70,35,Color.WHITE)
	draw_panel(Rect2(1125,635,70,58),Color("#496b60") if level_select_offset<level_select_max_offset() else Color("#354942"),Color("#9abcb0"),3)
	draw_string(ThemeDB.fallback_font,Vector2(1125,674),"›",HORIZONTAL_ALIGNMENT_CENTER,70,35,Color.WHITE)

func draw_level_world_headers() -> void:
	var group_start := 0
	var world_number := 1
	while group_start < LEVEL_DATA.size():
		var world := String(LEVEL_DATA[group_start+1].world)
		var group_end := group_start+1
		while group_end < LEVEL_DATA.size() and String(LEVEL_DATA[group_end+1].world)==world:
			group_end += 1
		var left := maxf(20.0,20.0+(group_start-level_select_offset)*240.0)
		var right := minf(W,20.0+(group_end-level_select_offset)*240.0)
		if right > left:
			draw_string(ThemeDB.fallback_font,Vector2(left,180),"第%d世界：%s"%[world_number,world],HORIZONTAL_ALIGNMENT_CENTER,right-left,28,Color("#ffe0a0") if world=="荒地" else Color("#f4ef9c"))
		group_start = group_end
		world_number += 1

func draw_almanac_screen() -> void:
	draw_rect(Rect2(0,0,W,H),Color("#172f34"))
	for y in range(0,720,32):
		for x in range(0,1280,32):
			if int(x/32+y/32)%2==0: draw_rect(Rect2(x,y,32,32),Color("#1b3839"))
	draw_string(ThemeDB.fallback_font,Vector2(0,66),"图鉴",HORIZONTAL_ALIGNMENT_CENTER,1280,42,Color("#ffe27a"))
	draw_panel(Rect2(420,88,205,52),Color("#70a852") if almanac_tab=="plants" else Color("#385b52"),Color("#cce482"),3)
	draw_string(ThemeDB.fallback_font,Vector2(420,122),"植物",HORIZONTAL_ALIGNMENT_CENTER,205,22,Color.WHITE)
	draw_panel(Rect2(655,88,205,52),Color("#8a5950") if almanac_tab=="zombies" else Color("#385b52"),Color("#d6a078"),3)
	draw_string(ThemeDB.fallback_font,Vector2(655,122),"僵尸",HORIZONTAL_ALIGNMENT_CENTER,205,22,Color.WHITE)
	var entries: Array = PLANT_DATA.keys() if almanac_tab == "plants" else ZOMBIE_INFO.keys()
	for i in entries.size():
		var logical_row := int(i/ALMANAC_COLUMNS)
		if logical_row < almanac_row_offset or logical_row >= almanac_row_offset+ALMANAC_VISIBLE_ROWS:
			continue
		draw_almanac_item(i,String(entries[i]))
	draw_panel(Rect2(610,165,600,445),Color("#25443d"),Color("#83a99d"),4)
	var selected_key := String(entries[clampi(almanac_selected,0,entries.size()-1)])
	if almanac_tab == "plants": draw_plant_detail(selected_key)
	else: draw_zombie_detail(selected_key)
	draw_panel(Rect2(60,635,190,58),Color("#496b60"),Color("#9abcb0"),3)
	draw_string(ThemeDB.fallback_font,Vector2(60,673),"返回主菜单",HORIZONTAL_ALIGNMENT_CENTER,190,22,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(280,672),"选择左侧条目查看详细信息",HORIZONTAL_ALIGNMENT_LEFT,430,16,Color("#829e95"))
	if almanac_max_offset()>0:
		draw_panel(Rect2(552,165,32,36),Color("#496a5e") if almanac_row_offset>0 else Color("#354942"),Color("#8faea3"),2)
		draw_string(ThemeDB.fallback_font,Vector2(552,191),"▲",HORIZONTAL_ALIGNMENT_CENTER,32,17,Color.WHITE)
		draw_panel(Rect2(552,556,32,36),Color("#496a5e") if almanac_row_offset<almanac_max_offset() else Color("#354942"),Color("#8faea3"),2)
		draw_string(ThemeDB.fallback_font,Vector2(552,583),"▼",HORIZONTAL_ALIGNMENT_CENTER,32,17,Color.WHITE)
		var track := Rect2(564,208,8,340)
		draw_rect(track,Color("#102822"))
		var row_count := ceili(float(entries.size())/ALMANAC_COLUMNS)
		var thumb_height := track.size.y*float(ALMANAC_VISIBLE_ROWS)/row_count
		var travel := track.size.y-thumb_height
		var thumb_y := track.position.y+travel*float(almanac_row_offset)/almanac_max_offset()
		draw_rect(Rect2(track.position.x,thumb_y,track.size.x,thumb_height),Color("#d8c36e"))

func draw_almanac_item(index: int, key: String) -> void:
	var rect := almanac_item_rect(index)
	var active := index == almanac_selected
	var active_color := Color("#52754e") if almanac_tab=="plants" else Color("#75534d")
	draw_panel(rect,active_color if active else Color("#294942"),Color("#f1dc78") if active else Color("#54766d"),4 if active else 2)
	if almanac_tab == "plants":
		draw_plant_shape(key,Vector2(rect.position.x+55,rect.position.y+53),0.65)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+100,rect.position.y+43),PLANT_DATA[key].name,HORIZONTAL_ALIGNMENT_LEFT,125,18,Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+100,rect.position.y+72),"阳光 %d"%PLANT_DATA[key].cost,HORIZONTAL_ALIGNMENT_LEFT,125,14,Color("#ffe072"))
	else:
		draw_zombie_portrait(key,Vector2(rect.position.x+55,rect.position.y+67),0.55)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+100,rect.position.y+43),ZOMBIE_INFO[key].name,HORIZONTAL_ALIGNMENT_LEFT,125,18,Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+100,rect.position.y+72),"生命 %d"%ZOMBIE_INFO[key].hp,HORIZONTAL_ALIGNMENT_LEFT,125,14,Color("#ef9a7e"))

func draw_plant_detail(kind: String) -> void:
	var data: Dictionary = PLANT_DATA[kind]
	var info: Dictionary = PLANT_INFO[kind]
	draw_plant_shape(kind,Vector2(755,290),1.65)
	draw_string(ThemeDB.fallback_font,Vector2(850,220),data.name,HORIZONTAL_ALIGNMENT_LEFT,310,36,Color("#ffe27a"))
	draw_string(ThemeDB.fallback_font,Vector2(850,253),info.role,HORIZONTAL_ALIGNMENT_LEFT,310,18,Color("#9cd18d"))
	draw_detail_row("所需阳光",str(data.cost),286,Color("#ffe072"))
	draw_detail_row("生命值",str(roundi(data.hp)),316,Color.WHITE)
	draw_detail_row("冷却时间",str(data.cool)+" 秒",346,Color.WHITE)
	var damage_label := "小红薯每秒伤害" if kind == "yam_guard" else "攻击力"
	draw_detail_row(damage_label,str(roundi(data.damage)) if data.damage > 0 else "无",376,Color("#ff9d7e") if data.damage > 0 else Color("#819c94"))
	if kind == "mine":
		draw_detail_row("准备时间",str(data.arm_time)+" 秒",406,Color.WHITE)
	elif kind == "yam_guard":
		draw_detail_row("重生 / 空闲回血","%s秒 / %d" % [str(data.respawn),roundi(data.heal)],406,Color.WHITE)
	else:
		draw_detail_row("攻击间隔",str(data.interval)+" 秒" if data.interval > 0 else "无",406,Color.WHITE if data.interval > 0 else Color("#819c94"))
	draw_line(Vector2(650,432),Vector2(1170,432),Color("#52776d"),2)
	draw_string(ThemeDB.fallback_font,Vector2(650,469),info.summary,HORIZONTAL_ALIGNMENT_LEFT,520,18,Color("#e4eee9"))
	draw_string(ThemeDB.fallback_font,Vector2(650,511),"使用建议",HORIZONTAL_ALIGNMENT_LEFT,120,17,Color("#ffe27a"))
	draw_string(ThemeDB.fallback_font,Vector2(650,548),info.tip,HORIZONTAL_ALIGNMENT_LEFT,520,17,Color("#b7d1c8"))

func draw_zombie_detail(kind: String) -> void:
	var info: Dictionary = ZOMBIE_INFO[kind]
	draw_zombie_portrait(kind,Vector2(755,350),1.55)
	draw_string(ThemeDB.fallback_font,Vector2(850,220),info.name,HORIZONTAL_ALIGNMENT_LEFT,310,36,Color("#f0a17f"))
	draw_string(ThemeDB.fallback_font,Vector2(850,253),info.role,HORIZONTAL_ALIGNMENT_LEFT,310,18,Color("#b9c899"))
	if kind=="charger":
		draw_detail_row("钢盔 / 本体","1500 / 190",303,Color("#ef9a7e"))
	else:
		draw_detail_row("生命值",str(info.hp),303,Color("#ef9a7e"))
	draw_detail_row("移动速度",str(info.speed),338,Color.WHITE)
	if kind=="kart":
		draw_detail_row("攻击方式","碾压植物",373,Color.WHITE)
	else:
		draw_detail_row("每秒伤害","%0.1f"%ZOMBIE_DPS,373,Color.WHITE)
	draw_line(Vector2(650,415),Vector2(1170,415),Color("#52776d"),2)
	draw_string(ThemeDB.fallback_font,Vector2(650,457),info.summary,HORIZONTAL_ALIGNMENT_LEFT,520,19,Color("#e4eee9"))
	draw_string(ThemeDB.fallback_font,Vector2(650,510),"应对建议",HORIZONTAL_ALIGNMENT_LEFT,120,17,Color("#ffe27a"))
	draw_string(ThemeDB.fallback_font,Vector2(650,548),info.tip,HORIZONTAL_ALIGNMENT_LEFT,520,17,Color("#b7d1c8"))

func draw_detail_row(label: String, value: String, y: float, value_color: Color) -> void:
	draw_string(ThemeDB.fallback_font,Vector2(850,y),label,HORIZONTAL_ALIGNMENT_LEFT,135,16,Color("#adc8c0"))
	draw_string(ThemeDB.fallback_font,Vector2(1030,y),value,HORIZONTAL_ALIGNMENT_RIGHT,110,18,value_color)

func draw_zombie_portrait(kind: String, pos: Vector2, scale: float) -> void:
	draw_zombie({"x":pos.x,"draw_y":pos.y,"draw_scale":scale,"row":0,"anim":0.0,"slow":0.0,
		"kind":kind,"hp":1.0,"max_hp":1.0,"walking":false,"biting":false,"hide_bar":true})

func draw_prepare_screen() -> void:
	set_world_draw_offset(Vector2(-prepare_camera_x, 0))
	draw_world(true)
	# 先画远处（上方），再画近处（下方），整只僵尸连同装备一起遮挡。
	var ordered_zombies := preview_zombies.duplicate()
	ordered_zombies.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if float(a.draw_y)==float(b.draw_y): return float(a.x)<float(b.x)
		return float(a.draw_y)<float(b.draw_y))
	for z in ordered_zombies: draw_zombie(z)
	set_world_draw_offset(Vector2.ZERO)
	draw_rect(Rect2(0,0,W,78),Color("#1d3935"))
	draw_rect(Rect2(0,73,W,5),Color("#d2bd6b"))
	draw_string(ThemeDB.fallback_font,Vector2(0,48),level_title(current_level),HORIZONTAL_ALIGNMENT_CENTER,1280,29,Color("#fff0a0"))
	if prepare_camera_x > 360.0:
		draw_plant_selection_panel()

func draw_plant_selection_panel() -> void:
	var fixed_loadout := has_fixed_loadout()
	# 最左边沿用战斗中的八个纵向卡槽，位置和尺寸保持一致。
	draw_rect(Rect2(0,78,160,H-78),Color("#203a34"))
	draw_rect(Rect2(154,78,6,H-78),Color("#d0bd6f"))
	for slot in 8:
		if slot < equipped_plants.size():
			draw_prepare_slot(slot,equipped_plants[slot])
		else:
			var empty_rect := card_rect(slot)
			draw_panel(empty_rect,Color("#2b443b"),Color("#536e63"),2)
			draw_panel(Rect2(empty_rect.position+Vector2(7,6),Vector2(20,20)),Color("#243c34"),Color("#607b70"),1)
			draw_string(ThemeDB.fallback_font,empty_rect.position+Vector2(7,21),key_name(plant_keys[slot]),HORIZONTAL_ALIGNMENT_CENTER,20,11,Color("#8da59a"))
	# 总植物池独立放在卡槽右侧。
	draw_panel(Rect2(174,96,572,552),Color("#29483e"),Color("#e0ca72"),5)
	draw_string(ThemeDB.fallback_font,Vector2(174,137),"固定卡组" if fixed_loadout else "选择植物",HORIZONTAL_ALIGNMENT_CENTER,572,27,Color("#fff0a0"))
	for i in available_plants.size():
		var logical_row := int(i/PREPARE_POOL_COLUMNS)
		if logical_row < prepare_pool_row_offset or logical_row >= prepare_pool_row_offset+PREPARE_POOL_VISIBLE_ROWS:
			continue
		var rect := prepare_card_rect(i)
		var kind: String = available_plants[i]
		var chosen_index := equipped_plants.find(kind)
		var chosen := chosen_index >= 0
		draw_panel(rect,Color("#6a8e55") if chosen else Color("#3d5c50"),Color("#ffe274") if chosen else Color("#789488"),3)
		draw_mini_plant(kind,rect.position+Vector2(40,46))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(75,33),PLANT_DATA[kind].name,HORIZONTAL_ALIGNMENT_LEFT,79,15,Color.WHITE)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(75,61),"阳光 %d" % PLANT_DATA[kind].cost,HORIZONTAL_ALIGNMENT_LEFT,79,13,Color("#ffe16d"))
		if chosen:
			draw_circle(rect.position+Vector2(154,14),12,Color("#ffe274"))
			draw_string(ThemeDB.fallback_font,rect.position+Vector2(142,19),"定" if fixed_loadout else str(chosen_index+1),HORIZONTAL_ALIGNMENT_CENTER,24,11,Color("#294036"))
	if prepare_pool_max_offset()>0:
		draw_panel(Rect2(674,105,27,31),Color("#496a5e") if prepare_pool_row_offset>0 else Color("#354942"),Color("#8faea3"),2)
		draw_string(ThemeDB.fallback_font,Vector2(674,128),"▲",HORIZONTAL_ALIGNMENT_CENTER,27,16,Color.WHITE)
		draw_panel(Rect2(704,105,27,31),Color("#496a5e") if prepare_pool_row_offset<prepare_pool_max_offset() else Color("#354942"),Color("#8faea3"),2)
		draw_string(ThemeDB.fallback_font,Vector2(704,128),"▼",HORIZONTAL_ALIGNMENT_CENTER,27,16,Color.WHITE)
		var track := Rect2(733,150,7,346)
		draw_rect(track,Color("#1d342d"))
		var row_count := ceili(float(available_plants.size())/PREPARE_POOL_COLUMNS)
		var thumb_height := track.size.y*float(PREPARE_POOL_VISIBLE_ROWS)/row_count
		var travel := track.size.y-thumb_height
		var thumb_y := track.position.y+travel*float(prepare_pool_row_offset)/prepare_pool_max_offset()
		draw_rect(Rect2(track.position.x,thumb_y,track.size.x,thumb_height),Color("#d8c36e"))
	draw_string(ThemeDB.fallback_font,Vector2(190,510),"本关植物：%d" % equipped_plants.size() if fixed_loadout else "已选择 %d / 8" % equipped_plants.size(),HORIZONTAL_ALIGNMENT_CENTER,540,18,Color("#d6e9c3"))
	draw_panel(Rect2(280,575,170,55),Color("#496a5e"),Color("#8faea3"),3)
	draw_string(ThemeDB.fallback_font,Vector2(280,610),"菜单",HORIZONTAL_ALIGNMENT_CENTER,170,18,Color.WHITE)
	draw_panel(Rect2(470,575,170,55),Color("#7eb34f") if not equipped_plants.is_empty() else Color("#53645d"),Color("#e3ef92") if not equipped_plants.is_empty() else Color("#75877f"),4)
	draw_string(ThemeDB.fallback_font,Vector2(470,610),"开始战斗" if not prepare_returning else "准备出发……",HORIZONTAL_ALIGNMENT_CENTER,170,19,Color("#183421") if not equipped_plants.is_empty() else Color("#9cad9f"))
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(190,552),message,HORIZONTAL_ALIGNMENT_CENTER,540,15,Color("#ffd080"))

func draw_prepare_slot(index: int, kind: String) -> void:
	var rect := card_rect(index)
	var data: Dictionary = PLANT_DATA[kind]
	draw_panel(rect,Color("#466b51"),Color("#d3c17a"),3)
	draw_mini_plant(kind,rect.position+Vector2(36,35))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(64,24),data.name,HORIZONTAL_ALIGNMENT_LEFT,73,12,Color.WHITE)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(64,49),str(data.cost),HORIZONTAL_ALIGNMENT_LEFT,58,20,Color("#ffe16d"))
	draw_panel(Rect2(rect.position+Vector2(7,6),Vector2(20,20)),Color("#243c34"),Color("#77927e"),1)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(7,21),key_name(plant_keys[index]),HORIZONTAL_ALIGNMENT_CENTER,20,11,Color("#fff0a2"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(64,66),"已选择",HORIZONTAL_ALIGNMENT_LEFT,73,10,Color("#cfe5bd"))

func draw_world(extended := false) -> void:
	draw_rect(Rect2(0,0,W + (650.0 if extended else 0.0),H),Color("#9ed76b"))
	# House and path
	draw_rect(Rect2(0,120,BOARD_X,530),Color("#d6b174"))
	for y in range(135,640,38): draw_line(Vector2(0,y),Vector2(BOARD_X,y),Color("#b68c59"),2)
	draw_rect(Rect2(0,120,142,530),Color("#ad594b"))
	draw_rect(Rect2(22,220,90,150),Color("#513c3f"))
	draw_rect(Rect2(37,235,60,120),Color("#80bfd0"))
	# 关卡准备镜头中的右侧是僵尸候场泥地，草坪仍严格只有 5×9。
	if extended:
		var staging_x := BOARD_X + COLS * CELL_W
		draw_rect(Rect2(staging_x,90,685,630),Color("#8b754f"))
		draw_rect(Rect2(staging_x,90,12,630),Color("#604b36"))
		var rock_specs := [
			[Vector2(42,82),Vector2(25,13)],[Vector2(166,147),Vector2(17,25)],
			[Vector2(307,63),Vector2(31,17)],[Vector2(518,126),Vector2(21,12)],
			[Vector2(92,276),Vector2(15,10)],[Vector2(249,238),Vector2(28,14)],
			[Vector2(448,319),Vector2(18,27)],[Vector2(611,250),Vector2(32,16)],
			[Vector2(48,471),Vector2(27,18)],[Vector2(193,414),Vector2(14,22)],
			[Vector2(362,526),Vector2(35,15)],[Vector2(566,451),Vector2(20,13)],
			[Vector2(646,580),Vector2(13,20)]
		]
		for i in rock_specs.size():
			var center: Vector2 = Vector2(staging_x,90) + rock_specs[i][0]
			var radius: Vector2 = rock_specs[i][1]
			var stone := PackedVector2Array()
			for point_index in 7:
				var angle := TAU * float(point_index) / 7.0
				var roughness := 0.84 + 0.16 * sin(float(point_index * 5 + i * 3))
				stone.append(center + Vector2(cos(angle)*radius.x,sin(angle)*radius.y)*roughness)
			draw_colored_polygon(stone,Color("#75654d"))
			draw_line(center-radius*Vector2(0.45,0.25),center+radius*Vector2(0.28,-0.18),Color("#a18a60"),3)
	# lawn checkerboard
	var draw_cols := COLS
	for row in ROWS:
		for col in draw_cols:
			var dirt_row := is_wasteland_level() and row % 2 == 1
			var c := (Color("#c99b55") if (row+col)%2==0 else Color("#bc8c48")) if dirt_row else (Color("#75c84c") if (row+col)%2==0 else Color("#6cbd45"))
			draw_rect(Rect2(BOARD_X+col*CELL_W,BOARD_Y+row*CELL_H,CELL_W,CELL_H),c)
			var seam_color := Color(0.35,0.22,0.08,.28) if dirt_row else Color(0.2,0.45,0.15,.25)
			draw_line(Vector2(BOARD_X+col*CELL_W,BOARD_Y+row*CELL_H+CELL_H-2),Vector2(BOARD_X+(col+1)*CELL_W,BOARD_Y+row*CELL_H+CELL_H-2),seam_color,2)
	# dirt borders
	draw_rect(Rect2(BOARD_X,BOARD_Y-12,draw_cols*CELL_W,12),Color("#77543b"))
	draw_rect(Rect2(BOARD_X,BOARD_Y+ROWS*CELL_H,draw_cols*CELL_W,18),Color("#77543b"))
	if hover_cell.x >= 0 and selected != "":
		var ok := selected=="item_air_bomb" or (get_plant(hover_cell.x,hover_cell.y)==null and is_plantable_cell(hover_cell.y)) or selected=="shovel"
		draw_rect(Rect2(BOARD_X+hover_cell.x*CELL_W,BOARD_Y+hover_cell.y*CELL_H,CELL_W,CELL_H),Color(0.9,1,0.5,.28) if ok else Color(1,0.2,0.2,.28))
	for m in mowers: draw_mower(m)
	for p in plants: draw_plant(p)
	for i in yam_minions.size():
		draw_yam_minion(yam_minions[i], yam_stack_offset(i))
	for z in zombies: draw_zombie(z)
	for arm in detached_arms: draw_detached_arm(arm)
	for armor in dropped_armor: draw_dropped_armor(armor)
	for pr in projectiles: draw_projectile(pr)
	for s in suns: draw_sun(s)
	for coin in coins: draw_coin(coin)
	for p in particles:
		draw_rect(Rect2(p.pos-Vector2.ONE*p.size/2.0,Vector2.ONE*p.size),Color(p.color,p.life/p.max))
	if wave_banner_time > 0.0:
		draw_wave_banner()

func draw_ui() -> void:
	# 左侧纵向操作栏和顶部轻量状态栏
	draw_rect(Rect2(0,0,160,H),Color("#203a34"))
	draw_rect(Rect2(154,0,6,H),Color("#d0bd6f"))
	draw_rect(Rect2(160,0,W-160,90),Color("#233e36"))
	draw_rect(Rect2(160,84,W-160,6),Color("#152c28"))
	# 紧凑阳光计数器
	draw_panel(Rect2(7,7,146,72),Color("#35594a"),Color("#e6d66a"),4)
	draw_sun({"pos":Vector2(37,36),"pulse":0.0})
	draw_string(ThemeDB.fallback_font,Vector2(65,43),str(sun_points),HORIZONTAL_ALIGNMENT_LEFT,77,25,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(62,67),"阳光",HORIZONTAL_ALIGNMENT_LEFT,70,13,Color("#bed5bc"))
	var keys := equipped_plants
	for i in keys.size(): draw_card(i,keys[i])
	# 铲子、关卡信息、倍速与暂停
	draw_panel(Rect2(175,14,105,62),Color("#80583d") if selected!="shovel" else Color("#d19b50"),Color("#e8ca86"),3)
	draw_shovel_icon(Vector2(198,43), 0.65)
	draw_string(ThemeDB.fallback_font,Vector2(207,50),"铲子",HORIZONTAL_ALIGNMENT_CENTER,63,17,Color.WHITE)
	draw_panel(Rect2(251,20,22,20),Color("#3d332b"),Color("#d5bd86"),1)
	draw_string(ThemeDB.fallback_font,Vector2(251,35),key_name(shovel_key),HORIZONTAL_ALIGNMENT_CENTER,22,11,Color("#fff0a2"))
	draw_string(ThemeDB.fallback_font,Vector2(294,43),level_title(current_level),HORIZONTAL_ALIGNMENT_LEFT,145,20,Color("#fff0a0"))
	draw_coin_icon(Vector2(309,65),"silver",0.48)
	draw_string(ThemeDB.fallback_font,Vector2(327,70),str(money),HORIZONTAL_ALIGNMENT_LEFT,105,14,Color("#dce5dc"))
	for i in 2:
		draw_item_slot(i,"air_bomb" if i==0 else "sun_pack")
	draw_panel(Rect2(1045,14,105,62),Color("#477772"),Color("#8fc5bb"),3)
	draw_string(ThemeDB.fallback_font,Vector2(1045,43),"倍速",HORIZONTAL_ALIGNMENT_CENTER,105,14,Color("#bfe1da"))
	draw_string(ThemeDB.fallback_font,Vector2(1045,67),str(game_speed)+"x",HORIZONTAL_ALIGNMENT_CENTER,105,21,Color("#fff0a0"))
	draw_panel(Rect2(1165,14,100,62),Color("#3a5b52"),Color("#8fc5bb"),3)
	draw_string(ThemeDB.fallback_font,Vector2(1165,53),"暂停",HORIZONTAL_ALIGNMENT_CENTER,100,20,Color.WHITE)
	# 显眼的关卡进度条，位于顶部中央
	var total_waves := maxi(wave_plan.size(), 1)
	var partial_wave := 0.0
	if not final_wave_sent and spawn_clock_start > 0.0:
		var clock_progress := clampf(1.0 - spawn_clock / spawn_clock_start, 0.0, 1.0)
		if current_wave % 10 == 9:
			partial_wave = 0.75 + clock_progress * 0.25 if big_wave_warning else clock_progress * 0.75
		else:
			partial_wave = clock_progress
	var prog := 1.0 if final_wave_sent else clampf((current_wave + partial_wave) / float(total_waves), 0.0, 1.0)
	draw_string(ThemeDB.fallback_font,Vector2(625,31),"关卡进度",HORIZONTAL_ALIGNMENT_LEFT,100,15,Color("#fff0a0"))
	draw_panel(Rect2(625,39,385,37),Color("#172724"),Color("#ffe36e"),5)
	draw_rect(Rect2(632,46,371*prog,23),Color("#df5a47"))
	draw_rect(Rect2(632,46,371*prog,7),Color("#ff8a62"))
	draw_string(ThemeDB.fallback_font,Vector2(625,65),str(roundi(prog*100))+"%",HORIZONTAL_ALIGNMENT_CENTER,385,14,Color.WHITE)
	var marker_x := 632.0 + 371.0 * prog
	draw_line(Vector2(marker_x,38),Vector2(marker_x,72),Color("#fff4b0"),2)
	draw_colored_polygon(PackedVector2Array([Vector2(marker_x,38),Vector2(marker_x+12,43),Vector2(marker_x,49)]),Color("#fff4b0"))
	# 每10波标记一次旗帜，支持以后配置两次或三次大波。
	for flag_wave in range(10, total_waves + 1, 10):
		var flag_x := 632.0 + 371.0 * float(flag_wave) / float(total_waves)
		draw_line(Vector2(flag_x,37),Vector2(flag_x,58),Color("#fff4b0"),2)
		draw_colored_polygon(PackedVector2Array([Vector2(flag_x+1,38),Vector2(flag_x+11,43),Vector2(flag_x+1,49)]),Color("#e95b4f"))
	if message_time > 0:
		draw_string(ThemeDB.fallback_font,Vector2(160,132),message,HORIZONTAL_ALIGNMENT_CENTER,1120,20,Color("#fff3a0"))

func draw_item_slot(index: int, kind: String) -> void:
	var rect := item_rect(index)
	var count := int(item_inventory.get(kind,0))
	var active := selected=="item_air_bomb" and kind=="air_bomb"
	draw_panel(rect,Color("#9b673a") if active else Color("#3a5f50") if count>0 else Color("#303f39"),Color("#f0cf78") if active else Color("#789489"),2)
	draw_item_icon(kind,rect.position+Vector2(28,34),0.62)
	draw_panel(Rect2(rect.position+Vector2(5,5),Vector2(18,18)),Color("#263832"),Color("#789489"),1)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(5,19),"A" if kind=="air_bomb" else "S",HORIZONTAL_ALIGNMENT_CENTER,18,10,Color("#fff1a3"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(46,29),"×%d"%count,HORIZONTAL_ALIGNMENT_LEFT,25,15,Color.WHITE)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(3,60),ITEM_DATA[kind].name,HORIZONTAL_ALIGNMENT_CENTER,68,10,Color("#dbe9df"))

func draw_card(index: int, kind: String) -> void:
	var rect := card_rect(index)
	var data: Dictionary = PLANT_DATA[kind]
	var ready: bool = cooldowns.get(kind,0.0)<=0 and sun_points>=data.cost
	var bg := Color("#466b51") if ready else Color("#37483f")
	if selected == kind: bg = Color("#7ca64e")
	if hover_card == index: bg = bg.lightened(.08)
	draw_panel(rect,bg,Color("#d3c17a") if selected==kind else Color("#708b6d"),3)
	draw_mini_plant(kind,Vector2(rect.position.x+36,rect.position.y+35))
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+64,rect.position.y+24),data.name,HORIZONTAL_ALIGNMENT_LEFT,73,12,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+64,rect.position.y+49),str(data.cost),HORIZONTAL_ALIGNMENT_LEFT,58,20,Color("#ffe16d") if sun_points>=data.cost else Color("#b16b62"))
	draw_panel(Rect2(rect.position.x+7,rect.position.y+6,20,20),Color("#243c34"),Color("#77927e"),1)
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+7,rect.position.y+21),key_name(plant_keys[index]),HORIZONTAL_ALIGNMENT_CENTER,20,11,Color("#fff0a2"))
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+64,rect.position.y+66),"可种植" if cooldowns.get(kind,0.0)<=0 else "%0.1f秒"%cooldowns[kind],HORIZONTAL_ALIGNMENT_LEFT,73,10,Color("#cfe5bd"))
	if cooldowns.get(kind,0.0)>0:
		var ratio: float = cooldowns[kind]/data.cool
		draw_rect(Rect2(rect.position.x,rect.position.y,rect.size.x,rect.size.y*ratio),Color(0.05,0.1,0.08,.46))

func draw_plant(p: Dictionary) -> void:
	var pos := cell_center(p.col,p.row)
	var bob := sin(p.anim*3.0)*2.0
	if p.kind=="squash":
		var phase := int(p.get("squash_phase",0))
		if phase==1:
			pos.y += 8.0
		elif phase==2:
			var leap_t := 1.0-clampf(float(p.get("squash_clock",0.0))/0.32,0.0,1.0)
			pos.x = lerpf(pos.x,float(p.get("squash_target_x",pos.x)),leap_t)
			pos.y -= sin(leap_t*PI)*72.0
		elif phase==3:
			pos.x = float(p.get("squash_target_x",pos.x))
			pos.y += 19.0
	else:
		pos.y += bob
	if p.kind=="slime" and int(p.get("slime_target_id",-1))>=0:
		for z in zombies:
			if not z.dead and int(z.get("id",-1))==int(p.slime_target_id):
				var target_y := float(z.get("draw_y",BOARD_Y+float(z.get("draw_row",z.row))*CELL_H+CELL_H/2.0-ZOMBIE_BOARD_LIFT))
				var target_pos := Vector2(z.x,target_y+20.0)
				draw_line(pos+Vector2(9,-5),target_pos,Color(0.35,0.85,0.65,0.55),5)
				for part in 4:
					var bead_pos := (pos+Vector2(9,-5)).lerp(target_pos,float(part+1)/5.0)
					draw_circle(bead_pos,4,Color("#82d6a8"))
				break
	if p.kind == "mine": draw_potato_mine(pos, p.armed, 1.0)
	else: draw_plant_shape(p.kind,pos,1.0)
	if show_health_bars and p.hp < p.max_hp:
		draw_bar(Vector2(pos.x-31,pos.y-49),62,p.hp/p.max_hp,Color("#7de05b"))

func draw_plant_shape(kind: String, pos: Vector2, scale: float) -> void:
	# stem and leaves
	if kind not in ["wall","cherry","mine","yam_guard","cactus","slime","squash"]:
		draw_rect(Rect2(pos+Vector2(-4,9)*scale,Vector2(8,31)*scale),Color("#347c3c"))
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-3,25)*scale,pos+Vector2(-28,14)*scale,pos+Vector2(-20,36)*scale]),Color("#55a94b"))
		draw_colored_polygon(PackedVector2Array([pos+Vector2(3,29)*scale,pos+Vector2(27,19)*scale,pos+Vector2(18,40)*scale]),Color("#438e42"))
	match kind:
		"sunflower":
			for i in 10:
				var a := i*TAU/10.0
				draw_circle(pos+Vector2(cos(a),sin(a))*21*scale,11*scale,Color("#ffd747"))
			draw_circle(pos,20*scale,Color("#874b2e")); draw_circle(pos+Vector2(-7,-4)*scale,3*scale,Color("#301f1b")); draw_circle(pos+Vector2(7,-4)*scale,3*scale,Color("#301f1b"))
			draw_line(pos+Vector2(-7,8)*scale,pos+Vector2(0,11)*scale,Color("#f4be55"),2*scale); draw_line(pos+Vector2(0,11)*scale,pos+Vector2(8,7)*scale,Color("#f4be55"),2*scale)
		"pea", "snow":
			var c := Color("#7bd34d") if kind=="pea" else Color("#78dce8")
			draw_circle(pos+Vector2(0,-8)*scale,23*scale,c); draw_circle(pos+Vector2(20,-9)*scale,12*scale,c.darkened(.08)); draw_circle(pos+Vector2(25,-9)*scale,6*scale,Color("#244f3e"))
			draw_circle(pos+Vector2(-6,-15)*scale,4*scale,Color("#172e28")); draw_circle(pos+Vector2(-5,-16)*scale,1.4*scale,Color.WHITE)
			if kind=="snow": draw_rect(Rect2(pos+Vector2(-18,-35)*scale,Vector2(30,7)*scale),Color("#e9fbff"))
		"cactus":
			var body := Color("#75ad43")
			var dark := Color("#3f6d34")
			# 粗短侧臂和高柱状主体保留参考造型，轮廓仍采用本作的扁平几何语言。
			draw_line(pos+Vector2(-13,-2)*scale,pos+Vector2(-31,-1)*scale,dark,15*scale)
			draw_line(pos+Vector2(-31,-1)*scale,pos+Vector2(-31,-24)*scale,dark,15*scale)
			draw_line(pos+Vector2(-13,-2)*scale,pos+Vector2(-31,-1)*scale,body.lightened(.08),10*scale)
			draw_line(pos+Vector2(-31,-1)*scale,pos+Vector2(-31,-24)*scale,body.lightened(.08),10*scale)
			draw_circle(pos+Vector2(-31,-25)*scale,6*scale,body.lightened(.08))
			draw_line(pos+Vector2(13,6)*scale,pos+Vector2(29,7)*scale,dark,14*scale)
			draw_line(pos+Vector2(29,7)*scale,pos+Vector2(29,-10)*scale,dark,14*scale)
			draw_line(pos+Vector2(13,6)*scale,pos+Vector2(29,7)*scale,body,9*scale)
			draw_line(pos+Vector2(29,7)*scale,pos+Vector2(29,-10)*scale,body,9*scale)
			draw_circle(pos+Vector2(29,-11)*scale,5.5*scale,body)
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(-21,27)*scale,pos+Vector2(-19,-25)*scale,
				pos+Vector2(-11,-42)*scale,pos+Vector2(9,-42)*scale,
				pos+Vector2(18,-25)*scale,pos+Vector2(20,27)*scale
			]),body)
			draw_circle(pos+Vector2(-1,-28)*scale,19*scale,body)
			draw_line(pos+Vector2(-10,-20)*scale,pos+Vector2(-8,20)*scale,body.lightened(.23),4*scale)
			# 半眯的单眼和右侧管状发射口。
			draw_rect(Rect2(pos+Vector2(-10,-34)*scale,Vector2(19,7)*scale),Color("#edf0c9"))
			draw_circle(pos+Vector2(5,-30)*scale,2.7*scale,Color("#263027"))
			draw_line(pos+Vector2(-11,-35)*scale,pos+Vector2(10,-36)*scale,dark,3*scale)
			draw_circle(pos+Vector2(20,-22)*scale,10*scale,dark)
			draw_circle(pos+Vector2(21,-22)*scale,7*scale,Color("#9ac555"))
			draw_circle(pos+Vector2(22,-22)*scale,3.5*scale,Color("#36572f"))
			# 顶部红色花冠与橙色花蕊。
			for i in 7:
				var angle := TAU*float(i)/7.0
				draw_circle(pos+Vector2(-1,-49)*scale+Vector2(cos(angle),sin(angle))*8*scale,6*scale,Color("#d94a32"))
			draw_circle(pos+Vector2(-1,-49)*scale,6*scale,Color("#ef6a34"))
			draw_circle(pos+Vector2(-6,-61)*scale,2.5*scale,Color("#f1a632"))
			draw_circle(pos+Vector2(1,-65)*scale,2.5*scale,Color("#f1a632"))
			draw_circle(pos+Vector2(7,-59)*scale,2.5*scale,Color("#f1a632"))
			for yy in [-14,2,17]:
				draw_line(pos+Vector2(10,yy)*scale,pos+Vector2(15,yy-3)*scale,Color("#e8dcaa"),1.5*scale)
		"slime":
			# 肉质莲座叶片包住半透明粘液核心。
			for i in 8:
				var angle := TAU*float(i)/8.0
				var direction := Vector2(cos(angle),sin(angle)*0.58)
				draw_colored_polygon(PackedVector2Array([
					pos+direction*7*scale,
					pos+direction.rotated(-0.28)*31*scale,
					pos+direction*43*scale,
					pos+direction.rotated(0.28)*31*scale
				]),Color("#58a987") if i%2==0 else Color("#70bd91"))
			draw_circle(pos+Vector2(0,3)*scale,21*scale,Color("#6bc9a1"))
			draw_circle(pos+Vector2(-7,-2)*scale,3*scale,Color("#24483d"))
			draw_circle(pos+Vector2(7,-2)*scale,3*scale,Color("#24483d"))
			draw_line(pos+Vector2(-6,9)*scale,pos+Vector2(7,9)*scale,Color("#36725c"),2.5*scale)
			draw_circle(pos+Vector2(-13,-11)*scale,5*scale,Color(0.75,1.0,0.86,0.55))
		"squash":
			var body := Color("#7eaa4f")
			var dark := Color("#3f6737")
			# 直立的矮胖梨形：顶部收窄、腰部凹凸、底部由几瓣鼓起。
			var outer := PackedVector2Array([
				pos+Vector2(-9,-43)*scale,pos+Vector2(5,-45)*scale,
				pos+Vector2(15,-37)*scale,pos+Vector2(18,-28)*scale,
				pos+Vector2(29,-23)*scale,pos+Vector2(35,-13)*scale,
				pos+Vector2(38,-3)*scale,pos+Vector2(44,8)*scale,
				pos+Vector2(43,22)*scale,pos+Vector2(35,34)*scale,
				pos+Vector2(22,41)*scale,pos+Vector2(7,44)*scale,
				pos+Vector2(-10,43)*scale,pos+Vector2(-25,39)*scale,
				pos+Vector2(-36,31)*scale,pos+Vector2(-42,18)*scale,
				pos+Vector2(-44,4)*scale,pos+Vector2(-38,-10)*scale,
				pos+Vector2(-29,-21)*scale,pos+Vector2(-18,-27)*scale,
				pos+Vector2(-16,-37)*scale
			])
			draw_colored_polygon(outer,dark)
			var inner := PackedVector2Array([
				pos+Vector2(-7,-37)*scale,pos+Vector2(4,-39)*scale,
				pos+Vector2(10,-32)*scale,pos+Vector2(13,-23)*scale,
				pos+Vector2(24,-18)*scale,pos+Vector2(30,-8)*scale,
				pos+Vector2(32,1)*scale,pos+Vector2(38,10)*scale,
				pos+Vector2(37,20)*scale,pos+Vector2(30,29)*scale,
				pos+Vector2(19,35)*scale,pos+Vector2(6,38)*scale,
				pos+Vector2(-9,37)*scale,pos+Vector2(-21,34)*scale,
				pos+Vector2(-31,27)*scale,pos+Vector2(-36,16)*scale,
				pos+Vector2(-38,5)*scale,pos+Vector2(-32,-7)*scale,
				pos+Vector2(-24,-16)*scale,pos+Vector2(-13,-22)*scale,
				pos+Vector2(-11,-32)*scale
			])
			draw_colored_polygon(inner,body)
			# 中央鼓起的亮瓣与两侧深瓣让瓜体保持不规则的体积感。
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(-7,-37)*scale,pos+Vector2(5,-39)*scale,
				pos+Vector2(14,-18)*scale,pos+Vector2(17,34)*scale,
				pos+Vector2(4,38)*scale,pos+Vector2(-8,36)*scale,
				pos+Vector2(-15,-17)*scale
			]),body.lightened(.13))
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(14,-24)*scale,pos+Vector2(25,-18)*scale,
				pos+Vector2(37,11)*scale,pos+Vector2(30,29)*scale,
				pos+Vector2(19,35)*scale,pos+Vector2(16,-10)*scale
			]),body.darkened(.09))
			draw_line(pos+Vector2(-27,-16)*scale,pos+Vector2(-30,28)*scale,body.lightened(.08),3*scale)
			draw_line(pos+Vector2(28,-11)*scale,pos+Vector2(32,25)*scale,dark.lightened(.15),3*scale)
			# 短而粗的瓜蒂从凹陷处弯向一侧。
			draw_line(pos+Vector2(-4,-41)*scale,pos+Vector2(0,-54)*scale,dark,8*scale)
			draw_line(pos+Vector2(0,-54)*scale,pos+Vector2(11,-58)*scale,dark,7*scale)
			draw_circle(pos+Vector2(12,-58)*scale,4*scale,dark)
			# 大块斜眉压住眼睛，形成倭瓜特有的怒视。
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(-31,-20)*scale,pos+Vector2(-7,-12)*scale,
				pos+Vector2(-9,-6)*scale,pos+Vector2(-33,-14)*scale
			]),Color("#29422d"))
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(31,-20)*scale,pos+Vector2(7,-12)*scale,
				pos+Vector2(9,-6)*scale,pos+Vector2(33,-14)*scale
			]),Color("#29422d"))
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(-26,-12)*scale,pos+Vector2(-8,-7)*scale,
				pos+Vector2(-9,4)*scale,pos+Vector2(-24,2)*scale
			]),Color("#edf1ca"))
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(26,-12)*scale,pos+Vector2(8,-7)*scale,
				pos+Vector2(9,4)*scale,pos+Vector2(24,2)*scale
			]),Color("#edf1ca"))
			draw_circle(pos+Vector2(-13,-3)*scale,3.5*scale,Color("#202b25"))
			draw_circle(pos+Vector2(13,-3)*scale,3.5*scale,Color("#202b25"))
			# 不规则下压的嘴线，比简单水平线更像憋足力气的表情。
			draw_polyline(PackedVector2Array([
				pos+Vector2(-16,16)*scale,pos+Vector2(-7,13)*scale,
				pos+Vector2(1,16)*scale,pos+Vector2(9,13)*scale,
				pos+Vector2(17,17)*scale
			]),Color("#304b32"),4*scale)
		"needle":
			var center := pos+Vector2(0,-8)*scale
			for i in 12:
				var angle := TAU*float(i)/12.0
				var direction := Vector2(cos(angle),sin(angle))
				draw_line(center+direction*15.0*scale,center+direction*31.0*scale,Color("#735098"),3.0*scale)
			draw_circle(center,20*scale,Color("#aa62c7"))
			draw_circle(center+Vector2(-6,-5)*scale,3.2*scale,Color("#30243a"))
			draw_circle(center+Vector2(7,-5)*scale,3.2*scale,Color("#30243a"))
			draw_line(center+Vector2(-6,7)*scale,center+Vector2(7,7)*scale,Color("#684078"),2.5*scale)
		"wall":
			draw_rect(Rect2(pos+Vector2(-30,-37)*scale,Vector2(60,75)*scale),Color("#ad7040")); draw_rect(Rect2(pos+Vector2(-24,-31)*scale,Vector2(48,63)*scale),Color("#c68a50"))
			for yy in [-18,5,22]: draw_line(pos+Vector2(-18,yy)*scale,pos+Vector2(18,yy-5)*scale,Color("#8d5938"),2*scale)
			draw_circle(pos+Vector2(-10,-10)*scale,4*scale,Color("#34261f")); draw_circle(pos+Vector2(11,-10)*scale,4*scale,Color("#34261f")); draw_line(pos+Vector2(-9,12)*scale,pos+Vector2(10,12)*scale,Color("#513528"),3*scale)
		"cherry":
			draw_line(pos+Vector2(-14,-9)*scale,pos+Vector2(3,-34)*scale,Color("#376b36"),5*scale); draw_line(pos+Vector2(14,-7)*scale,pos+Vector2(3,-34)*scale,Color("#376b36"),5*scale)
			draw_circle(pos+Vector2(-16,7)*scale,22*scale,Color("#e74d49")); draw_circle(pos+Vector2(17,9)*scale,22*scale,Color("#cf383d"))
			draw_circle(pos+Vector2(-22,0)*scale,5*scale,Color("#ff9580")); draw_circle(pos+Vector2(-22,8)*scale,3*scale,Color("#391e26")); draw_circle(pos+Vector2(11,8)*scale,3*scale,Color("#391e26"))
		"mine":
			draw_potato_mine(pos, true, scale)
		"yam_guard":
			draw_circle(pos+Vector2(0,5)*scale,31*scale,Color("#b84f36"))
			draw_circle(pos+Vector2(-10,-2)*scale,16*scale,Color("#d46a45"))
			draw_circle(pos+Vector2(11,2)*scale,17*scale,Color("#c45a3b"))
			draw_circle(pos+Vector2(-8,-6)*scale,3*scale,Color("#30231f"))
			draw_circle(pos+Vector2(12,-3)*scale,3*scale,Color("#30231f"))
			draw_line(pos+Vector2(-4,12)*scale,pos+Vector2(8,12)*scale,Color("#6e2f29"),3*scale)
			draw_colored_polygon(PackedVector2Array([
				pos+Vector2(-8,-27)*scale,pos+Vector2(-3,-43)*scale,
				pos+Vector2(3,-28)*scale,pos+Vector2(13,-40)*scale,
				pos+Vector2(11,-22)*scale
			]),Color("#4d9a45"))

func yam_stack_offset(index: int) -> Vector2:
	var minion: Dictionary = yam_minions[index]
	var order := 0
	var total := 0
	for i in yam_minions.size():
		var other: Dictionary = yam_minions[i]
		if not other.dead and other.col == minion.col and other.row == minion.row:
			if i < index:
				order += 1
			total += 1
	return Vector2((float(order) - float(total - 1) * 0.5) * 14.0, float(order) * 2.0)

func draw_yam_minion(minion: Dictionary, stack_offset := Vector2.ZERO) -> void:
	if minion.dead:
		return
	var pos := cell_center(minion.col,minion.row) + stack_offset
	var bob := sin(minion.anim*4.0)*1.5
	var body_color := Color("#ed8554") if minion.attack_flash <= 0.0 else Color("#ffd06b")
	draw_circle(pos+Vector2(0,8+bob),22,body_color)
	draw_circle(pos+Vector2(-8,3+bob),3,Color("#30231f"))
	draw_circle(pos+Vector2(8,3+bob),3,Color("#30231f"))
	draw_line(pos+Vector2(-7,15+bob),pos+Vector2(7,15+bob),Color("#77352d"),3)
	draw_colored_polygon(PackedVector2Array([
		pos+Vector2(-5,-13+bob),pos+Vector2(-1,-27+bob),
		pos+Vector2(4,-14+bob),pos+Vector2(12,-24+bob),
		pos+Vector2(9,-9+bob)
	]),Color("#57a74b"))
	draw_line(pos+Vector2(20,4+bob),pos+Vector2(31,-3+bob),Color("#7a3b2c"),5)
	if show_health_bars and minion.hp < minion.max_hp:
		draw_bar(Vector2(pos.x-27,pos.y-29-stack_offset.y*3.0),54,minion.hp/minion.max_hp,Color("#f09a5f"))

func draw_potato_mine(pos: Vector2, armed: bool, scale: float) -> void:
	var dirt := PackedVector2Array()
	for i in 16:
		var angle := TAU * float(i) / 16.0
		dirt.append(pos + Vector2(cos(angle) * 35.0, 24.0 + sin(angle) * 11.0) * scale)
	draw_colored_polygon(dirt, Color("#805b39"))
	if not armed:
		draw_circle(pos + Vector2(0, 18) * scale, 17 * scale, Color("#a67543"))
		draw_circle(pos + Vector2(-7, 13) * scale, 2.5 * scale, Color("#3b2b25"))
		draw_circle(pos + Vector2(8, 13) * scale, 2.5 * scale, Color("#3b2b25"))
	else:
		draw_circle(pos + Vector2(0, 5) * scale, 24 * scale, Color("#bd8749"))
		draw_circle(pos + Vector2(-8, 0) * scale, 3.5 * scale, Color("#30251f"))
		draw_circle(pos + Vector2(9, 0) * scale, 3.5 * scale, Color("#30251f"))
		draw_line(pos + Vector2(-9, 13) * scale, pos + Vector2(10, 13) * scale, Color("#633d2b"), 3 * scale)
		draw_rect(Rect2(pos + Vector2(-4, -27) * scale, Vector2(8, 12) * scale), Color("#d9b25b"))
		draw_circle(pos + Vector2(0, -30) * scale, 5 * scale, Color("#f2d65c"))

const ZOMBIE_BOARD_LIFT := 12.0

func zombie_display_position(z: Dictionary) -> Vector2:
	if z.has("draw_y"):
		return Vector2(float(z.x),float(z.draw_y))
	return Vector2(float(z.x),BOARD_Y+float(z.get("draw_row",z.row))*CELL_H+CELL_H/2.0-ZOMBIE_BOARD_LIFT)

func zombie_bar_position(z: Dictionary, pos: Vector2) -> Vector2:
	# 血条留在原位置，第一行不会因角色上移而钻到顶部栏后面。
	return pos if z.has("draw_y") else pos+Vector2(0,ZOMBIE_BOARD_LIFT)

func draw_zombie(z: Dictionary) -> void:
	if z.kind=="kart":
		draw_kart_zombie(z)
		return
	if z.kind=="imp":
		draw_imp_zombie(z)
		return
	var pos := zombie_display_position(z)
	var scale: float = z.get("draw_scale",1.0)
	var head := ZombieArt.draw(self,z,pos,scale,art_parent_transform)
	var skin := Color("#92a17b") if z.slow<=0 else Color("#71b8bd")
	if z.kind == "flag":
		draw_line(pos+Vector2(-19,-21)*scale,pos+Vector2(-34,-30)*scale,Color("#70513b"),11*scale)
		draw_line(pos+Vector2(-34,-30)*scale,pos+Vector2(-34,-43)*scale,skin,8*scale)
		draw_circle(pos+Vector2(-34,-45)*scale,7*scale,skin)
	if z.kind=="cone" and not z.get("armor_lost",false):
		draw_colored_polygon(PackedVector2Array([head+Vector2(-22,-18)*scale,head+Vector2(1,-62)*scale,head+Vector2(25,-18)*scale]),Color("#e88737"))
		draw_rect(Rect2(head+Vector2(-28,-21)*scale,Vector2(58,8)*scale),Color("#f0a246"))
		draw_line(head+Vector2(-13,-36)*scale,head+Vector2(12,-36)*scale,Color("#f6c06b"),4*scale)
	elif z.kind=="bucket" and not z.get("armor_lost",false):
		draw_colored_polygon(PackedVector2Array([head+Vector2(-25,-55)*scale,head+Vector2(24,-51)*scale,head+Vector2(29,-17)*scale,head+Vector2(-21,-18)*scale]),Color("#879397"))
		draw_rect(Rect2(head+Vector2(-30,-56)*scale,Vector2(61,7)*scale),Color("#c0c7c7"))
		draw_line(head+Vector2(-16,-41)*scale,head+Vector2(21,-38)*scale,Color("#5d696c"),3*scale)
	elif z.kind=="charger" and not z.get("armor_lost",false):
		# 冲锋盔由圆顶和完整面甲组成；防具存在时遮住原脸，
		# 仅通过观察缝和通气孔暗示里面的僵尸。
		draw_colored_polygon(PackedVector2Array([
			head+Vector2(-29,-13)*scale,head+Vector2(-24,-40)*scale,
			head+Vector2(0,-57)*scale,head+Vector2(24,-40)*scale,
			head+Vector2(30,-13)*scale
		]),Color("#7f8d91"))
		# 面甲向下覆盖整张脸，底部略微收窄以免看起来像方桶。
		draw_colored_polygon(PackedVector2Array([
			head+Vector2(-30,-15)*scale,head+Vector2(31,-15)*scale,
			head+Vector2(28,20)*scale,head+Vector2(17,36)*scale,
			head+Vector2(-18,34)*scale,head+Vector2(-29,19)*scale
		]),Color("#6f7d81"))
		draw_line(head+Vector2(-32,-14)*scale,head+Vector2(33,-14)*scale,Color("#bdc7c8"),6*scale)
		draw_line(head+Vector2(0,-54)*scale,head+Vector2(0,-17)*scale,Color("#515e62"),3*scale)
		draw_line(head+Vector2(-20,-39)*scale,head+Vector2(-26,-15)*scale,Color("#9da9ab"),3*scale)
		draw_line(head+Vector2(20,-39)*scale,head+Vector2(26,-15)*scale,Color("#515e62"),3*scale)
		# 狭窄的观察缝完全取代裸露的双眼。
		draw_colored_polygon(PackedVector2Array([
			head+Vector2(-23,-5)*scale,head+Vector2(24,-5)*scale,
			head+Vector2(20,3)*scale,head+Vector2(-22,3)*scale
		]),Color("#263235"))
		draw_line(head+Vector2(-13,-2)*scale,head+Vector2(-5,-2)*scale,Color("#b9c97d"),2*scale)
		# 通气孔和铆钉让下半张面甲保持可读性。
		for vent_x in [-13.0,-5.0,5.0,13.0]:
			draw_line(head+Vector2(vent_x,16)*scale,head+Vector2(vent_x-2.0,24)*scale,Color("#3f4b4f"),2*scale)
		draw_circle(head+Vector2(-24,10)*scale,2.5*scale,Color("#c0c9ca"))
		draw_circle(head+Vector2(24,10)*scale,2.5*scale,Color("#c0c9ca"))
	elif z.kind=="runner":
		draw_rect(Rect2(head+Vector2(-27,-24)*scale,Vector2(52,9)*scale),Color("#e95855"))
		draw_colored_polygon(PackedVector2Array([head+Vector2(23,-22)*scale,head+Vector2(45,-33)*scale,head+Vector2(35,-17)*scale]),Color("#e95855"))
	elif z.kind=="swing":
		# 仅用耳机和骨架动作表现摇摆，避免额外装饰遮挡身体轮廓。
		draw_arc(head+Vector2(0,-2)*scale,28*scale,PI,TAU,16,Color("#824f9d"),5*scale)
		draw_circle(head+Vector2(-27,-1)*scale,8*scale,Color("#b868c2"))
		draw_circle(head+Vector2(27,-1)*scale,8*scale,Color("#b868c2"))
	elif z.kind=="flag":
		# 面向左侧时，角色右手位于画面左侧；旗杆由这只前手握持。
		var pole_x := pos.x - 34.0 * scale
		draw_line(Vector2(pole_x,pos.y+28*scale),Vector2(pole_x,pos.y-104*scale),Color("#d9c8a1"),4*scale)
		draw_colored_polygon(PackedVector2Array([
			Vector2(pole_x,pos.y-102*scale), Vector2(pole_x-48*scale,pos.y-91*scale),
			Vector2(pole_x,pos.y-72*scale)]),Color("#e4514c"))
		draw_circle(Vector2(pole_x-15*scale,pos.y-88*scale),7*scale,Color("#f5e8c0"))
		# 手掌覆盖在旗杆上，表现为真正握持而不是旗杆悬空。
		draw_circle(Vector2(pole_x,pos.y-45*scale),5*scale,skin.darkened(.08))
	if z.get("rooted",false):
		draw_rooted_effect(pos,scale)
	# 僵尸血条始终显示；草坪顶部留出的空间可完整容纳第一行血条和帽子。
	if show_health_bars and not z.get("hide_bar", false):
		draw_bar(zombie_bar_position(z,pos)+Vector2(-39,-112)*scale,68*scale,z.hp/z.max_hp,Color("#df6b54"))
	if z.slow>0: draw_circle(pos+Vector2(-10,-55)*scale,32*scale,Color(0.4,0.9,1,0.13),false,3*scale)

func draw_kart_zombie(z: Dictionary) -> void:
	var pos := zombie_display_position(z)
	var scale: float = z.get("draw_scale",1.0)
	var bounce := sin(z.anim*3.2)*1.5 if z.get("walking",true) else 0.0
	ImpArt.draw_driver(self,z,pos+Vector2(0,bounce)*scale,scale,art_parent_transform)
	# 低矮、缓慢的自制卡丁车，前端朝向房子。
	draw_circle(pos+Vector2(-31,31+bounce)*scale,14*scale,Color("#26302f"))
	draw_circle(pos+Vector2(35,31+bounce)*scale,14*scale,Color("#26302f"))
	draw_circle(pos+Vector2(-31,31+bounce)*scale,6*scale,Color("#89928a"))
	draw_circle(pos+Vector2(35,31+bounce)*scale,6*scale,Color("#89928a"))
	draw_colored_polygon(PackedVector2Array([
		pos+Vector2(-54,8+bounce)*scale,pos+Vector2(-40,-12+bounce)*scale,
		pos+Vector2(30,-10+bounce)*scale,pos+Vector2(52,15+bounce)*scale,
		pos+Vector2(43,28+bounce)*scale,pos+Vector2(-49,28+bounce)*scale
	]),Color("#d95443"))
	draw_rect(Rect2(pos+Vector2(-54,12+bounce)*scale,Vector2(18,8)*scale),Color("#efbf59"))
	draw_line(pos+Vector2(-16,-7+bounce)*scale,pos+Vector2(-28,-31+bounce)*scale,Color("#343e3a"),5*scale)
	draw_circle(pos+Vector2(-30,-34+bounce)*scale,9*scale,Color("#343e3a"),false,4*scale)
	if z.get("rooted",false): draw_rooted_effect(pos,scale)
	if show_health_bars and not z.get("hide_bar",false):
		draw_bar(zombie_bar_position(z,pos)+Vector2(-39,-72)*scale,78*scale,z.hp/z.max_hp,Color("#df6b54"))

func draw_imp_zombie(z: Dictionary) -> void:
	var pos := zombie_display_position(z)
	var size: float = z.get("draw_scale",1.0)
	ImpArt.draw(self,z,pos,size,art_parent_transform)
	if z.get("rooted",false): draw_rooted_effect(pos,size)
	if show_health_bars and not z.get("hide_bar",false):
		draw_bar(zombie_bar_position(z,pos)+Vector2(-27,-66)*size,54*size,z.hp/z.max_hp,Color("#df6b54"))

func draw_rooted_effect(pos: Vector2, scale: float) -> void:
	draw_arc(pos+Vector2(0,38)*scale,28*scale,0,TAU,22,Color("#58b78d"),6*scale)
	for offset in [-18.0,0.0,18.0]:
		draw_circle(pos+Vector2(offset,37)*scale,6*scale,Color(0.48,0.86,0.68,0.75))

func draw_detached_arm(arm: Dictionary) -> void:
	var pos: Vector2 = arm.pos
	var angle: float = arm.angle
	var skin := Color("#71b8bd") if arm.slow else Color("#83a96b")
	var jacket := Color("#46372f")
	var elbow := pos + Vector2(16,5).rotated(angle)
	var wrist := pos + Vector2(27,19).rotated(angle)
	draw_line(pos,elbow,jacket,10.0)
	draw_line(elbow,wrist,skin,8.0)
	draw_circle(wrist,6.0,skin.darkened(.08))

func draw_dropped_armor(armor: Dictionary) -> void:
	var pos: Vector2 = armor.pos
	var angle: float = armor.angle
	if armor.kind == "cone":
		draw_colored_polygon(PackedVector2Array([
			pos+Vector2(-23,18).rotated(angle),pos+Vector2(0,-28).rotated(angle),
			pos+Vector2(24,18).rotated(angle)]),Color("#e88737"))
		draw_line(pos+Vector2(-27,20).rotated(angle),pos+Vector2(28,20).rotated(angle),Color("#f0a246"),7)
	elif armor.kind == "bucket":
		draw_colored_polygon(PackedVector2Array([
			pos+Vector2(-24,-18).rotated(angle),pos+Vector2(24,-18).rotated(angle),
			pos+Vector2(21,18).rotated(angle),pos+Vector2(-21,18).rotated(angle)]),Color("#879397"))
		draw_line(pos+Vector2(-28,-20).rotated(angle),pos+Vector2(28,-20).rotated(angle),Color("#c0c7c7"),6)
		draw_line(pos+Vector2(-17,-6).rotated(angle),pos+Vector2(17,-6).rotated(angle),Color("#5d696c"),3)
	else:
		draw_arc(pos,27,PI+angle,TAU+angle,18,Color("#77858a"),17)
		draw_line(pos+Vector2(-30,0).rotated(angle),pos+Vector2(30,0).rotated(angle),Color("#b7c1c2"),7)
		draw_line(pos+Vector2(0,-26).rotated(angle),pos+Vector2(0,-4).rotated(angle),Color("#566267"),3)

func draw_projectile(pr: Dictionary) -> void:
	if pr.get("needle",false):
		var pos := Vector2(pr.x,pr.y)
		draw_colored_polygon(PackedVector2Array([
			pos+Vector2(-12,0),pos+Vector2(-3,-5),pos+Vector2(8,0),pos+Vector2(-3,5)
		]),Color("#8e4eb1"))
		draw_circle(pos,4,Color("#d191e5"))
		return
	if pr.get("piercing",false):
		var pos := Vector2(pr.x,pr.y)
		draw_colored_polygon(PackedVector2Array([
			pos+Vector2(-13,-3),pos+Vector2(10,0),pos+Vector2(-13,3)
		]),Color("#e6d49b"))
		draw_line(pos+Vector2(-8,0),pos+Vector2(7,0),Color("#6e9f4e"),2)
		return
	var c := Color("#7de04e") if not pr.snow else Color("#8cebf2")
	draw_circle(Vector2(pr.x,pr.y),8,c); draw_rect(Rect2(pr.x-14,pr.y-2,7,4),c.darkened(.2))

func draw_sun(s: Dictionary) -> void:
	var pos: Vector2=s.pos; var rad:=19.0+sin(s.pulse*5.0)*2.0
	for i in 8:
		var a:=i*TAU/8.0; draw_line(pos+Vector2(cos(a),sin(a))*24,pos+Vector2(cos(a),sin(a))*31,Color("#ffe466"),5)
	draw_circle(pos,rad,Color("#ffd34d")); draw_circle(pos-Vector2(5,5),5,Color("#fff09a"))

func draw_coin(coin: Dictionary) -> void:
	var pulse := 1.0+sin(float(coin.pulse)*7.0)*0.07
	draw_coin_icon(Vector2(coin.pos),String(coin.kind),pulse)

func draw_coin_icon(pos: Vector2, kind: String, scale := 1.0) -> void:
	var outer := Color("#ffd34f") if kind=="gold" else Color("#d9e1df")
	var inner := Color("#e8a92f") if kind=="gold" else Color("#9eaeae")
	draw_circle(pos,14.0*scale,Color("#53452f"))
	draw_circle(pos,12.0*scale,outer)
	draw_circle(pos,8.0*scale,inner)
	draw_line(pos+Vector2(-3,-5)*scale,pos+Vector2(-3,5)*scale,outer,2.0*scale)
	draw_line(pos+Vector2(3,-5)*scale,pos+Vector2(3,5)*scale,outer,2.0*scale)

func draw_item_icon(kind: String, pos: Vector2, scale := 1.0) -> void:
	if kind=="air_bomb":
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-20,-10)*scale,pos+Vector2(12,-16)*scale,pos+Vector2(22,0)*scale,pos+Vector2(12,16)*scale,pos+Vector2(-20,10)*scale]),Color("#d94e43"))
		draw_rect(Rect2(pos+Vector2(-27,-7)*scale,Vector2(9,14)*scale),Color("#e8ca72"))
		draw_line(pos+Vector2(14,-11)*scale,pos+Vector2(27,-24)*scale,Color("#f0df9b"),3*scale)
		draw_circle(pos+Vector2(29,-27)*scale,4*scale,Color("#ffdc55"))
	else:
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-21,-17)*scale,pos+Vector2(20,-17)*scale,pos+Vector2(26,20)*scale,pos+Vector2(-26,20)*scale]),Color("#d59d4b"))
		draw_line(pos+Vector2(-17,-14)*scale,pos+Vector2(17,-14)*scale,Color("#f0d187"),4*scale)
		draw_circle(pos+Vector2(0,3)*scale,11*scale,Color("#ffe55f"))
		draw_circle(pos+Vector2(0,3)*scale,6*scale,Color("#fff1a1"))

func draw_money_bag(pos: Vector2, scale := 1.0) -> void:
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-30,-25)*scale,pos+Vector2(28,-25)*scale,pos+Vector2(42,28)*scale,pos+Vector2(-42,28)*scale]),Color("#b67d42"))
	draw_line(pos+Vector2(-24,-22)*scale,pos+Vector2(24,-22)*scale,Color("#e4bf70"),6*scale)
	draw_string(ThemeDB.fallback_font,pos+Vector2(-22,15)*scale,"钱",HORIZONTAL_ALIGNMENT_CENTER,44*scale,24*scale,Color("#ffe29a"))

func draw_mower(m: Dictionary) -> void:
	if m.used:return
	var pos:=Vector2(m.x,BOARD_Y+m.row*CELL_H+CELL_H/2.0+5.0)
	draw_circle(pos+Vector2(-15,17),10,Color("#253535")); draw_circle(pos+Vector2(17,17),10,Color("#253535")); draw_rect(Rect2(pos+Vector2(-25,-5),Vector2(55,24)),Color("#d94c42")); draw_rect(Rect2(pos+Vector2(-32,-10),Vector2(12,9)),Color("#d7d7ba")); draw_line(pos+Vector2(23,-3),pos+Vector2(37,-31),Color("#4d554f"),5)

func draw_shovel_icon(pos: Vector2, scale: float) -> void:
	draw_line(pos + Vector2(-8, 15) * scale, pos + Vector2(13, -13) * scale, Color("#d9b06c"), 7.0 * scale)
	draw_line(pos + Vector2(10, -12) * scale, pos + Vector2(18, -22) * scale, Color("#f2d799"), 5.0 * scale)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-18, 14) * scale,
		pos + Vector2(-5, 7) * scale,
		pos + Vector2(3, 17) * scale,
		pos + Vector2(-9, 29) * scale,
		pos + Vector2(-20, 25) * scale
	]), Color("#c7d0ca"))
	draw_line(pos + Vector2(-17, 17) * scale, pos + Vector2(-8, 25) * scale, Color("#eef2df"), 2.0 * scale)

func draw_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos,Vector2(width,6)),Color("#28332e")); draw_rect(Rect2(pos+Vector2(1,1),Vector2((width-2)*clampf(ratio,0,1),4)),color)

func draw_panel(rect: Rect2, fill: Color, border: Color, thick: float) -> void:
	draw_rect(rect,fill); draw_rect(rect,border,false,thick); draw_line(rect.position+Vector2(thick,thick),Vector2(rect.end.x-thick,rect.position.y+thick),fill.lightened(.18),thick)

func draw_mini_plant(kind: String, pos: Vector2) -> void:
	if kind == "mine": draw_potato_mine(pos, true, 0.48)
	else: draw_plant_shape(kind,pos,0.48)

func draw_wave_banner() -> void:
	var alpha := clampf(wave_banner_time, 0.0, 1.0)
	draw_rect(Rect2(290,285,830,118),Color(0.10,0.08,0.06,0.82*alpha))
	draw_rect(Rect2(290,285,830,118),Color(1.0,0.83,0.30,alpha),false,5)
	draw_line(Vector2(345,378),Vector2(345,302),Color(0.9,0.85,0.7,alpha),5)
	draw_colored_polygon(PackedVector2Array([Vector2(348,304),Vector2(415,323),Vector2(348,344)]),Color(0.88,0.25,0.22,alpha))
	draw_string(ThemeDB.fallback_font,Vector2(430,356),"一大波僵尸正在接近！",HORIZONTAL_ALIGNMENT_CENTER,610,37,Color(1.0,0.91,0.55,alpha))

func draw_title_plant(pos: Vector2) -> void:
	draw_plant_shape("pea",pos,2.15)

func draw_title_zombie(pos: Vector2) -> void:
	draw_zombie({"x":pos.x,"draw_y":pos.y,"row":2,"anim":0.0,"slow":0.0,"kind":"cone","hp":1.0,"max_hp":1.0,"hide_bar":true})

func draw_pause_overlay() -> void:
	draw_rect(Rect2(0,0,W,H),Color(0.03,0.08,0.07,.82))
	draw_panel(Rect2(250,35,780,650),Color("#295451"),Color("#bde9df"),5)
	draw_rect(Rect2(257,42,766,8),Color("#73bdb3"))
	if pause_page == "more":
		draw_more_settings()
		return
	if pause_page == "keys":
		draw_key_settings()
		return
	var standalone := game_state=="settings"
	draw_string(ThemeDB.fallback_font,Vector2(250,103),"设置" if standalone else "暂停与设置",HORIZONTAL_ALIGNMENT_CENTER,780,42,Color("#fff4b0"))
	draw_string(ThemeDB.fallback_font,Vector2(285,134),"游戏速度",HORIZONTAL_ALIGNMENT_LEFT,150,20,Color.WHITE)
	for i in speed_options.size():
		var speed: float = speed_options[i]
		var active := is_equal_approx(game_speed, speed)
		var rect := Rect2(335 + i * 104, 145, 90, 44)
		draw_panel(rect,Color("#8cb95b") if active else Color("#41706b"),Color("#fff0a0") if active else Color("#79a8a1"),3)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+29),str(speed)+" 倍",HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,16,Color.WHITE)
	draw_volume_slider("音乐", music_volume, 225)
	draw_volume_slider("音效", sfx_volume, 280)
	# 自动拾取阳光与钱币
	draw_panel(Rect2(420,310,32,32),Color("#e7f4e8"),Color("#153f3d"),3)
	if auto_collect_sun:
		draw_line(Vector2(426,326),Vector2(436,337),Color("#55a52e"),6)
		draw_line(Vector2(436,337),Vector2(449,315),Color("#55a52e"),6)
	draw_string(ThemeDB.fallback_font,Vector2(470,336),"自动拾取",HORIZONTAL_ALIGNMENT_LEFT,190,24,Color.WHITE)
	var fullscreen := get_window().mode == Window.MODE_FULLSCREEN or get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	draw_panel(Rect2(700,307,160,44),Color("#5c9d74") if fullscreen else Color("#41706b"),Color("#8fc5bb"),2)
	draw_string(ThemeDB.fallback_font,Vector2(700,336),"退出全屏" if fullscreen else "全屏显示",HORIZONTAL_ALIGNMENT_CENTER,160,18,Color.WHITE)
	if standalone:
		draw_pause_icon_button(Rect2(565,376,150,106),"gear","更多设置")
	else:
		draw_pause_icon_button(Rect2(360,376,150,106),"door","返回主菜单")
		draw_pause_icon_button(Rect2(565,376,150,106),"gear","更多设置")
		draw_pause_icon_button(Rect2(770,376,150,106),"restart","重新开始")
	draw_panel(Rect2(350,520,580,70),Color("#bceee6"),Color("#184d4b"),5)
	draw_string(ThemeDB.fallback_font,Vector2(350,566),"返回主菜单" if standalone else "返回游戏",HORIZONTAL_ALIGNMENT_CENTER,580,31,Color("#173c3a"))
	draw_string(ThemeDB.fallback_font,Vector2(250,650),"Esc 返回主菜单  •  F11 切换全屏" if standalone else "P / Esc 继续  •  F11 切换全屏",HORIZONTAL_ALIGNMENT_CENTER,780,15,Color("#b5d2cc"))
	if fullscreen_notice != "":
		draw_string(ThemeDB.fallback_font,Vector2(250,674),fullscreen_notice,HORIZONTAL_ALIGNMENT_CENTER,780,14,Color("#ffd28a"))

func draw_more_settings() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(250,105),"更多设置",HORIZONTAL_ALIGNMENT_CENTER,780,42,Color("#fff4b0"))
	draw_string(ThemeDB.fallback_font,Vector2(310,158),"操作设置",HORIZONTAL_ALIGNMENT_LEFT,200,22,Color.WHITE)
	draw_panel(Rect2(410,180,460,74),Color("#68b8ad"),Color("#d4f4ef"),4)
	draw_string(ThemeDB.fallback_font,Vector2(410,227),"⌨  快捷键设置",HORIZONTAL_ALIGNMENT_CENTER,460,26,Color("#153e3b"))
	draw_string(ThemeDB.fallback_font,Vector2(310,293),"当前设置",HORIZONTAL_ALIGNMENT_LEFT,200,22,Color.WHITE)
	draw_panel(Rect2(310,330,660,170),Color("#234642"),Color("#56827b"),2)
	draw_rect(Rect2(316,336,648,43),Color("#315b56"))
	draw_string(ThemeDB.fallback_font,Vector2(340,364),"显示植物和僵尸的血量",HORIZONTAL_ALIGNMENT_LEFT,360,18,Color.WHITE)
	draw_panel(Rect2(850,341,92,32),Color("#62a96a") if show_health_bars else Color("#665b59"),Color("#94c5a0") if show_health_bars else Color("#8b7d78"),2)
	draw_string(ThemeDB.fallback_font,Vector2(850,363),"显示" if show_health_bars else "隐藏",HORIZONTAL_ALIGNMENT_CENTER,92,15,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(340,400),"游戏速度",HORIZONTAL_ALIGNMENT_LEFT,180,17,Color("#b9d6d0"))
	draw_string(ThemeDB.fallback_font,Vector2(690,400),str(game_speed)+" 倍",HORIZONTAL_ALIGNMENT_RIGHT,220,17,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(340,432),"自动拾取",HORIZONTAL_ALIGNMENT_LEFT,180,17,Color("#b9d6d0"))
	draw_string(ThemeDB.fallback_font,Vector2(690,432),"开启" if auto_collect_sun else "关闭",HORIZONTAL_ALIGNMENT_RIGHT,220,17,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(340,464),"音乐 / 音效",HORIZONTAL_ALIGNMENT_LEFT,180,17,Color("#b9d6d0"))
	draw_string(ThemeDB.fallback_font,Vector2(690,464),str(roundi(music_volume*100))+"%  /  "+str(roundi(sfx_volume*100))+"%",HORIZONTAL_ALIGNMENT_RIGHT,220,17,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(340,494),"显示模式",HORIZONTAL_ALIGNMENT_LEFT,180,17,Color("#b9d6d0"))
	var full := get_window().mode == Window.MODE_FULLSCREEN or get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	draw_string(ThemeDB.fallback_font,Vector2(690,494),"全屏" if full else "窗口",HORIZONTAL_ALIGNMENT_RIGHT,220,17,Color.WHITE)
	draw_panel(Rect2(350,565,580,64),Color("#bceee6"),Color("#184d4b"),4)
	draw_string(ThemeDB.fallback_font,Vector2(350,607),"返回设置" if game_state=="settings" else "返回暂停菜单",HORIZONTAL_ALIGNMENT_CENTER,580,25,Color("#173c3a"))

func draw_key_settings() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(250,98),"快捷键设置",HORIZONTAL_ALIGNMENT_CENTER,780,38,Color("#fff4b0"))
	draw_string(ThemeDB.fallback_font,Vector2(250,126),"点击键位后按下新按键；A、S固定用于关卡道具",HORIZONTAL_ALIGNMENT_CENTER,780,15,Color("#b8d4ce"))
	for i in plant_keys.size():
		var col := 0 if i < 4 else 1
		var row := i if i < 4 else i - 4
		var base_x := 300.0 if col == 0 else 670.0
		var y := 145.0 + row * 67.0
		var occupied := i < equipped_plants.size()
		draw_string(ThemeDB.fallback_font,Vector2(base_x,y+20),"植物卡槽 %d" % (i + 1),HORIZONTAL_ALIGNMENT_LEFT,145,17,Color.WHITE if occupied else Color("#88a59f"))
		var current_name: String = "当前：" + str(PLANT_DATA[equipped_plants[i]].name) if occupied else "尚未装备"
		draw_string(ThemeDB.fallback_font,Vector2(base_x,y+40),current_name,HORIZONTAL_ALIGNMENT_LEFT,145,12,Color("#b9d6d0") if occupied else Color("#688680"))
		var key_rect := Rect2(base_x+155,y,120,44)
		var waiting := binding_target == i
		draw_panel(key_rect,Color("#b3ad5c") if waiting else Color("#477772"),Color("#fff0a0") if waiting else Color("#8ab9b1"),3)
		draw_string(ThemeDB.fallback_font,Vector2(key_rect.position.x,key_rect.position.y+29),"请按键…" if waiting else key_name(plant_keys[i]),HORIZONTAL_ALIGNMENT_CENTER,key_rect.size.x,17,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(445,516),"铲子",HORIZONTAL_ALIGNMENT_LEFT,125,20,Color.WHITE)
	var shovel_rect := Rect2(580,487,120,44)
	var shovel_waiting := binding_target == -1
	draw_panel(shovel_rect,Color("#b3ad5c") if shovel_waiting else Color("#765f48"),Color("#fff0a0") if shovel_waiting else Color("#b89b78"),3)
	draw_string(ThemeDB.fallback_font,Vector2(580,516),"请按键…" if shovel_waiting else key_name(shovel_key),HORIZONTAL_ALIGNMENT_CENTER,120,17,Color.WHITE)
	draw_panel(Rect2(350,585,580,58),Color("#bceee6"),Color("#184d4b"),4)
	draw_string(ThemeDB.fallback_font,Vector2(350,623),"返回更多设置",HORIZONTAL_ALIGNMENT_CENTER,580,23,Color("#173c3a"))

func draw_volume_slider(label: String, value: float, y: float) -> void:
	draw_string(ThemeDB.fallback_font,Vector2(300,y+9),label,HORIZONTAL_ALIGNMENT_LEFT,110,27,Color.WHITE)
	draw_rect(Rect2(445,y-7,380,20),Color("#c9e5e2"))
	draw_rect(Rect2(449,y-3,372*value,12),Color("#64b8ad"))
	var knob_x := 445.0 + 380.0 * value
	draw_circle(Vector2(knob_x,y+3),20,Color("#d9f3ef"))
	draw_circle(Vector2(knob_x,y+3),15,Color("#70c3b8"))
	draw_string(ThemeDB.fallback_font,Vector2(850,y+9),str(roundi(value*100))+"%",HORIZONTAL_ALIGNMENT_LEFT,70,18,Color("#e8f7f4"))

func draw_pause_icon_button(rect: Rect2, kind: String, label: String) -> void:
	draw_panel(rect,Color("#66b7ad"),Color("#173f3e"),4)
	var center := Vector2(rect.position.x+rect.size.x/2.0,rect.position.y+40)
	match kind:
		"door":
			draw_rect(Rect2(center+Vector2(-23,-25),Vector2(36,48)),Color("#f1f4e9"))
			draw_rect(Rect2(center+Vector2(-17,-19),Vector2(24,36)),Color("#8fd2ca"))
			draw_colored_polygon(PackedVector2Array([center+Vector2(27,-12),center+Vector2(10,0),center+Vector2(27,12)]),Color.WHITE)
			draw_line(center+Vector2(11,0),center+Vector2(38,0),Color.WHITE,6)
		"gear":
			for i in 8:
				var a := i*TAU/8.0
				draw_rect(Rect2(center+Vector2(cos(a),sin(a))*27-Vector2(5,5),Vector2(10,10)),Color.WHITE)
			draw_circle(center,25,Color.WHITE); draw_circle(center,11,Color("#3d8179"))
		"restart":
			draw_arc(center,25,-1.0,4.8,20,Color.WHITE,8)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-28,-20),center+Vector2(-8,-23),center+Vector2(-22,-5)]),Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+91),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,17,Color.WHITE)

func draw_end_overlay() -> void:
	draw_rect(Rect2(0,0,W,H),Color(0.03,0.08,0.07,.76))
	var won:=game_state=="win"
	draw_string(ThemeDB.fallback_font,Vector2(0,230),"%s完成！" % level_title(current_level) if won else "僵尸攻破了花园",HORIZONTAL_ALIGNMENT_CENTER,1280,54,Color("#ffe36c") if won else Color("#f06b5e"))
	var reward: String = LEVEL_DATA[current_level].reward
	if won and reward_bag_awarded:
		draw_panel(Rect2(405,275,470,155),Color("#315a48"),Color("#ffe074"),5)
		draw_money_bag(Vector2(485,350),1.0)
		for i in 10:
			draw_coin_icon(Vector2(585+(i%5)*42,318+int(i/5)*52),"silver",0.72)
		draw_string(ThemeDB.fallback_font,Vector2(565,414),"钱袋：10枚银币（100资金）",HORIZONTAL_ALIGNMENT_CENTER,285,17,Color("#ffe6a2"))
	elif won and reward in PLANT_DATA:
		draw_panel(Rect2(445,275,390,155),Color("#315a48"),Color("#ffe074"),5)
		draw_plant_shape(reward,Vector2(520,355),1.0)
		draw_string(ThemeDB.fallback_font,Vector2(575,330),"获得新植物",HORIZONTAL_ALIGNMENT_LEFT,220,20,Color("#cde5c5"))
		draw_string(ThemeDB.fallback_font,Vector2(575,370),PLANT_DATA[reward].name,HORIZONTAL_ALIGNMENT_LEFT,220,32,Color("#ffe36c"))
	elif won:
		draw_string(ThemeDB.fallback_font,Vector2(0,340),"当前主线已经全部完成！",HORIZONTAL_ALIGNMENT_CENTER,1280,27,Color.WHITE)
	else:
		draw_string(ThemeDB.fallback_font,Vector2(0,330),"调整阵型，再试一次吧。",HORIZONTAL_ALIGNMENT_CENTER,1280,24,Color.WHITE)
	if won:
		draw_string(ThemeDB.fallback_font,Vector2(0,466),"本关获得 %d 资金  •  保留小推车 %d 辆（每辆100）"%[level_money_earned,mower_bonus_count],HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#d9e8cf"))
	draw_panel(Rect2(300,500,320,68),Color("#6aa746"),Color("#d9e378"),4)
	var button_text := "重试本关" if not won else ("进入下一关" if current_level < LEVEL_DATA.size() else "重玩本关")
	draw_string(ThemeDB.fallback_font,Vector2(300,545),button_text,HORIZONTAL_ALIGNMENT_CENTER,320,28,Color("#183421"))
	draw_panel(Rect2(660,500,320,68),Color("#4d7770"),Color("#a9d4ca"),4)
	draw_string(ThemeDB.fallback_font,Vector2(660,545),"返回主菜单",HORIZONTAL_ALIGNMENT_CENTER,320,27,Color.WHITE)
