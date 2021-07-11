extends Label



func _ready():
	Signals.connect("lobbyUIupdate",self,"_updateLobbyUI")




func _updateLobbyUI(data,ready):
	var updateString = ""
	for key in data:
		updateString += "Player ID: " + str(key) + " " + ("READY" if ready[key] else "") + "\n"
	self.text = updateString
