
scale = teoria.note("c#4").scale("lydian")

audioContext = new AudioContext()
#master = audioContext.createGain()
#master.gain.value = 0
#master.connect audioContext.destination

@song = new Array 500

LS_KEY = "chiptool song data"

# TODO: just store midi numbers instead of Note objects
# and avoid serialization complexity
try
	json = localStorage.getItem(LS_KEY)
	if json
		data = JSON.parse(json)
		if data
			@song = []
			for datum in data
				if datum
					@song.push({
						n1: teoria.note(datum.n1),
						n2: teoria.note(datum.n2),
					})
				else
					song.push(null)
catch err
	console.warn err

save = ->
	teoria.Note::toJSON = teoria.Note::toString
	localStorage.setItem(LS_KEY, JSON.stringify(song))

playing = no

x_scale = 30 # pixels
note_length = 0.5 # seconds

pointers = {} # used for display
pressed = {} # used for interaction

document.body.setAttribute "touch-action", "none"

document.body.addEventListener "pointermove", (e)->
	x = e.clientX
	y = e.clientY
	
	pointer = pointers[e.pointerId]
	if pointer
		pointer.x = x
		pointer.y = y

	time = audioContext.currentTime
	
	pointer = pressed[e.pointerId]
	if pointer
		pointer.x = x
		pointer.y = y
		{gain, osc} = pointer
		note_at_pointer_y = note_at y
		if note_at_pointer_y
			new_freq = note_at_pointer_y.fq()
			
			xi = x // x_scale
			last_xi = pointer.last_x // x_scale
			
			if xi isnt last_xi
				for _xi_ in [xi...last_xi]
					song[_xi_] =
						n1: pointer.last_note
						n2: pointer.last_note
			
			if new_freq isnt pointer.last_freq
				pointer.last_freq = new_freq
				osc.frequency.value = new_freq
				
				if song[xi]
					song[xi].n2 = note_at_pointer_y
			
			save()
			
			pointer.last_note = note_at_pointer_y
			pointer.last_x = x

