extends Spatial


var lookSensitivity : float = 15.0
var minLookAngle : float = -20.0
var maxLookAngle : float = 75.0

var playerCameraLocked = false

var mouseDelta : Vector2 = Vector2()

onready var player = get_parent()
onready var orbit = get_parent().get_node("CameraOrbit")

func _input(event):	
	if event is InputEventMouseMotion:
		mouseDelta = event.relative

func _unhandled_input(event):
	if event.is_action_pressed("setPlayerRotation"):
		if playerCameraLocked:
			player.rotation_degrees.y = orbit.rotation_degrees.y
			orbit.rotation_degrees.y = 0
		playerCameraLocked = not playerCameraLocked
			

func _process(delta):
	if is_network_master():
		var rot = Vector3(mouseDelta.y, mouseDelta.x, 0) * lookSensitivity * delta
		rotation_degrees.x += rot.x
		rotation_degrees.x = clamp(rotation_degrees.x, minLookAngle, maxLookAngle)
		
		if playerCameraLocked:
			orbit.rotation_degrees.y -= rot.y
		else:
			player.rotation_degrees.y -= rot.y
		
		mouseDelta  = Vector2()
	
func _ready():
	#TODO replace with onready for main level
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass
