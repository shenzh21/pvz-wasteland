extends "res://scripts/game_view.gd"

const WavePlanner := preload("res://scripts/wave_planner.gd")
const Persistence := preload("res://scripts/persistence.gd")
const AudioSynth := preload("res://scripts/audio_synth.gd")
const WildlandRules := preload("res://scripts/wildland_rules.gd")
const PepperRules := preload("res://scripts/pepper_rules.gd")

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
		if "--zombies" in args:
			almanac_tab = "zombies"
			if "--charger" in args or "--camo" in args or "--glider" in args or "--copper" in args:
				var capture_kind := "copper" if "--copper" in args else "glider" if "--glider" in args else "camo" if "--camo" in args else "charger"
				almanac_selected = ZOMBIE_INFO.keys().find(capture_kind)
				almanac_row_offset = almanac_max_offset()
		elif "--squash" in args or "--short-pea" in args or "--energy-pea" in args or "--bbq-mushroom" in args:
			var capture_plant := "bbq_mushroom" if "--bbq-mushroom" in args else "energy_pea" if "--energy-pea" in args else "short_pea" if "--short-pea" in args else "squash"
			almanac_selected = PLANT_DATA.keys().find(capture_plant)
			almanac_row_offset = almanac_max_offset()
		capture_preview.call_deferred()
	elif "--smoke-almanac" in args:
		game_state = "almanac"
		almanac_tab = "plants"
		scroll_almanac(1)
	elif "--capture-level-select" in args or "--smoke-level-select" in args:
		game_state = "level_select"
		if "--capture-level-select" in args: capture_preview.call_deferred()
	elif "--smoke-prepare" in args:
		prepare_level(3)
		prepare_camera_x = 520.0
	elif "--smoke-wasteland" in args:
		equipped_plants.assign(LEVEL_DATA[4].plants)
		reset_game(4)
		assert(is_equal_approx(zombie_row_score("normal",1,9),2.0),"第一大波结束前荒地行僵尸必须占双倍分数")
		assert(is_equal_approx(zombie_row_score("normal",1,10),1.5),"第一大波结束后荒地行僵尸必须占1.5倍分数")
		assert(is_equal_approx(zombie_row_score("cone",0,10),2.0),"草地行僵尸分数不能受到荒地倍率影响")
		sun_points = 999
		place_plant("yam_guard", 2, 2)
		place_plant("yam_guard", 2, 0)
		spawn_zombie(1, "normal", 570.0)
		spawn_zombie(3, "cone", 570.0)
	elif "--smoke-needle" in args:
		equipped_plants.assign(LEVEL_DATA[5].plants)
		reset_game(5)
		sun_points = 999
		place_plant("needle", 4, 2)
		spawn_zombie(1, "normal", 930.0)
		spawn_zombie(3, "runner", 850.0)
	elif "--smoke-kart" in args:
		equipped_plants.assign(LEVEL_DATA[6].plants.slice(0,8))
		reset_game(6)
		spawn_zombie(0,"kart",850.0)
		var blast_target: Dictionary = zombies[-1]
		damage_zombie(blast_target,1800.0)
		assert(blast_target.dead,"卡丁车必须把车体剩余伤害继续传递给小鬼")
		reset_game(6)
		sun_points = 999
		place_plant("cherry",3,2)
		var invincible_cherry: Dictionary = plants[-1]
		var cherry_x := cell_center(3,2).x
		spawn_zombie(2,"kart",cherry_x)
		zombies[-1].x = cherry_x
		spawn_zombie(2,"normal",cherry_x)
		zombies[-1].x = cherry_x
		update_zombies(0.25)
		assert(not invincible_cherry.dead and invincible_cherry.hp==invincible_cherry.max_hp,
			"樱桃炸弹引爆前不能被卡丁车碾压或被僵尸啃伤")
		update_plants(1.0)
		assert(invincible_cherry.dead and zombies[0].dead and zombies[1].dead,
			"无敌的樱桃炸弹仍必须在自身引爆后消失并造成伤害")
	elif "--smoke-cactus" in args:
		equipped_plants.assign(LEVEL_DATA[6].plants.slice(0,8))
		reset_game(6)
		sun_points = 999
		place_plant("cactus",2,2)
		for i in 4:
			spawn_zombie(2,"normal",700.0)
			zombies[-1].x = 700.0+i*5.0
		projectiles.append({"row":2,"x":700.0,"y":cell_center(2,2).y-9.0,"speed":0.0,
			"damage":20.0,"snow":false,"piercing":true,"hit_ids":[],"max_hits":3,"dead":false})
		update_projectiles(0.0)
		assert(projectiles[-1].dead and zombies[0].hp==170.0 and zombies[1].hp==170.0 and zombies[2].hp==170.0 and zombies[3].hp==190.0,
			"仙人掌尖刺必须只命中前三个不同目标")
	elif "--smoke-slime" in args:
		equipped_plants.assign(LEVEL_DATA[7].plants.slice(0,8))
		reset_game(7)
		sun_points = 999
		place_plant("slime",4,2)
		spawn_zombie(2,"swing",cell_center(5,2).x)
		zombies[-1].x = cell_center(5,2).x
		update_plants(0.2)
		assert(zombies[-1].rooted,"粘液多肉必须固定自身及前后一格范围内的目标")
		var swing_test: Dictionary = zombies[-1]
		var old_row: int = swing_test.row
		swing_test.swing_clock = 0.0
		update_zombies(0.1)
		assert(swing_test.row==old_row,"被固定的摇摆僵尸不能换行")
		swing_test.rooted = false
		update_zombies(0.1)
		assert(absi(swing_test.row-old_row)==1,"摇摆僵尸每次只能移动到相邻行")
		assert(absf(float(swing_test.draw_row)-float(old_row))<0.5,"摇摆僵尸换行时画面位置必须平滑过渡")
		spawn_zombie(0,"swing",850.0)
		var down_test: Dictionary = zombies[-1]
		down_test.swing_clock = 0.0
		update_zombies(0.1)
		assert(down_test.row==1,"顶行摇摆僵尸必须向下换行")
		spawn_zombie(ROWS-1,"swing",850.0)
		var up_test: Dictionary = zombies[-1]
		up_test.swing_clock = 0.0
		update_zombies(0.1)
		assert(up_test.row==ROWS-2,"底行摇摆僵尸必须向上换行")
		reset_game(7)
		sun_points = 999
		place_plant("slime",4,2)
		var slime_test: Dictionary = plants[-1]
		spawn_zombie(2,"normal",cell_center(4,2).x)
		var held_test: Dictionary = zombies[-1]
		held_test.x = cell_center(4,2).x+20.0
		held_test.rooted = true
		held_test.biting = true
		var slime_hp_before: float = slime_test.hp
		update_zombies(0.25)
		assert(not held_test.biting and slime_test.hp==slime_hp_before,"被固定的僵尸必须停止啃咬和造成伤害")
		reset_game(7)
		sun_points = 999
		place_plant("slime",4,2)
		spawn_zombie(2,"kart",cell_center(5,2).x)
		var kart_test: Dictionary = zombies[-1]
		kart_test.x = cell_center(5,2).x
		update_plants(0.1)
		assert(not kart_test.rooted,"粘液多肉不能固定卡丁车车体")
		damage_zombie(kart_test,500.0)
		update_plants(0.1)
		assert(kart_test.kind=="imp" and kart_test.rooted,"车毁后的小鬼僵尸必须可以被固定")
	elif "--smoke-economy" in args:
		equipped_plants.assign(LEVEL_DATA[8].plants.slice(0,8))
		reset_game(8)
		assert(wave_plan.size()==20 and level_zombie_types()==["normal","cone","kart","swing"],"荒地第五关必须有两组大波和指定僵尸")
		assert(coin_kind_for_roll(0.019)=="gold" and coin_kind_for_roll(0.02)=="silver" and coin_kind_for_roll(0.099)=="silver" and coin_kind_for_roll(0.10)=="","钱币掉率边界必须为金币2%、银币8%")
		money = 30000
		item_inventory = {"air_bomb":0,"sun_pack":0}
		for i in 4: purchase_item("air_bomb")
		assert(item_inventory.air_bomb==3 and money==6000,"空投炸弹最多持有三个，达到上限后不能继续扣款")
		purchase_item("sun_pack")
		var sun_before := sun_points
		activate_item("sun_pack")
		assert(item_inventory.sun_pack==0 and sun_points==sun_before+500,"阳光礼包必须消耗一份并提供500阳光")
		unlocked_level = 17
		sun_shovel_level = 0
		money = 25000
		purchase_sun_shovel()
		assert(sun_shovel_level==0 and money==25000,"阳光铲必须在完成荒地第十四关后才能购买")
		unlocked_level = 18
		purchase_sun_shovel()
		assert(sun_shovel_level==1 and money==15000 and shovel_refund_for("pea")==25,
			"一级阳光铲必须花费10000并返还植物价格的25%")
		purchase_sun_shovel()
		assert(sun_shovel_level==2 and money==3000 and shovel_refund_for("energy_pea")==162,
			"二级阳光铲必须花费12000并返还植物价格的50%（向下取整）")
		purchase_sun_shovel()
		assert(sun_shovel_level==2 and money==3000,"阳光铲最多只能购买两次")
		sun_points = 0
		var shovel_test_plant := {"kind":"energy_pea","col":2,"row":2,"dead":false}
		remove_plant_with_shovel(shovel_test_plant)
		assert(shovel_test_plant.dead and sun_points==162,"满级阳光铲必须在铲除植物时实际返还50%阳光")
		save_game()
		sun_shovel_level = 0
		load_save_game()
		assert(sun_shovel_level==2,"阳光铲的永久升级等级必须写入并恢复存档")
		spawn_zombie(2,"normal",cell_center(4,2).x)
		zombies[-1].x = cell_center(4,2).x
		use_air_bomb(4,2)
		assert(zombies[-1].dead and item_inventory.air_bomb==2,"空投炸弹必须造成樱桃炸弹伤害并消耗库存")
		# 隔离前一项击杀测试可能产生的随机掉币。
		coins.clear()
		var money_before := money
		spawn_coin(Vector2(500,400),"silver")
		collect_coin(coins[-1])
		spawn_coin(Vector2(540,400),"gold")
		collect_coin(coins[-1])
		assert(money==money_before+110,"银币和金币必须分别价值10与100")
		auto_collect_sun = true
		var auto_money_before := money
		spawn_coin(Vector2(580,400),"silver")
		var auto_coin: Dictionary = coins[-1]
		auto_coin.pos = Vector2(auto_coin.pos.x,auto_coin.target_y)
		auto_coin.vel = Vector2.ZERO
		auto_coin.pulse = 1.0
		update_coins(0.05)
		assert(auto_coin.dead,"自动拾取必须收取已经落地的钱币")
		assert(money==auto_money_before+10,"自动拾取的银币必须增加10资金")
		auto_collect_sun = false
		spawn_coin(Vector2(620,400),"gold")
		var manual_coin: Dictionary = coins[-1]
		manual_coin.pos = Vector2(manual_coin.pos.x,manual_coin.target_y)
		manual_coin.vel = Vector2.ZERO
		manual_coin.pulse = 1.0
		update_coins(0.05)
		assert(not manual_coin.dead and money==auto_money_before+10,"关闭自动拾取后钱币必须留在场上")
		reset_game(7)
		money = 0
		claimed_money_bags.clear()
		mowers[0].used = true
		finish_level()
		assert(money==500 and mower_bonus_count==4 and reward_bag_awarded,"首次钱袋奖励和保留小推车奖励必须正确结算")
		reset_game(1)
		unlocked_level = LEVEL_DATA.size()
		money = 0
		finish_level()
		assert(money==600 and reward_bag_awarded,"重玩任意已完成关卡都必须额外获得钱袋")
	elif "--smoke-squash" in args:
		equipped_plants.assign(LEVEL_DATA[9].plants.slice(0,8))
		reset_game(9)
		sun_points = 999
		assert(wave_plan.size()==30 and level_zombie_types()==["normal","cone","bucket","runner","kart","swing"],"荒地第六关必须有三组大波和完整的非旗帜僵尸阵容")
		var planned_kinds: Array[String] = []
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				if planned_kind not in planned_kinds:
					planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","bucket","runner","kart","swing"]:
			assert(required_kind in planned_kinds,"荒地第六关的随机波次不能漏掉%s" % required_kind)
		var third_group_score := 0
		for wave_index in range(20,30):
			third_group_score += wave_score(wave_plan[wave_index])
		assert(third_group_score==111,"荒地第六关第三个大波组的计划分数必须为111")
		place_plant("squash",4,2)
		var squash_test: Dictionary = plants[-1]
		var squash_center := cell_center(4,2).x
		spawn_zombie(2,"normal",squash_center+CELL_W+30.0)
		zombies[-1].x = squash_center+CELL_W+30.0
		update_plants(0.1)
		assert(int(squash_test.squash_phase)==0,"倭瓜不能攻击触发范围外的僵尸")
		# 回归截图中的情况：僵尸已经越过倭瓜中心、位于左侧相邻格时也应触发。
		zombies[-1].x = squash_center-CELL_W+2.0
		spawn_zombie(2,"cone",squash_center-CELL_W+8.0)
		zombies[-1].x = squash_center-CELL_W+8.0
		update_plants(0.1)
		assert(int(squash_test.squash_phase)==1,"倭瓜必须攻击左侧相邻格内已经靠近的僵尸")
		update_plants(0.2)
		update_plants(0.4)
		assert(zombies[0].dead and zombies[1].dead,"倭瓜必须伤害落点附近的所有僵尸")
		update_plants(0.3)
		assert(squash_test.dead,"倭瓜攻击后必须消失")
		place_plant("squash",3,2)
		var kart_squash: Dictionary = plants[-1]
		spawn_zombie(2,"kart",cell_center(3,2).x)
		zombies[-1].x = cell_center(3,2).x
		update_plants(0.1)
		update_zombies(0.1)
		assert(kart_squash.squash_phase==1 and not kart_squash.dead,
			"与卡丁车同格种下倭瓜时必须先触发攻击，不能被车辆碾压")
		update_plants(0.2)
		update_plants(0.4)
		assert(zombies[-1].dead and kart_squash.squash_phase==3,"倭瓜伤害必须贯穿卡丁车车体并消灭小鬼")
	elif "--smoke-charger" in args:
		equipped_plants.assign(LEVEL_DATA[10].plants.slice(0,8))
		reset_game(10)
		assert(wave_plan.size()==20 and level_zombie_types()==["normal","cone","bucket","runner","charger"],
			"荒地第七关必须有两个大波组和指定僵尸阵容")
		var planned_kinds: Array[String] = []
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","bucket","runner","charger"]:
			assert(required_kind in planned_kinds,"荒地第七关的波次不能漏掉%s" % required_kind)
		spawn_zombie(2,"charger",900.0)
		var charger_test: Dictionary = zombies[-1]
		assert(charger_test.hp==1690.0 and charger_test.speed==25.0 and ZOMBIE_POINTS.charger==4,
			"钢盔冲锋僵尸的生命、速度和点数必须正确")
		damage_zombie(charger_test,1500.0)
		assert(charger_test.hp==190.0 and charger_test.armor_lost,"钢盔承受1500伤害后必须脱落并留下190本体生命")
		damage_zombie(charger_test,190.0)
		assert(charger_test.dead,"钢盔脱落后的190点本体生命耗尽时必须死亡")
	elif "--smoke-music" in args:
		collect_music_prewarm(true)
		var menu_stream: AudioStreamWAV = music_cache.menu
		var frontyard_stream: AudioStreamWAV = music_cache.frontyard
		var wasteland_stream: AudioStreamWAV = music_cache.wasteland
		assert(menu_stream.get_length()>35.0,"关卡外音乐必须明显长于旧循环")
		assert(frontyard_stream.get_length()>30.0,"前院音乐必须是较长循环")
		assert(wasteland_stream.get_length()>40.0,"荒地音乐必须是较长循环")
		assert(not is_equal_approx(frontyard_stream.get_length(),wasteland_stream.get_length()),"前院和荒地音乐必须使用不同编曲")
	elif "--smoke-navigation" in args:
		game_state = "title"
		handle_click(Vector2(900,515))
		assert(game_state=="settings" and pause_page=="main","主界面设置按钮必须打开设置")
		handle_pause_click(Vector2(620,420))
		assert(pause_page=="more","主界面设置必须能够进入更多设置")
		handle_pause_click(Vector2(600,595))
		assert(pause_page=="main","更多设置必须能够返回设置首页")
		handle_pause_click(Vector2(600,550))
		assert(game_state=="title","独立设置必须能够返回主界面")
		prepare_level(1)
		prepare_camera_x = 520.0
		handle_prepare_click(Vector2(350,600))
		assert(game_state=="title","选卡界面的菜单按钮必须返回主界面")
		reset_game(1)
		game_state = "win"
		handle_click(Vector2(800,535))
		assert(game_state=="title","关卡结算界面的返回主菜单按钮必须生效")
	elif "--smoke-fixed-level" in args:
		prepare_level(11)
		assert(has_fixed_loadout() and equipped_plants==["sunflower","slime"],"荒地第八关必须固定向日葵和粘液多肉")
		assert(not is_wasteland_level() and is_plantable_cell(1) and is_plantable_cell(3),"荒地第八关必须使用五行都能种植的前院地图")
		assert(LEVEL_DATA[current_level].world=="荒地" and desired_music_track()=="frontyard","荒地第八关须保留章节名称，但音乐跟随前院地图")
		assert(is_equal_approx(zombie_row_score("normal",1,0),1.0),"前院地图不能应用荒地行出怪分数倍率")
		prepare_camera_x = 520.0
		handle_prepare_click(card_rect(0).get_center())
		handle_prepare_click(prepare_card_rect(1).get_center())
		assert(equipped_plants==["sunflower","slime"],"固定卡组不能在选卡界面增删")
		reset_game(11)
		assert(wave_plan.size()==10 and level_zombie_types()==["normal","cone"],"荒地第八关必须只有一组大波和普通、路障僵尸")
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","cone"],"荒地第八关不能生成其他僵尸")
		assert(is_equal_approx(spawn_clock,9.0),"固定卡组关卡的首次出波等待必须为普通关卡的1.5倍")
		spawn_clock = 0.0
		update_spawning(0.0)
		assert(spawn_clock>=13.5 and spawn_clock<=17.25,"固定卡组关卡的小波间隔必须为普通关卡的1.5倍")
		current_wave = 9
		spawn_clock = 0.0
		big_wave_warning = false
		update_spawning(0.0)
		assert(big_wave_warning and is_equal_approx(spawn_clock,3.75),"固定卡组关卡的大波警告时间必须为普通关卡的1.5倍")
	elif "--smoke-locked-level" in args:
		saved_loadouts[14] = ["sunflower","short_pea","cherry"]
		prepare_level(14)
		assert(available_plants.has("short_pea") and is_plant_locked("short_pea"),
			"荒地第十一关必须显示被锁定的矮茎豌豆卡片")
		assert(equipped_plants==["sunflower","cherry"],"保存阵容中的矮茎豌豆必须在本关被自动剔除")
		prepare_camera_x = 520.0
		var short_pea_index := available_plants.find("short_pea")
		handle_prepare_click(prepare_card_rect(short_pea_index).get_center())
		assert(not equipped_plants.has("short_pea") and message=="该植物在本关被锁定",
			"点击锁定卡片不能把矮茎豌豆加入卡槽")
		reset_game(14)
		assert(wave_plan.size()==30 and level_zombie_types()==["normal","cone","bucket","runner","swing","camo"],
			"荒地第十一关必须有三个大波组和指定僵尸阵容")
		var planned_kinds: Array[String] = []
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","cone","bucket","runner","swing","camo"],"荒地第十一关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","bucket","runner","swing","camo"]:
			assert(required_kind in planned_kinds,"荒地第十一关的波次不能漏掉%s" % required_kind)
	elif "--smoke-glider" in args:
		assert(LEVEL_DATA[14].reward=="energy_pea" and PLANT_DATA.energy_pea.cost==325 and PLANT_DATA.energy_pea.cool==30.0 and PLANT_DATA.energy_pea.damage==80.0,
			"荒地第十一关必须奖励325阳光、冷却30秒、单发80伤害的聚能豆")
		assert(energy_pea_shot_count(0.0)==2 and energy_pea_shot_count(0.0999)==2 and energy_pea_shot_count(0.10)==1,
			"聚能豆双发概率边界必须严格为10%")
		equipped_plants.assign(LEVEL_DATA[15].plants.slice(0,8))
		reset_game(15)
		assert(wave_plan.size()==20 and level_zombie_types()==["normal","bucket","runner","glider"],
			"荒地第十二关必须有两个大波组和指定僵尸阵容")
		var planned_kinds: Array[String] = []
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","bucket","runner","glider"],"荒地第十二关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","bucket","runner","glider"]:
			assert(required_kind in planned_kinds,"荒地第十二关的波次不能漏掉%s" % required_kind)
		sun_points = 999
		spawn_zombie(2,"glider",900.0)
		var glider_test: Dictionary = zombies[-1]
		glider_test.x = cell_center(4,2).x
		assert(glider_test.hp==360.0 and glider_test.speed==80.0 and ZOMBIE_POINTS.glider==3 and zombie_is_airborne(glider_test),
			"滑翔伞僵尸必须以360生命、80滑翔速度和3点分值入场")
		assert(has_zombie_ahead(2,500.0,false) and not has_zombie_ahead(2,500.0,true),
			"滑翔目标必须能被普通弹道锁定，但不能被矮茎豌豆锁定")
		assert(find_squash_target({"col":4,"row":2})==null and find_slime_target({"col":4,"row":2})==null,
			"滑翔途中不能被倭瓜或粘液多肉选中")
		assert(not mine_has_target({"col":4,"row":2}) and plant_at_zombie(glider_test)==null,
			"滑翔途中必须越过土豆雷和所有地面阻挡物")
		yam_minions.append({"owner_col":4,"owner_row":1,"col":4,"row":2,"hp":500.0,"max_hp":500.0,"dead":false,"anim":0.0,"attack_flash":0.0})
		var air_hp_before: float = glider_test.hp
		update_yam_minions(0.5)
		assert(glider_test.hp==air_hp_before,"小红薯不能攻击滑翔中的僵尸")
		place_plant("energy_pea",2,2)
		plants[-1].timer = 0.0
		update_plants(0.01)
		assert(not projectiles.is_empty() and projectiles[-1].damage==80.0 and projectiles[-1].get("energy",false),
			"聚能豆必须发射80伤害的聚能豌豆")
		projectiles[-1].x = glider_test.x
		projectiles[-1].speed = 0.0
		update_projectiles(0.0)
		assert(glider_test.hp==280.0,"普通高度的聚能豌豆必须能够命中滑翔目标")
		glider_test.x = cell_center(4,2).x+100.0
		update_zombies(2.1)
		assert(not zombie_is_airborne(glider_test) and glider_test.x==cell_center(4,2).x and glider_test.speed==15.0,
			"滑翔伞僵尸必须在第五格落地并恢复普通步行速度")
		reset_game(16)
		assert(wave_plan.size()==30 and level_zombie_types()==["normal","cone","bucket","charger","glider"],
			"荒地第十三关必须有三个大波组和指定僵尸阵容")
		planned_kinds.clear()
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","cone","bucket","charger","glider"],"荒地第十三关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","bucket","charger","glider"]:
			assert(required_kind in planned_kinds,"荒地第十三关的波次不能漏掉%s" % required_kind)
		reset_game(17)
		assert(wave_plan.size()==20 and level_zombie_types()==["normal","cone","bucket","charger","copper","runner"],
			"荒地第十四关必须有两个大波组和指定僵尸阵容")
		planned_kinds.clear()
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","cone","bucket","charger","copper","runner"],"荒地第十四关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","bucket","charger","copper","runner"]:
			assert(required_kind in planned_kinds,"荒地第十四关的波次不能漏掉%s" % required_kind)
		var aggressive_second_group_score := 0
		for wave_index in range(10,20):
			aggressive_second_group_score += wave_score(wave_plan[wave_index])
		assert(aggressive_second_group_score==88,
			"荒地第十四关起第二个大波组的计划分数必须提高到88点")
		spawn_zombie(2,"copper",900.0)
		var copper_test: Dictionary = zombies[-1]
		assert(copper_test.hp==2290.0 and copper_test.speed==12.0 and ZOMBIE_POINTS.copper==4,
			"铜头僵尸必须具有2100防具、190本体生命、12速度和4点分值")
		damage_zombie(copper_test,2100.0)
		assert(copper_test.hp==190.0 and copper_test.armor_lost,"铜球承受2100伤害后必须脱落并留下190本体生命")
		damage_zombie(copper_test,190.0)
		assert(copper_test.dead,"铜球脱落后的本体生命耗尽时必须死亡")
		reset_game(18)
		assert(wave_plan.size()==30 and level_zombie_types()==["normal","cone","bucket","copper","camo","kart"],
			"荒地第十五关必须有三个大波组和指定僵尸阵容")
		planned_kinds.clear()
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","cone","bucket","copper","camo","kart"],"荒地第十五关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","bucket","copper","camo","kart"]:
			assert(required_kind in planned_kinds,"荒地第十五关的波次不能漏掉%s" % required_kind)
		var second_group_score := 0
		var third_group_score := 0
		for wave_index in range(10,20): second_group_score += wave_score(wave_plan[wave_index])
		for wave_index in range(20,30): third_group_score += wave_score(wave_plan[wave_index])
		assert(second_group_score==88 and third_group_score==157,
			"荒地第十五关必须应用激进的第二、第三大波组预算")
		reset_game(19)
		assert(wave_plan.size()==30 and level_zombie_types()==["normal","bucket","kart","runner","camo","glider","copper"],
			"荒地第十六关必须有三个大波组和指定僵尸阵容")
		planned_kinds.clear()
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","bucket","kart","runner","camo","glider","copper"],"荒地第十六关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","bucket","kart","runner","camo","glider","copper"]:
			assert(required_kind in planned_kinds,"荒地第十六关的波次不能漏掉%s" % required_kind)
		second_group_score = 0
		third_group_score = 0
		for wave_index in range(10,20): second_group_score += wave_score(wave_plan[wave_index])
		for wave_index in range(20,30): third_group_score += wave_score(wave_plan[wave_index])
		assert(second_group_score==88 and third_group_score==157,
			"荒地第十六关必须继续应用激进的后续大波组预算")
		assert(LEVEL_DATA[19].reward=="bbq_mushroom" and PLANT_DATA.bbq_mushroom.cost==150 and PLANT_DATA.bbq_mushroom.damage==1800.0,
			"荒地第十六关必须奖励150阳光、1800伤害的烧烤蘑菇")
		reset_game(20)
		assert(wave_plan.size()==30 and level_zombie_types()==["normal","swing","runner","camo","glider","kart","charger"],
			"荒地第十七关必须有三个大波组和指定僵尸阵容")
		planned_kinds.clear()
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","swing","runner","camo","glider","kart","charger"],"荒地第十七关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","swing","runner","camo","glider","kart","charger"]:
			assert(required_kind in planned_kinds,"荒地第十七关的波次不能漏掉%s" % required_kind)
		second_group_score = 0
		third_group_score = 0
		for wave_index in range(10,20): second_group_score += wave_score(wave_plan[wave_index])
		for wave_index in range(20,30): third_group_score += wave_score(wave_plan[wave_index])
		assert(second_group_score==88 and third_group_score==157,"荒地第十七关必须继续使用激进波次预算")
		sun_points = 999
		place_plant("bbq_mushroom",4,2)
		var bbq_test: Dictionary = plants[-1]
		var column_x := cell_center(4,2).x
		for row in ROWS:
			spawn_zombie(row,"glider" if row==4 else "kart" if row==2 else "normal",column_x)
			zombies[-1].x = column_x
		spawn_zombie(2,"normal",column_x+CELL_W/2.0+2.0)
		zombies[-1].x = column_x+CELL_W/2.0+2.0
		assert(plant_at_zombie(zombies[2])==null,"烧烤蘑菇引爆前不能被卡丁车碾压")
		update_plants(1.0)
		assert(bbq_test.dead,"烧烤蘑菇引爆后必须消失")
		for target_index in ROWS:
			assert(zombies[target_index].dead,"烧烤蘑菇必须命中整列五行内的目标")
		assert(not zombies[-1].dead and zombies[-1].hp==190.0,"烧烤蘑菇不能伤害相邻列外的僵尸")
	elif "--smoke-camo" in args:
		assert(LEVEL_DATA[11].reward=="short_pea" and PLANT_DATA.short_pea.cost==125,
			"荒地第八关必须奖励125阳光的矮茎豌豆")
		equipped_plants.assign(LEVEL_DATA[12].plants.slice(0,8))
		reset_game(12)
		assert(wave_plan.size()==20 and level_zombie_types()==["normal","cone","runner","camo"],
			"荒地第九关必须有两组大波和指定僵尸阵容")
		var planned_kinds: Array[String] = []
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","cone","runner","camo"],"荒地第九关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","runner","camo"]:
			assert(required_kind in planned_kinds,"荒地第九关的波次不能漏掉%s" % required_kind)
		reset_game(13)
		assert(wave_plan.size()==30 and level_zombie_types()==["normal","cone","bucket","kart","charger","camo"],
			"荒地第十关必须有三个大波组和指定僵尸阵容")
		planned_kinds.clear()
		for planned_wave in wave_plan:
			for planned_kind in planned_wave:
				assert(planned_kind in ["normal","cone","bucket","kart","charger","camo"],"荒地第十关生成了未指定的僵尸")
				if planned_kind not in planned_kinds: planned_kinds.append(planned_kind)
		for required_kind in ["normal","cone","bucket","kart","charger","camo"]:
			assert(required_kind in planned_kinds,"荒地第十关的波次不能漏掉%s" % required_kind)
		reset_game(12)
		sun_points = 999
		place_plant("pea",2,2)
		plants[-1].timer = 0.0
		spawn_zombie(2,"camo",720.0)
		var camo_test: Dictionary = zombies[-1]
		camo_test.x = 720.0
		assert(camo_test.hp==360.0 and camo_test.speed==10.0 and ZOMBIE_POINTS.camo==3,
			"军迷僵尸必须具有360生命、10速度和3点分值")
		update_plants(0.01)
		assert(projectiles.is_empty(),"普通豌豆射手不能锁定匍匐的军迷僵尸")
		projectiles.append({"row":2,"x":720.0,"y":cell_center(2,2).y-9.0,"speed":0.0,
			"damage":20.0,"snow":false,"piercing":true,"hit_ids":[],"max_hits":3,"dead":false})
		update_projectiles(0.0)
		assert(camo_test.hp==360.0 and not projectiles[-1].dead,"仙人掌等普通射手的子弹必须从军迷僵尸上方掠过")
		place_plant("short_pea",3,2)
		plants[-1].timer = 0.0
		update_plants(0.01)
		assert(projectiles.size()==2 and projectiles[-1].get("hits_prone",false),"矮茎豌豆必须锁定匍匐目标并发射低位子弹")
		projectiles[-1].x = camo_test.x
		projectiles[-1].speed = 0.0
		update_projectiles(0.0)
		assert(camo_test.hp==340.0,"矮茎豌豆必须对军迷僵尸造成20点伤害")
		camo_test.hp = 181.0
		damage_zombie(camo_test,1.0)
		update_zombies(0.0)
		assert(camo_test.arm_lost and ZOMBIE_POINTS.camo==3,"军迷僵尸必须在180生命时断手，且占3点")
		reset_game(12)
		sun_points = 999
		place_plant("slime",4,2)
		plants[-1].timer = 0.0
		spawn_zombie(2,"camo",cell_center(4,2).x+20.0)
		zombies[-1].x = cell_center(4,2).x+20.0
		update_plants(0.01)
		assert(zombies[-1].rooted and zombies[-1].hp==340.0,"粘液多肉必须能够固定并攻击军迷僵尸")
	elif "--smoke-shop" in args or "--capture-shop" in args:
		unlocked_level = maxi(unlocked_level,18 if "--capture-shop" in args else 4)
		money = 25000 if "--capture-shop" in args else 1800
		item_inventory = {"air_bomb":2,"sun_pack":1}
		if "--capture-shop" in args: sun_shovel_level = 0
		game_state = "shop"
		if "--capture-shop" in args: capture_preview.call_deferred()
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
	sand_clock = 90.0
	sand_buff = 0.0
	sun_points = 150+starting_sun_level*100
	selected = ""
	plants.clear()
	zombies.clear()
	projectiles.clear()
	suns.clear()
	coins.clear()
	particles.clear()
	pepper_fires.clear()
	yam_minions.clear()
	detached_arms.clear()
	dropped_armor.clear()
	level_money_earned = 0
	mower_bonus_count = 0
	reward_bag_awarded = false
	next_zombie_id = 1
	mowers.clear()
	cooldowns.clear()
	wave_plan = build_wave_plan(current_level)
	current_wave = 0
	spawn_clock = 6.0*wave_interval_scale()
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
	prepare_pool_row_offset = 0
	equipped_plants.clear()
	available_plants.assign(LEVEL_DATA[current_level].plants)
	if has_fixed_loadout():
		equipped_plants.assign(available_plants)
	elif saved_loadouts.has(current_level):
		for kind in saved_loadouts[current_level]:
			if kind in available_plants and not is_plant_locked(kind) and equipped_plants.size() < 8:
				equipped_plants.append(kind)
	plants.clear()
	zombies.clear()
	projectiles.clear()
	suns.clear()
	coins.clear()
	particles.clear()
	pepper_fires.clear()
	yam_minions.clear()
	detached_arms.clear()
	mowers.clear()
	dropped_armor.clear()
	build_zombie_preview()
	play_sfx(330.0, 0.12, 0.08, "square")
	queue_redraw()

