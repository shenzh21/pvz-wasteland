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
		# 荒地第14关起显著抬高后续大波组预算；此前关卡维持原难度。
		# 第二组为普通小波 +4、大波 +10；第三组及以后为 +10/+25。
		if group_index == 1:
			budget += (10 if local_wave == 9 else 4) if level>=17 else (5 if local_wave == 9 else 2)
		elif group_index >= 2:
			budget += (25 if local_wave == 9 else 10) if level>=17 else (15 if local_wave == 9 else 6)
		while budget > 0:
			var kind := choose_zombie_type(level, wave_index, total, budget, rng)
			wave.append(kind)
			budget -= int(GameData.ZOMBIE_POINTS[kind])
		plan.append(wave)
	return plan

static func choose_zombie_type(level: int, wave_index: int, total_waves: int, max_points: int, rng: RandomNumberGenerator) -> String:
	if level==26:
		var forced: String = {3:"bucket",4:"runner",6:"kart",7:"charger",9:"giant"}.get(wave_index%10,"")
		if forced!="" and GameData.ZOMBIE_POINTS[forced]<=max_points: return forced
		for attempt in range(8):
			var roll := rng.randf()
			var kind := "giant" if wave_index>=9 and roll<0.10 else "charger" if wave_index>=6 and roll<0.26 else "kart" if wave_index>=6 and roll<0.42 else "runner" if wave_index>=3 and roll<0.61 else "bucket" if roll<0.80 else "normal"
			if GameData.ZOMBIE_POINTS[kind]<=max_points: return kind
		return "normal"
	if level==25:
		var forced: String = {3:"cone",4:"camo",5:"glider",7:"copper"}.get(wave_index%10,"")
		if forced!="" and GameData.ZOMBIE_POINTS[forced]<=max_points: return forced
		for attempt in range(8):
			var roll := rng.randf()
			var kind := "copper" if wave_index>=6 and roll<0.16 else "glider" if wave_index>=4 and roll<0.34 else "camo" if wave_index>=3 and roll<0.53 else "cone" if roll<0.78 else "normal"
			if GameData.ZOMBIE_POINTS[kind]<=max_points: return kind
		return "normal"
	if level==24:
		if wave_index%10 in [7,9] and max_points>=GameData.ZOMBIE_POINTS.giant: return "giant"
		if wave_index%10==3 and max_points>=2: return "cone"
		var roll := rng.randf()
		if wave_index>=6 and max_points>=GameData.ZOMBIE_POINTS.giant and roll<0.25: return "giant"
		if max_points>=2 and roll<0.65: return "cone"
		return "normal"
	if level in [22,23]:
		var schedule := {3:"cone",4:"bucket",5:"camo",7:"kart",8:"basket"} if level==22 else {3:"bucket",4:"glider",6:"charger",7:"copper",8:"basket"}
		var forced: String = schedule.get(wave_index%10,"")
		if forced!="" and GameData.ZOMBIE_POINTS[forced]<=max_points: return forced
		for attempt in 8:
			var roll := rng.randf()
			var kind := "normal"
			if level==22:
				kind = "basket" if wave_index>=6 and roll<0.14 else "kart" if wave_index>=6 and roll<0.28 else "camo" if wave_index>=4 and roll<0.44 else "bucket" if wave_index>=3 and roll<0.62 else "cone" if roll<0.82 else "normal"
			else:
				kind = "basket" if wave_index>=6 and roll<0.14 else "copper" if wave_index>=6 and roll<0.28 else "charger" if wave_index>=6 and roll<0.42 else "glider" if wave_index>=4 and roll<0.60 else "bucket" if roll<0.80 else "normal"
			if GameData.ZOMBIE_POINTS[kind]<=max_points: return kind
		return "normal"
	if level==21:
		var forced: String = {3:"cone",4:"swing",7:"basket"}.get(wave_index%10,"")
		if forced!="" and GameData.ZOMBIE_POINTS[forced]<=max_points: return forced
		for attempt in 8:
			var roll := rng.randf()
			var kind := "basket" if wave_index>=6 and roll<0.24 else "swing" if wave_index>=3 and roll<0.48 else "cone" if roll<0.72 else "normal"
			if GameData.ZOMBIE_POINTS[kind]<=max_points: return kind
		return "normal"
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
	if level == 12:
		# 两个大波组都会出现军迷僵尸，并保证疾跑和路障不会被随机漏掉。
		var forced_kind: String = str({
			3:"camo", 6:"runner", 8:"cone",
			13:"camo", 16:"runner", 18:"cone"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 13:
		# 三个大波组都轮流安排本关的五种非普通敌人，保证完整阵容稳定登场。
		var forced_kind: String = str({
			3:"camo", 4:"cone", 5:"bucket", 7:"kart", 8:"charger",
			13:"camo", 14:"cone", 15:"bucket", 17:"kart", 18:"charger",
			23:"camo", 24:"cone", 25:"bucket", 27:"kart", 28:"charger"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 14:
		# 三组都明确安排军迷、摇摆和疾跑僵尸，其余指定敌人也不会被随机漏掉。
		var forced_kind: String = str({
			3:"camo", 4:"swing", 5:"bucket", 7:"runner", 8:"cone",
			13:"camo", 14:"swing", 15:"bucket", 17:"runner", 18:"cone",
			23:"camo", 24:"swing", 25:"bucket", 27:"runner", 28:"cone"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 15:
		# 两个大波组均安排新敌人，同时保证铁桶和疾跑不会被随机漏掉。
		var forced_kind: String = str({
			4:"glider", 7:"runner", 8:"bucket",
			14:"glider", 17:"runner", 18:"bucket"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 16:
		# 三个大波组都稳定展示路障、铁桶、滑翔伞和钢盔冲锋僵尸。
		var forced_kind: String = str({
			3:"cone", 4:"glider", 5:"bucket", 7:"charger",
			13:"cone", 14:"glider", 15:"bucket", 17:"charger",
			23:"cone", 24:"glider", 25:"bucket", 27:"charger"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 17:
		# 两个大波组都安排全部强化敌人，确保新铜头僵尸稳定出现。
		var forced_kind: String = str({
			3:"cone", 4:"bucket", 6:"charger", 7:"copper", 8:"runner",
			13:"cone", 14:"bucket", 16:"charger", 17:"copper", 18:"runner"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 18:
		# 三个大波组都覆盖本关五种强化敌人，避免高点数敌人被随机预算漏掉。
		var forced_kind: String = str({
			3:"cone", 4:"bucket", 6:"kart", 7:"copper", 8:"camo",
			13:"cone", 14:"bucket", 16:"kart", 17:"copper", 18:"camo",
			23:"cone", 24:"bucket", 26:"kart", 27:"copper", 28:"camo"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 19:
		# 每个大波组都覆盖本关六种特殊敌人；本关不生成路障和钢盔。
		var forced_kind: String = str({
			3:"bucket", 4:"runner", 5:"camo", 6:"kart", 7:"copper", 8:"glider",
			13:"bucket", 14:"runner", 15:"camo", 16:"kart", 17:"copper", 18:"glider",
			23:"bucket", 24:"runner", 25:"camo", 26:"kart", 27:"copper", 28:"glider"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
	if level == 20:
		# 三个大波组都覆盖摇摆、疾跑、军迷、滑翔伞、卡丁车和钢盔冲锋。
		var forced_kind: String = str({
			3:"swing", 4:"runner", 5:"camo", 6:"kart", 7:"charger", 8:"glider",
			13:"swing", 14:"runner", 15:"camo", 16:"kart", 17:"charger", 18:"glider",
			23:"swing", 24:"runner", 25:"camo", 26:"kart", 27:"charger", 28:"glider"
		}.get(wave_index,""))
		if forced_kind!="" and max_points>=int(GameData.ZOMBIE_POINTS[forced_kind]):
			return forced_kind
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
		elif level == 12:
			if progress>=0.22 and roll<0.22:
				candidate = "camo"
			elif progress>=0.16 and roll<0.43:
				candidate = "runner"
			elif roll<0.72:
				candidate = "cone"
		elif level == 13:
			if progress>=0.30 and roll<0.12:
				candidate = "charger"
			elif progress>=0.24 and roll<0.24:
				candidate = "kart"
			elif progress>=0.18 and roll<0.38:
				candidate = "camo"
			elif progress>=0.12 and roll<0.52:
				candidate = "bucket"
			elif roll<0.76:
				candidate = "cone"
		elif level == 14:
			if progress>=0.25 and roll<0.16:
				candidate = "camo"
			elif progress>=0.20 and roll<0.31:
				candidate = "runner"
			elif progress>=0.14 and roll<0.48:
				candidate = "swing"
			elif progress>=0.10 and roll<0.61:
				candidate = "bucket"
			elif roll<0.80:
				candidate = "cone"
		elif level == 15:
			if progress>=0.20 and roll<0.20:
				candidate = "glider"
			elif progress>=0.14 and roll<0.40:
				candidate = "runner"
			elif progress>=0.10 and roll<0.62:
				candidate = "bucket"
		elif level == 16:
			if progress>=0.24 and roll<0.17:
				candidate = "charger"
			elif progress>=0.18 and roll<0.35:
				candidate = "glider"
			elif progress>=0.12 and roll<0.55:
				candidate = "bucket"
			elif roll<0.78:
				candidate = "cone"
		elif level == 17:
			if progress>=0.30 and roll<0.10:
				candidate = "copper"
			elif progress>=0.24 and roll<0.24:
				candidate = "charger"
			elif progress>=0.18 and roll<0.39:
				candidate = "runner"
			elif progress>=0.12 and roll<0.57:
				candidate = "bucket"
			elif roll<0.80:
				candidate = "cone"
		elif level == 18:
			if progress>=0.28 and roll<0.11:
				candidate = "copper"
			elif progress>=0.22 and roll<0.26:
				candidate = "kart"
			elif progress>=0.16 and roll<0.42:
				candidate = "camo"
			elif progress>=0.10 and roll<0.59:
				candidate = "bucket"
			elif roll<0.81:
				candidate = "cone"
		elif level == 19:
			if progress>=0.26 and roll<0.12:
				candidate = "copper"
			elif progress>=0.22 and roll<0.25:
				candidate = "kart"
			elif progress>=0.18 and roll<0.39:
				candidate = "glider"
			elif progress>=0.14 and roll<0.54:
				candidate = "camo"
			elif progress>=0.10 and roll<0.70:
				candidate = "runner"
			elif roll<0.84:
				candidate = "bucket"
		elif level == 20:
			if progress>=0.25 and roll<0.12:
				candidate = "charger"
			elif progress>=0.21 and roll<0.25:
				candidate = "kart"
			elif progress>=0.17 and roll<0.38:
				candidate = "glider"
			elif progress>=0.13 and roll<0.51:
				candidate = "camo"
			elif progress>=0.10 and roll<0.64:
				candidate = "runner"
			elif roll<0.79:
				candidate = "swing"
		elif progress >= 0.55 and roll < 0.13:
			candidate = "bucket"
		elif progress >= 0.35 and roll > 0.83:
			candidate = "runner"
		elif progress >= 0.2 and roll < 0.42:
			candidate = "cone"
		if int(GameData.ZOMBIE_POINTS[candidate]) <= max_points:
			return candidate
	return "normal"
