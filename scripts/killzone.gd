extends Area2D

@onready var timer: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	print("You died!")
	Engine.time_scale = 0.5 #Lelassítja az egész rendszert, ha ütközik a killzone-nal. (Dramatikusabbá teszi a halál pillanatát)
	body.get_node("CollisionShape2D").queue_free() #Ha ütközik a killzone-nal, akkor a CollisionShape2D részét elengedi a program
	timer.start()



func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0 #Alapgyorsaságba teszi az egész motort, respawn után.
	get_tree().reload_current_scene()