func level_zombie_types() -> Array[String]:
	if current_level==21: return ["normal","cone","swing","basket"]
	if current_level==24: return ["normal","cone","giant"]
	if current_level==25: return ["normal","cone","copper","camo","glider"]
	if current_level==26: return ["normal","bucket","kart","charger","runner","giant"]
	if current_level==22: return ["normal","cone","bucket","basket","kart","camo"]
	if current_level==23: return ["normal","bucket","charger","glider","copper","basket"]
	# 旗帜僵尸只用于实际大波提示，不加入开战前的阵容展示。
	var result: Array[String] = ["normal", "cone"]
	if current_level == 4:
		return result
	if current_level == 6:
		return ["normal","cone","kart"]
	if current_level == 7:
		return ["normal","cone","runner","swing"]
	if current_level == 8:
		return ["normal","cone","kart","swing"]
	if current_level == 9:
		return ["normal","cone","bucket","runner","kart","swing"]
	if current_level == 10:
		return ["normal","cone","bucket","runner","charger"]
	if current_level == 11:
		return ["normal","cone"]
	if current_level == 12:
		return ["normal","cone","runner","camo"]
	if current_level == 13:
		return ["normal","cone","bucket","kart","charger","camo"]
	if current_level == 14:
		return ["normal","cone","bucket","runner","swing","camo"]
	if current_level == 15:
		return ["normal","bucket","runner","glider"]
	if current_level == 16:
		return ["normal","cone","bucket","charger","glider"]
	if current_level == 17:
		return ["normal","cone","bucket","charger","copper","runner"]
	if current_level == 18:
		return ["normal","cone","bucket","copper","camo","kart"]
	if current_level == 19:
		return ["normal","bucket","kart","runner","camo","glider","copper"]
	if current_level == 20:
		return ["normal","swing","runner","camo","glider","kart","charger"]
	if current_level >= 2: result.insert(2, "bucket")
	if current_level >= 3: result.append("runner")
	return result

func choose_preview_zombie() -> String:
	if current_level==26: return WavePlanner.choose_zombie_type(26,10,30,7,rng)
	if current_level==25: return WavePlanner.choose_zombie_type(25,9,30,4,rng)
	if current_level==24: return "giant" if rng.randf()<0.25 else "cone" if rng.randf()<0.5 else "normal"
	if current_level in [22,23]:
		return WavePlanner.choose_zombie_type(current_level,9,int(LEVEL_DATA[current_level].waves),4,rng)
	if current_level==21:
		return ["normal","cone","swing","basket"][rng.randi_range(0,3)]
	var value := rng.randf()
	if current_level == 1:
		return "cone" if value < 0.28 else "normal"
	if current_level == 2:
		if value < 0.07: return "bucket"
		return "cone" if value < 0.38 else "normal"
	if current_level == 4:
		return "cone" if value < 0.35 else "normal"
	if current_level == 6:
		if value < 0.25: return "kart"
		return "cone" if value < 0.52 else "normal"
	if current_level == 7:
		if value < 0.2: return "runner"
		if value < 0.45: return "swing"
		return "cone" if value < 0.68 else "normal"
	if current_level == 8:
		if value < 0.20: return "kart"
		if value < 0.45: return "swing"
		return "cone" if value < 0.70 else "normal"
	if current_level == 9:
		if value < 0.12: return "kart"
		if value < 0.25: return "bucket"
		if value < 0.39: return "runner"
		if value < 0.55: return "swing"
		return "cone" if value < 0.78 else "normal"
	if current_level == 10:
		if value < 0.14: return "charger"
		if value < 0.29: return "bucket"
		if value < 0.45: return "runner"
		return "cone" if value < 0.72 else "normal"
	if current_level == 11:
		return "cone" if value<0.42 else "normal"
	if current_level == 12:
		if value<0.22: return "camo"
		if value<0.43: return "runner"
		return "cone" if value<0.72 else "normal"
	if current_level == 13:
		if value<0.12: return "charger"
		if value<0.24: return "kart"
		if value<0.38: return "camo"
		if value<0.52: return "bucket"
		return "cone" if value<0.76 else "normal"
	if current_level == 14:
		if value<0.16: return "camo"
		if value<0.31: return "runner"
		if value<0.48: return "swing"
		if value<0.61: return "bucket"
		return "cone" if value<0.80 else "normal"
	if current_level == 15:
		if value<0.20: return "glider"
		if value<0.40: return "runner"
		if value<0.62: return "bucket"
		return "normal"
	if current_level == 16:
		if value<0.17: return "charger"
		if value<0.35: return "glider"
		if value<0.55: return "bucket"
		return "cone" if value<0.78 else "normal"
	if current_level == 17:
		if value<0.10: return "copper"
		if value<0.24: return "charger"
		if value<0.39: return "runner"
		if value<0.57: return "bucket"
		return "cone" if value<0.80 else "normal"
	if current_level == 18:
		if value<0.11: return "copper"
		if value<0.26: return "kart"
		if value<0.42: return "camo"
		if value<0.59: return "bucket"
		return "cone" if value<0.81 else "normal"
	if current_level == 19:
		if value<0.12: return "copper"
		if value<0.25: return "kart"
		if value<0.39: return "glider"
		if value<0.54: return "camo"
		if value<0.70: return "runner"
		return "bucket" if value<0.84 else "normal"
	if current_level == 20:
		if value<0.12: return "charger"
		if value<0.25: return "kart"
		if value<0.38: return "glider"
		if value<0.51: return "camo"
		if value<0.64: return "runner"
		return "swing" if value<0.79 else "normal"
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
			"row":0, "anim":rng.randf_range(0.0,TAU), "idle_rate":rng.randf_range(0.86,1.12), "slow":0.0, "walking":false,
			"hp":1.0, "max_hp":1.0, "hide_bar":true,"airborne":display_kinds[i]=="glider"
		})

