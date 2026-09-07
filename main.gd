extends Node2D

const W := 1280.0
const H := 720.0
const BOARD_X := 165.0
const BOARD_Y := 150.0
const CELL_W := 120.0
const CELL_H := 110.0
const ROWS := 5
const COLS := 9
const ZOMBIE_DPS := 100.0
const SUNFLOWER_INTERVAL := 16.0
const ZOMBIE_POINTS := {
	"normal": 1,
	"cone": 2,
	"bucket": 3,
	"runner": 3
}

const PLANT_DATA := {
	"sunflower": {"name":"向日葵", "cost":50, "cool":5.0, "hp":300.0, "damage":0.0, "interval":0.0, "color":Color("#ffd84a")},
	"pea": {"name":"豌豆射手", "cost":100, "cool":6.0, "hp":300.0, "damage":20.0, "interval":1.42, "color":Color("#70cf45")},
	"wall": {"name":"坚果墙", "cost":50, "cool":12.0, "hp":4000.0, "damage":0.0, "interval":0.0, "color":Color("#b97942")},
	"mine": {"name":"土豆地雷", "cost":25, "cool":15.0, "hp":300.0, "damage":1800.0, "interval":0.0, "arm_time":14.0, "color":Color("#b88148")},
	"snow": {"name":"寒冰射手", "cost":175, "cool":9.0, "hp":300.0, "damage":25.0, "interval":1.85, "color":Color("#76dceb")},
	"cherry": {"name":"樱桃炸弹", "cost":150, "cool":30.0, "hp":300.0, "damage":1800.0, "interval":0.72, "color":Color("#ef4b45")},
	"yam_guard": {"name":"红薯防卫队", "cost":125, "cool":15.0, "hp":300.0, "damage":60.0, "interval":0.0, "respawn":8.0, "heal":25.0, "color":Color("#c85f3d")}
}

const PLANT_INFO := {
	"sunflower": {"role":"资源生产", "summary":"周期性生产阳光，是建立防线经济的核心。", "tip":"尽早种植在后排，并用坚果墙保护。"},
	"pea": {"role":"单线输出", "summary":"向所在行发射豌豆，持续攻击前方的僵尸。", "tip":"适合成排布置，稳定处理普通僵尸。"},
	"wall": {"role":"前排防御", "summary":"拥有很高的生命值，可以长时间阻挡僵尸。", "tip":"放在输出植物前方，为攻击争取时间。"},
	"mine": {"role":"埋伏爆破", "summary":"种下后需要准备，成熟时会炸毁靠近的僵尸。", "tip":"提前种在僵尸行进路线上，适合低成本处理重甲敌人。"},
	"snow": {"role":"减速输出", "summary":"寒冰子弹会降低僵尸移动速度并造成伤害。", "tip":"每行一株即可显著延长整条防线的输出时间。"},
	"cherry": {"role":"范围爆发", "summary":"短暂延迟后爆炸，重创附近三行内的僵尸。", "tip":"适合处理密集尸群或紧急解围。"},
	"yam_guard": {"role":"跨行驻守", "summary":"向相邻黄土地块派出小红薯驻守；空闲时会回血，阵亡后会自动补充。", "tip":"种在第3行时，点击防卫队本体可切换上方或下方的驻守格。"}
}

const ZOMBIE_INFO := {
	"normal": {"name":"普通僵尸", "role":"基础敌人", "hp":190, "speed":15, "summary":"行动缓慢、耐久一般，是最常见的进攻单位。", "tip":"一株持续输出植物通常可以从容应对。"},
	"cone": {"name":"路障僵尸", "role":"强化敌人", "hp":560, "speed":15, "summary":"头顶路障提供额外防护，比普通僵尸更耐打。", "tip":"集中火力，或用寒冰射手拖延它的推进。"},
	"bucket": {"name":"铁桶僵尸", "role":"重甲敌人", "hp":1290, "speed":15, "summary":"铁桶带来极高防护，能够承受大量远程攻击。", "tip":"利用坚果拖延，并准备樱桃炸弹快速清除。"},
	"runner": {"name":"疾跑僵尸", "role":"快速敌人", "hp":160, "speed":35, "summary":"生命较低但移动迅速，容易突破尚未成形的防线。", "tip":"及时补齐空行，寒冰减速对它尤其有效。"},
	"flag": {"name":"旗帜僵尸", "role":"大波先锋", "hp":190, "speed":15, "summary":"挥舞旗帜走在尸群前方，宣告一大波僵尸来袭。", "tip":"旗帜出现时应立即检查每一行的防线。"}
}

