extends Node
## Local PCM effects. Synthesised once; no files/samples or gameplay RNG.
var _streams: Dictionary={}
var _voices: Array[AudioStreamPlayer]=[]
var enabled:=true
var _cursor:=0
func _ready() -> void:
	for kind in ["step","bump","hit","guard","bell","gate","pickup","restore","ring"]: _streams[kind]=_synth(kind)
	for _i in range(4):
		var voice:=AudioStreamPlayer.new()
		voice.volume_db=-16
		add_child(voice); _voices.append(voice)
func play(kind: String) -> void:
	if not enabled or not _streams.has(kind): return
	var voice:=_voices[_cursor%_voices.size()]; _cursor+=1
	voice.stream=_streams[kind]; voice.volume_db=-23 if kind=="step" else -16
	voice.play()
func stop() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream=null
func _synth(kind: String) -> AudioStreamWAV:
	var length:=0.8 if kind=="restore" else (0.23 if kind in ["bell","guard","gate","ring"] else 0.075)
	var rate:=22050
	var bytes:=PackedByteArray()
	var noise_state: int=127
	for index in range(int(length*rate)):
		var t:=index/float(rate)
		var envelope:=pow(1.0-t/length,2.0)*minf(1.0,t*800.0)
		noise_state=(1664525*noise_state+1013904223)&0xffffffff
		var noise:=((noise_state>>8)%65536)/32768.0-1.0
		var sample:=0.0
		match kind:
			"step": sample=sin(TAU*75*t)*0.55+noise*0.3
			"bump": sample=sin(TAU*48*t)*0.7+noise*0.15
			"hit": sample=sin(TAU*100*t)*0.45+noise*0.45
			"guard": sample=(sin(TAU*780*t)+sin(TAU*1437*t)*0.5+noise*0.2)*0.5
			"bell": sample=(sin(TAU*220*t)+sin(TAU*607*t)*0.4+sin(TAU*1188*t)*0.2)*0.55
			"ring": sample=(sin(TAU*330*t)+sin(TAU*677*t)*0.5+sin(TAU*990*t)*0.3)*0.45
			"restore": sample=(sin(TAU*330*t)+sin(TAU*440*t)*0.65+sin(TAU*660*t)*0.45)*0.4
			"gate": sample=sin(TAU*(80*t+70*t*t))*0.5+noise*0.3
			"pickup": sample=(sin(TAU*660*t)+sin(TAU*990*t)*0.4)*0.55
		var value:=clampi(roundi(sample*envelope*23000),-32768,32767)&0xffff
		bytes.append(value&255); bytes.append((value>>8)&255)
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=rate; stream.data=bytes
	return stream
