## RoomGraph — граф связанных комнат
## Представляет здание как набор узлов с рёбрами
class_name RoomGraph
extends RefCounted

var rooms: Dictionary = {}  # room_id → RoomNode
var _adjacency: Dictionary = {}  # room_id → Array[room_id]


class RoomNode:
	var id: String
	var display_name: String
	var camera_id: int  # -1 if no camera
	var is_office: bool = false

	func _init(p_id: String, p_name: String, p_cam: int = -1) -> void:
		id = p_id
		display_name = p_name
		camera_id = p_cam


func add_room(id: String, display_name: String, camera_id: int = -1) -> void:
	rooms[id] = RoomNode.new(id, display_name, camera_id)
	if not _adjacency.has(id):
		_adjacency[id] = []


func add_edge(from_id: String, to_id: String, bidirectional: bool = false) -> void:
	if not _adjacency.has(from_id):
		_adjacency[from_id] = []
	_adjacency[from_id].append(to_id)
	if bidirectional:
		if not _adjacency.has(to_id):
			_adjacency[to_id] = []
		_adjacency[to_id].append(from_id)


func get_neighbors(room_id: String) -> Array:
	return _adjacency.get(room_id, [])


func get_room(room_id: String) -> RoomNode:
	return rooms.get(room_id)


func get_path_towards(from_id: String, target_id: String) -> Array:
	# BFS to find shortest path
	var queue: Array = [[from_id]]
	var visited: Dictionary = {from_id: true}

	while queue.size() > 0:
		var path: Array = queue.pop_front()
		var current: String = path[-1]

		if current == target_id:
			return path

		for neighbor in get_neighbors(current):
			if not visited.has(neighbor):
				visited[neighbor] = true
				var new_path := path.duplicate()
				new_path.append(neighbor)
				queue.append(new_path)

	return []


static func create_default() -> RoomGraph:
	var graph := RoomGraph.new()

	# Define rooms
	graph.add_room("reception", "Приёмная", 1)        # CAM 01
	graph.add_room("archive", "Архив", 2)              # CAM 02
	graph.add_room("workshop", "Мастерская", 3)        # CAM 03
	graph.add_room("storage", "Склад", 4)              # CAM 04
	graph.add_room("left_corridor", "Левый коридор", 5)  # CAM 05
	graph.add_room("right_corridor", "Правый коридор", 6) # CAM 06
	graph.add_room("service", "Сервисная", 7)          # CAM 07
	graph.add_room("office", "Офис", -1)
	graph.rooms["office"].is_office = true

	# Define connections (directed: from → towards office)
	graph.add_edge("service", "reception")
	graph.add_edge("service", "workshop")
	graph.add_edge("reception", "archive")
	graph.add_edge("archive", "left_corridor")
	graph.add_edge("left_corridor", "office")
	graph.add_edge("workshop", "storage")
	graph.add_edge("storage", "right_corridor")
	graph.add_edge("right_corridor", "office")

	# Retreat edges (back from door)
	graph.add_edge("office", "left_corridor")
	graph.add_edge("office", "right_corridor")
	graph.add_edge("left_corridor", "archive")
	graph.add_edge("right_corridor", "storage")

	return graph
