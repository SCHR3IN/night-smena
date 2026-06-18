## CameraSystem — управление системой наблюдения
## Переключение камер, отображение видеопотоков
extends Node

signal camera_switched(cam_id: int, room_id: String)

var current_camera: int = 1
var _cameras: Dictionary = {}  # cam_id → room_id
var _cam_sprites: Dictionary = {}  # cam_id → Sprite2D reference

const CAMERA_ROOMS: Dictionary = {
	1: "reception",
	2: "archive",
	3: "workshop",
	4: "storage",
	5: "left_corridor",
	6: "right_corridor",
	7: "service",
}

const CAMERA_NAMES: Dictionary = {
	1: "CAM 01 — Приёмная",
	2: "CAM 02 — Архив",
	3: "CAM 03 — Мастерская",
	4: "CAM 04 — Склад",
	5: "CAM 05 — Левый коридор",
	6: "CAM 06 — Правый коридор",
	7: "CAM 07 — Сервисная",
}


func _ready() -> void:
	_cameras = CAMERA_ROOMS.duplicate()


func switch_camera(cam_id: int) -> void:
	if not _cameras.has(cam_id):
		return
	current_camera = cam_id
	camera_switched.emit(cam_id, _cameras[cam_id])


func get_room_for_camera(cam_id: int) -> String:
	return _cameras.get(cam_id, "")


func get_camera_name(cam_id: int) -> String:
	return CAMERA_NAMES.get(cam_id, "CAM ??")


func get_current_room() -> String:
	return _cameras.get(current_camera, "")


func register_cam_sprite(cam_id: int, sprite: Sprite2D) -> void:
	_cam_sprites[cam_id] = sprite


func is_animatronic_visible(animatronic_room: String) -> bool:
	return get_current_room() == animatronic_room