const LEVEL_DATA := {
	1: {"world":"前院", "stage":1, "waves":10, "plants":["sunflower","pea","wall","mine"], "reward":"cherry"},
	2: {"world":"前院", "stage":2, "waves":10, "plants":["sunflower","pea","wall","mine","cherry"], "reward":"snow"},
	3: {"world":"前院", "stage":3, "waves":10, "plants":["sunflower","pea","wall","mine","cherry","snow"], "reward":"yam_guard"},
	4: {"world":"荒地", "stage":1, "waves":10, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard"], "reward":""}
}

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
var projectiles: Array = []
var suns: Array = []
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
var sfx_cache := {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_cursor := 0
var pause_page := "main"
var almanac_tab := "plants"
var almanac_selected := 0
var binding_target := -99
var fullscreen_notice := ""
var prepare_time := 0.0
var prepare_camera_x := 0.0
var prepare_returning := false
var available_plants: Array[String] = []
var preview_zombies: Array = []
var plant_keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_Q, KEY_W, KEY_E, KEY_R]
var shovel_key := KEY_D
const SETTINGS_PATH := "user://garden_settings.cfg"
const SAVE_PATH := "user://pixel_garden_save.cfg"
var campaign_completed := false
var saved_loadouts := {}

func _ready() -> void:
	rng.randomize()
	get_tree().root.content_scale_size = Vector2i(int(W), int(H))
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	get_window().min_size = Vector2i(800, 450)
	load_settings()
	load_save_game()
	setup_sfx_audio()
	apply_saved_display_mode.call_deferred()
	start_music()
	set_process(true)
	var args := OS.get_cmdline_user_args()
	if "--capture-almanac" in args:
		game_state = "almanac"
		if "--zombies" in args: almanac_tab = "zombies"
		capture_preview.call_deferred()
	elif "--capture-level-select" in args or "--smoke-level-select" in args:
		game_state = "level_select"
		if "--capture-level-select" in args: capture_preview.call_deferred()
	elif "--smoke-prepare" in args:
		prepare_level(3)
		prepare_camera_x = 520.0
	elif "--smoke-wasteland" in args:
		equipped_plants.assign(LEVEL_DATA[4].plants)
		reset_game(4)
		sun_points = 999
		place_plant("yam_guard", 2, 2)
		place_plant("yam_guard", 2, 0)
		spawn_zombie(1, "normal", 570.0)
		spawn_zombie(3, "cone", 570.0)
	elif "--capture-preview" in args or "--capture-zombie-art" in args or "--capture-pause" in args or "--capture-more" in args or "--capture-keys" in args or "--smoke-test" in args:
		reset_game()
		sun_points = 999
		place_plant("sunflower", 0, 0)
		place_plant("pea", 1, 1)
		place_plant("wall", 3, 2)
		place_plant("mine", 2, 2)
		place_plant("snow", 1, 3)
		place_plant("cherry", 2, 4)
		spawn_zombie(0, "normal", 910.0)
		spawn_zombie(1, "cone", 980.0)
		spawn_zombie(2, "bucket", 1050.0)
		spawn_zombie(3, "runner", 940.0)
		spawn_zombie(4, "flag", 1010.0)
		if "--capture-zombie-art" in args:
			# 专用视觉检查：第一只展示断臂，第二只贴近植物展示啃食姿态。
			zombies[0].hp = 90.0
			zombies[0].arm_lost = true
			zombies[1].x = cell_center(1, 1).x + 24.0
			zombies[1].biting = true
			zombies[2].hp = 180.0
			update_zombie_armor(zombies[2])
		if "--smoke-test" in args:
			current_wave = wave_plan.size() - 1
			spawn_clock = 0.1
			for plant in plants:
				if plant.kind == "mine": plant.timer = 0.0
		if "--capture-pause" in args:
			paused = true
		if "--capture-keys" in args:
			paused = true
			pause_page = "keys"
		if "--capture-more" in args:
			paused = true
			pause_page = "more"
		if "--capture-preview" in args or "--capture-zombie-art" in args or "--capture-pause" in args or "--capture-more" in args or "--capture-keys" in args:
			capture_preview.call_deferred()
	queue_redraw()

func capture_preview() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://preview.png")
	get_tree().quit()

func reset_game(level := current_level) -> void:
	current_level = clampi(level, 1, LEVEL_DATA.size())
	if equipped_plants.is_empty():
		equipped_plants.assign(LEVEL_DATA[current_level].plants)
	game_state = "play"
	paused = false
	game_time = 0.0
	sun_points = 150
	selected = ""
	plants.clear()
	zombies.clear()
	projectiles.clear()
	suns.clear()
	particles.clear()
	yam_minions.clear()
	detached_arms.clear()
	dropped_armor.clear()
	mowers.clear()
	cooldowns.clear()
	wave_plan = build_wave_plan(current_level)
	current_wave = 0
	spawn_clock = 6.0
	spawn_clock_start = spawn_clock
	big_wave_warning = false
	sky_sun_clock = 3.5
	final_wave_sent = false
	wave_banner_time = 0.0
	for key in PLANT_DATA:
		cooldowns[key] = 0.0
	for row in ROWS:
		mowers.append({"row":row, "x":195.0, "active":false, "used":false})
	message = ""
	message_time = 0.0
	queue_redraw()

func prepare_level(level: int) -> void:
	current_level = clampi(level, 1, LEVEL_DATA.size())
	game_state = "prepare"
	paused = false
	selected = ""
	prepare_time = 0.0
	prepare_camera_x = 0.0
	prepare_returning = false
	equipped_plants.clear()
	available_plants.assign(LEVEL_DATA[current_level].plants)
	if saved_loadouts.has(current_level):
		for kind in saved_loadouts[current_level]:
			if kind in available_plants and equipped_plants.size() < 8:
				equipped_plants.append(kind)
	plants.clear()
	zombies.clear()
	projectiles.clear()
	suns.clear()
	particles.clear()
	yam_minions.clear()
	detached_arms.clear()
	mowers.clear()
	dropped_armor.clear()
	build_zombie_preview()
	play_sfx(330.0, 0.12, 0.08, "square")
	queue_redraw()

func level_zombie_types() -> Array[String]:
	var result: Array[String] = ["normal", "cone", "flag"]
	if current_level == 4:
		return result
	if current_level >= 2: result.insert(2, "bucket")
	if current_level >= 3: result.insert(result.size() - 1, "runner")
	return result

func choose_preview_zombie() -> String:
	var value := rng.randf()
	if current_level == 1:
		return "cone" if value < 0.28 else "normal"
	if current_level == 2:
		if value < 0.07: return "bucket"
		return "cone" if value < 0.38 else "normal"
	if current_level == 4:
		return "cone" if value < 0.35 else "normal"
	if value < 0.12: return "bucket"
	if value < 0.28: return "runner"
	return "cone" if value < 0.52 else "normal"

func build_zombie_preview() -> void:
	preview_zombies.clear()
	var kinds := level_zombie_types()
	var display_kinds: Array[String] = []
	# 每种必放一个，其余位置按实际出场倾向加权抽取。
	for kind in kinds: display_kinds.append(kind)
	while display_kinds.size() < 11:
		display_kinds.append(choose_preview_zombie())
	for i in display_kinds.size():
		var preview_pos := Vector2.ZERO
		var found_position := false
		for attempt in 40:
			preview_pos = Vector2(rng.randf_range(1305.0,1785.0),rng.randf_range(215.0,645.0))
			var separated := true
			for placed in preview_zombies:
				# 横向稍微压缩后再计算距离，形成自然散布而不是隐形网格。
				var offset := Vector2((preview_pos.x-float(placed.x))*0.72,preview_pos.y-float(placed.draw_y))
				if offset.length() < 102.0:
					separated = false
					break
			if separated:
				found_position = true
				break
		if not found_position:
			preview_pos = Vector2(rng.randf_range(1305.0,1785.0),rng.randf_range(215.0,645.0))
		preview_zombies.append({
			"kind":display_kinds[i], "x":preview_pos.x, "draw_y":preview_pos.y,
			"draw_scale":rng.randf_range(0.84,1.06),
			"row":0, "anim":0.0, "slow":0.0, "walking":false,
			"hp":1.0, "max_hp":1.0, "hide_bar":true
		})

func _process(delta: float) -> void:
	if game_state == "prepare":
		prepare_time += delta
		message_time = maxf(0.0, message_time - delta)
		if prepare_returning:
			prepare_camera_x = maxf(0.0, prepare_camera_x - delta * 520.0)
			if prepare_camera_x <= 0.0:
				reset_game(current_level)
		else:
			prepare_camera_x = minf(520.0, prepare_camera_x + delta * 390.0)
		queue_redraw()
		return
	if game_state != "play" or paused:
		queue_redraw()
		return
	var scaled_delta := delta * game_speed
	game_time += scaled_delta
	message_time = maxf(0.0, message_time - scaled_delta)
	wave_banner_time = maxf(0.0, wave_banner_time - scaled_delta)
	shake = maxf(0.0, shake - scaled_delta * 12.0)
	flash = maxf(0.0, flash - scaled_delta * 3.0)
	for key in cooldowns:
		cooldowns[key] = maxf(0.0, cooldowns[key] - scaled_delta)
	update_spawning(scaled_delta)
	update_plants(scaled_delta)
	update_yam_minions(scaled_delta)
	update_projectiles(scaled_delta)
	update_zombies(scaled_delta)
	update_suns(scaled_delta)
	update_particles(scaled_delta)
	update_mowers(scaled_delta)
	cleanup_entities()
	if final_wave_sent and zombies.is_empty():
		finish_level()
	queue_redraw()

func finish_level() -> void:
	game_state = "win"
	high_score = maxi(high_score, sun_points)
	if current_level < LEVEL_DATA.size():
		unlocked_level = maxi(unlocked_level, current_level + 1)
	else:
		campaign_completed = true
	save_game()
	play_sfx(740.0, 0.28, 0.22, "sine")

func update_spawning(delta: float) -> void:
	if final_wave_sent:
		return
	spawn_clock -= delta
	if spawn_clock > 0.0:
		return
	var is_big_wave := current_wave % 10 == 9
	if is_big_wave:
		if not big_wave_warning:
			big_wave_warning = true
			wave_banner_time = 3.2
			show_message("一大波僵尸正在接近！", 3.0)
			spawn_clock = 2.5
			spawn_clock_start = spawn_clock
			return
		var is_final_wave := current_wave == wave_plan.size() - 1
		spawn_big_wave(wave_plan[current_wave])
		current_wave += 1
		big_wave_warning = false
		if is_final_wave:
			final_wave_sent = true
			return
		spawn_clock = 10.0 + rng.randf_range(-1.0, 1.5)
		spawn_clock_start = spawn_clock
		return
	spawn_small_wave(current_wave, wave_plan[current_wave])
	current_wave += 1
	spawn_clock = 10.0 + rng.randf_range(-1.0, 1.5)
	spawn_clock_start = spawn_clock

func build_wave_plan(level: int) -> Array:
	var plan: Array = []
	var total: int = LEVEL_DATA[level].waves
	var base_budgets := [1, 1, 1, 3, 3, 3, 5, 5, 5, 15]
	for wave_index in total:
		var wave: Array[String] = []
		var local_wave := wave_index % 10
		var group_index := int(wave_index / 10)
		var budget: int = base_budgets[local_wave]
		# 后续每个大波组平缓加压：普通波+1分，大波+3分。
		budget += group_index * (3 if local_wave == 9 else 1)
		while budget > 0:
			var kind := choose_zombie_type(level, wave_index, total, budget)
			wave.append(kind)
			budget -= int(ZOMBIE_POINTS[kind])
		plan.append(wave)
	return plan

func spawn_small_wave(wave_index: int, wave: Array) -> void:
	var rows := [0, 1, 2, 3, 4]
	if LEVEL_DATA[current_level].world == "荒地" and wave_index % 10 < 6:
		rows = [0, 2, 4]
	rows.shuffle()
	var budget := wave_score(wave)
	var spent := 0
	var spawned := 0
	for i in wave.size():
		var row: int = rows[i % rows.size()]
		var cost := zombie_row_score(wave[i], row)
		if spent + cost > budget:
			continue
		spawn_zombie(row, wave[i], 1260.0 + spawned * 18.0)
		spent += cost
		spawned += 1

func spawn_big_wave(wave: Array) -> void:
	spawn_zombie(2, "flag", 1160.0)
	var rows := [0, 1, 2, 3, 4]
	rows.shuffle()
	var budget := wave_score(wave)
	var spent := 0
	var spawned := 0
	for i in wave.size():
		var row: int = rows[i % ROWS]
		var cost := zombie_row_score(wave[i], row)
		if spent + cost > budget:
			continue
		spawn_zombie(row, wave[i], 1210.0 + spawned * 22.0)
		spent += cost
		spawned += 1

func wave_score(wave: Array) -> int:
	var total := 0
	for kind in wave:
		total += int(ZOMBIE_POINTS[kind])
	return total

func zombie_row_score(kind: String, row: int) -> int:
	var score := int(ZOMBIE_POINTS[kind])
	if is_wasteland_level() and row % 2 == 1:
		score *= 2
	return score

func choose_zombie_type(level: int, wave_index: int, total_waves: int, max_points: int) -> String:
	var progress := float(wave_index) / maxf(float(total_waves - 1), 1.0)
	for attempt in 8:
		var r := rng.randf()
		var candidate := "normal"
		if level == 1:
			candidate = "cone" if progress >= 0.33 and r < 0.28 else "normal"
		elif level == 2:
			if progress >= 0.75 and r < 0.06:
				candidate = "bucket"
			elif progress >= 0.25 and r < 0.38:
				candidate = "cone"
		elif level == 4:
			candidate = "cone" if progress >= 0.2 and r < 0.35 else "normal"
		elif progress >= 0.55 and r < 0.13:
			candidate = "bucket"
		elif progress >= 0.35 and r > 0.83:
			candidate = "runner"
		elif progress >= 0.2 and r < 0.42:
			candidate = "cone"
		if int(ZOMBIE_POINTS[candidate]) <= max_points:
			return candidate
	return "normal"

func spawn_zombie(row: int, kind: String, at_x := 1260.0) -> void:
	var stats: Dictionary = {
		"normal":{"hp":190.0,"speed":15.0}, "cone":{"hp":560.0,"speed":15.0},
		"bucket":{"hp":1290.0,"speed":15.0}, "runner":{"hp":160.0,"speed":35.0},
		"flag":{"hp":190.0,"speed":15.0}
	}[kind]
	zombies.append({"row":row,"x":at_x + rng.randf_range(0.0, 70.0),"hp":stats.hp,"max_hp":stats.hp,
		"speed":stats.speed,"kind":kind,"attack":0.0,"slow":0.0,"dead":false,"anim":rng.randf_range(0.0, 5.0),
		"biting":false,"walking":true,"arm_lost":false,"armor_lost":false})

func update_plants(delta: float) -> void:
	for p in plants:
		p.timer -= delta
		p.anim += delta
		match p.kind:
			"sunflower":
				if p.timer <= 0.0:
					spawn_sun(cell_center(p.col, p.row) + Vector2(0, -25), false)
					p.timer = SUNFLOWER_INTERVAL
			"pea", "snow":
				if p.timer <= 0.0 and has_zombie_ahead(p.row, cell_center(p.col, p.row).x):
					projectiles.append({"row":p.row,"x":cell_center(p.col,p.row).x + 23.0,
						"y":cell_center(p.col,p.row).y - 9.0,"speed":235.0,"damage":PLANT_DATA[p.kind].damage,
						"snow":p.kind == "snow","dead":false})
					p.timer = PLANT_DATA[p.kind].interval
			"cherry":
				if p.timer <= 0.0 and not p.dead:
					explode_cherry(p)
			"mine":
				if not p.armed and p.timer <= 0.0:
					p.armed = true
					burst(cell_center(p.col,p.row), Color("#e5bd67"), 8)
					play_sfx(520.0, 0.09, 0.08, "square")
				if p.armed and mine_has_target(p):
					explode_mine(p)
			"yam_guard":
				var minion = get_yam_minion(p)
				if minion == null:
					if p.minion_active:
						p.minion_active = false
						p.respawn_timer = PLANT_DATA.yam_guard.respawn
					p.respawn_timer -= delta
					if p.respawn_timer <= 0.0:
						spawn_yam_minion(p)

func get_yam_minion(owner: Dictionary):
	for minion in yam_minions:
		if not minion.dead and minion.owner_col == owner.col and minion.owner_row == owner.row:
			return minion
	return null

func spawn_yam_minion(owner: Dictionary) -> void:
	var target_row: int = owner.row + owner.deploy_dir
	if target_row < 0 or target_row >= ROWS:
		owner.deploy_dir *= -1
		target_row = owner.row + owner.deploy_dir
	yam_minions.append({
		"owner_col":owner.col, "owner_row":owner.row, "col":owner.col, "row":target_row,
		"hp":500.0, "max_hp":500.0, "dead":false, "anim":0.0, "attack_flash":0.0
	})
	owner.minion_active = true
	burst(cell_center(owner.col,target_row),Color("#df8252"),7)

func update_yam_minions(delta: float) -> void:
	for minion in yam_minions:
		if minion.dead:
			continue
		minion.anim += delta
		minion.attack_flash = maxf(0.0, minion.attack_flash - delta)
		var target = null
		var target_distance := 62.0
		var center_x := cell_center(minion.col,minion.row).x
		for z in zombies:
			if not z.dead and z.row == minion.row:
				var distance := absf(z.x - center_x)
				if distance < target_distance:
					target = z
					target_distance = distance
		if target != null:
			target.hp -= PLANT_DATA.yam_guard.damage * delta
			minion.attack_flash = 0.12
			update_zombie_armor(target)
			if target.hp <= 0.0:
				kill_zombie(target)
		else:
			minion.hp = minf(minion.max_hp, minion.hp + PLANT_DATA.yam_guard.heal * delta)

func has_zombie_ahead(row: int, x: float) -> bool:
	for z in zombies:
		if not z.dead and z.row == row and z.x > x:
			return true
	return false

func explode_cherry(p: Dictionary) -> void:
	var center := cell_center(p.col, p.row)
	for z in zombies:
		if not z.dead and absf(z.row - p.row) <= 1 and absf(z.x - center.x) < 155.0:
			z.hp -= PLANT_DATA.cherry.damage
			update_zombie_armor(z)
			if z.hp <= 0.0: kill_zombie(z)
	for i in 36:
		var a := rng.randf_range(0, TAU)
		particles.append({"pos":center,"vel":Vector2(cos(a),sin(a))*rng.randf_range(60,220),
			"life":rng.randf_range(.35,.8),"max":.8,"color":Color("#ffb23e"),"size":rng.randf_range(4,12)})
	p.dead = true
	shake = 1.0
	flash = 0.7
	play_sfx(105.0, 0.36, 0.42, "noise")

func mine_has_target(p: Dictionary) -> bool:
	var center_x := cell_center(p.col, p.row).x
	for z in zombies:
		if not z.dead and z.row == p.row and absf(z.x - center_x) < 48.0:
			return true
	return false

func explode_mine(p: Dictionary) -> void:
	var center := cell_center(p.col, p.row)
	for z in zombies:
		if not z.dead and z.row == p.row and absf(z.x - center.x) < 82.0:
			z.hp -= PLANT_DATA.mine.damage
			update_zombie_armor(z)
			if z.hp <= 0.0: kill_zombie(z)
	for i in 28:
		var a := rng.randf_range(0, TAU)
		particles.append({"pos":center,"vel":Vector2(cos(a),sin(a))*rng.randf_range(50,185),
			"life":rng.randf_range(.3,.7),"max":.7,"color":Color("#c99550"),"size":rng.randf_range(4,11)})
	p.dead = true
	shake = 0.65
	flash = 0.35
	play_sfx(82.0, 0.3, 0.34, "noise")

func update_projectiles(delta: float) -> void:
	for pr in projectiles:
		pr.x += pr.speed * delta
		if pr.x > W + 20: pr.dead = true
		for z in zombies:
			if not pr.dead and not z.dead and z.row == pr.row and absf(z.x - pr.x) < 25.0:
				z.hp -= pr.damage
				update_zombie_armor(z)
				if pr.snow: z.slow = 3.0
				pr.dead = true
				burst(Vector2(pr.x, pr.y), Color("#8ce8f0") if pr.snow else Color("#9bea55"), 5)
				play_sfx(390.0 if pr.snow else 310.0, 0.045, 0.08, "square")
				if z.hp <= 0.0: kill_zombie(z)

func update_zombies(delta: float) -> void:
	for z in zombies:
		if z.dead: continue
		z.anim += delta
		z.slow = maxf(0.0, z.slow - delta)
		if z.hp <= 100.0 and not z.get("arm_lost", false):
			z.arm_lost = true
			detached_arms.append({"pos":Vector2(z.x + 13.0, BOARD_Y + z.row * CELL_H + CELL_H/2.0 - 18.0),
				"vel":Vector2(34.0,-48.0),"angle":0.0,"spin":4.8,"life":1.35,"slow":z.slow > 0.0})
		var target = plant_at_zombie(z)
		z.biting = target != null
		z.walking = target == null
		if target != null:
			target.hp -= ZOMBIE_DPS * delta
			z.attack -= delta
			if z.attack <= 0.0:
				z.attack = 0.7
				burst(cell_center(target.col,target.row), Color("#cfa46e"), 3)
			if target.hp <= 0.0: target.dead = true
		else:
			var slow_factor := 0.5 if z.slow > 0.0 else 1.0
			z.x -= z.speed * slow_factor * delta
		if z.x < 115.0:
			game_state = "lose"

func update_zombie_armor(z: Dictionary) -> void:
	if z.kind not in ["cone","bucket"] or z.get("armor_lost",false) or z.hp > 190.0:
		return
	z.armor_lost = true
	var drop_y: float = BOARD_Y + float(z.row) * CELL_H + CELL_H/2.0 - 78.0
	dropped_armor.append({"kind":z.kind,"pos":Vector2(z.x-5.0,drop_y),
		"vel":Vector2(rng.randf_range(-52.0,32.0),-92.0),"angle":0.0,
		"spin":rng.randf_range(-5.5,5.5),"life":1.45})
	burst(Vector2(z.x,drop_y),Color("#e9a34e") if z.kind=="cone" else Color("#aab4b6"),7)
	play_sfx(185.0 if z.kind=="cone" else 125.0,0.11,0.12,"square")

func plant_at_zombie(z: Dictionary):
	for p in plants:
		if not p.dead and p.row == z.row:
			var px := cell_center(p.col,p.row).x
			if z.x > px - 30.0 and z.x < px + 42.0:
				return p
	for minion in yam_minions:
		if not minion.dead and minion.row == z.row:
			var minion_x := cell_center(minion.col,minion.row).x
			if z.x > minion_x - 30.0 and z.x < minion_x + 42.0:
				return minion
	return null

func kill_zombie(z: Dictionary) -> void:
	if z.dead: return
	update_zombie_armor(z)
	z.dead = true
	burst(Vector2(z.x, BOARD_Y + z.row * CELL_H + CELL_H/2.0), Color("#8fbd70"), 12)
	play_sfx(145.0, 0.12, 0.11, "square")

func update_suns(delta: float) -> void:
	sky_sun_clock -= delta
	if sky_sun_clock <= 0.0 and not final_wave_sent:
		spawn_sun(Vector2(rng.randf_range(280,1050), -20), true)
		sky_sun_clock = rng.randf_range(6.5, 9.0)
	for s in suns:
		s.life -= delta
		s.pulse += delta
		if s.sky and s.pos.y < s.target_y:
			s.pos.y = minf(s.target_y, s.pos.y + 72.0 * delta)
		elif not s.sky and s.pos.y > s.target_y:
			s.pos.y = maxf(s.target_y, s.pos.y - 38.0 * delta)
		if auto_collect_sun and s.pulse > 0.8 and absf(s.pos.y - s.target_y) < 1.0:
			collect_sun(s)
		if s.life <= 0.0: s.dead = true

func spawn_sun(pos: Vector2, sky: bool) -> void:
	suns.append({"pos":pos,"target_y":rng.randf_range(250,590) if sky else pos.y - 35.0,
		"sky":sky,"life":10.0,"pulse":0.0,"dead":false})

func collect_sun(s: Dictionary) -> void:
	if s.dead:
		return
	s.dead = true
	sun_points += 25
	burst(s.pos, Color("#ffe56b"), 8)
	play_sfx(880.0, 0.11, 0.14, "sine")

func update_mowers(delta: float) -> void:
	for m in mowers:
		if m.used: continue
		if not m.active:
			for z in zombies:
				if not z.dead and z.row == m.row and z.x < 198.0:
					m.active = true
					show_message("割草机启动！", 1.5)
					play_sfx(92.0, 0.45, 0.3, "noise")
					break
		else:
			m.x += 430.0 * delta
			for z in zombies:
				if not z.dead and z.row == m.row and absf(z.x - m.x) < 62.0: kill_zombie(z)
			if m.x > W + 80: m.used = true

func update_particles(delta: float) -> void:
	for p in particles:
		p.life -= delta
		p.pos += p.vel * delta
		p.vel *= 0.96
		p.vel.y += 90.0 * delta
	for arm in detached_arms:
		arm.life -= delta
		arm.pos += arm.vel * delta
		arm.vel.x *= 0.97
		arm.vel.y += 155.0 * delta
		arm.angle += arm.spin * delta
	for armor in dropped_armor:
		armor.life -= delta
		armor.pos += armor.vel * delta
		armor.vel.x *= 0.97
		armor.vel.y += 210.0 * delta
		armor.angle += armor.spin * delta

func cleanup_entities() -> void:
	for minion in yam_minions:
		if not minion.dead and get_plant(minion.owner_col,minion.owner_row) == null:
			minion.dead = true
	for i in range(plants.size() - 1, -1, -1):
		if plants[i].dead: plants.remove_at(i)
	for i in range(zombies.size() - 1, -1, -1):
		if zombies[i].dead: zombies.remove_at(i)
	for i in range(projectiles.size() - 1, -1, -1):
		if projectiles[i].dead: projectiles.remove_at(i)
	for i in range(suns.size() - 1, -1, -1):
		if suns[i].dead: suns.remove_at(i)
	for i in range(particles.size() - 1, -1, -1):
		if particles[i].life <= 0.0: particles.remove_at(i)
	for i in range(yam_minions.size() - 1, -1, -1):
		if yam_minions[i].dead: yam_minions.remove_at(i)
	for i in range(detached_arms.size() - 1, -1, -1):
		if detached_arms[i].life <= 0.0: detached_arms.remove_at(i)
	for i in range(dropped_armor.size() - 1, -1, -1):
		if dropped_armor[i].life <= 0.0: dropped_armor.remove_at(i)

func burst(pos: Vector2, color: Color, count: int) -> void:
	for i in count:
		particles.append({"pos":pos,"vel":Vector2(rng.randf_range(-100,100),rng.randf_range(-120,30)),
			"life":rng.randf_range(.25,.6),"max":.6,"color":color,"size":rng.randf_range(3,7)})

func sfx_cache_key(frequency: float, duration: float, strength: float, wave: String) -> String:
	return "%s:%d:%d:%d" % [wave, roundi(frequency * 10.0), roundi(duration * 1000.0), roundi(strength * 1000.0)]

func get_sfx_stream(frequency: float, duration: float, strength: float, wave: String) -> AudioStreamWAV:
	var cache_key := sfx_cache_key(frequency, duration, strength, wave)
	if sfx_cache.has(cache_key):
		return sfx_cache[cache_key]
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / sample_rate
		var phase := t * frequency * TAU
		var value := sin(phase)
		if wave == "square":
			value = 1.0 if value >= 0.0 else -1.0
		elif wave == "noise":
			value = rng.randf_range(-1.0, 1.0)
		var envelope := pow(1.0 - float(i) / sample_count, 1.8)
		bytes.encode_s16(i * 2, int(value * envelope * strength * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	sfx_cache[cache_key] = stream
	return stream

func setup_sfx_audio() -> void:
	for i in 16:
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	# 游戏中高频触发的声音在进入画面前生成，避免首次命中、收集或爆炸时卡帧。
	var common_sounds := [
		[520.0, 0.09, 0.08, "square"], [105.0, 0.36, 0.42, "noise"],
		[82.0, 0.3, 0.34, "noise"], [390.0, 0.045, 0.08, "square"],
		[310.0, 0.045, 0.08, "square"], [185.0, 0.11, 0.12, "square"],
		[125.0, 0.11, 0.12, "square"], [145.0, 0.12, 0.11, "square"],
		[880.0, 0.11, 0.14, "sine"], [92.0, 0.45, 0.3, "noise"],
		[740.0, 0.28, 0.22, "sine"]
	]
	for sound in common_sounds:
		get_sfx_stream(sound[0], sound[1], sound[2], sound[3])

func play_sfx(frequency: float, duration: float, strength: float, wave := "sine") -> void:
	if not sound_enabled or sfx_volume <= 0.001 or sfx_players.is_empty():
		return
	var player := sfx_players[sfx_player_cursor]
	sfx_player_cursor = (sfx_player_cursor + 1) % sfx_players.size()
	player.stop()
	player.stream = get_sfx_stream(frequency, duration, strength, wave)
	player.volume_db = linear_to_db(sfx_volume)
	player.play()

func start_music() -> void:
	var sample_rate := 22050
	var beat_time := 0.28
	var notes := [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 349.23,
		440.0, 587.33, 440.0, 349.23, 261.63, 329.63, 392.0, 329.63]
	var sample_count := int(sample_rate * beat_time * notes.size())
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / sample_rate
		var note_index := mini(int(t / beat_time), notes.size() - 1)
		var local_t := fmod(t, beat_time)
		var frequency: float = notes[note_index]
		var envelope := minf(local_t / 0.025, 1.0) * minf((beat_time - local_t) / 0.06, 1.0)
		var lead := signf(sin(t * frequency * TAU)) * 0.12
		var bass_frequency: float = notes[int(note_index / 4) * 4] * 0.5
		var bass := sin(t * bass_frequency * TAU) * 0.11
		var sparkle := sin(t * frequency * 2.0 * TAU) * 0.035
		bytes.encode_s16(i * 2, int((lead + bass + sparkle) * envelope * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = stream
	update_music_volume()
	music_player.play()

func update_music_volume() -> void:
	if music_player:
		music_player.volume_db = linear_to_db(maxf(music_volume, 0.0001))

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	auto_collect_sun = bool(config.get_value("game", "auto_collect", auto_collect_sun))
	show_health_bars = bool(config.get_value("game", "show_health_bars", show_health_bars))
	game_speed = clampf(float(config.get_value("game", "speed", game_speed)), 0.5, 3.0)
	fullscreen_enabled = bool(config.get_value("display", "fullscreen", fullscreen_enabled))
	# 兼容旧版本曾经写在设置文件中的主线进度。
	unlocked_level = clampi(int(config.get_value("progress", "unlocked_level", unlocked_level)), 1, LEVEL_DATA.size())
	for i in plant_keys.size():
		plant_keys[i] = int(config.get_value("keys", "plant_%d" % i, plant_keys[i]))
	shovel_key = int(config.get_value("keys", "shovel", shovel_key))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("game", "auto_collect", auto_collect_sun)
	config.set_value("game", "show_health_bars", show_health_bars)
	config.set_value("game", "speed", game_speed)
	config.set_value("display", "fullscreen", fullscreen_enabled)
	for i in plant_keys.size():
		config.set_value("keys", "plant_%d" % i, plant_keys[i])
	config.set_value("keys", "shovel", shovel_key)
	config.save(SETTINGS_PATH)

func load_save_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	unlocked_level = clampi(int(config.get_value("campaign","unlocked_level",unlocked_level)),1,LEVEL_DATA.size())
	high_score = maxi(0,int(config.get_value("campaign","high_score",high_score)))
	campaign_completed = bool(config.get_value("campaign","completed",campaign_completed))
	# 三关版本的“已通关”存档在新增荒地后，应继续解锁新关而非误判整条主线完成。
	if campaign_completed and unlocked_level < LEVEL_DATA.size():
		unlocked_level = LEVEL_DATA.size()
		campaign_completed = false
		config.set_value("campaign","unlocked_level",unlocked_level)
		config.set_value("campaign","completed",false)
		config.save(SAVE_PATH)
	saved_loadouts.clear()
	for level in range(1,LEVEL_DATA.size()+1):
		var raw_loadout: Array = config.get_value("loadouts","level_%d"%level,[])
		var valid_loadout: Array[String] = []
		for value in raw_loadout:
			var kind := String(value)
			if kind in LEVEL_DATA[level].plants and kind not in valid_loadout and valid_loadout.size() < 8:
				valid_loadout.append(kind)
		if not valid_loadout.is_empty(): saved_loadouts[level] = valid_loadout

func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("save","version",1)
	config.set_value("campaign","unlocked_level",unlocked_level)
	config.set_value("campaign","high_score",high_score)
	config.set_value("campaign","completed",campaign_completed)
	for level in range(1,LEVEL_DATA.size()+1):
		if saved_loadouts.has(level):
			config.set_value("loadouts","level_%d"%level,saved_loadouts[level])
	config.save(SAVE_PATH)

func apply_saved_display_mode() -> void:
	if fullscreen_enabled and not Engine.is_embedded_in_editor() and DisplayServer.get_name() != "headless":
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func _exit_tree() -> void:
	if not Engine.is_embedded_in_editor() and DisplayServer.get_name() != "headless":
		var mode := get_window().mode
		fullscreen_enabled = mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	save_settings()
	save_game()

func key_name(keycode: int) -> String:
	var result := OS.get_keycode_string(keycode)
	return result if result != "" else "未设置"

func assign_key(target: int, new_key: int) -> void:
	if new_key == 0:
		return
	var old_key: int = shovel_key if target == -1 else plant_keys[target]
	for i in plant_keys.size():
		if i != target and plant_keys[i] == new_key:
			plant_keys[i] = old_key
	if target != -1 and shovel_key == new_key:
		shovel_key = old_key
	if target == -1:
		shovel_key = new_key
	else:
		plant_keys[target] = new_key
	binding_target = -99
	save_settings()
	play_sfx(690.0, 0.09, 0.1, "square")

func toggle_fullscreen() -> void:
	if Engine.is_embedded_in_editor():
		fullscreen_notice = "编辑器嵌入模式不支持全屏，请关闭“嵌入游戏”后运行"
		return
	var current := get_window().mode
	var is_full := current == Window.MODE_FULLSCREEN or current == Window.MODE_EXCLUSIVE_FULLSCREEN
	get_window().mode = Window.MODE_WINDOWED if is_full else Window.MODE_EXCLUSIVE_FULLSCREEN
	fullscreen_enabled = not is_full
	save_settings()
	fullscreen_notice = ""
	play_sfx(520.0, 0.07, 0.08, "square")

func select_plant_slot(index: int) -> void:
	if index < 0 or index >= equipped_plants.size():
		return
	var kind: String = equipped_plants[index]
	if cooldowns.get(kind, 0.0) <= 0.0 and sun_points >= PLANT_DATA[kind].cost:
		selected = kind if selected != kind else ""
		play_sfx(560.0, 0.055, 0.06, "square")
	else:
		show_message("植物还在冷却" if cooldowns.get(kind,0.0) > 0 else "阳光不足", 1.1)

func cell_center(col: int, row: int) -> Vector2:
	return Vector2(BOARD_X + col * CELL_W + CELL_W/2.0, BOARD_Y + row * CELL_H + CELL_H/2.0)

func level_title(level: int) -> String:
	var data: Dictionary = LEVEL_DATA[level]
	return "%s-第%d关" % [data.world, data.stage]

func is_wasteland_level() -> bool:
	return LEVEL_DATA[current_level].world == "荒地"

func is_plantable_cell(row: int) -> bool:
	return not is_wasteland_level() or row % 2 == 0

func show_message(text: String, duration: float) -> void:
	message = text
	message_time = duration

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var pressed_key := int(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
		if paused and pause_page == "keys" and binding_target != -99:
			if event.keycode == KEY_ESCAPE:
				binding_target = -99
			else:
				assign_key(binding_target, pressed_key)
			queue_redraw()
			return
		if game_state == "play" and not paused:
			for i in plant_keys.size():
				if pressed_key == plant_keys[i]:
					select_plant_slot(i)
					queue_redraw()
					return
			if pressed_key == shovel_key:
				selected = "shovel" if selected != "shovel" else ""
				play_sfx(410.0, 0.06, 0.08, "square")
				queue_redraw()
				return
		if event.keycode == KEY_P and game_state == "play":
			paused = not paused
			if paused: pause_page = "main"
		if event.keycode == KEY_F11: toggle_fullscreen()
		if event.keycode == KEY_ESCAPE:
			if game_state == "prepare": game_state = "title"
			elif game_state == "level_select": game_state = "title"
			elif game_state == "almanac": game_state = "title"
			elif game_state == "play" and paused and pause_page == "keys": pause_page = "more"
			elif game_state == "play" and paused and pause_page == "more": pause_page = "main"
			elif game_state == "play" and paused: paused = false
			elif selected != "": selected = ""
			elif game_state == "play": paused = not paused
	if event is InputEventMouseMotion:
		update_hover(event.position)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			selected = ""
		elif event.button_index == MOUSE_BUTTON_LEFT:
			handle_click(event.position)
	queue_redraw()

func update_hover(pos: Vector2) -> void:
	hover_cell = Vector2i(-1,-1)
	hover_card = -1
	if Rect2(BOARD_X,BOARD_Y,COLS*CELL_W,ROWS*CELL_H).has_point(pos):
		hover_cell = Vector2i(int((pos.x-BOARD_X)/CELL_W),int((pos.y-BOARD_Y)/CELL_H))
	for i in equipped_plants.size():
		if card_rect(i).has_point(pos): hover_card = i

func handle_click(pos: Vector2) -> void:
	if game_state == "title":
		if Rect2(370,480,250,72).has_point(pos):
			game_state = "level_select"
			play_sfx(610.0,0.1,0.1,"square")
		elif Rect2(660,480,250,72).has_point(pos):
			game_state = "almanac"
			almanac_tab = "plants"
			almanac_selected = 0
			play_sfx(610.0, 0.1, 0.1, "square")
		return
	if game_state == "level_select":
		if Rect2(50,635,190,58).has_point(pos):
			game_state = "title"
			return
		for i in LEVEL_DATA.size():
			if level_select_rect(i).has_point(pos) and i+1 <= unlocked_level:
				prepare_level(i+1)
				return
		return
	if game_state == "prepare":
		handle_prepare_click(pos)
		return
	if game_state == "almanac":
		handle_almanac_click(pos)
		return
	if game_state == "win" or game_state == "lose":
		if Rect2(470,500,340,68).has_point(pos):
			if game_state == "lose": prepare_level(current_level)
			elif current_level < LEVEL_DATA.size(): prepare_level(current_level + 1)
			else: game_state = "title"
		return
	if Rect2(1165,14,100,62).has_point(pos):
		paused = not paused
		if paused: pause_page = "main"
		play_sfx(480.0, 0.06, 0.08, "square")
		return
	if paused:
		handle_pause_click(pos)
		return
	for s in suns:
		if not s.dead and s.pos.distance_to(pos) < 34.0:
			collect_sun(s)
			return
	var keys := equipped_plants
	for i in keys.size():
		if card_rect(i).has_point(pos):
			var key: String = keys[i]
			if cooldowns[key] <= 0.0 and sun_points >= PLANT_DATA[key].cost:
				selected = key if selected != key else ""
				play_sfx(560.0, 0.055, 0.06, "square")
			else:
				show_message("植物还在冷却" if cooldowns[key] > 0 else "阳光不足", 1.1)
			return
	if Rect2(175,14,105,62).has_point(pos):
		selected = "shovel" if selected != "shovel" else ""
		return
	if hover_cell.x >= 0:
		var existing = get_plant(hover_cell.x, hover_cell.y)
		if selected == "shovel":
			var old = existing
			if old != null:
				old.dead = true
				burst(cell_center(old.col,old.row),Color("#d7a66e"),8)
			selected = ""
		elif existing != null and existing.kind == "yam_guard":
			if is_wasteland_level() and existing.row == 2:
				existing.deploy_dir *= -1
				var minion = get_yam_minion(existing)
				if minion != null:
					minion.row = existing.row + existing.deploy_dir
					burst(cell_center(minion.col,minion.row),Color("#df8252"),7)
				show_message("小红薯改为驻守%s" % ("上方" if existing.deploy_dir < 0 else "下方"),1.2)
			else:
				show_message("该位置的小红薯只能驻守相邻荒地",1.2)
			selected = ""
		elif selected != "" and existing == null:
			if is_plantable_cell(hover_cell.y):
				place_plant(selected, hover_cell.x, hover_cell.y)
			else:
				show_message("黄土地块不能种植植物",1.2)

func prepare_card_rect(index: int) -> Rect2:
	return Rect2(190.0 + (index % 2) * 180.0, 150.0 + int(index / 2) * 88.0, 170.0, 82.0)

func handle_prepare_click(pos: Vector2) -> void:
	if prepare_camera_x < 500.0 or prepare_returning:
		return
	if Rect2(190,575,170,55).has_point(pos):
		game_state = "title"
		return
	for i in equipped_plants.size():
		if card_rect(i).has_point(pos):
			equipped_plants.remove_at(i)
			play_sfx(430.0, 0.06, 0.07, "square")
			return
	for i in available_plants.size():
		if prepare_card_rect(i).has_point(pos):
			var kind: String = available_plants[i]
			var selected_index := equipped_plants.find(kind)
			if selected_index >= 0:
				equipped_plants.remove_at(selected_index)
			elif equipped_plants.size() < 8:
				equipped_plants.append(kind)
			play_sfx(570.0, 0.06, 0.07, "square")
			return
	if Rect2(380,575,170,55).has_point(pos):
		if equipped_plants.is_empty():
			show_message("请至少选择一种植物", 1.5)
			return
		saved_loadouts[current_level] = equipped_plants.duplicate()
		save_game()
		prepare_returning = true
		play_sfx(720.0, 0.1, 0.1, "square")
		return

func handle_almanac_click(pos: Vector2) -> void:
	if Rect2(60, 635, 190, 58).has_point(pos):
		game_state = "title"
		play_sfx(470.0, 0.08, 0.08, "square")
		return
	if Rect2(420, 88, 205, 52).has_point(pos):
		almanac_tab = "plants"
		almanac_selected = 0
		play_sfx(570.0, 0.07, 0.08, "square")
		return
	if Rect2(655, 88, 205, 52).has_point(pos):
		almanac_tab = "zombies"
		almanac_selected = 0
		play_sfx(390.0, 0.07, 0.08, "square")
		return
	var count := PLANT_DATA.size() if almanac_tab == "plants" else ZOMBIE_INFO.size()
	for i in count:
		var item_rect := Rect2(70 + (i % 2) * 255, 175 + int(i / 2) * 125, 235, 105)
		if item_rect.has_point(pos):
			almanac_selected = i
			play_sfx(520.0 + i * 25.0, 0.06, 0.07, "square")
			return

func place_plant(kind: String, col: int, row: int) -> void:
	var data: Dictionary = PLANT_DATA[kind]
	sun_points -= data.cost
	cooldowns[kind] = data.cool
	var first_timer: float = 4.0 if kind == "sunflower" else (data.interval if kind == "cherry" else (data.arm_time if kind == "mine" else 0.15))
	plants.append({"kind":kind,"col":col,"row":row,"hp":data.hp,"max_hp":data.hp,
		"timer":first_timer,"anim":rng.randf_range(0,2),"armed":false,"dead":false,
		"deploy_dir":-1,"respawn_timer":0.6,"minion_active":false})
	burst(cell_center(col,row),data.color,8)
	play_sfx(220.0, 0.09, 0.1, "square")
	selected = ""

func handle_pause_click(pos: Vector2) -> void:
	if pause_page == "more":
		if Rect2(410, 180, 460, 74).has_point(pos):
			pause_page = "keys"
			binding_target = -99
			play_sfx(560.0, 0.07, 0.08, "square")
		elif Rect2(310, 330, 660, 55).has_point(pos):
			show_health_bars = not show_health_bars
			save_settings()
			play_sfx(620.0, 0.07, 0.08, "square")
		elif Rect2(350, 565, 580, 64).has_point(pos):
			pause_page = "main"
		return
	if pause_page == "keys":
		for i in plant_keys.size():
			var col := 0 if i < 4 else 1
			var row := i if i < 4 else i - 4
			var x := 455.0 if col == 0 else 825.0
			if Rect2(x, 145 + row * 67, 120, 44).has_point(pos):
				binding_target = i
				return
		if Rect2(580, 487, 120, 44).has_point(pos):
			binding_target = -1
			return
		if Rect2(350, 585, 580, 58).has_point(pos):
			binding_target = -99
			pause_page = "more"
		return
	for i in speed_options.size():
		if Rect2(335 + i * 104, 145, 90, 44).has_point(pos):
			game_speed = speed_options[i]
			save_settings()
			play_sfx(420.0 + i * 55.0, 0.07, 0.08, "square")
			return
	if Rect2(430, 204, 410, 44).has_point(pos):
		music_volume = clampf((pos.x - 445.0) / 380.0, 0.0, 1.0)
		update_music_volume()
		save_settings()
		return
	if Rect2(430, 259, 410, 44).has_point(pos):
		sfx_volume = clampf((pos.x - 445.0) / 380.0, 0.0, 1.0)
		save_settings()
		if sfx_volume > 0.01: play_sfx(620.0, 0.06, 0.08, "square")
		return
	if Rect2(420, 305, 230, 48).has_point(pos):
		auto_collect_sun = not auto_collect_sun
		save_settings()
		play_sfx(660.0, 0.09, 0.1, "square")
		return
	if Rect2(700, 307, 160, 44).has_point(pos):
		toggle_fullscreen()
		return
	if Rect2(360, 376, 150, 106).has_point(pos):
		paused = false
		game_state = "title"
		selected = ""
		return
	if Rect2(565, 376, 150, 106).has_point(pos):
		pause_page = "more"
		play_sfx(520.0, 0.1, 0.1, "square")
		return
	if Rect2(770, 376, 150, 106).has_point(pos):
		prepare_level(current_level)
		play_sfx(700.0, 0.11, 0.1, "square")
		return
	if Rect2(350, 520, 580, 70).has_point(pos):
		paused = false
		play_sfx(540.0, 0.08, 0.08, "square")
		return

func get_plant(col: int, row: int):
	for p in plants:
		if not p.dead and p.col == col and p.row == row: return p
	return null

func card_rect(index: int) -> Rect2:
	return Rect2(7, 86 + index*78, 146, 72)

func _draw() -> void:
	if game_state == "title": draw_title_screen(); return
	if game_state == "level_select": draw_level_select_screen(); return
	if game_state == "almanac": draw_almanac_screen(); return
	if game_state == "prepare": draw_prepare_screen(); return
	var offset := Vector2(rng.randf_range(-4,4),rng.randf_range(-3,3)) if shake > 0 else Vector2.ZERO
	draw_set_transform(offset)
	draw_world()
	draw_set_transform(Vector2.ZERO)
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
	draw_panel(Rect2(370,480,250,72),Color("#76b947"),Color("#d8ed74"),5)
	draw_string(ThemeDB.fallback_font,Vector2(370,528),"冒险模式",HORIZONTAL_ALIGNMENT_CENTER,250,30,Color("#17351f"))
	draw_panel(Rect2(660,480,250,72),Color("#4c8f79"),Color("#a8dfc0"),5)
	draw_string(ThemeDB.fallback_font,Vector2(660,528),"图鉴",HORIZONTAL_ALIGNMENT_CENTER,250,27,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(0,602),"冒险进度：%s" % level_title(unlocked_level),HORIZONTAL_ALIGNMENT_CENTER,1280,19,Color("#d7e49b"))
	draw_string(ThemeDB.fallback_font,Vector2(0,640),"所有画面与特效均由代码实时绘制",HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#829b8d"))
	draw_string(ThemeDB.fallback_font,Vector2(0,674),"1 2 3 4 Q W E R 选择植物  •  D 铲子  •  P / Esc 暂停",HORIZONTAL_ALIGNMENT_CENTER,1280,16,Color("#66847a"))

func level_select_rect(index: int) -> Rect2:
	return Rect2(40.0+index*305.0,250.0,270.0,190.0)

func draw_level_select_screen() -> void:
	draw_rect(Rect2(0,0,W,H),Color("#1b3533"))
	# 前三个入口属于前院，第四个入口进入荒地。
	draw_rect(Rect2(0,120,945,510),Color("#76bd4b"))
	draw_rect(Rect2(945,120,335,510),Color("#b78a4e"))
	for row in 5:
		for col in 8:
			if (row+col)%2==0:
				draw_rect(Rect2(col*128,120+row*102,128,102),Color(0.12,0.25,0.06,0.08))
	for row in 5:
		if row % 2 == 0:
			draw_rect(Rect2(945,120+row*102,335,102),Color("#c69b58"))
	draw_rect(Rect2(0,0,W,120),Color("#203e38"))
	draw_rect(Rect2(0,114,W,6),Color("#dcc86e"))
	draw_string(ThemeDB.fallback_font,Vector2(0,62),"冒险地图",HORIZONTAL_ALIGNMENT_CENTER,1280,40,Color("#ffe879"))
	draw_string(ThemeDB.fallback_font,Vector2(0,99),"选择关卡",HORIZONTAL_ALIGNMENT_CENTER,1280,19,Color("#bcd8c4"))
	draw_string(ThemeDB.fallback_font,Vector2(40,180),"第一世界：前院",HORIZONTAL_ALIGNMENT_CENTER,880,28,Color("#f4ef9c"))
	draw_string(ThemeDB.fallback_font,Vector2(955,180),"第二世界：荒地",HORIZONTAL_ALIGNMENT_CENTER,310,28,Color("#ffe0a0"))
	for i in LEVEL_DATA.size():
		var rect := level_select_rect(i)
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
		draw_almanac_item(i,String(entries[i]))
	draw_panel(Rect2(610,165,600,445),Color("#25443d"),Color("#83a99d"),4)
	var selected_key := String(entries[clampi(almanac_selected,0,entries.size()-1)])
	if almanac_tab == "plants": draw_plant_detail(selected_key)
	else: draw_zombie_detail(selected_key)
	draw_panel(Rect2(60,635,190,58),Color("#496b60"),Color("#9abcb0"),3)
	draw_string(ThemeDB.fallback_font,Vector2(60,673),"返回主菜单",HORIZONTAL_ALIGNMENT_CENTER,190,22,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(280,672),"选择左侧条目查看详细信息",HORIZONTAL_ALIGNMENT_LEFT,430,16,Color("#829e95"))

func draw_almanac_item(index: int, key: String) -> void:
	var rect := Rect2(70 + (index % 2) * 255, 175 + int(index / 2) * 125, 235, 105)
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
	draw_detail_row("生命值",str(info.hp),303,Color("#ef9a7e"))
	draw_detail_row("移动速度",str(info.speed),338,Color.WHITE)
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
	draw_set_transform(Vector2(-prepare_camera_x, 0))
	draw_world(true)
	for z in preview_zombies: draw_zombie(z)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0,0,W,78),Color("#1d3935"))
	draw_rect(Rect2(0,73,W,5),Color("#d2bd6b"))
	draw_string(ThemeDB.fallback_font,Vector2(0,48),level_title(current_level),HORIZONTAL_ALIGNMENT_CENTER,1280,29,Color("#fff0a0"))
	if prepare_camera_x > 360.0:
		draw_plant_selection_panel()

func draw_plant_selection_panel() -> void:
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
	draw_panel(Rect2(174,96,392,552),Color("#29483e"),Color("#e0ca72"),5)
	draw_string(ThemeDB.fallback_font,Vector2(174,137),"选择植物",HORIZONTAL_ALIGNMENT_CENTER,392,27,Color("#fff0a0"))
	for i in available_plants.size():
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
			draw_string(ThemeDB.fallback_font,rect.position+Vector2(142,19),str(chosen_index+1),HORIZONTAL_ALIGNMENT_CENTER,24,11,Color("#294036"))
	draw_string(ThemeDB.fallback_font,Vector2(190,510),"已选择 %d / 8" % equipped_plants.size(),HORIZONTAL_ALIGNMENT_LEFT,176,18,Color("#d6e9c3"))
	draw_panel(Rect2(190,575,170,55),Color("#496a5e"),Color("#8faea3"),3)
	draw_string(ThemeDB.fallback_font,Vector2(190,610),"返回主菜单",HORIZONTAL_ALIGNMENT_CENTER,170,18,Color.WHITE)
	draw_panel(Rect2(380,575,170,55),Color("#7eb34f") if not equipped_plants.is_empty() else Color("#53645d"),Color("#e3ef92") if not equipped_plants.is_empty() else Color("#75877f"),4)
	draw_string(ThemeDB.fallback_font,Vector2(380,610),"开始战斗" if not prepare_returning else "准备出发……",HORIZONTAL_ALIGNMENT_CENTER,170,19,Color("#183421") if not equipped_plants.is_empty() else Color("#9cad9f"))
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(190,552),message,HORIZONTAL_ALIGNMENT_CENTER,360,15,Color("#ffd080"))

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
		var ok := (get_plant(hover_cell.x,hover_cell.y)==null and is_plantable_cell(hover_cell.y)) or selected=="shovel"
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
	draw_string(ThemeDB.fallback_font,Vector2(320,53),level_title(current_level),HORIZONTAL_ALIGNMENT_LEFT,285,24,Color("#fff0a0"))
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
	pos.y += bob
	if p.kind == "mine": draw_potato_mine(pos, p.armed, 1.0)
	else: draw_plant_shape(p.kind,pos,1.0)
	if show_health_bars and p.hp < p.max_hp:
		draw_bar(Vector2(pos.x-31,pos.y-49),62,p.hp/p.max_hp,Color("#7de05b"))

func draw_plant_shape(kind: String, pos: Vector2, scale: float) -> void:
	# stem and leaves
	if kind != "wall" and kind != "cherry" and kind != "mine" and kind != "yam_guard":
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

func draw_zombie(z: Dictionary) -> void:
	var pos := Vector2(z.x,z.get("draw_y",BOARD_Y+z.row*CELL_H+CELL_H/2.0))
	var scale: float = z.get("draw_scale",1.0)
	var biting: bool = z.get("biting",false)
	var walking: bool = z.get("walking",not biting)
	var bite := (sin(z.anim*11.0)+1.0)*0.5 if biting else 0.0
	# 步频跟随移动速度：基础僵尸缓慢拖步，疾跑僵尸才明显加快。
	var movement_speed: float = float(z.get("speed",15.0))
	var gait_rate := 2.65 * clampf(movement_speed/15.0,0.8,1.7)
	var gait := sin(z.anim*gait_rate) if walking else 0.0
	var left_lift := maxf(gait,0.0)*7.0 if walking else 0.0
	var right_lift := maxf(-gait,0.0)*7.0 if walking else 0.0
	var head_shift := Vector2(-6.0*bite,2.0*bite)*scale
	var skin := Color("#83a96b") if z.slow<=0 else Color("#71b8bd")
	var outline := Color("#263029")
	var jacket := Color("#66503e")
	var jacket_dark := Color("#46372f")
	var pants := Color("#465160")
	# 行走时两腿交替前后迈步并抬脚；停止啃食时回到固定弯腿站姿。
	var left_hip := pos+Vector2(-7,11)*scale
	var left_knee := pos+Vector2(-16-gait*6.0,29-left_lift*0.35)*scale
	var left_ankle := pos+Vector2(-12-gait*14.0,44-left_lift)*scale
	draw_line(left_hip,left_knee,pants,12*scale)
	draw_line(left_knee,left_ankle,pants.darkened(.12),11*scale)
	var right_hip := pos+Vector2(10,13)*scale
	var right_knee := pos+Vector2(8+gait*6.0,31-right_lift*0.35)*scale
	var right_ankle := pos+Vector2(18+gait*14.0,44-right_lift)*scale
	draw_line(right_hip,right_knee,pants.darkened(.08),12*scale)
	draw_line(right_knee,right_ankle,pants,11*scale)
	draw_colored_polygon(PackedVector2Array([left_ankle+Vector2(-22,-2)*scale,left_ankle+Vector2(7,-2)*scale,left_ankle+Vector2(9,7)*scale,left_ankle+Vector2(-19,9)*scale]),Color("#513727"))
	draw_colored_polygon(PackedVector2Array([right_ankle+Vector2(-17,-2)*scale,right_ankle+Vector2(14,-1)*scale,right_ankle+Vector2(16,7)*scale,right_ankle+Vector2(-14,9)*scale]),Color("#3e2d24"))
	# 驼背的破旧西装，身体向行进方向（左）前倾。
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-25,-30)*scale,pos+Vector2(4,-37)*scale,pos+Vector2(23,-21)*scale,pos+Vector2(21,15)*scale,pos+Vector2(-16,19)*scale]),jacket)
	draw_colored_polygon(PackedVector2Array([pos+Vector2(5,-35)*scale,pos+Vector2(23,-21)*scale,pos+Vector2(23,16)*scale,pos+Vector2(9,11)*scale]),jacket_dark)
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-11,-31)*scale,pos+Vector2(4,-33)*scale,pos+Vector2(7,10)*scale,pos+Vector2(-6,12)*scale]),Color("#c9c4aa"))
	# 鲜明领带保留角色识别，避免过多衣物纹理。
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-7,-27)*scale,pos+Vector2(1,-28)*scale,pos+Vector2(3,8)*scale,pos+Vector2(-4,13)*scale]),Color("#a53e3c"))
	draw_line(pos+Vector2(-5,-10)*scale,pos+Vector2(2,-7)*scale,Color("#e4d8c0"),2*scale)
	# 普通僵尸右手自然下垂，啃食时才前伸；旗帜僵尸单独抬起右手握旗。
	if z.kind == "flag":
		draw_line(pos+Vector2(-19,-21)*scale,pos+Vector2(-34,-30)*scale,jacket,11*scale)
		draw_line(pos+Vector2(-34,-30)*scale,pos+Vector2(-34,-43)*scale,skin,8*scale)
		draw_circle(pos+Vector2(-34,-45)*scale,7*scale,skin.darkened(.07))
	else:
		var elbow := Vector2(-27,-2).lerp(Vector2(-39,-8),bite)
		var hand := Vector2(-24,17).lerp(Vector2(-45,3),bite)
		draw_line(pos+Vector2(-19,-21)*scale,pos+elbow*scale,jacket,11*scale)
		draw_line(pos+elbow*scale,pos+hand*scale,skin,8*scale)
		draw_circle(pos+(hand+Vector2(0,3))*scale,7*scale,skin.darkened(.07))
	# 后臂在 100 生命值时从肩部脱落，留下破袖口。
	if not z.get("arm_lost",false):
		draw_line(pos+Vector2(14,-23)*scale,pos+Vector2(22,-4)*scale,jacket_dark,11*scale)
		draw_line(pos+Vector2(22,-4)*scale,pos+Vector2(16,15)*scale,skin,9*scale)
		draw_circle(pos+Vector2(15,18)*scale,7*scale,skin.darkened(.08))
	else:
		draw_colored_polygon(PackedVector2Array([pos+Vector2(12,-29)*scale,pos+Vector2(25,-24)*scale,pos+Vector2(20,-13)*scale,pos+Vector2(11,-17)*scale]),jacket_dark.darkened(.18))
		draw_circle(pos+Vector2(20,-20)*scale,4*scale,Color("#735044"))
	# 大头、凸眼、松垮下颌，整体面向左侧。
	var head := pos+Vector2(-11,-58)*scale+head_shift
	draw_circle(head,28*scale,outline)
	draw_circle(head,25*scale,skin)
	# 不画鼻子实体；两个鼻孔位于双眼下方、嘴巴正上方。
	draw_circle(head+Vector2(-9,3)*scale,1.6*scale,Color("#40513f"))
	draw_circle(head+Vector2(-3,3)*scale,1.6*scale,Color("#40513f"))
	var jaw_drop := 7.0*bite
	draw_colored_polygon(PackedVector2Array([head+Vector2(-23,13)*scale,head+Vector2(11,14)*scale,head+Vector2(8,26+jaw_drop)*scale,head+Vector2(-18,28+jaw_drop)*scale]),skin.darkened(.08))
	# 不对称凸眼，保持简洁的扁平几何形状。
	draw_circle(head+Vector2(-16,-8)*scale,8*scale,Color("#eee9c9"))
	draw_circle(head+Vector2(3,-11)*scale,9*scale,Color("#f3edcf"))
	draw_circle(head+Vector2(-20,-6)*scale,2.7*scale,Color("#242922"))
	draw_circle(head+Vector2(-2,-8)*scale,2.7*scale,Color("#242922"))
	# 啃食状态张大嘴；上下两排参差牙齿随下颌开合。
	draw_colored_polygon(PackedVector2Array([head+Vector2(-24,12)*scale,head+Vector2(9,13)*scale,head+Vector2(6,22+jaw_drop)*scale,head+Vector2(-19,22+jaw_drop)*scale]),Color("#352728"))
	draw_rect(Rect2(head+Vector2(-15,12)*scale,Vector2(7,6)*scale),Color("#e4ddc1"))
	draw_rect(Rect2(head+Vector2(-2,13)*scale,Vector2(6,5)*scale),Color("#ded6b9"))
	if biting:
		draw_line(head+Vector2(-17,22+jaw_drop)*scale,head+Vector2(2,21+jaw_drop)*scale,Color("#8f3d43"),3*scale)
	# 稀疏凌乱的头发。
	draw_line(head+Vector2(-4,-25)*scale,head+Vector2(-2,-35)*scale,outline,2*scale)
	draw_line(head+Vector2(7,-23)*scale,head+Vector2(14,-31)*scale,outline,2*scale)
	if z.kind=="cone" and not z.get("armor_lost",false):
		draw_colored_polygon(PackedVector2Array([head+Vector2(-22,-18)*scale,head+Vector2(1,-62)*scale,head+Vector2(25,-18)*scale]),Color("#e88737"))
		draw_rect(Rect2(head+Vector2(-28,-21)*scale,Vector2(58,8)*scale),Color("#f0a246"))
		draw_line(head+Vector2(-13,-36)*scale,head+Vector2(12,-36)*scale,Color("#f6c06b"),4*scale)
	elif z.kind=="bucket" and not z.get("armor_lost",false):
		draw_colored_polygon(PackedVector2Array([head+Vector2(-25,-55)*scale,head+Vector2(24,-51)*scale,head+Vector2(29,-17)*scale,head+Vector2(-21,-18)*scale]),Color("#879397"))
		draw_rect(Rect2(head+Vector2(-30,-56)*scale,Vector2(61,7)*scale),Color("#c0c7c7"))
		draw_line(head+Vector2(-16,-41)*scale,head+Vector2(21,-38)*scale,Color("#5d696c"),3*scale)
	elif z.kind=="runner":
		draw_rect(Rect2(head+Vector2(-27,-24)*scale,Vector2(52,9)*scale),Color("#e95855"))
		draw_colored_polygon(PackedVector2Array([head+Vector2(23,-22)*scale,head+Vector2(45,-33)*scale,head+Vector2(35,-17)*scale]),Color("#e95855"))
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
	# 僵尸血条始终显示；草坪顶部留出的空间可完整容纳第一行血条和帽子。
	if show_health_bars and not z.get("hide_bar", false):
		draw_bar(pos+Vector2(-39,-112)*scale,68*scale,z.hp/z.max_hp,Color("#df6b54"))
	if z.slow>0: draw_circle(pos+Vector2(-10,-55)*scale,32*scale,Color(0.4,0.9,1,0.13),false,3*scale)

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
	else:
		draw_colored_polygon(PackedVector2Array([
			pos+Vector2(-24,-18).rotated(angle),pos+Vector2(24,-18).rotated(angle),
			pos+Vector2(21,18).rotated(angle),pos+Vector2(-21,18).rotated(angle)]),Color("#879397"))
		draw_line(pos+Vector2(-28,-20).rotated(angle),pos+Vector2(28,-20).rotated(angle),Color("#c0c7c7"),6)
		draw_line(pos+Vector2(-17,-6).rotated(angle),pos+Vector2(17,-6).rotated(angle),Color("#5d696c"),3)