document.body.addEventListener "pointerdown", (e)->
	pointers[e.pointerId]?.down = yes
	return if pressed[e.pointerId]
	x = e.clientX
	y = e.clientY
	note_at_pointer_y = note_at y
	
	if note_at_pointer_y
		
		song[x // x_scale] = n1: note_at_pointer_y, n2: note_at_pointer_y
		save()
		
		osc = audioContext.createOscillator()
		gain = audioContext.createGain()
		
		osc.type = "triangle"
		osc.connect gain
		gain.connect audioContext.destination
		
		freq = last_freq = note_at_pointer_y.fq()
		
		pointer = pressed[e.pointerId] = {x, y, gain, osc, last_freq, last_x: x, last_note: note_at_pointer_y}
		
		time = audioContext.currentTime
		
		osc.frequency.value = freq
		osc.start 0
		gain.gain.cancelScheduledValues time
		gain.gain.linearRampToValueAtTime 0.001, time
		gain.gain.exponentialRampToValueAtTime 0.1, time + 0.01
	
	e.preventDefault()
	document.body.tabIndex = 1
	document.body.focus()

pointerstop = (e)->
	pointers[e.pointerId]?.down = no
	pointer = pressed[e.pointerId]
	delete pressed[e.pointerId]
	if pointer
		{gain, osc} = pointer
		time = audioContext.currentTime
		gain.gain.setValueAtTime 0.1, time
		gain.gain.exponentialRampToValueAtTime 0.01, time + 0.9
		gain.gain.linearRampToValueAtTime 0.0001, time + 0.99
		setTimeout ->
			osc.stop 0
		, 1500
window.addEventListener "pointerup", pointerstop
window.addEventListener "pointercancel", pointerstop

document.body.addEventListener "pointerout", (e)->
	delete pointers[e.pointerId]
document.body.addEventListener "pointerover", (e)->
	x = e.clientX
	y = e.clientY
	
	pointers[e.pointerId] = {
		x, y
		hover_y_lagged: undefined
		hover_y: undefined
		hover_r: 0
		hover_r_lagged: 0
	}

playback = []
playback_start_time = undefined

play = ->
	stop()
	playing = yes
	
	time = playback_start_time = audioContext.currentTime
	
	playback = []
	for position, i in song
		if position
			{n1, n2} = position
			prev_position = song[i - 1]
			# TODO: allow explicit reactuation
			if prev_position and prev_position.n2.midi() is n1.midi()
				{osc, gain} = playback[playback.length - 1]
				# cancel the note fading out
				gain.gain.cancelScheduledValues time - 0.2
				#gain.gain.setValueAtTime 0.1, time
				gain.gain.exponentialRampToValueAtTime 0.1, time + 0.5
				# fade it out later
				gain.gain.exponentialRampToValueAtTime 0.01, time + 0.9
				gain.gain.linearRampToValueAtTime 0.0001, time + 0.99
				# bend the pitch
				osc.frequency.setValueAtTime n1.fq(), time
				# TODO: glide for less than note_length
				osc.frequency.exponentialRampToValueAtTime n2.fq(), time + note_length
			else
				osc = audioContext.createOscillator()
				gain = audioContext.createGain()
				
				osc.type = "triangle"
				osc.connect gain
				gain.connect audioContext.destination
				# TODO: DRY
				osc.frequency.setValueAtTime n1.fq(), time
				osc.frequency.exponentialRampToValueAtTime n2.fq(), time + note_length
				
				osc.start time
				gain.gain.cancelScheduledValues time
				gain.gain.linearRampToValueAtTime 0.001, time
				gain.gain.exponentialRampToValueAtTime 0.1, time + 0.01
				gain.gain.exponentialRampToValueAtTime 0.01, time + 0.9
				gain.gain.linearRampToValueAtTime 0.0001, time + 0.99
			
			playback.push {osc, gain}
		
		time += note_length

stop = ->
	time = audioContext.currentTime
	for {osc, gain} in playback
		#gain.gain.cancelScheduledValues time
		#gain.gain.exponentialRampToValueAtTime 0.01, time + 0.1
		#gain.gain.linearRampToValueAtTime 0.0001, time + 0.19
		#osc.stop time + 1
		osc.stop()
	playback = []
	playback_start_time = undefined
	playing = no

window.addEventListener "keydown", (e)->
	if e.keyCode is 32
		if playing
			stop()
		else
			play()

note_at = (y)->
	# scale.get(~~((1 - y / canvas.height) * scale.notes().length))
	scale_notes = scale.notes()
	scale_notes[~~((1 - y / canvas.height) * scale_notes.length)]
y_for_note_i = (i)->
	(i + 0.5) / scale.notes().length * canvas.height
y_for_note = (note)->
	simple = scale.simple()
	y_for_note_i(simple.length - 1 - (simple.indexOf(note.toString(true))))
	# y_for_note_i(simple.length - (simple.indexOf(note.toString(true))))

lerp = (v1, v2, x)->
	v1 + (v2 - v1) * x

animate ->
	
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	
	ctx.save()
	
	ctx.beginPath()
	for note, i in scale.notes()
		y = y_for_note_i i
		ctx.moveTo 0, y
		ctx.lineTo canvas.width, y
	ctx.strokeStyle = "rgba(255, 255, 255, 0.2)"
	ctx.lineWidth = 1
	ctx.stroke()
	
	ctx.beginPath()
	for position, i in song when position
		i1 = i + 0
		i2 = i + 1
		x1 = x_scale * i1
		x2 = x_scale * i2
		y1 = y_for_note position.n1
		y2 = y_for_note position.n2
		ctx.moveTo x1, y1
		#ctx.bezierCurveTo lerp(x1, x2, 0.5), y1, lerp(x1, x2, 0.5), y2, x2, y2
		ctx.lineTo x2, y2
		#ctx.bezierCurveTo lerp(x1, x2, 0.3), y1, lerp(x1, x2, 0.4), y2, x2, y2
		#ctx.bezierCurveTo lerp(x1, x2, 0.2), y1, lerp(x1, x2, 0.4), y2, x2, y2
	ctx.strokeStyle = "rgba(0, 255, 0, 1)"
	ctx.lineCap = "round"
	ctx.lineWidth = 3
	ctx.stroke()
	
	if playing
		ctx.beginPath()
		playback_position = (audioContext.currentTime - playback_start_time) / note_length
		playback_position_x = playback_position * x_scale
		ctx.moveTo playback_position_x, 0
		ctx.lineTo playback_position_x, canvas.height
		ctx.strokeStyle = "rgba(0, 255, 0, 1)"
		ctx.lineWidth = 1
		ctx.stroke()
	
	for pointerId, pointer of pointers
		note_at_pointer_y = note_at pointer.y
		if note_at_pointer_y
			pointer.hover_y = y_for_note note_at_pointer_y
			pointer.hover_r = if pointer.down then 20 else 30
			pointer.hover_y_lagged ?= pointer.hover_y
			pointer.hover_y_lagged += (pointer.hover_y - pointer.hover_y_lagged) * 0.6
			pointer.hover_r_lagged += (pointer.hover_r - pointer.hover_r_lagged) * 0.5
			ctx.beginPath()
			ctx.arc pointer.x, pointer.hover_y_lagged, pointer.hover_r_lagged, 0, TAU
			ctx.fillStyle = "rgba(0, 255, 0, 0.3)"
			ctx.fill()
	
	ctx.restore()
