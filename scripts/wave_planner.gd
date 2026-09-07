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
		budget += group_index * (3 if local_wave == 9 else 1)
		while budget > 0:
			var kind := choose_zombie_type(level, wave_index, total, budget, rng)
			wave.append(kind)
			budget -= int(GameData.ZOMBIE_POINTS[kind])
		plan.append(wave)
	return plan

static func choose_zombie_type(level: int, wave_index: int, total_waves: int, max_points: int, rng: RandomNumberGenerator) -> String:
	var progress := float(wave_index) / maxf(float(total_waves - 1), 1.0)
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
		elif progress >= 0.55 and roll < 0.13:
			candidate = "bucket"
		elif progress >= 0.35 and roll > 0.83:
			candidate = "runner"
		elif progress >= 0.2 and roll < 0.42:
			candidate = "cone"
		if int(GameData.ZOMBIE_POINTS[candidate]) <= max_points:
			return candidate
	return "normal"