func draw_projectile(pr: Dictionary) -> void:
	var c := Color("#7de04e") if not pr.snow else Color("#8cebf2")
	draw_circle(Vector2(pr.x,pr.y),8,c); draw_rect(Rect2(pr.x-14,pr.y-2,7,4),c.darkened(.2))

func draw_sun(s: Dictionary) -> void:
	var pos: Vector2=s.pos; var rad:=19.0+sin(s.pulse*5.0)*2.0
	for i in 8:
		var a:=i*TAU/8.0; draw_line(pos+Vector2(cos(a),sin(a))*24,pos+Vector2(cos(a),sin(a))*31,Color("#ffe466"),5)
	draw_circle(pos,rad,Color("#ffd34d")); draw_circle(pos-Vector2(5,5),5,Color("#fff09a"))

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
	draw_string(ThemeDB.fallback_font,Vector2(250,103),"暂停与设置",HORIZONTAL_ALIGNMENT_CENTER,780,42,Color("#fff4b0"))
	draw_string(ThemeDB.fallback_font,Vector2(285,134),"游戏速度",HORIZONTAL_ALIGNMENT_LEFT,150,20,Color.WHITE)
	for i in speed_options.size():
		var speed: float = speed_options[i]
		var active := is_equal_approx(game_speed, speed)
		var rect := Rect2(335 + i * 104, 145, 90, 44)
		draw_panel(rect,Color("#8cb95b") if active else Color("#41706b"),Color("#fff0a0") if active else Color("#79a8a1"),3)
		draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+29),str(speed)+" 倍",HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,16,Color.WHITE)
	draw_volume_slider("音乐", music_volume, 225)
	draw_volume_slider("音效", sfx_volume, 280)
	# 自动拾取阳光
	draw_panel(Rect2(420,310,32,32),Color("#e7f4e8"),Color("#153f3d"),3)
	if auto_collect_sun:
		draw_line(Vector2(426,326),Vector2(436,337),Color("#55a52e"),6)
		draw_line(Vector2(436,337),Vector2(449,315),Color("#55a52e"),6)
	draw_string(ThemeDB.fallback_font,Vector2(470,336),"自动拾取阳光",HORIZONTAL_ALIGNMENT_LEFT,190,24,Color.WHITE)
	var fullscreen := get_window().mode == Window.MODE_FULLSCREEN or get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	draw_panel(Rect2(700,307,160,44),Color("#5c9d74") if fullscreen else Color("#41706b"),Color("#8fc5bb"),2)
	draw_string(ThemeDB.fallback_font,Vector2(700,336),"退出全屏" if fullscreen else "全屏显示",HORIZONTAL_ALIGNMENT_CENTER,160,18,Color.WHITE)
	draw_pause_icon_button(Rect2(360,376,150,106),"door","返回主菜单")
	draw_pause_icon_button(Rect2(565,376,150,106),"gear","更多设置")
	draw_pause_icon_button(Rect2(770,376,150,106),"restart","重新开始")
	draw_panel(Rect2(350,520,580,70),Color("#bceee6"),Color("#184d4b"),5)
	draw_string(ThemeDB.fallback_font,Vector2(350,566),"返回游戏",HORIZONTAL_ALIGNMENT_CENTER,580,31,Color("#173c3a"))
	draw_string(ThemeDB.fallback_font,Vector2(250,650),"P / Esc 继续  •  F11 切换全屏",HORIZONTAL_ALIGNMENT_CENTER,780,15,Color("#b5d2cc"))
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
	draw_string(ThemeDB.fallback_font,Vector2(340,432),"自动拾取阳光",HORIZONTAL_ALIGNMENT_LEFT,180,17,Color("#b9d6d0"))
	draw_string(ThemeDB.fallback_font,Vector2(690,432),"开启" if auto_collect_sun else "关闭",HORIZONTAL_ALIGNMENT_RIGHT,220,17,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(340,464),"音乐 / 音效",HORIZONTAL_ALIGNMENT_LEFT,180,17,Color("#b9d6d0"))
	draw_string(ThemeDB.fallback_font,Vector2(690,464),str(roundi(music_volume*100))+"%  /  "+str(roundi(sfx_volume*100))+"%",HORIZONTAL_ALIGNMENT_RIGHT,220,17,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(340,494),"显示模式",HORIZONTAL_ALIGNMENT_LEFT,180,17,Color("#b9d6d0"))
	var full := get_window().mode == Window.MODE_FULLSCREEN or get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	draw_string(ThemeDB.fallback_font,Vector2(690,494),"全屏" if full else "窗口",HORIZONTAL_ALIGNMENT_RIGHT,220,17,Color.WHITE)
	draw_panel(Rect2(350,565,580,64),Color("#bceee6"),Color("#184d4b"),4)
	draw_string(ThemeDB.fallback_font,Vector2(350,607),"返回暂停菜单",HORIZONTAL_ALIGNMENT_CENTER,580,25,Color("#173c3a"))

