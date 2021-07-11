extends Button


func _on_Host_pressed():
	
	var SERVER_PORT = int(get_node("../../VBoxContainer2/port").text)
	var MAX_PLAYERS = 2 # not including server
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
