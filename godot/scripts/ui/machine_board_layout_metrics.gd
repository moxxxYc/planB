class_name MachineBoardLayoutMetrics
extends RefCounted

const MIN_VIEW_SIZE: Vector2 = Vector2(380.0, 600.0)
const SUPPLY_STRIP_HEIGHT: float = 164.0
const OUTER_MARGIN: float = 14.0
const SUPPLY_TOP_MARGIN: float = 14.0
const BOARD_TOP_AFTER_SUPPLY: float = 32.0
const BOARD_GAP: float = 12.0
const QUEUE_HEIGHT: float = 64.0
const BOARD_BOTTOM_MARGIN: float = 18.0
const MIN_BOARD_HEIGHT: float = 96.0

var view_size: Vector2 = MIN_VIEW_SIZE
var ui_scale: float = 1.0
var physics_scale: float = 1.0
var supply_rect: Rect2 = Rect2()
var stage_rects: Dictionary = {}
var physics_clip_rect: Rect2 = Rect2()
var queue_rect: Rect2 = Rect2()
var readable: bool = true

static func stable_size(size: Vector2) -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return MIN_VIEW_SIZE
	return Vector2(maxf(size.x, MIN_VIEW_SIZE.x), maxf(size.y, MIN_VIEW_SIZE.y))

func configure(size: Vector2) -> RefCounted:
	view_size = stable_size(size)
	_build_rects()
	return self

func _build_rects() -> void:
	supply_rect = Rect2(
		Vector2(OUTER_MARGIN, SUPPLY_TOP_MARGIN),
		Vector2(view_size.x - OUTER_MARGIN * 2.0, SUPPLY_STRIP_HEIGHT)
	)

	var board_top: float = SUPPLY_STRIP_HEIGHT + BOARD_TOP_AFTER_SUPPLY
	var available_height: float = view_size.y - board_top - QUEUE_HEIGHT - BOARD_GAP * 2.0 - BOARD_BOTTOM_MARGIN
	var board_height: float = maxf(MIN_BOARD_HEIGHT, available_height / 3.0)
	var launch_rect := Rect2(
		Vector2(OUTER_MARGIN, board_top),
		Vector2(view_size.x - OUTER_MARGIN * 2.0, board_height)
	)
	var tuning_rect := Rect2(launch_rect.position + Vector2(0.0, board_height + BOARD_GAP), launch_rect.size)
	var unit_rect := Rect2(launch_rect.position + Vector2(0.0, (board_height + BOARD_GAP) * 2.0), launch_rect.size)
	stage_rects = {
		"Launch": launch_rect,
		"Tuning": tuning_rect,
		"Unit": unit_rect,
	}
	physics_clip_rect = launch_rect.merge(tuning_rect).merge(unit_rect)
	queue_rect = Rect2(
		Vector2(OUTER_MARGIN, unit_rect.end.y + BOARD_GAP),
		Vector2(view_size.x - OUTER_MARGIN * 2.0, QUEUE_HEIGHT)
	)
	readable = launch_rect.size.x >= 340.0 and launch_rect.size.y >= MIN_BOARD_HEIGHT
