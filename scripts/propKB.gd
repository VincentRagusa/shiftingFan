extends Node

func get_BodyScene():
	return get_parent().BodyScene.resource_path
	
	
func get_BodyTransform():
	return get_node("./Body").transform
	

func get_allCollisionShapesAndTransforms():
	var shapes = []
	var transforms = []
	for c in get_children():
		if c is CollisionShape:
			shapes.append(c.shape)
			transforms.append(c.transform)
	return [shapes, transforms]

func get_height():
	return self.translation.y

func requestPropImpulse(impulse):
	get_parent()._onKBImpulseRequest(impulse)
