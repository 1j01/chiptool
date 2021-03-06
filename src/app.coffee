
scale = teoria.note("c#4").scale("lydian")
scale_notes = scale.notes()
scale_note_midis = (note.midi() for note in scale_notes)

midi_to_freq = (midi)->
	teoria.note.fromMIDI(midi).fq()

audioContext = new AudioContext()
#master = audioContext.createGain()
#master.gain.value = 0
#master.connect audioContext.destination

FORMAT_VERSION = 0

@song = {formatVersion: FORMAT_VERSION, noteData: []}

LS_KEY = "chiptool song data"

@state_changed = ->
	# TODO: update playback here
	try
		save()
	catch err
		console.warn err
		# TODO: warn user

@get_state = ->
	JSON.stringify(song)

@set_state = (song_json)->
	# Performance: could do without JSON parsing and document validation for undo/redo
	try
		if song_json
			data = JSON.parse(song_json)
			if data
				if not Number.isInteger(data.formatVersion)
					console.error "In the JSON data, expected a top level property `formatVersion` to hold an integer; is this a Chiptool song?", data
					return
				if data.formatVersion > FORMAT_VERSION
					console.error "The song file appears to have been created with a later version of Chiptool; try refreshing to get the latest version."
					return
				if data.formatVersion < FORMAT_VERSION
					
					# upgrades can be done like so:
					
					# if data.formatVersion is 0
					# 	console.log "Upgrading song file from format version #{data.formatVersion} to #{data.formatVersion + 1}"
					# 	data.formatVersion += 1
					# 	data.foo = data.bar
					# 	delete data.bar
					# 	return
					
					# they could also be moved into an array/map of format upgrades
					
					# for backwards compatible changes, the version number can simply be incremented
					
					# also, in Wavey, I've included undos and redos in the saved state and done this:
					
					# upgrade = (fn)->
					# 	fn doc.state
					# 	fn state for state in doc.undos
					# 	fn state for state in doc.redos
					
					if data.formatVersion isnt FORMAT_VERSION
						# this message is really verbose, but also not nearly as helpful as it could be
						# this isn't even shown to the user yet
						# and this app is very much pre-alpha; it's an experiment
						# but this shows what kind of help could be given for this sort of scenario
						console.error "The song file appears to have been created with an earlier version of Chiptool,
							but there's no upgrade path from #{data.formatVersion} to #{FORMAT_VERSION}.
							You could try refreshing the page in case an upgrade path has been established since whenever,
							or you could look through the source history (https://github.com/1j01/chiptool)
							to find a version capable of loading the file
							and maybe use RawGit to get a URL for that version of the app"
						return
				if not Array.isArray(data.noteData)
					console.error "In JSON data, expected a top level property `noteData` to hold an array.", data
					return
				# TODO: recover from validation errors?
				for position, index in data when position?
					for note_prop in ["n1", "n2"]
						if not Number.isInteger(position[note_prop])
							console.error "At index #{index} in song, expected an integer for property `#{note_prop}`", position
							return
				# TODO: check for unhandled keys?
				# maybe have a more robust system with schemas?
				@song = data
	catch err
		console.warn err
		# TODO: warn user
	state_changed()

load = ->
	set_state(localStorage.getItem(LS_KEY))

save = ->
	localStorage.setItem(LS_KEY, get_state())

playing = no

x_scale = 30 # pixels
note_length = 0.5 # seconds
glide_length = 0.2 # seconds

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
		note_midi_at_pointer_y = note_midi_at y
		if note_midi_at_pointer_y
			new_freq = midi_to_freq(note_midi_at_pointer_y)
			
			xi = x // x_scale
			last_xi = pointer.last_x // x_scale
			
			if xi isnt last_xi
				for _xi_ in [xi...last_xi]
					song.noteData[_xi_] =
						n1: pointer.last_note_midi
						n2: pointer.last_note_midi
			
			if new_freq isnt pointer.last_freq
				pointer.last_freq = new_freq
				osc.frequency.value = new_freq
				
				if song.noteData[xi]
					song.noteData[xi].n2 = note_midi_at_pointer_y
			
			state_changed()
			
			pointer.last_note_midi = note_midi_at_pointer_y
			pointer.last_x = x

document.body.addEventListener "pointerdown", (e)->
	pointers[e.pointerId]?.down = yes
	return if pressed[e.pointerId]
	x = e.clientX
	y = e.clientY
	note_midi_at_pointer_y = note_midi_at y
	
	if note_midi_at_pointer_y
		
		undoable =>
			song.noteData[x // x_scale] =
				n1: note_midi_at_pointer_y
				n2: note_midi_at_pointer_y
		
		osc = audioContext.createOscillator()
		gain = audioContext.createGain()
		
		osc.type = "triangle"
		osc.connect gain
		gain.connect audioContext.destination
		
		freq = last_freq = midi_to_freq(note_midi_at_pointer_y)
		
		pointer = pressed[e.pointerId] = {x, y, gain, osc, last_freq, last_x: x, last_note: note_midi_at_pointer_y}
		
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
window.addEventListener "pointercancel", pointerstop # TODO: cancel edit

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
	for position, i in song.noteData
		if position
			{n1, n2} = position
			prev_position = song.noteData[i - 1]
			
			# TODO: allow explicit reactuation
			if prev_position and prev_position.n2 is n1
				{osc, gain} = playback[playback.length - 1]
				# cancel the note fading out
				gain.gain.cancelScheduledValues time - 0.2
				#gain.gain.setValueAtTime 0.1, time
				gain.gain.exponentialRampToValueAtTime 0.1, time + 0.5
				# fade it out later
				gain.gain.exponentialRampToValueAtTime 0.01, time + 0.9
				gain.gain.linearRampToValueAtTime 0.0001, time + 0.99
			else
				osc = audioContext.createOscillator()
				gain = audioContext.createGain()
				
				osc.type = "triangle"
				osc.connect gain
				gain.connect audioContext.destination
				
				osc.start time
				gain.gain.cancelScheduledValues time
				gain.gain.linearRampToValueAtTime 0.001, time
				gain.gain.exponentialRampToValueAtTime 0.1, time + 0.01
				gain.gain.exponentialRampToValueAtTime 0.01, time + 0.9
				gain.gain.linearRampToValueAtTime 0.0001, time + 0.99
			
			osc.frequency.setValueAtTime midi_to_freq(n1), time
			osc.frequency.exponentialRampToValueAtTime midi_to_freq(n2), time + glide_length
			
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
	key = (e.key ? String.fromCharCode(e.keyCode)).toUpperCase()
	if e.ctrlKey
		switch key
			when "Z"
				if e.shiftKey then redo() else undo()
			when "Y"
				redo()
			#when "A"
				#select_all()
			else
				return # don't prevent default
	else
		switch e.keyCode
			when 32 # Space
				if playing
					stop()
				else
					play()
			#when 27 # Escape
				#deselect() if selection
			#when 13 # Enter
				#deselect() if selection
			when 115 # F4
				redo()
			#when 46 # Delete
				#delete_selected()
			else
				return # don't prevent default
	e.preventDefault()

note_midi_at = (y)->
	scale_note_midis[~~((1 - y / canvas.height) * scale_note_midis.length)]
y_for_note_i = (i)->
	(i + 0.5) / scale_notes.length * canvas.height
y_for_note_midi = (note_midi)->
	y_for_note_i(scale_note_midis.length - 1 - (scale_note_midis.indexOf(note_midi)))

lerp = (v1, v2, x)->
	v1 + (v2 - v1) * x

animate ->
	
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	
	ctx.save()
	
	ctx.beginPath()
	for note, i in scale_notes
		y = y_for_note_i i
		ctx.moveTo 0, y
		ctx.lineTo canvas.width, y
	ctx.strokeStyle = "rgba(255, 255, 255, 0.2)"
	ctx.lineWidth = 1
	ctx.stroke()
	
	ctx.beginPath()
	for position, i in song.noteData when position
		i1 = i + 0
		i2 = i + 1
		x1 = x_scale * i1
		x2 = x_scale * i2
		y1 = y_for_note_midi position.n1
		y2 = y_for_note_midi position.n2
		ctx.moveTo x1, y1
		#ctx.bezierCurveTo lerp(x1, x2, 0.5), y1, lerp(x1, x2, 0.5), y2, x2, y2
		ctx.lineTo x1 + x_scale * glide_length, y2
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
		note_midi_at_pointer_y = note_midi_at pointer.y
		if note_midi_at_pointer_y
			pointer.hover_y = y_for_note_midi note_midi_at_pointer_y
			pointer.hover_r = if pointer.down then 20 else 30
			pointer.hover_y_lagged ?= pointer.hover_y
			pointer.hover_y_lagged += (pointer.hover_y - pointer.hover_y_lagged) * 0.6
			pointer.hover_r_lagged += (pointer.hover_r - pointer.hover_r_lagged) * 0.5
			ctx.beginPath()
			ctx.arc pointer.x, pointer.hover_y_lagged, pointer.hover_r_lagged, 0, TAU
			ctx.fillStyle = "rgba(0, 255, 0, 0.3)"
			ctx.fill()
	
	ctx.restore()

load()
