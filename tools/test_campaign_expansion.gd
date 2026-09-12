extends SceneTree

const Persistence := preload("res://scripts/persistence.gd")
const Data := preload("res://scripts/game_data.gd")
const TEST_PATH := "user://campaign_expansion_test.cfg"

func _init() -> void:
	var defaults := {
		"unlocked_level":1,"high_score":0,"campaign_completed":false,
		"money":0,"item_inventory":{"air_bomb":0,"sun_pack":0},
		"sun_shovel_level":0,"claimed_money_bags":{},"saved_loadouts":{}
	}
	var last := Data.LEVEL_DATA.size()
	for case in [[21,true,22,false],[21,false,21,false],[22,false,22,false],[last,true,last,true]]:
		var original := defaults.duplicate(true)
		original.unlocked_level = case[0]
		original.campaign_completed = case[1]
		Persistence.save_campaign(TEST_PATH,original,last)
		var loaded := Persistence.load_campaign(TEST_PATH,defaults,Data.LEVEL_DATA)
		assert(loaded.unlocked_level==case[2],"新增关卡不能跳过尚未完成的关卡")
		assert(loaded.campaign_completed==case[3])
		# 连续重启不能继续自动解锁。
		var reloaded := Persistence.load_campaign(TEST_PATH,defaults,Data.LEVEL_DATA)
		assert(reloaded.unlocked_level==case[2] and reloaded.campaign_completed==case[3])
	DirAccess.remove_absolute(TEST_PATH)
	print("关卡扩展进度迁移验证通过")
	quit()
