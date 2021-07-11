extends RigidBody

onready var body = $Body
export (PackedScene) var BodyScene


func get_BodyScene():
	return BodyScene.resource_path
	
	
func get_BodyTransform():
	return body.transform
	

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

func _process(delta):
	if is_network_master() and (linear_velocity != Vector3() or angular_velocity != Vector3()):
		get_parent()._onGenericPropNotifyMove(self.global_transform)
