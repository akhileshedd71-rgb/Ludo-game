extends SceneTree
## Run with Godot --main-pack build/ludo-lane.x86_64 and this script's absolute path.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures+=1
		push_error(message)

func run() -> void:
	for path in ["res://assets/art/hero.png","res://assets/audio/win.wav","res://assets/fonts/Body.ttf","res://assets/icon.svg"]:
		check(ResourceLoader.exists(path),"Packaged resource exists: "+path)
	for path in ["res://assets/licenses/GODOT_LICENSE.txt","res://assets/licenses/APACHE-2.0.txt","res://assets/fonts/LICENSE.txt"]:
		check(FileAccess.file_exists(path),"Packaged notice exists: "+path)
		check(FileAccess.get_file_as_string(path).length()>100,"Packaged notice has its contents")
	check(not FileAccess.file_exists("res://tests/test_ui.gd"),"Tests are excluded from the shipped game")
	check(not FileAccess.file_exists("res://tools/setup_cloud.sh"),"Development tools are excluded from the shipped game")
	var scene: PackedScene=load("res://scenes/main.tscn")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	app.show_credits()
	await process_frame
	check(app.modal,"The packaged game can display credits")
	app.queue_free()
	await process_frame
	print("PACKAGE: %d failures" % failures)
	quit(1 if failures else 0)
