extends RigidBody3D

@export var move_speed: float = 10.0
@export var jump_force: float = 5.0
@export var acceleration: float = 15.0 # Controls how fast it speeds up/stops


var input_dir: Vector3 = Vector3.ZERO
var wants_to_jump: bool = false

func _ready() -> void:
	# Keeps the cat upright
	axis_lock_angular_x = true
	axis_lock_angular_z = true

func _process(_delta: float) -> void:
	# Get input vector
	var input_3d := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	input_dir = Vector3(input_3d.x, 0, input_3d.y).normalized()
	
	
	# CRITICAL FIX: Transform the direction vector based on the player's current local orientation
	# This ensures "Forward" is always where the character is actually facing!
	var direction := (global_transform.basis * Vector3(input_3d.x, 0, input_3d.y)).normalized()
	input_dir = direction
	
	if Input.is_action_just_pressed("jump"):
		wants_to_jump = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Wake up the physics body if the player provides input
	if input_dir.length() > 0 or wants_to_jump:
		sleeping = false
	
	# 1. Handle Horizontal Movement
	var current_vel := state.linear_velocity
	
	# Calculate the target horizontal velocity
	var target_velocity := input_dir * move_speed
	
	# Smoothly blend from the current velocity to the target velocity using lerp.
	# This prevents the chaotic, random "snapping" and gives tight control.
	var new_x : float = lerp(current_vel.x, target_velocity.x, state.step * acceleration)
	var new_z : float = lerp(current_vel.z, target_velocity.z, state.step * acceleration)
	
	# Apply the smooth horizontal movement while preserving gravity/jumping (Y)
	state.linear_velocity = Vector3(new_x, current_vel.y, new_z)
	
	# Handle Jumping
	if wants_to_jump:
		if abs(state.linear_velocity.y) < 0.1:
			state.apply_central_impulse(Vector3.UP * jump_force)
		wants_to_jump = false