func update_preview_idle(delta: float) -> void:
	for z in preview_zombies:
		z.anim = float(z.anim) + delta

func _process(delta: float) -> void:
	update_music_context()
	if game_state == "prepare":
		prepare_time += delta
		update_preview_idle(delta)
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
		message_time = maxf(0.0,message_time-delta)
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
	WildlandRules.update_wind(self,scaled_delta)
	update_plants(scaled_delta)
	update_yam_minions(scaled_delta)
	PepperRules.update_effects(self,scaled_delta)
	update_projectiles(scaled_delta)
	update_zombies(scaled_delta)
	update_suns(scaled_delta)
	update_coins(scaled_delta)
	update_particles(scaled_delta)
	update_mowers(scaled_delta)
	cleanup_entities()
	if final_wave_sent and zombies.is_empty():
		finish_level()
	queue_redraw()

func finish_level() -> void:
	game_state = "win"
	high_score = maxi(high_score, sun_points)
	var replaying_completed_level := current_level<unlocked_level or campaign_completed
	# 终场最后一只僵尸掉落的钱币也必须结算，避免胜利界面盖住后无法拾取。
	for coin in coins:
		if not coin.dead: collect_coin(coin)
	mower_bonus_count = 0
	for mower in mowers:
		if not mower.used and not mower.active:
			mower_bonus_count += 1
	var mower_money := mower_bonus_count*100
	money += mower_money
	level_money_earned += mower_money
	var first_money_bag := String(LEVEL_DATA[current_level].reward)=="money_bag" and not claimed_money_bags.has(current_level)
	if replaying_completed_level or first_money_bag:
		if first_money_bag: claimed_money_bags[current_level] = true
		reward_bag_awarded = true
		money += 100
		level_money_earned += 100
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
			spawn_clock = 2.5*wave_interval_scale()
			spawn_clock_start = spawn_clock
			return
		var is_final_wave := current_wave == wave_plan.size() - 1
		spawn_big_wave(wave_plan[current_wave])
		current_wave += 1
		big_wave_warning = false
		if is_final_wave:
			final_wave_sent = true
			return
		spawn_clock = next_wave_delay()
		spawn_clock_start = spawn_clock
		return
	spawn_small_wave(current_wave, wave_plan[current_wave])
	current_wave += 1
	spawn_clock = next_wave_delay()
	spawn_clock_start = spawn_clock

func wave_interval_scale() -> float:
	return float(LEVEL_DATA[current_level].get("wave_interval_scale",1.0))

func next_wave_delay() -> float:
	return (10.0+rng.randf_range(-1.0,1.5))*wave_interval_scale()

func build_wave_plan(level: int) -> Array:
	return WavePlanner.build(level, rng)

func spawn_small_wave(wave_index: int, wave: Array) -> void:
	var rows := [0, 1, 2, 3, 4]
	if is_wasteland_level() and wave_index < 6:
		rows = [0, 2, 4]
	rows.shuffle()
	var budget := wave_score(wave)
	var spent := 0.0
	var spawned := 0
	for i in wave.size():
		var row: int = rows[i % rows.size()]
		var cost := zombie_row_score(wave[i],row,wave_index)
		if spent+cost > budget:
			continue
		spawn_zombie(row,wave[i],1260.0+spawned*18.0)
		spent += cost
		spawned += 1

func spawn_big_wave(wave: Array) -> void:
	var wave_index := current_wave
	spawn_zombie(2, "flag", 1160.0)
	var rows := [0, 1, 2, 3, 4]
	rows.shuffle()
	var budget := wave_score(wave)
	var spent := 0.0
	var spawned := 0
	for i in wave.size():
		var row: int = rows[i % ROWS]
		var cost := zombie_row_score(wave[i],row,wave_index)
		if spent+cost > budget:
			continue
		spawn_zombie(row,wave[i],1210.0+spawned*22.0)
		spent += cost
		spawned += 1

func wave_score(wave: Array) -> int:
	var total := 0
	for kind in wave:
		total += int(ZOMBIE_POINTS[kind])
	return total

func zombie_row_score(kind: String, row: int, wave_index: int) -> float:
	var score := float(ZOMBIE_POINTS[kind])
	if is_wasteland_level() and row % 2 == 1:
		# 第一大波（第10个小波）结束后降低荒地行的额外占分，
		# 让后续尸群数量增加，但荒地行仍比草地行更昂贵。
		score *= 2.0 if wave_index < 10 else 1.5
	return score

