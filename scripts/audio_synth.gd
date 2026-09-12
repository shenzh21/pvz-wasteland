class_name AudioSynth
extends RefCounted

const SAMPLE_RATE := 22050
const MUSIC_SAMPLE_RATE := 11025

static func create_sfx(frequency: float, duration: float, strength: float, wave: String, rng: RandomNumberGenerator) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var time := float(i) / SAMPLE_RATE
		var progress := float(i) / sample_count
		# 换行提示使用方向明确的滑音；相位积分可避免频率变化时产生爆音。
		var sweep_ratio := 0.75 if wave=="sweep_up" else -0.55 if wave=="sweep_down" else 0.0
		var phase := (time*frequency+0.5*frequency*sweep_ratio/duration*time*time)*TAU if sweep_ratio!=0.0 else time*frequency*TAU
		var value := sin(phase)
		if sweep_ratio!=0.0:
			# 少量二次谐波让短音在较低音效音量下也更容易被听见。
			value = value*0.82+sin(phase*2.0)*0.18
		if wave == "square":
			value = 1.0 if value >= 0.0 else -1.0
		elif wave == "noise":
			value = rng.randf_range(-1.0, 1.0)
		var envelope := pow(1.0-progress,1.8)
		bytes.encode_s16(i * 2, int(value * envelope * strength * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

static func midi_frequency(note: int) -> float:
	return 440.0*pow(2.0,float(note-69)/12.0)

static func music_theme_data(theme: String) -> Dictionary:
	if theme=="wildland":
		# 32小节：风笛式短句、拨弦应答、低音鼓；四段发展后回到主题。
		return {
			"step":0.29,
			"chords":[[45,48,52],[45,48,52],[46,50,53],[45,49,52],[43,46,50],[41,45,48],[40,44,47],[45,48,52],
				[45,48,52],[48,52,55],[50,53,57],[46,50,53],[43,47,50],[46,50,53],[40,44,47],[40,44,47],
				[53,57,60],[52,55,59],[50,53,57],[48,52,55],[46,50,53],[45,48,52],[40,44,47],[45,48,52],
				[45,48,52],[46,50,53],[43,46,50],[45,48,52],[41,45,48],[46,50,53],[40,44,47],[45,48,52]],
			"melodies":[
				[69,-1,70,73,76,-1,73,-1,70,69,-1,64,65,-1,64,-1],
				[65,-1,69,70,73,-1,70,69,68,-1,64,-1,69,-1,-1,-1],
				[76,73,-1,76,77,76,73,-1,74,-1,77,76,74,-1,70,-1],
				[70,74,73,-1,70,69,-1,67,68,-1,71,76,73,-1,68,-1],
				[77,-1,81,-1,79,77,76,-1,74,-1,77,76,74,72,-1,69],
				[70,-1,74,73,70,-1,69,-1,68,71,76,-1,73,70,69,-1],
				[69,-1,-1,70,73,-1,76,-1,74,73,70,-1,69,-1,64,-1],
				[65,69,70,-1,73,70,69,-1,68,64,-1,68,69,-1,-1,-1]]
		}
	if theme=="frontyard":
		return {
			"step":0.27,
			"chords":[[48,52,55],[45,48,52],[53,57,60],[55,59,62], [48,52,55],[57,60,64],[53,57,60],[55,59,62], [48,52,55],[52,55,59],[53,57,60],[55,59,62], [57,60,64],[53,57,60],[55,59,62],[48,52,55]],
			"melodies":[
				[72,-1,76,79,76,-1,74,-1,72,74,76,-1,67,-1,69,-1],
				[71,-1,74,76,79,-1,76,74,72,-1,69,72,74,-1,67,-1],
				[76,79,81,-1,79,76,74,-1,72,74,76,72,69,-1,67,-1],
				[69,72,76,-1,74,72,69,-1,67,69,71,74,72,-1,-1,-1]
			]
		}
	if theme=="wasteland":
		return {
			"step":0.32,
			"chords":[[38,41,45],[36,40,43],[34,38,41],[33,36,40], [38,41,45],[41,45,48],[36,40,43],[33,36,40], [38,41,45],[34,38,41],[36,40,43],[33,36,40], [41,45,48],[36,40,43],[33,36,40],[38,41,45]],
			"melodies":[
				[62,-1,65,-1,69,68,65,-1,60,-1,62,-1,65,-1,60,-1],
				[62,65,68,-1,67,-1,63,-1,60,63,65,-1,62,-1,-1,-1],
				[69,-1,68,65,62,-1,60,-1,58,-1,60,62,65,-1,63,-1],
				[57,60,62,-1,65,63,60,-1,58,-1,57,-1,60,-1,62,-1]
			]
		}
	# 关卡外界面使用较舒展、留白更多的旋律。
	return {
		"step":0.30,
		"chords":[[48,52,55],[45,48,52],[41,45,48],[43,47,50], [48,52,55],[40,43,47],[41,45,48],[43,47,50], [45,48,52],[41,45,48],[43,47,50],[48,52,55], [41,45,48],[45,48,52],[43,47,50],[48,52,55]],
		"melodies":[
			[64,-1,67,-1,71,-1,67,-1,62,-1,64,-1,67,-1,64,-1],
			[64,67,69,-1,67,-1,64,-1,62,64,60,-1,-1,-1,60,-1],
			[67,-1,71,72,71,-1,67,-1,64,-1,62,64,67,-1,-1,-1],
			[69,-1,67,64,62,-1,60,-1,59,62,64,-1,62,-1,60,-1]
		]
	}

static func create_music(theme := "menu") -> AudioStreamWAV:
	var theme_data := music_theme_data(theme)
	var step_time: float = theme_data.step
	var chords: Array = theme_data.chords
	var melodies: Array = theme_data.melodies
	var total_steps := chords.size()*8
	var sample_count := int(MUSIC_SAMPLE_RATE*step_time*total_steps)
	# 音高在生成前统一换算，避免在几十万个采样点中反复计算指数。
	var midi_freqs: Array[float] = []
	midi_freqs.resize(128)
	for midi_note in 128:
		midi_freqs[midi_note] = midi_frequency(midi_note)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var time := float(i) / MUSIC_SAMPLE_RATE
		var step_index := mini(int(time/step_time),total_steps-1)
		var step_in_bar := step_index%8
		var local_time := fmod(time,step_time)
		var bar_index := int(step_index/8)
		var chord: Array = chords[bar_index]
		var motif: Array = melodies[int(step_index/16)%melodies.size()]
		var note: int = int(motif[step_index%16])
		var value := 0.0
		if note>=0:
			var frequency: float = midi_freqs[note]
			var note_envelope := minf(local_time/0.018,1.0)*minf((step_time-local_time)/0.075,1.0)
			var phase := local_time*frequency*TAU
			if theme=="wildland":
				var reed := sin(phase+0.18*sin(local_time*TAU*5.5))
				var pluck := exp(-local_time*10.0)
				value += (reed*0.085+sin(phase*2.0)*0.025+sin(phase*3.0)*0.018)*note_envelope*(0.65+pluck*0.35)
			elif theme=="frontyard":
				value += (sin(phase)*0.13+sin(phase*2.0)*0.035)*note_envelope
			elif theme=="wasteland":
				value += (sin(phase)*0.11+sin(phase*3.0)*0.032)*note_envelope
			else:
				value += (sin(phase)*0.105+sin(phase*2.0)*0.028)*note_envelope
		# 每两步拨一次低音，避免旧音乐从头到尾只有同一种短方波。
		var bass_time := fmod(time,step_time*2.0)
		var bass_decay := maxf(0.0,1.0-bass_time/(step_time*2.0))
		var bass_envelope := minf(bass_time/0.025,1.0)*bass_decay*bass_decay
		value += sin(bass_time*midi_freqs[int(chord[0])-12]*TAU)*bass_envelope*(0.09 if theme!="wasteland" else 0.11)
		# 缓慢和弦铺底，每小节重新起伏，三套曲目采用不同明暗比例。
		var bar_time := fmod(time,step_time*8.0)
		var bar_length := step_time*8.0
		var pad_envelope := minf(bar_time/0.12,1.0)*minf((bar_length-bar_time)/0.18,1.0)
		for chord_note in chord:
			value += sin(bar_time*midi_freqs[int(chord_note)]*TAU)*pad_envelope*(0.018 if theme=="wasteland" else 0.022)
		# 前院偏轻快，荒地使用低鼓和干燥的金属沙声；菜单只保留很轻的节拍提示。
		var hit_progress := local_time/step_time
		var hit_decay := maxf(0.0,1.0-hit_progress)
		var hit_decay_2 := hit_decay*hit_decay
		var hit_decay_4 := hit_decay_2*hit_decay_2
		if theme=="wildland":
			if step_in_bar in [0,3,5]:
				value += sin(TAU*(70.0*local_time-40.0*local_time*local_time))*hit_decay_4*0.13
			if step_in_bar in [2,6,7]:
				value += sin(local_time*1777.0*TAU)*sin(local_time*2413.0*TAU)*hit_decay_4*0.042
			if bar_index%8>=4:
				var answer := int(chord[step_in_bar%3])+12
				value += (sin(local_time*midi_freqs[answer]*TAU)+0.25*sin(local_time*midi_freqs[answer]*2.0*TAU))*minf(local_time/0.008,1.0)*hit_decay_4*0.045
		elif theme=="frontyard":
			if step_in_bar in [0,4]:
				value += sin(local_time*(92.0-45.0*hit_progress)*TAU)*hit_decay_4*0.10
			if step_in_bar%2==1:
				value += sin(local_time*4100.0*TAU)*hit_decay_4*hit_decay*0.025
		elif theme=="wasteland":
			if step_in_bar in [0,3,6]:
				value += sin(local_time*(76.0-30.0*hit_progress)*TAU)*hit_decay_2*hit_decay*0.12
			if step_in_bar%2==1:
				value += sin(local_time*1870.0*TAU)*sin(local_time*2630.0*TAU)*hit_decay_4*0.035
		elif step_in_bar in [0,4]:
			value += sin(local_time*880.0*TAU)*hit_decay_4*hit_decay*0.018
		bytes.encode_s16(i*2,int(clampf(value,-0.92,0.92)*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
