class_name BatterData
extends Resource

@export var display_name: String
@export var jersey_number: int
@export var body_color: Color
@export var swing_radius_x: float
@export var swing_radius_y: float
## Y of the contact box center, relative to home plate.
@export var contact_center_y: float
@export var contact_speed: float
@export var swing_trigger_z: float
## Contact launch angle in degrees. 0 = flat line drive, 30 = lazy fly, 45 = popup.
@export var launch_angle_degrees: float = 12.0
## Strike zone in world space, relative to home plate.
@export var zone_half_width: float = 0.22
@export var zone_bottom_y: float = 0.5
@export var zone_top_y: float = 1.05