func draw_key_settings() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(250,98),"快捷键设置",HORIZONTAL_ALIGNMENT_CENTER,780,38,Color("#fff4b0"))
	draw_string(ThemeDB.fallback_font,Vector2(250,126),"点击键位后，按下新的按键；冲突键位会自动交换",HORIZONTAL_ALIGNMENT_CENTER,780,15,Color("#b8d4ce"))
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
	if won and reward != "":
		draw_panel(Rect2(445,275,390,155),Color("#315a48"),Color("#ffe074"),5)
		draw_plant_shape(reward,Vector2(520,355),1.0)
		draw_string(ThemeDB.fallback_font,Vector2(575,330),"获得新植物",HORIZONTAL_ALIGNMENT_LEFT,220,20,Color("#cde5c5"))
		draw_string(ThemeDB.fallback_font,Vector2(575,370),PLANT_DATA[reward].name,HORIZONTAL_ALIGNMENT_LEFT,220,32,Color("#ffe36c"))
	elif won:
		draw_string(ThemeDB.fallback_font,Vector2(0,340),"当前主线已经全部完成！",HORIZONTAL_ALIGNMENT_CENTER,1280,27,Color.WHITE)
	else:
		draw_string(ThemeDB.fallback_font,Vector2(0,330),"调整阵型，再试一次吧。",HORIZONTAL_ALIGNMENT_CENTER,1280,24,Color.WHITE)
	draw_panel(Rect2(470,500,340,68),Color("#6aa746"),Color("#d9e378"),4)
	var button_text := "重试本关" if not won else ("进入下一关" if current_level < LEVEL_DATA.size() else "返回主菜单")
	draw_string(ThemeDB.fallback_font,Vector2(470,545),button_text,HORIZONTAL_ALIGNMENT_CENTER,340,30,Color("#183421"))
