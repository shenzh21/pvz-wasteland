extends SceneTree

const Synth := preload("res://scripts/audio_synth.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var track := Synth.create_music("wildland")
	assert(is_equal_approx(track.get_length(),74.24))
	assert(track.loop_mode==AudioStreamWAV.LOOP_FORWARD and track.loop_end==track.data.size()/2)
	assert(Synth.music_theme_data("wildland").melodies!=Synth.music_theme_data("wasteland").melodies)
	var peak := 0
	var samples := track.data
	for i in range(samples.size()/2):
		peak = maxi(peak,absi(samples.decode_s16(i*2)))
	assert(peak>1000 and peak<30000,"音乐必须有声且无削波")
	assert(absi(track.data.decode_s16(0)-track.data.decode_s16(track.data.size()-2))<100,"循环接缝应平滑")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.current_level = 24
	for state in ["prepare","play","win","lose"]:
		game.game_state = state
		assert(game.desired_music_track()=="wildland")
	game.game_state = "menu"
	assert(game.desired_music_track()=="menu")
	game.current_level = 23
	game.game_state = "play"
	assert(game.desired_music_track()=="wasteland")
	print("芜地独立音乐：74.24秒，循环及场景切换验证通过")
	quit()
