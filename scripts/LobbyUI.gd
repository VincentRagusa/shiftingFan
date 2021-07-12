extends VBoxContainer

onready var propList = $Props
onready var hunterList = $Hunters
onready var propButton = $RoleChoices/Prop
onready var hunterButton = $RoleChoices/Hunter

func _ready():
	Signals.connect("lobbyUIupdate",self,"_updateLobbyUI")




func _updateLobbyUI(data,ready,role,selfReady,selfRole):
	propList.clear()
	hunterList.clear()
	
	#add yourself
	var myID = get_tree().get_network_unique_id()
	var playerString = "Player ID: " + str(myID) + " (ME) " + ("READY" if selfReady else "")
	if selfRole == 0:
		propList.add_item(playerString)
	else:
		hunterList.add_item(playerString)
	
	#add other players
	for key in data:
		playerString = "Player ID: " + str(key) + " " + ("READY" if ready[key] else "")
		if role[key] == 0:
			propList.add_item(playerString)
		else:
			hunterList.add_item(playerString)


func _on_Prop_pressed():
	Signals.emit_signal("lobbyChangeRole",0)
	propButton.disabled = true
	hunterButton.disabled = false


func _on_Hunter_pressed():
	Signals.emit_signal("lobbyChangeRole",1)
	propButton.disabled = false
	hunterButton.disabled = true
