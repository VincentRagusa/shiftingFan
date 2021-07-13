extends Button


func _on_Host_pressed():
	
	var SERVER_PORT = int(get_node("../../VBoxContainer2/port").text)
	var MAX_PLAYERS = 9 # not including server
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	
	get_node("../../VBoxContainer2/ItemList").visible = true
	
	self.disabled = true
	get_node("../Join").disabled = true
	
	Signals.emit_signal(
		"lobbyUIupdate",
		Lobby.player_info,
		Lobby.ready_players,
		Lobby.player_roles,
		Lobby.selfReady,
		Lobby.selfRole)
