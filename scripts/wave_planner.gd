class_name WavePlanner
extends RefCounted

const GameData := preload("res://scripts/game_data.gd")
const BASE_BUDGETS := [1, 1, 1, 3, 3, 3, 5, 5, 5, 15]

static func build(level: int, rng: RandomNumberGenerator) -> Array:
	var plan: Array = []
	var total: int = GameData.LEVEL_DATA[level].waves
	for wave_index in total:
		var wave: Array[String] = []
		var local_wave := wave_index % 10
		var group_index := int(wave_index / 10)
		var budget: int = BASE_BUDGETS[local_wave]
		# 第二组按普通小波 +2、大波 +5；第三组进一步提高到 +6/+15，
		# 不限制僵尸类型比例，让后半关在原有随机规则下形成更强的尸群。
		if group_index == 1:
			budget += 5 if local_wave == 9 else 2
		elif group_index >= 2:
			budget += 15 if local_wave == 9 else 6
		while budget > 0:
			var kind := choose_zombie_type(level, wave_index, total, budget, rng)
			wave.append(kind)
			budget -= int(GameData.ZOMBIE_POINTS[kind])
		plan.append(wave)
	return plan

static func choose_zombie_type(level: int, wave_index: int, total_waves: int, max_points: int, rng: RandomNumberGenerator) -> String:
	var progress := float(wave_index) / maxf(float(total_waves - 1), 1.0)
	# 荒地第二关明确展示完整阵容，避免随机结果恰好漏掉某个新敌人。
	if level == 5:
		if wave_index == 3 and max_points >= GameData.ZOMBIE_POINTS.cone:
			return "cone"
		if wave_index == 6 and max_points >= GameData.ZOMBIE_POINTS.runner:
			return "runner"
		if wave_index == 8 and max_points >= GameData.ZOMBIE_POINTS.bucket:
			return "bucket"
	if level == 6 and wave_index == 6 and max_points >= GameData.ZOMBIE_POINTS.kart:
		return "kart"
	if level == 7:
		if wave_index == 3 and max_points >= GameData.ZOMBIE_POINTS.swing:
			return "swing"
		if wave_index == 6 and max_points >= GameData.ZOMBIE_POINTS.runner:
			return "runner"
	if level == 8:
		# 两个大波组内都确保能看到卡丁车和摇摆僵尸。
		if wave_index % 10 == 4 and max_points >= GameData.ZOMBIE_POINTS.swing:
			return "swing"
		if wave_index % 10 == 7 and max_points >= GameData.ZOMBIE_POINTS.kart:
			return "kart"
	if level == 9:
		# 每个大波组都安排稀有敌人，整关必定覆盖六种非旗帜僵尸。
		var forced_kind: String = str({
			3:"cone", 5:"swing", 7:"runner", 8:"bucket",
			13:"kart", 15:"swing", 17:"runner", 18:"bucket",
			23:"kart", 25:"swing", 27:"runner", 28:"bucket"
		}.get(wave_index, ""))
		if forced_kind != "" and max_points >= int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 10:
		# 两个大波组都明确安排钢盔冲锋僵尸，其余指定敌人也至少出现一次。
		var forced_kind: String = str({
			3:"cone", 6:"runner", 8:"bucket", 9:"charger",
			13:"cone", 16:"runner", 18:"bucket", 19:"charger"
		}.get(wave_index, ""))
		if forced_kind != "" and max_points >= int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 11 and wave_index==3 and max_points>=GameData.ZOMBIE_POINTS.cone:
		return "cone"
	for attempt in 8:
		var roll := rng.randf()
		var candidate := "normal"
		if level == 1:
			candidate = "cone" if progress >= 0.33 and roll < 0.28 else "normal"
		elif level == 2:
			if progress >= 0.75 and roll < 0.06:
				candidate = "bucket"
			elif progress >= 0.25 and roll < 0.38:
				candidate = "cone"
		elif level == 4:
			candidate = "cone" if progress >= 0.2 and roll < 0.35 else "normal"
		elif level == 6:
			if progress >= 0.45 and roll < 0.25:
				candidate = "kart"
			elif progress >= 0.2 and roll < 0.52:
				candidate = "cone"
		elif level == 7:
			if progress >= 0.42 and roll < 0.22:
				candidate = "runner"
			elif progress >= 0.25 and roll < 0.48:
				candidate = "swing"
			elif progress >= 0.15 and roll < 0.68:
				candidate = "cone"
		elif level == 8:
			if progress >= 0.30 and roll < 0.20:
				candidate = "kart"
			elif progress >= 0.18 and roll < 0.47:
				candidate = "swing"
			elif progress >= 0.12 and roll < 0.70:
				candidate = "cone"
		elif level == 9:
			if progress >= 0.30 and roll < 0.12:
				candidate = "kart"
			elif progress >= 0.22 and roll < 0.25:
				candidate = "bucket"
			elif progress >= 0.16 and roll < 0.39:
				candidate = "runner"
			elif progress >= 0.10 and roll < 0.55:
				candidate = "swing"
			elif roll < 0.78:
				candidate = "cone"
		elif level == 10:
			if progress >= 0.32 and roll < 0.14:
				candidate = "charger"
			elif progress >= 0.24 and roll < 0.29:
				candidate = "bucket"
			elif progress >= 0.16 and roll < 0.45:
				candidate = "runner"
			elif roll < 0.72:
				candidate = "cone"
		elif level == 11:
			candidate = "cone" if progress>=0.2 and roll<0.42 else "normal"
		elif progress >= 0.55 and roll < 0.13:
			candidate = "bucket"
		elif progress >= 0.35 and roll > 0.83:
			candidate = "runner"
		elif progress >= 0.2 and roll < 0.42:
			candidate = "cone"
		if int(GameData.ZOMBIE_POINTS[candidate]) <= max_points:
			return candidate
	return "normal"
