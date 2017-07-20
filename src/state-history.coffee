
@undos = []
@redos = []

@undoable = (action)=>
	redos.length = 0
	console.log redos
	
	undos.push(get_state())
	
	if action
		action()
		state_changed()
	
	return true

@undo = =>
	return false if undos.length < 1

	redos.push(get_state())
	set_state(undos.pop())
	
	return true

@redo = =>
	return false if redos.length < 1

	undos.push(get_state())
	set_state(redos.pop())
	
	return true