func spawn_zombie(row: int, kind: String, at_x := 1260.0) -> void:
	var stats: Dictionary = {
		"giant":{"hp":3000.0,"speed":15.0},
		"basket":{"hp":360.0,"speed":25.0},
		"normal":{"hp":190.0,"speed":15.0}, "cone":{"hp":560.0,"speed":15.0},
		"bucket":{"hp":1290.0,"speed":15.0}, "runner":{"hp":160.0,"speed":35.0},
		"flag":{"hp":190.0,"speed":15.0}, "kart":{"hp":500.0,"speed":20.0},
		"imp":{"hp":190.0,"speed":25.0}, "swing":{"hp":300.0,"speed":17.0},
		"charger":{"hp":1690.0,"speed":25.0}, "camo":{"hp":360.0,"speed":10.0},
		"glider":{"hp":360.0,"speed":80.0}, "copper":{"hp":2290.0,"speed":12.0}
	}[kind]
	zombies.append({"id":next_zombie_id,"row":row,"draw_row":float(row),"x":at_x + rng.randf_range(0.0, 70.0),"hp":stats.hp,"max_hp":stats.hp,
		"speed":stats.speed,"kind":kind,"attack":0.0,"slow":0.0,"dead":false,"anim":rng.randf_range(0.0, 5.0),
		"biting":false,"walking":true,"rooted":false,"swing_clock":rng.randf_range(4.5,7.0),
		"arm_lost":false,"armor_lost":false,"airborne":kind=="glider",
		"landing_x":cell_center(4,row).x,"ground_speed":15.0})
	next_zombie_id += 1

func update_plants(delta: float) -> void:
	for z in zombies:
		z.rooted = false
	for p in plants:
		p.timer -= delta
		if p.dead: continue
		p.anim += delta
		match p.kind:
			"sky_pepper":
				PepperRules.attack(self,p)
			"wind_grass":
				p.wind_attack = maxf(0.0,float(p.get("wind_attack",0.0))-delta)
				WildlandRules.attack_grass(self,p)
			"sunflower":
				if p.timer <= 0.0:
					spawn_sun(cell_center(p.col, p.row) + Vector2(0, -25), false)
					p.timer = SUNFLOWER_INTERVAL
			"pea", "snow", "cactus", "short_pea", "energy_pea":
				var hits_prone: bool = bool(PLANT_DATA[p.kind].get("hits_prone",false))
				if p.timer <= 0.0 and has_zombie_ahead(p.row, cell_center(p.col, p.row).x,hits_prone):
					var shot_count := energy_pea_shot_count(rng.randf()) if p.kind=="energy_pea" else 1
					for shot_index in shot_count:
						projectiles.append({"row":p.row,"x":cell_center(p.col,p.row).x + 23.0-shot_index*11.0,
							"y":cell_center(p.col,p.row).y + (22.0 if hits_prone else -9.0)+(shot_index*2.0),"speed":235.0,"damage":PLANT_DATA[p.kind].damage,
							"snow":p.kind == "snow","energy":p.kind=="energy_pea","piercing":p.kind=="cactus","hit_ids":[],
							"max_hits":PLANT_DATA.cactus.max_targets if p.kind=="cactus" else 1,
							"hits_prone":hits_prone,"dead":false})
					p.timer = PLANT_DATA[p.kind].interval
			"needle":
				if p.timer <= 0.0:
					var target = find_needle_target(p)
					if target != null:
						var center := cell_center(p.col,p.row)
						projectiles.append({"row":target.row,"x":center.x,"y":center.y-9.0,
							"speed":360.0,"damage":PLANT_DATA.needle.damage,"snow":false,
							"needle":true,"target":target,"dead":false})
						p.timer = PLANT_DATA.needle.interval
			"slime":
				var target = get_zombie_by_id(int(p.get("slime_target_id",-1)))
				if not slime_target_valid(p,target):
					p.slime_target_id = -1
					target = find_slime_target(p)
					if target != null:
						p.slime_target_id = target.id
				if target != null:
					target.rooted = true
					if p.timer <= 0.0:
						damage_zombie(target,PLANT_DATA.slime.damage)
						p.timer = PLANT_DATA.slime.interval
			"cherry":
				if p.timer <= 0.0 and not p.dead:
					explode_cherry(p)
			"bbq_mushroom":
				if p.timer <= 0.0 and not p.dead:
					explode_bbq_mushroom(p)
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
			"squash":
				update_squash(p,delta)

func find_squash_target(p: Dictionary):
	var center_x := cell_center(p.col,p.row).x
	var left_edge := center_x-CELL_W
	var right_edge := center_x+CELL_W
	var result = null
	for z in zombies:
		if z.dead or zombie_is_airborne(z) or z.row!=p.row or z.x<left_edge or z.x>right_edge:
			continue
		if result==null or absf(z.x-center_x)<absf(result.x-center_x):
			result = z
	return result

func update_squash(p: Dictionary, delta: float) -> void:
	var phase := int(p.get("squash_phase",0))
	if phase==0:
		var target = find_squash_target(p)
		if target==null:
			return
		p.squash_phase = 1
		p.squash_clock = 0.16
		p.squash_target_id = target.id
		p.squash_target_x = target.x
		play_sfx(230.0,0.08,0.10,"square")
		return
	p.squash_clock -= delta
	var tracked = get_zombie_by_id(int(p.get("squash_target_id",-1)))
	if tracked!=null and tracked.row==p.row:
		p.squash_target_x = tracked.x
	if phase==1 and p.squash_clock<=0.0:
		p.squash_phase = 2
		p.squash_clock = 0.32
	elif phase==2 and p.squash_clock<=0.0:
		p.squash_phase = 3
		p.squash_clock = 0.22
		var landing_x := float(p.squash_target_x)
		for z in zombies:
			if not z.dead and not zombie_is_airborne(z) and z.row==p.row and absf(z.x-landing_x)<=58.0:
				damage_zombie(z,PLANT_DATA.squash.damage)
		burst(Vector2(landing_x,cell_center(p.col,p.row).y+25.0),Color("#b5c76b"),18)
		shake = 0.8
		play_sfx(88.0,0.22,0.30,"noise")
	elif phase==3 and p.squash_clock<=0.0:
		p.dead = true

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
			if not z.dead and not zombie_is_airborne(z) and z.row == minion.row:
				var distance := absf(z.x - center_x)
				if distance < target_distance:
					target = z
					target_distance = distance
		if target != null:
			damage_zombie(target,PLANT_DATA.yam_guard.damage*delta)
			minion.attack_flash = 0.12
		else:
			minion.hp = minf(minion.max_hp, minion.hp + PLANT_DATA.yam_guard.heal * delta)

func has_zombie_ahead(row: int, x: float, hits_prone := false) -> bool:
	for z in zombies:
		if not z.dead and z.row == row and z.x > x and projectile_can_hit_zombie(z,hits_prone):
			return true
	return false

func energy_pea_shot_count(roll: float) -> int:
	return 2 if roll<0.10 else 1

func zombie_is_airborne(z: Dictionary) -> bool:
	return bool(z.get("airborne",false))

func projectile_can_hit_zombie(z: Dictionary, hits_prone: bool) -> bool:
	if z.kind=="camo" and not hits_prone:
		return false
	# 矮茎豌豆的低弹道能打匍匐目标，但会从滑翔单位下方穿过。
	if zombie_is_airborne(z) and hits_prone:
		return false
	return true

func get_zombie_by_id(id: int):
	if id < 0:
		return null
	for z in zombies:
		if not z.dead and int(z.get("id",-1))==id:
			return z
	return null

func slime_target_valid(p: Dictionary, target) -> bool:
	if target==null or target.dead or zombie_is_airborne(target) or target.kind=="kart" or target.row!=p.row or target.get("rooted",false):
		return false
	var radius: int = PLANT_DATA.slime.column_radius
	var left_edge := BOARD_X+float(p.col-radius)*CELL_W
	var right_edge := BOARD_X+float(p.col+radius+1)*CELL_W
	return target.x>=left_edge and target.x<right_edge

func find_slime_target(p: Dictionary):
	var result = null
	var radius: int = PLANT_DATA.slime.column_radius
	var left_edge := BOARD_X+float(p.col-radius)*CELL_W
	var right_edge := BOARD_X+float(p.col+radius+1)*CELL_W
	for z in zombies:
		if z.dead or zombie_is_airborne(z) or z.kind=="kart" or z.row!=p.row or z.get("rooted",false) or z.x<left_edge or z.x>=right_edge:
			continue
		if result==null or z.x<result.x:
			result = z
	return result

func find_needle_target(p: Dictionary):
	var target = null
	var column_radius: int = PLANT_DATA.needle.column_radius
	var left_edge := BOARD_X + float(p.col-column_radius)*CELL_W
	var right_edge := BOARD_X + float(p.col+column_radius+1)*CELL_W
	for z in zombies:
		if z.dead or z.kind=="camo" or absi(int(z.row) - int(p.row)) != 1:
			continue
		# 上下相邻行各覆盖正对格和左右各两格，共五格。
		if z.x < left_edge or z.x >= right_edge:
			continue
		if target == null or z.x < target.x:
			target = z
	return target

func explode_cherry(p: Dictionary) -> void:
	var center := cell_center(p.col, p.row)
	for z in zombies:
		if not z.dead and absf(z.row - p.row) <= 1 and absf(z.x - center.x) < 155.0:
			damage_zombie(z,PLANT_DATA.cherry.damage)
	for i in 36:
		var a := rng.randf_range(0, TAU)
		particles.append({"pos":center,"vel":Vector2(cos(a),sin(a))*rng.randf_range(60,220),
			"life":rng.randf_range(.35,.8),"max":.8,"color":Color("#ffb23e"),"size":rng.randf_range(4,12)})
	p.dead = true
	shake = 1.0
	flash = 0.7
	play_sfx(105.0, 0.36, 0.42, "noise")

func explode_bbq_mushroom(p: Dictionary) -> void:
	var center_x := cell_center(p.col,p.row).x
	for z in zombies:
		if not z.dead and absf(z.x-center_x)<CELL_W/2.0:
			damage_zombie(z,PLANT_DATA.bbq_mushroom.damage)
	for row in ROWS:
		var blast_center := Vector2(center_x,cell_center(p.col,row).y)
		for i in 12:
			var angle := rng.randf_range(0.0,TAU)
			particles.append({"pos":blast_center,"vel":Vector2(cos(angle),sin(angle))*rng.randf_range(55.0,190.0),
				"life":rng.randf_range(0.35,0.8),"max":0.8,"color":Color("#f08a3f"),"size":rng.randf_range(5.0,13.0)})
	p.dead = true
	shake = 1.0
	flash = 0.75
	play_sfx(105.0,0.36,0.42,"noise")

func mine_has_target(p: Dictionary) -> bool:
	var center_x := cell_center(p.col, p.row).x
	for z in zombies:
		if not z.dead and not zombie_is_airborne(z) and z.row == p.row and absf(z.x - center_x) < 48.0:
			return true
	return false

