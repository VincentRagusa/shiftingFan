extends RigidBody

onready var body = $Body
export (PackedScene) var BodyScene #TODO: instead of double linking this, can we use the genericProp instead?


func get_BodyScene():
	return BodyScene.resource_path
	
	
func get_BodyTransform():
	return body.transform
	

func get_rigidScene():
	return get_parent().RigidScene.resource_path


func get_height():
	return self.translation.y


func _process(delta):
	if is_network_master() and (linear_velocity != Vector3() or angular_velocity != Vector3()):
		get_parent()._onGenericPropNotifyMove(self.global_transform)
