extends KinematicBody
 

export var maxHp : int = 10
export var moveSpeed : float = 5.0
export var jumpForce : float = 10.0
export var gravity : float = 15.0
export var inertia :int = 10
 
var vel : Vector3 = Vector3()
var curHp : int = 10
var lastUpdateTime = 0

onready var cameraOrbit = $CameraOrbit
onready var camera = $CameraOrbit/Camera
onready var attackRayCast = $CameraOrbit/AttackRayCast
onready var HUD_role = $CameraOrbit/Camera/HUD/RoleIdentifier
onready var HUD_HP = $CameraOrbit/Camera/HUD/HPIndicator
onready var body = $Body


func _ready():
	if is_network_master():
		HUD_role.text = "PROP"
		HUD_HP.text = "HP: " + str(curHp)


remote func takeDamage(damage):
	curHp -= damage
	HUD_HP.text = "HP: " + str(curHp)
	if curHp < 1:
		print("YOU DIED")	


func notifyOwnerOfDamage(damage,id):
	#remember that RPCs must call functions in the same file
	rpc_id(id,"takeDamage",damage)


remote func _update_player_body(y, bodyScene, origin, rigidScene):
	_changePlayerBody(y, bodyScene, origin, rigidScene)


func _changePlayerBody(y, bodyScene, origin, rigidScene):
	self.translation.y = y
	
	for c in body.get_children():
		c.queue_free()
	body.add_child(load(bodyScene).instance())
	
	body.transform = origin

	for c in get_children():
		if c is CollisionShape:
			c.queue_free()

	var dummyProp = load(rigidScene).instance()
	for child in dummyProp.get_children():
		if child is CollisionShape:
			add_child(child.duplicate(true))


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
		if event.is_action_pressed("attack"):
			var thingInFront = attackRayCast.get_collider()
			if thingInFront:
				if thingInFront.is_in_group("prop"):
					var newY = thingInFront.get_height()+0.01
					var newBodyScene = thingInFront.get_BodyScene()
					var newBodyOrigin = thingInFront.get_BodyTransform()
					var rigidScene = thingInFront.get_rigidScene()
					_changePlayerBody(newY, newBodyScene, newBodyOrigin, rigidScene)
					rpc("_update_player_body",newY, newBodyScene, newBodyOrigin, rigidScene)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


remote func _set_pos_and_rot(pos,rot,time):
	if time > lastUpdateTime:
		global_transform.origin = pos
		self.rotation_degrees = rot
		lastUpdateTime = time


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