func explode_mine(p: Dictionary) -> void:
	var center := cell_center(p.col, p.row)
	for z in zombies:
		if not z.dead and not zombie_is_airborne(z) and z.row == p.row and absf(z.x - center.x) < 82.0:
			damage_zombie(z,PLANT_DATA.mine.damage)
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
		if pr.dead: continue
		if pr.get("pepper",false):
			PepperRules.update_projectile(self,pr,delta)
			continue
		if pr.get("basketball",false):
			pr.elapsed += delta
			var t := clampf(pr.elapsed/pr.duration,0.0,1.0)
			var point: Vector2 = pr.start.lerp(pr.finish,t)+Vector2(0,-4.0*110.0*t*(1.0-t))
			pr.x = point.x
			pr.y = point.y
			if t>=1.0:
				pr.dead = true
				var target = get_pumpkin(pr.col,pr.row)
				if target==null: target = get_plant(pr.col,pr.row)
				if target!=null and target.kind not in ["cherry","bbq_mushroom"] and not (target.kind=="squash" and target.squash_phase>0):
					target.hp -= 300.0
					if target.hp<=0: target.dead = true
				burst(point,Color("#df8844"),8)
			continue
		if pr.get("needle",false):
			var target = pr.get("target")
			if target == null or target.dead:
				pr.dead = true
				continue
			var target_pos := Vector2(target.x,BOARD_Y+target.row*CELL_H+CELL_H/2.0-22.0)
			var projectile_pos := Vector2(pr.x,pr.y).move_toward(target_pos,pr.speed*delta)
			pr.x = projectile_pos.x
			pr.y = projectile_pos.y
			pr.row = target.row
			if projectile_pos.distance_to(target_pos) <= 18.0:
				damage_zombie(target,pr.damage)
				pr.dead = true
				burst(projectile_pos,Color("#c77ae5"),5)
				play_sfx(440.0,0.035,0.07,"square")
			continue
		pr.x += pr.speed * delta
		if pr.x > W + 20: pr.dead = true
		for z in zombies:
			var already_hit: bool = bool(pr.get("piercing",false)) and int(z.get("id",-1)) in pr.hit_ids
			if not pr.dead and not z.dead and not already_hit and z.row == pr.row and projectile_can_hit_zombie(z,bool(pr.get("hits_prone",false))) and absf(z.x - pr.x) < 25.0:
				damage_zombie(z,pr.damage)
				if pr.snow and not z.dead: z.slow = 3.0
				if pr.get("piercing",false):
					pr.hit_ids.append(int(z.get("id",-1)))
					if pr.hit_ids.size() >= int(pr.get("max_hits",3)):
						pr.dead = true
				else:
					pr.dead = true
				burst(Vector2(pr.x, pr.y), Color("#8ce8f0") if pr.snow else Color("#65f0a0") if pr.get("energy",false) else Color("#9bea55"), 7 if pr.get("energy",false) else 5)
				play_sfx(390.0 if pr.snow else 310.0, 0.045, 0.08, "square")

func update_basket_attack(z: Dictionary, delta: float, rooted: bool) -> bool:
	var phase := int(z.get("throw_phase",0))
	if phase==3: return false
	if rooted:
		# 定身中止尚未出手的蓄力，恢复后必须重新准备。
		if phase==1: z.throw_phase = 0
		return false
	if phase==0:
		var target = null
		for p in plants:
			var distance: float = z.x-cell_center(p.col,p.row).x
			if not p.dead and absi(int(p.row)-int(z.row))<=1 and distance>=0 and distance<=CELL_W*3.0:
				if target==null or p.col>target.col: target = p
		if target==null: return false
		z.throw_col = target.col
		z.throw_row = target.row
		z.throw_phase = 1
		z.throw_time = 0.0
		z.walking = false
		z.biting = false
		return true
	z.walking = false
	z.biting = false
	z.throw_time += delta
	if phase==1 and z.throw_time>=1.2:
		var start := basket_ball_position(z,zombie_display_position(z),1.0)
		var target_row := int(z.get("throw_row",z.row))
		var finish := cell_center(z.throw_col,target_row)
		projectiles.append({"basketball":true,"row":target_row,"col":z.throw_col,"x":start.x,"y":start.y,
			"start":start,"finish":finish,"elapsed":0.0,"duration":0.8,"dead":false})
		z.throw_phase = 2
		z.throw_time = 0.0
		z.speed = 15.0
	elif phase==2 and z.throw_time>=0.35:
		z.throw_phase = 3
	return true

func update_zombies(delta: float) -> void:
	for z in zombies.duplicate():
		if z.dead: continue
		z.anim += delta
		if z.kind=="imp" and z.get("airborne",false):
			WildlandRules.update_flying_imp(self,z,delta)
			continue
		z.slow = maxf(0.0, z.slow - delta)
		z.draw_row = move_toward(float(z.get("draw_row",z.row)),float(z.row),delta*3.2)
		if z.kind=="glider" and zombie_is_airborne(z):
			z.rooted = false
			z.biting = false
			z.walking = false
			var glide_slow_factor := 0.5 if z.slow>0.0 else 1.0
			z.x -= z.speed*glide_slow_factor*delta*sand_speed_multiplier()
			if z.x<=float(z.landing_x):
				z.x = float(z.landing_x)
				z.airborne = false
				z.speed = float(z.ground_speed)
				z.walking = true
				burst(Vector2(z.x,BOARD_Y+z.row*CELL_H+CELL_H/2.0),Color("#8cae93"),10)
				play_sfx(155.0,0.16,0.16,"noise")
			continue
		var rooted: bool = bool(z.get("rooted",false)) and z.kind!="kart"
		if z.kind=="giant" and WildlandRules.update_giant(self,z,delta,rooted): continue
		if z.kind=="basket" and update_basket_attack(z,delta,rooted):
			continue
		if z.kind=="kart":
			z.rooted = false
		if z.kind=="swing" and not rooted:
			z.swing_clock -= delta
			if z.swing_clock <= 0.0:
				var previous_row: int = z.row
				var adjacent_rows: Array[int] = []
				if z.row>0: adjacent_rows.append(z.row-1)
				if z.row<ROWS-1: adjacent_rows.append(z.row+1)
				z.row = adjacent_rows[rng.randi_range(0,adjacent_rows.size()-1)]
				z.swing_clock = rng.randf_range(4.5,7.0)
				burst(Vector2(z.x,BOARD_Y+z.row*CELL_H+CELL_H/2.0),Color("#c77bd2"),7)
				if z.row<previous_row:
					play_sfx(560.0,0.16,0.18,"sweep_up")
				else:
					play_sfx(720.0,0.16,0.18,"sweep_down")
		var arm_loss_hp := 180.0 if z.kind=="camo" else 100.0
		if z.kind not in ["kart","imp","giant"] and z.hp <= arm_loss_hp and not z.get("arm_lost", false):
			z.arm_lost = true
			var arm_y_offset := 20.0 if z.kind=="camo" else -18.0
			detached_arms.append({"pos":Vector2(z.x + 13.0, BOARD_Y + z.row * CELL_H + CELL_H/2.0 - ZOMBIE_BOARD_LIFT + arm_y_offset),
				"vel":Vector2(34.0,-48.0),"angle":0.0,"spin":4.8,"life":1.35,"slow":z.slow > 0.0,"kind":z.kind})
		if z.kind=="kart":
			var crushed = plant_at_zombie(z)
			if crushed != null:
				crushed.dead = true
				burst(Vector2(z.x,BOARD_Y+z.row*CELL_H+CELL_H/2.0),Color("#d39a55"),9)
				play_sfx(105.0,0.13,0.16,"noise")
			z.biting = false
			z.walking = not rooted
			var kart_slow_factor := 0.5 if z.slow>0.0 else 1.0
			if not rooted:
				z.x -= z.speed*kart_slow_factor*delta*sand_speed_multiplier()
			if z.x < 115.0: game_state = "lose"
			continue
		# 定身会立刻中断啃咬；目标切换后也不能沿用上一帧的攻击状态。
		var target = null if rooted else plant_at_zombie(z)
		z.biting = target != null
		z.walking = target == null and not rooted
		if target != null:
			target.hp -= ZOMBIE_DPS * delta
			z.attack -= delta
			if z.attack <= 0.0:
				z.attack = 0.7
				burst(cell_center(target.col,target.row), Color("#cfa46e"), 3)
			if target.hp <= 0.0: target.dead = true
		elif not rooted:
			var slow_factor := 0.5 if z.slow > 0.0 else 1.0
			z.x -= z.speed * slow_factor * delta*sand_speed_multiplier()
		if z.x < 115.0:
			game_state = "lose"

func update_zombie_armor(z: Dictionary) -> void:
	if z.kind not in ["cone","bucket","charger","copper"] or z.get("armor_lost",false) or z.hp > 190.0:
		return
	z.armor_lost = true
	var drop_y: float = BOARD_Y + float(z.row) * CELL_H + CELL_H/2.0 - ZOMBIE_BOARD_LIFT - 78.0
	dropped_armor.append({"kind":z.kind,"pos":Vector2(z.x-5.0,drop_y),
		"vel":Vector2(rng.randf_range(-52.0,32.0),-92.0),"angle":0.0,
		"spin":rng.randf_range(-5.5,5.5),"life":1.45})
	var armor_burst_color := Color("#e9a34e") if z.kind=="cone" else Color("#c77a45") if z.kind=="copper" else Color("#aab4b6")
	burst(Vector2(z.x,drop_y),armor_burst_color,7)
	play_sfx(185.0 if z.kind=="cone" else 96.0 if z.kind=="copper" else 110.0 if z.kind=="charger" else 125.0,0.11,0.12,"square")

func plant_at_zombie(z: Dictionary):
	if zombie_is_airborne(z):
		return null
	for shell in plants:
		if not shell.dead and shell.kind=="pumpkin" and shell.row==z.row and absf(z.x-cell_center(shell.col,shell.row).x)<54.0:
			return shell
	for p in plants:
		if not p.dead and p.row == z.row:
			# 樱桃炸弹从放下到引爆始终无敌，也不作为啃咬或车辆碾压目标；
			# 它只会在 explode_cherry() 完成伤害结算后自行消失。
			if p.kind in ["cherry","bbq_mushroom"]:
				continue
			# 倭瓜一旦锁定目标就进入不可伤害的攻击过程；跳起中的倭瓜也不再
			# 作为啃咬或车辆碾压的阻挡物。
			if p.kind=="squash" and int(p.get("squash_phase",0))>0:
				continue
			var px := cell_center(p.col,p.row).x
			if z.x > px-30.0 and z.x < px+42.0:
				return p
	for minion in yam_minions:
		if not minion.dead and minion.row == z.row:
			var minion_x := cell_center(minion.col,minion.row).x
			if z.x > minion_x-30.0 and z.x < minion_x+42.0:
				return minion
	return null

func release_imp(z: Dictionary) -> void:
	z.kind = "imp"
	z.hp = 190.0
	z.max_hp = 190.0
	z.speed = 25.0
	z.slow = 0.0
	z.attack = 0.0
	z.biting = false
	z.walking = true
	z.rooted = false
	z.arm_lost = false
	z.armor_lost = false
	burst(Vector2(z.x,BOARD_Y+z.row*CELL_H+CELL_H/2.0),Color("#d95f49"),12)
	play_sfx(170.0,0.12,0.14,"square")

func damage_zombie(z: Dictionary, amount: float) -> void:
	if z.dead or amount <= 0.0:
		return
	var remaining := amount
	if z.kind=="kart":
		if remaining < z.hp:
			z.hp -= remaining
			return
		remaining -= z.hp
		release_imp(z)
		if remaining <= 0.0:
			return
	z.hp -= remaining
	update_zombie_armor(z)
	if z.hp <= 0.0:
		kill_zombie(z)

