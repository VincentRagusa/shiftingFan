extends KinematicBody
 
var curHp : int = 10
export var maxHp : int = 10
export var damage : int = 1



export var moveSpeed : float = 5.0
export var jumpForce : float = 10.0
export var gravity : float = 15.0
export var inertia :int = 10
 
var vel : Vector3 = Vector3()

var lastUpdateTime = 0


onready var cameraOrbit = get_node("CameraOrbit")
onready var camera = get_node("CameraOrbit/Camera")
onready var attackRayCast = get_node("CameraOrbit/AttackRayCast")

#onready var hitbox = $CollisionShape
onready var body = $Body

remote func _update_player_body(y, bodyScene, origin, collisionShapes):
	_changePlayerBody(y, bodyScene, origin, collisionShapes)

func _changePlayerBody(y, bodyScene, origin, collisionShapes):
	self.translation.y = y
	
	for c in body.get_children():
		c.queue_free()
	body.add_child(load(bodyScene).instance())
	
	body.transform = origin

	for c in get_children():
		if c is CollisionShape:
			c.queue_free()
	
	for i in range(len(collisionShapes[0])):
		var collisionBody = CollisionShape.new()
		collisionBody.shape = collisionShapes[0][i]
		collisionBody.transform = collisionShapes[1][i]
		add_child(collisionBody)



func _process(_delta):
	if is_network_master():
		var thingInFront = attackRayCast.get_collider()
		if thingInFront:
			if thingInFront.is_in_group("prop"):
				if Input.is_action_just_pressed("attack"):
					var newY = thingInFront.get_height()+0.01
					var newBodyScene = thingInFront.get_BodyScene()
					var newBodyOrigin = thingInFront.get_BodyTransform()
					var CollisionData = thingInFront.get_allCollisionShapesAndTransforms()
					_changePlayerBody(newY, newBodyScene, newBodyOrigin, CollisionData)
					rpc("_update_player_body",newY, newBodyScene, newBodyOrigin, CollisionData)
					

func _unhandled_input(event):
	if is_network_master():
		if event.is_action_pressed("zoom_in"):
			print("zoom in")
			camera.translation = Vector3(0,0,0)
			attackRayCast.translation = Vector3(0,0,0)
			attackRayCast.cast_to = Vector3(0,0,3)
			cameraOrbit.translation = Vector3(0,0.5,0)
		if event.is_action_pressed("zoom_out"):
			print("zoom out")
			camera.translation = Vector3(0,0.9,-4)
			attackRayCast.translation = Vector3(0,0.9,-4)
			attackRayCast.cast_to = Vector3(0,0,8)
			cameraOrbit.translation = Vector3(-0.5,0,0)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

#remote func _set_rotation(rotation,time):
#	if time > lastUpdateTime:
#		self.rotation_degrees = rotation
#		lastUpdateTime = time
#
#remote func _set_position(pos,time):
#	if time > lastUpdateTime:
#		global_transform.origin = lerp(global_transform.origin,pos,0.33)
#		lastUpdateTime = time
		
remote func _set_pos_and_rot(pos,rot,time):
	if time > lastUpdateTime:
		global_transform.origin = lerp(global_transform.origin,pos,0.33)
		self.rotation_degrees = rot
		lastUpdateTime = time
		
# called every physics step (60 times a second)
func _physics_process(delta):
	
	vel.x = 0
	vel.z = 0
	
	var input = Vector3()
	
	# movement inputs
	if Input.is_action_pressed("move_forward"):
		input.z += 1
	if Input.is_action_pressed("move_backward"):
		input.z -= 1
	if Input.is_action_pressed("move_left"):
		input.x += 1
	if Input.is_action_pressed("move_right"):
		input.x -= 1
	
	# normalize the input vector to prevent increased diagonal speed
	input = input.normalized()
	
	# get the relative direction
	var dir = (transform.basis.z * input.z + transform.basis.x * input.x)
	
	# apply the direction to our velocity
	vel.x = dir.x * moveSpeed
	vel.z = dir.z * moveSpeed
	
	# gravity
	vel.y -= gravity * delta
	
	if Input.is_action_pressed("jump") and is_on_floor():
		vel.y = jumpForce
		
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.is_in_group("prop"):
			if get_tree().get_network_unique_id() == 1:
				collision.collider.apply_central_impulse(-collision.normal * inertia)
			else:
				collision.collider.requestPropImpulse(-collision.normal * inertia)
		
	# move along the current velocity
	if vel != Vector3(): #don't update if not moving
		if is_network_master():#only allow master to control local obj
			vel = move_and_slide(vel, Vector3.UP,false,4,PI/4,false)
			#rpc to puppet all remote objs
			rpc_unreliable("_set_pos_and_rot",
				global_transform.origin,
				self.rotation_degrees,
				OS.get_system_time_msecs())
