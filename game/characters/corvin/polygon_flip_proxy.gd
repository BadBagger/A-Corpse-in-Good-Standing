@tool
extends Polygon2D

var flip_h := false:
	set(value):
		flip_h = value
		scale.x = -1.0 if flip_h else 1.0
