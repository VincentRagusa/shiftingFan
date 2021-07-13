extends Node

func get_BodyScene():
	return get_parent().BodyScene.resource_path
	
	
func get_BodyTransform():
	return get_node("./Body").transform
	

func get_rigidScene():
	return get_parent().RigidScene.resource_path


func get_height():
	return self.translation.y


func requestPropImpulse(impulse):
	get_parent()._onKBImpulseRequest(impulse)
