extends Node


var player_info = {}
var my_info = { name = "Johnson Magenta", favorite_color = Color8(255, 0, 255) }
var ready_players = {}
var done_players = {}
var selfReady = false
var selfDone = false

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	Signals.connect("lobbyToggleReady", self, "_handle_toggle_ready")


func _player_connected(id):
	#rpc_id is called every time someone joins, and is called by every client
	#this means that every existing client will send their info to the new client
	#since the connecting client can't call an rpc on their own ID that instance is not handled
	rpc_id(id,"register_player", my_info)
	print(id," network_peer_connected")


func _player_disconnected(id):
	player_info.erase(id)
	ready_players.erase(id)
	done_players.erase(id)
	print(id," network_peer_disconnected")
	Signals.emit_signal("lobbyUIupdate",player_info,ready_players)


func _connected_ok():
	print("connected_to_server")


func _server_disconnected():
	print("server_disconnected")


func _connected_fail():
	print("connection_failed")


remote func register_player(info):
	var id = get_tree().get_rpc_sender_id()
	player_info[id] = info
	ready_players[id] = false #ready system is bugged if player x is ready and player y joins after
	done_players[id] = false
	Signals.emit_signal("lobbyUIupdate",player_info,ready_players)

func _handle_toggle_ready():
	print("Changing ready status to ", not selfReady)
	selfReady = not selfReady
	rpc("toggle_ready_player")
	checkAllReady()
	
func checkAllReady():
	if get_tree().is_network_server():
		print("Checking if all members are ready...")
		var allReady = selfReady
		for key in ready_players:
			allReady = allReady and ready_players[key]
		if allReady:
			print("All members ready! Sending signal to pre configure...")
			#calls everyone, but is only called by server, and only when last guy readies up
			rpc("pre_configure_game")
			
remote func toggle_ready_player():
	var id = get_tree().get_rpc_sender_id()
	print("Changing ready status of ", id, " to ", not ready_players[id])
	ready_players[id] = not ready_players[id]
	Signals.emit_signal("lobbyUIupdate",player_info,ready_players)
	checkAllReady()

remotesync func pre_configure_game():
	get_tree().set_pause(true) # Pre-pause
	var selfPeerID = get_tree().get_network_unique_id()

	# Load world
	var world = preload("res://Scenes/Levels/TestLevel.tscn").instance()
	get_node("/root").add_child(world)

	# Load my player
	var my_player = preload("res://Scenes/Player.tscn").instance()
	my_player.set_name(str(selfPeerID))
	my_player.set_network_master(selfPeerID) # Will be explained later
	get_node("/root/world/players").add_child(my_player)

	# Load other players
	for p in player_info:
		var player = preload("res://Scenes/Player.tscn").instance()
		player.set_name(str(p))
		player.set_network_master(p) # Will be explained later
		get_node("/root/world/players").add_child(player)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
	print("Done pre config.")
	selfDone = true
	rpc("done_preconfiguring")
	checkAllDone()

func checkAllDone():
	if get_tree().is_network_server():
		print("Checking if all members are done with preconfig...")
		var allDone = selfDone
		for key in done_players:
			allDone = allDone and done_players[key]
		if allDone:
			print("All members done! Sending signal to start game...")
			#calls everyone, but is only called by server, and only when last guy readies up
			rpc("post_configure_game")
			
			
remote func done_preconfiguring():
	var id = get_tree().get_rpc_sender_id()
	print(id, " has reported finishing preconfig.")
	done_players[id] = true
	checkAllDone()

remotesync func post_configure_game():
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id(): #isn't necessary actually
		print("received signal to start game!")
		get_node("/root/Main/Menu").visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().set_pause(false)
		# Game starts now!
