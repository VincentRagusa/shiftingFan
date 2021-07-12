extends ItemList


func _ready():
	self.add_item("res://Scenes/Levels/TestLevel.tscn")
	self.add_item("res://Scenes/Levels/SmallOffice.tscn")
	self.select(0)
	
	
func getWorldPath():
	return self.get_item_text(self.get_selected_items()[0]) #assume one item
