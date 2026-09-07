class_name AudioSynth
extends RefCounted

const SAMPLE_RATE := 22050

static func create_sfx(frequency: float, duration: float, strength: float, wave: String, rng: RandomNumberGenerator) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var time := float(i) / SAMPLE_RATE
		var phase := time * frequency * TAU
		var value := sin(phase)
		if wave == "square":
			value = 1.0 if value >= 0.0 else -1.0
		elif wave == "noise":
			value = rng.randf_range(-1.0, 1.0)
		var envelope := pow(1.0 - float(i) / sample_count, 1.8)
		bytes.encode_s16(i * 2, int(value * envelope * strength * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

static func create_music() -> AudioStreamWAV:
	var beat_time := 0.28
	var notes := [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 349.23,
		440.0, 587.33, 440.0, 349.23, 261.63, 329.63, 392.0, 329.63]
	var sample_count := int(SAMPLE_RATE * beat_time * notes.size())
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var time := float(i) / SAMPLE_RATE
		var note_index := mini(int(time / beat_time), notes.size() - 1)
		var local_time := fmod(time, beat_time)
		var frequency: float = notes[note_index]
		var envelope := minf(local_time / 0.025, 1.0) * minf((beat_time - local_time) / 0.06, 1.0)
		var lead := signf(sin(time * frequency * TAU)) * 0.12
		var bass_frequency: float = notes[int(note_index / 4) * 4] * 0.5
		var bass := sin(time * bass_frequency * TAU) * 0.11
		var sparkle := sin(time * frequency * 2.0 * TAU) * 0.035
		bytes.encode_s16(i * 2, int((lead + bass + sparkle) * envelope * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