func kill_zombie(z: Dictionary) -> void:
	if z.dead: return
	if z.kind=="kart":
		release_imp(z)
		return
	update_zombie_armor(z)
	z.dead = true
	try_drop_coin(Vector2(z.x,BOARD_Y+z.row*CELL_H+CELL_H/2.0-35.0))
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

func try_drop_coin(pos: Vector2) -> void:
	var kind := coin_kind_for_roll(rng.randf())
	if kind!="": spawn_coin(pos,kind)

func coin_kind_for_roll(roll: float) -> String:
	if roll<0.02: return "gold"
	if roll<0.10: return "silver"
	return ""

func spawn_coin(pos: Vector2, kind: String) -> void:
	coins.append({"pos":pos,"target_y":minf(660.0,pos.y+rng.randf_range(25.0,55.0)),
		"vel":Vector2(rng.randf_range(-24.0,24.0),-115.0),"kind":kind,
		"value":100 if kind=="gold" else 10,"life":14.0,"pulse":rng.randf_range(0.0,2.0),"dead":false})

func update_coins(delta: float) -> void:
	for coin in coins:
		if coin.dead: continue
		coin.life -= delta
		coin.pulse += delta
		if coin.vel.y!=0.0 or coin.pos.y<float(coin.target_y)-0.5:
			coin.pos += coin.vel*delta
			coin.vel.y += 420.0*delta
			if coin.pos.y>=float(coin.target_y) and coin.vel.y>0.0:
				coin.pos.y = coin.target_y
				coin.vel = Vector2.ZERO
		if auto_collect_sun and coin.pulse>0.8 and coin.vel==Vector2.ZERO and absf(coin.pos.y-float(coin.target_y))<1.0:
			collect_coin(coin)
		if coin.life<=0.0: coin.dead = true

func collect_coin(coin: Dictionary) -> void:
	if coin.dead: return
	coin.dead = true
	money += int(coin.value)
	level_money_earned += int(coin.value)
	burst(Vector2(coin.pos),Color("#ffe071") if coin.kind=="gold" else Color("#dce7e5"),7)
	play_sfx(1040.0 if coin.kind=="gold" else 820.0,0.10,0.13,"sine")
	save_game()

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
	for i in range(coins.size()-1,-1,-1):
		if coins[i].dead: coins.remove_at(i)
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
	var stream := AudioSynth.create_sfx(frequency, duration, strength, wave, rng)
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
		[96.0, 0.11, 0.12, "square"],
		[125.0, 0.11, 0.12, "square"], [145.0, 0.12, 0.11, "square"],
		[880.0, 0.11, 0.14, "sine"], [92.0, 0.45, 0.3, "noise"],
		[740.0, 0.28, 0.22, "sine"],
		[560.0, 0.16, 0.18, "sweep_up"], [720.0, 0.16, 0.18, "sweep_down"],
		[1040.0,0.10,0.13,"sine"], [820.0,0.10,0.13,"sine"],
		[920.0,0.14,0.16,"sine"], [760.0,0.12,0.14,"sine"]
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
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	update_music_volume()
	switch_music("menu")
	# 两首关卡音乐在后台预先合成。玩家进入选关和选卡期间不会因首次
	# 生成几十秒的波形而卡住主线程。
	music_prewarm_thread = Thread.new()
	music_prewarm_thread.start(build_level_music_cache)

func build_level_music_cache() -> Dictionary:
	return {
		"frontyard":AudioSynth.create_music("frontyard"),
		"wasteland":AudioSynth.create_music("wasteland"),
		"wildland":AudioSynth.create_music("wildland")
	}

func collect_music_prewarm(wait_for_completion := false) -> void:
	if music_prewarm_thread==null:
		return
	if music_prewarm_thread.is_alive() and not wait_for_completion:
		return
	var generated: Dictionary = music_prewarm_thread.wait_to_finish()
	for track in generated:
		music_cache[track] = generated[track]
	music_prewarm_thread = null

func desired_music_track() -> String:
	if game_state in ["prepare","play","win","lose"]:
		if is_wildland_level(): return "wildland"
		return "wasteland" if is_wasteland_level() else "frontyard"
	return "menu"

func update_music_context() -> void:
	collect_music_prewarm()
	var desired := desired_music_track()
	if desired!=current_music_track:
		switch_music(desired)

func switch_music(track: String) -> void:
	if music_player==null or track==current_music_track:
		return
	if not music_cache.has(track):
		# 后台尚未完成时先延续当前音乐，下一帧会再次检查并自动切换。
		if music_prewarm_thread!=null and music_prewarm_thread.is_alive():
			return
		collect_music_prewarm()
	if not music_cache.has(track):
		music_cache[track] = AudioSynth.create_music(track)
	music_player.stop()
	music_player.stream = music_cache[track]
	current_music_track = track
	update_music_volume()
	music_player.play()

func update_music_volume() -> void:
	if music_player:
		music_player.volume_db = linear_to_db(maxf(music_volume, 0.0001))

func load_settings() -> void:
	var loaded := Persistence.load_settings(SETTINGS_PATH, {
		"music_volume":music_volume, "sfx_volume":sfx_volume, "auto_collect_sun":auto_collect_sun,
		"show_health_bars":show_health_bars, "game_speed":game_speed,
		"fullscreen_enabled":fullscreen_enabled, "unlocked_level":unlocked_level
	}, plant_keys, shovel_key, LEVEL_DATA.size())
	music_volume = loaded.music_volume
	sfx_volume = loaded.sfx_volume
	auto_collect_sun = loaded.auto_collect_sun
	show_health_bars = loaded.show_health_bars
	game_speed = loaded.game_speed
	fullscreen_enabled = loaded.fullscreen_enabled
	unlocked_level = loaded.unlocked_level
	plant_keys = loaded.plant_keys
	shovel_key = loaded.shovel_key
	# A、S现在固定给关卡道具；兼容旧存档中可能存在的自定义冲突绑定。
	var fallback_keys := [KEY_1,KEY_2,KEY_3,KEY_4,KEY_Q,KEY_W,KEY_E,KEY_R]
	for i in plant_keys.size():
		if plant_keys[i] in [KEY_A,KEY_S]:
			for fallback in fallback_keys:
				if fallback not in plant_keys and fallback!=shovel_key:
					plant_keys[i] = fallback
					break
	if shovel_key in [KEY_A,KEY_S]: shovel_key = KEY_D

func save_settings() -> void:
	Persistence.save_settings(SETTINGS_PATH, {
		"music_volume":music_volume, "sfx_volume":sfx_volume, "auto_collect_sun":auto_collect_sun,
		"show_health_bars":show_health_bars, "game_speed":game_speed,
		"fullscreen_enabled":fullscreen_enabled, "plant_keys":plant_keys, "shovel_key":shovel_key
	})

func load_save_game() -> void:
	var loaded := Persistence.load_campaign(SAVE_PATH, {
		"unlocked_level":unlocked_level, "high_score":high_score,
		"campaign_completed":campaign_completed,"money":money,
		"item_inventory":item_inventory,"claimed_money_bags":claimed_money_bags,
		"sun_shovel_level":sun_shovel_level,"starting_sun_level":starting_sun_level
	}, LEVEL_DATA)
	unlocked_level = loaded.unlocked_level
	high_score = loaded.high_score
	campaign_completed = loaded.campaign_completed
	saved_loadouts = loaded.saved_loadouts
	money = loaded.money
	item_inventory = loaded.item_inventory
	claimed_money_bags = loaded.claimed_money_bags
	sun_shovel_level = loaded.sun_shovel_level
	starting_sun_level = int(loaded.get("starting_sun_level",0))

func save_game() -> void:
	Persistence.save_campaign(SAVE_PATH, {
		"unlocked_level":unlocked_level, "high_score":high_score,
		"campaign_completed":campaign_completed, "saved_loadouts":saved_loadouts,
		"money":money,"item_inventory":item_inventory,"claimed_money_bags":claimed_money_bags,
		"sun_shovel_level":sun_shovel_level,"starting_sun_level":starting_sun_level
	}, LEVEL_DATA.size())

func apply_saved_display_mode() -> void:
	if fullscreen_enabled and not Engine.is_embedded_in_editor() and DisplayServer.get_name() != "headless":
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func _exit_tree() -> void:
	collect_music_prewarm(true)
	if not Engine.is_embedded_in_editor() and DisplayServer.get_name() != "headless":
		var mode := get_window().mode
		fullscreen_enabled = mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	save_settings()
	save_game()

func assign_key(target: int, new_key: int) -> void:
	if new_key == 0:
		return
	if new_key in [KEY_A,KEY_S]:
		show_message("A 和 S 已用于关卡道具",1.5)
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

func activate_item(kind: String) -> void:
	if int(item_inventory.get(kind,0))<=0:
		show_message("没有%s"%ITEM_DATA[kind].name,1.2)
		return
	if kind=="air_bomb":
		selected = "" if selected=="item_air_bomb" else "item_air_bomb"
		play_sfx(510.0,0.07,0.10,"square")
	else:
		item_inventory.sun_pack -= 1
		sun_points += 500
		selected = ""
		show_message("阳光 +500",1.3)
		burst(Vector2(570,105),Color("#ffe56b"),14)
		play_sfx(920.0,0.14,0.16,"sine")
		save_game()

func use_air_bomb(col: int,row: int) -> void:
	if int(item_inventory.air_bomb)<=0:
		selected = ""
		return
	item_inventory.air_bomb -= 1
	var center := cell_center(col,row)
	for z in zombies:
		if not z.dead and absi(int(z.row)-row)<=1 and absf(z.x-center.x)<155.0:
			damage_zombie(z,PLANT_DATA.cherry.damage)
	for i in 34:
		var angle := rng.randf_range(0.0,TAU)
		particles.append({"pos":center,"vel":Vector2(cos(angle),sin(angle))*rng.randf_range(70.0,235.0),
			"life":rng.randf_range(0.35,0.8),"max":0.8,"color":Color("#ffb23e"),"size":rng.randf_range(4.0,12.0)})
	shake = 1.0
	flash = 0.7
	selected = ""
	show_message("空投炸弹！",1.0)
	play_sfx(105.0,0.36,0.42,"noise")
	save_game()

func purchase_item(kind: String) -> void:
	var data: Dictionary = ITEM_DATA[kind]
	var owned := int(item_inventory.get(kind,0))
	if owned>=int(data.max_owned):
		show_message("已达到持有上限",1.3)
		return
	if money<int(data.price):
		show_message("资金不足",1.3)
		return
	money -= int(data.price)
	item_inventory[kind] = owned+1
	show_message("已购买%s"%data.name,1.3)
	play_sfx(760.0,0.12,0.14,"sine")
	save_game()

func purchase_sun_shovel() -> void:
	if unlocked_level<GameData.SUN_SHOVEL_UNLOCK_LEVEL and not campaign_completed:
		show_message("完成荒地-第14关后解锁",1.4)
		return
	if sun_shovel_level>=2:
		show_message("阳光铲已升满",1.3)
		return
	var price: int = GameData.SUN_SHOVEL_PRICES[sun_shovel_level]
	if money<price:
		show_message("资金不足",1.3)
		return
	money -= price
	sun_shovel_level += 1
	show_message("阳光铲升级：返还%d%%"%roundi(GameData.SUN_SHOVEL_RATES[sun_shovel_level]*100.0),1.5)
	play_sfx(920.0,0.14,0.16,"sine")
	save_game()

