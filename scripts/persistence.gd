class_name Persistence
extends RefCounted

static func load_settings(path: String, defaults: Dictionary, default_plant_keys: Array, default_shovel_key: int, level_count: int) -> Dictionary:
	var result := defaults.duplicate(true)
	result.plant_keys = default_plant_keys.duplicate()
	result.shovel_key = default_shovel_key
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return result
	result.music_volume = clampf(float(config.get_value("audio", "music", result.music_volume)), 0.0, 1.0)
	result.sfx_volume = clampf(float(config.get_value("audio", "sfx", result.sfx_volume)), 0.0, 1.0)
	result.auto_collect_sun = bool(config.get_value("game", "auto_collect", result.auto_collect_sun))
	result.show_health_bars = bool(config.get_value("game", "show_health_bars", result.show_health_bars))
	result.game_speed = clampf(float(config.get_value("game", "speed", result.game_speed)), 0.5, 3.0)
	result.fullscreen_enabled = bool(config.get_value("display", "fullscreen", result.fullscreen_enabled))
	result.unlocked_level = clampi(int(config.get_value("progress", "unlocked_level", result.unlocked_level)), 1, level_count)
	for i in result.plant_keys.size():
		result.plant_keys[i] = int(config.get_value("keys", "plant_%d" % i, result.plant_keys[i]))
	result.shovel_key = int(config.get_value("keys", "shovel", result.shovel_key))
	return result

static func save_settings(path: String, state: Dictionary) -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", state.music_volume)
	config.set_value("audio", "sfx", state.sfx_volume)
	config.set_value("game", "auto_collect", state.auto_collect_sun)
	config.set_value("game", "show_health_bars", state.show_health_bars)
	config.set_value("game", "speed", state.game_speed)
	config.set_value("display", "fullscreen", state.fullscreen_enabled)
	for i in state.plant_keys.size():
		config.set_value("keys", "plant_%d" % i, state.plant_keys[i])
	config.set_value("keys", "shovel", state.shovel_key)
	config.save(path)

static func load_campaign(path: String, defaults: Dictionary, level_data: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	result.saved_loadouts = {}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return result
	result.unlocked_level = clampi(int(config.get_value("campaign", "unlocked_level", result.unlocked_level)), 1, level_data.size())
	result.high_score = maxi(0, int(config.get_value("campaign", "high_score", result.high_score)))
	result.campaign_completed = bool(config.get_value("campaign", "completed", result.campaign_completed))
	result.money = maxi(0,int(config.get_value("economy","money",result.money)))
	result.item_inventory = result.item_inventory.duplicate(true)
	result.item_inventory.air_bomb = clampi(int(config.get_value("items","air_bomb",result.item_inventory.air_bomb)),0,3)
	result.item_inventory.sun_pack = clampi(int(config.get_value("items","sun_pack",result.item_inventory.sun_pack)),0,99)
	result.sun_shovel_level = clampi(int(config.get_value("upgrades","sun_shovel",result.sun_shovel_level)),0,2)
	result.starting_sun_level = clampi(int(config.get_value("upgrades","starting_sun",0)),0,2)
	result.claimed_money_bags = {}
	for value in config.get_value("rewards","money_bags",[]):
		var level := int(value)
		if level>=1 and level<=level_data.size():
			result.claimed_money_bags[level] = true
	if result.campaign_completed and result.unlocked_level < level_data.size():
		# 旧版全通只意味着旧末关已完成；新增多关时只能开放紧接的一关。
		result.unlocked_level += 1
		result.campaign_completed = false
		config.set_value("campaign", "unlocked_level", result.unlocked_level)
		config.set_value("campaign", "completed", false)
		config.save(path)
	for level in range(1, level_data.size() + 1):
		var raw_loadout: Array = config.get_value("loadouts", "level_%d" % level, [])
		var valid_loadout: Array[String] = []
		for value in raw_loadout:
			var kind := String(value)
			if kind in level_data[level].plants and kind not in valid_loadout and valid_loadout.size() < 8:
				valid_loadout.append(kind)
		if not valid_loadout.is_empty():
			result.saved_loadouts[level] = valid_loadout
	return result

static func save_campaign(path: String, state: Dictionary, level_count: int) -> void:
	var config := ConfigFile.new()
	config.set_value("save", "version", 3)
	config.set_value("campaign", "unlocked_level", state.unlocked_level)
	config.set_value("campaign", "high_score", state.high_score)
	config.set_value("campaign", "completed", state.campaign_completed)
	config.set_value("economy","money",state.money)
	config.set_value("items","air_bomb",state.item_inventory.air_bomb)
	config.set_value("items","sun_pack",state.item_inventory.sun_pack)
	config.set_value("upgrades","sun_shovel",state.sun_shovel_level)
	config.set_value("upgrades","starting_sun",state.get("starting_sun_level",0))
	var claimed_levels: Array[int] = []
	for level in state.claimed_money_bags:
		if bool(state.claimed_money_bags[level]): claimed_levels.append(int(level))
	claimed_levels.sort()
	config.set_value("rewards","money_bags",claimed_levels)
	for level in range(1, level_count + 1):
		if state.saved_loadouts.has(level):
			config.set_value("loadouts", "level_%d" % level, state.saved_loadouts[level])
	config.save(path)
