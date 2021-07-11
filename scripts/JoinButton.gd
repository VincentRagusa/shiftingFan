extends Button

onready var menu = get_node("/root/Main/Menu")

func _on_Join_pressed():
	
	var SERVER_IP = get_node("../../VBoxContainer2/IPaddr").text
	var SERVER_PORT = int(get_node("../../VBoxContainer2/port").text)
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = peer
