class_name LaneStorage
extends RefCounted

const MATCH_PATH := "user://match.json"
const SETTINGS_PATH := "user://settings.json"

static func write_json(path: String, data: Dictionary) -> bool:
	var temporary := path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error!=OK:
		return false
	return DirAccess.rename_absolute(temporary,path)==OK

static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>65536:
		return null
	return JSON.parse_string(file.get_as_text())

static func load_game() -> LudoGame:
	var state := LudoGame.new()
	return state if state.restore(read_json(MATCH_PATH)) and state.winner<0 else null

static func clear_game() -> void:
	if FileAccess.file_exists(MATCH_PATH):
		DirAccess.remove_absolute(MATCH_PATH)

static func settings() -> Dictionary:
	var defaults := {"sound":true,"haptics":true,"motion":true,"wins":0,"matches":0}
	var data: Variant = read_json(SETTINGS_PATH)
	if data is Dictionary:
		for key in ["sound","haptics","motion"]:
			if data.get(key) is bool: defaults[key]=data[key]
		for key in ["wins","matches"]:
			if (data.get(key) is float or data.get(key) is int) and data[key]>=0 and data[key]<1000000:
				defaults[key]=int(data[key])
	return defaults
