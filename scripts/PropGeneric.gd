extends Spatial

export (PackedScene) var RigidScene #used server-side to compute physics
export (PackedScene) var BodyScene # sent to player for mesh

func get_BodyScenePath():
	return BodyScene.resource_path

func _ready():
	if get_tree().get_network_unique_id() == 1: #if is the server
		Signals.connect("genericPropNotifyMove", self, "_onGenericPropNotifyMove")
		add_child(RigidScene.instance())
	else:
		Signals.connect("impulsePropRequest", self, "_onKBImpulseRequest")
		var kbScript = preload("res://scripts/propKB.gd")
		var kb = KinematicBody.new()
		kb.set_network_master(1)
		kb.add_to_group("prop")
		kb.set_script(kbScript) #may have to set process to true
		var rb = RigidScene.instance()
		for child in rb.get_children():
			kb.add_child(child.duplicate(true))
		add_child(kb)

func _onKBImpulseRequest(impulse):
	rpc_id(1,"applyRemoteImpulse",impulse)

remote func applyRemoteImpulse(impulse):
	for child in get_children():
		if child is RigidBody:
			child.apply_central_impulse(impulse)

func _onGenericPropNotifyMove(RBtransform):
#	print("RB update signal received")
	rpc_unreliable("propKBUpdate",RBtransform) #TODO: probably should do a time stamp
	
remote func propKBUpdate(RBtransform):
#	print("received KBupdate packet")
	for child in get_children():
		if child is KinematicBody:
			child.global_transform = RBtransform
