extends Node

const CELL_SIDE_LENGTH: int = 22


func get_grid_coordinate(global_coordinate: Vector2) -> Vector2i:
	return Vector2(global_coordinate.x / CELL_SIDE_LENGTH, global_coordinate.y / CELL_SIDE_LENGTH)
