extends Button




func _on_Ready_pressed():
	Signals.emit_signal("lobbyToggleReady")
