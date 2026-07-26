extends RefCounted
class_name MooSynth

## The moo is synthesised, not sampled - the project ships with zero audio
## assets. A moo is a low buzzy fundamental with a rise-then-fall pitch
## contour, run through a sweeping lowpass that reads as "mmm - ooo - mmm".

const MIX_RATE := 22050
const VARIANTS := 4

static var _cache: Array = []


static func stream(index: int) -> AudioStreamWAV:
	if _cache.is_empty():
		for i in VARIANTS:
			_cache.append(_synthesise(1000 + i * 37))
	return _cache[abs(index) % VARIANTS]


static func random_stream() -> AudioStreamWAV:
	return stream(randi())


static func _synthesise(rng_seed: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	var duration := rng.randf_range(1.05, 1.4)
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var f0_start := rng.randf_range(148.0, 178.0)
	var f0_peak := f0_start * rng.randf_range(1.16, 1.28)
	var f0_end := f0_start * rng.randf_range(0.56, 0.68)
	var vibrato_hz := rng.randf_range(4.6, 6.4)

	var phase := 0.0
	var lowpass := 0.0

	for i in sample_count:
		var t := float(i) / float(MIX_RATE)
		var u := t / duration

		var f0: float
		if u < 0.25:
			f0 = lerpf(f0_start, f0_peak, u / 0.25)
		else:
			f0 = lerpf(f0_peak, f0_end, (u - 0.25) / 0.75)
		f0 += sin(TAU * vibrato_hz * t) * 3.2

		phase += TAU * f0 / float(MIX_RATE)
		if phase > TAU:
			phase -= TAU

		# Harmonic stack. A pure sine sounds like a test tone; the upper
		# partials are what make it sound like an animal.
		var s := sin(phase)
		s += sin(phase * 2.0) * 0.55
		s += sin(phase * 3.0) * 0.38
		s += sin(phase * 4.0) * 0.22
		s += sin(phase * 5.0) * 0.12
		s /= 2.27

		# One-pole lowpass whose cutoff opens in the middle of the call.
		var cutoff := lerpf(300.0, 1300.0, sin(clampf(u, 0.0, 1.0) * PI))
		var a := clampf(1.0 - exp(-TAU * cutoff / float(MIX_RATE)), 0.0, 1.0)
		lowpass += (s - lowpass) * a

		var env := clampf(u / 0.10, 0.0, 1.0) * clampf((1.0 - u) / 0.30, 0.0, 1.0)
		var v := clampf(lowpass * env * 0.75, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