func purchase_starting_sun() -> void:
	if unlocked_level<GameData.STARTING_SUN_UNLOCK_LEVEL:
		show_message("完成荒地-第20关后解锁",1.4)
		return
	if starting_sun_level>=2:
		show_message("新增初始阳光已升满",1.3)
		return
	var price: int = GameData.STARTING_SUN_PRICES[starting_sun_level]
	if money<price:
		show_message("资金不足",1.3)
		return
	money -= price
	starting_sun_level += 1
	show_message("初始阳光永久增加至%d"%(150+starting_sun_level*100),1.5)
	play_sfx(920.0,0.14,0.16,"sine")
	save_game()

func shovel_refund_for(kind: String) -> int:
	if kind not in PLANT_DATA:
		return 0
	return floori(float(PLANT_DATA[kind].cost)*float(GameData.SUN_SHOVEL_RATES[sun_shovel_level]))

func remove_plant_with_shovel(plant: Dictionary) -> void:
	var refund := shovel_refund_for(String(plant.kind))
	plant.dead = true
	if refund>0:
		sun_points += refund
		show_message("阳光返还 +%d"%refund,1.2)
	burst(cell_center(plant.col,plant.row),Color("#d7a66e"),8)

func show_message(text: String, duration: float) -> void:
	message = text
	message_time = duration

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var pressed_key := int(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
		if (paused or game_state=="settings") and pause_page == "keys" and binding_target != -99:
			if event.keycode == KEY_ESCAPE:
				binding_target = -99
			else:
				assign_key(binding_target, pressed_key)
			queue_redraw()
			return
		if game_state == "play" and not paused:
			if pressed_key==KEY_A:
				activate_item("air_bomb")
				queue_redraw()
				return
			if pressed_key==KEY_S:
				activate_item("sun_pack")
				queue_redraw()
				return
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
			if game_state=="settings" and pause_page=="keys": pause_page = "more"
			elif game_state=="settings" and pause_page=="more": pause_page = "main"
			elif game_state=="settings": game_state = "title"
			elif game_state == "prepare": game_state = "title"
			elif game_state == "level_select": game_state = "title"
			elif game_state == "almanac": game_state = "title"
			elif game_state == "shop": game_state = "title"
			elif game_state == "play" and paused and pause_page == "keys": pause_page = "more"
			elif game_state == "play" and paused and pause_page == "more": pause_page = "main"
			elif game_state == "play" and paused: paused = false
			elif selected != "": selected = ""
			elif game_state == "play": paused = not paused
	if event is InputEventMouseMotion:
		update_hover(event.position)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			if game_state == "prepare" and Rect2(174,96,572,450).has_point(event.position):
				scroll_prepare_pool(-1)
			elif game_state == "level_select":
				scroll_level_select(-1)
			elif game_state == "almanac" and Rect2(50,150,540,450).has_point(event.position):
				scroll_almanac(-1)
			queue_redraw()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			if game_state == "prepare" and Rect2(174,96,572,450).has_point(event.position):
				scroll_prepare_pool(1)
			elif game_state == "level_select":
				scroll_level_select(1)
			elif game_state == "almanac" and Rect2(50,150,540,450).has_point(event.position):
				scroll_almanac(1)
			queue_redraw()
			return
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
		if Rect2(175,480,200,72).has_point(pos):
			game_state = "level_select"
			level_select_offset = clampi(unlocked_level-LEVEL_SELECT_VISIBLE_COUNT,0,level_select_max_offset())
			play_sfx(610.0,0.1,0.1,"square")
		elif Rect2(395,480,200,72).has_point(pos):
			game_state = "almanac"
			almanac_tab = "plants"
			almanac_selected = 0
			almanac_row_offset = 0
			play_sfx(610.0, 0.1, 0.1, "square")
		elif Rect2(615,480,200,72).has_point(pos):
			if unlocked_level>=4:
				game_state = "shop"
				play_sfx(610.0,0.1,0.1,"square")
		elif Rect2(835,480,200,72).has_point(pos):
			game_state = "settings"
			pause_page = "main"
			binding_target = -99
			play_sfx(610.0,0.1,0.1,"square")
		return
	if game_state == "settings":
		handle_pause_click(pos)
		return
	if game_state == "shop":
		if Rect2(50,635,190,58).has_point(pos):
			game_state = "title"
			return
		var shop_kinds := ["air_bomb","sun_pack","sun_shovel","starting_sun"]
		for i in shop_kinds.size():
			if shop_buy_rect(i).has_point(pos):
				if shop_kinds[i]=="sun_shovel": purchase_sun_shovel()
				elif shop_kinds[i]=="starting_sun": purchase_starting_sun()
				else: purchase_item(shop_kinds[i])
				return
		return
	if game_state == "level_select":
		if Rect2(50,635,190,58).has_point(pos):
			game_state = "title"
			return
		if Rect2(1040,635,70,58).has_point(pos):
			scroll_level_select(-1)
			return
		if Rect2(1125,635,70,58).has_point(pos):
			scroll_level_select(1)
			return
		for i in LEVEL_DATA.size():
			if i >= level_select_offset and i < level_select_offset+LEVEL_SELECT_VISIBLE_COUNT and level_select_rect(i).has_point(pos) and i+1 <= unlocked_level:
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
		if Rect2(300,500,320,68).has_point(pos):
			if game_state == "lose": prepare_level(current_level)
			elif current_level < LEVEL_DATA.size(): prepare_level(current_level + 1)
			else: prepare_level(current_level)
		elif Rect2(660,500,320,68).has_point(pos):
			game_state = "title"
		return
	if Rect2(1165,14,100,62).has_point(pos):
		paused = not paused
		if paused: pause_page = "main"
		play_sfx(480.0, 0.06, 0.08, "square")
		return
	if paused:
		handle_pause_click(pos)
		return
	for coin in coins:
		if not coin.dead and Vector2(coin.pos).distance_to(pos)<30.0:
			collect_coin(coin)
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
	for i in 2:
		if item_rect(i).has_point(pos):
			activate_item("air_bomb" if i==0 else "sun_pack")
			return
	if hover_cell.x >= 0:
		if selected=="item_air_bomb":
			use_air_bomb(hover_cell.x,hover_cell.y)
			return
		var existing = get_plant(hover_cell.x, hover_cell.y)
		if selected == "shovel":
			var old = get_pumpkin(hover_cell.x,hover_cell.y)
			if old==null: old = existing
			if old != null:
				remove_plant_with_shovel(old)
			selected = ""
		elif selected=="pumpkin":
			if is_plantable_cell(hover_cell.y) and get_pumpkin(hover_cell.x,hover_cell.y)==null:
				place_plant("pumpkin",hover_cell.x,hover_cell.y)
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

func handle_prepare_click(pos: Vector2) -> void:
	if prepare_camera_x < 500.0 or prepare_returning:
		return
	if Rect2(280,575,170,55).has_point(pos):
		game_state = "title"
		return
	if not has_fixed_loadout() and Rect2(674,105,27,31).has_point(pos):
		scroll_prepare_pool(-1)
		return
	if not has_fixed_loadout() and Rect2(704,105,27,31).has_point(pos):
		scroll_prepare_pool(1)
		return
	if not has_fixed_loadout():
		for i in equipped_plants.size():
			if card_rect(i).has_point(pos):
				equipped_plants.remove_at(i)
				play_sfx(430.0, 0.06, 0.07, "square")
				return
		for i in available_plants.size():
			var logical_row := int(i/PREPARE_POOL_COLUMNS)
			if logical_row >= prepare_pool_row_offset and logical_row < prepare_pool_row_offset+PREPARE_POOL_VISIBLE_ROWS and prepare_card_rect(i).has_point(pos):
				var kind: String = available_plants[i]
				if is_plant_locked(kind):
					show_message("该植物在本关被锁定",1.5)
					play_sfx(145.0,0.07,0.07,"square")
					return
				var selected_index := equipped_plants.find(kind)
				if selected_index >= 0:
					equipped_plants.remove_at(selected_index)
				elif equipped_plants.size() < 8:
					equipped_plants.append(kind)
				play_sfx(570.0, 0.06, 0.07, "square")
				return
	if Rect2(470,575,170,55).has_point(pos):
		if equipped_plants.is_empty():
			show_message("请至少选择一种植物", 1.5)
			return
		if not has_fixed_loadout():
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
		almanac_row_offset = 0
		play_sfx(570.0, 0.07, 0.08, "square")
		return
	if Rect2(655, 88, 205, 52).has_point(pos):
		almanac_tab = "zombies"
		almanac_selected = 0
		almanac_row_offset = 0
		play_sfx(390.0, 0.07, 0.08, "square")
		return
	if Rect2(552,165,32,36).has_point(pos):
		scroll_almanac(-1)
		return
	if Rect2(552,556,32,36).has_point(pos):
		scroll_almanac(1)
		return
	var count := PLANT_DATA.size() if almanac_tab == "plants" else ZOMBIE_INFO.size()
	for i in count:
		var logical_row := int(i/ALMANAC_COLUMNS)
		if logical_row >= almanac_row_offset and logical_row < almanac_row_offset+ALMANAC_VISIBLE_ROWS and almanac_item_rect(i).has_point(pos):
			almanac_selected = i
			play_sfx(520.0 + i * 25.0, 0.06, 0.07, "square")
			return

func place_plant(kind: String, col: int, row: int) -> void:
	if not is_plantable_cell(row): return
	if (get_pumpkin(col,row) if kind=="pumpkin" else get_plant(col,row))!=null: return
	var data: Dictionary = PLANT_DATA[kind]
	sun_points -= data.cost
	cooldowns[kind] = data.cool
	var first_timer: float = 4.0 if kind == "sunflower" else (data.interval if kind in ["cherry","bbq_mushroom"] else (data.arm_time if kind == "mine" else 0.15))
	plants.append({"kind":kind,"col":col,"row":row,"hp":data.hp,"max_hp":data.hp,
		"timer":first_timer,"anim":rng.randf_range(0,2),"armed":false,"dead":false,
		"deploy_dir":-1,"respawn_timer":0.6,"minion_active":false,"slime_target_id":-1,
		"squash_phase":0,"squash_clock":0.0,"squash_target_id":-1,"squash_target_x":cell_center(col,row).x})
	burst(cell_center(col,row),data.color,8)
	play_sfx(220.0, 0.09, 0.1, "square")
	selected = ""

func handle_pause_click(pos: Vector2) -> void:
	var standalone := game_state=="settings"
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
	if not standalone and Rect2(360, 376, 150, 106).has_point(pos):
		paused = false
		game_state = "title"
		selected = ""
		return
	if Rect2(565, 376, 150, 106).has_point(pos):
		pause_page = "more"
		play_sfx(520.0, 0.1, 0.1, "square")
		return
	if not standalone and Rect2(770, 376, 150, 106).has_point(pos):
		prepare_level(current_level)
		play_sfx(700.0, 0.11, 0.1, "square")
		return
	if Rect2(350, 520, 580, 70).has_point(pos):
		if standalone:
			game_state = "title"
		else:
			paused = false
		play_sfx(540.0, 0.08, 0.08, "square")
		return
