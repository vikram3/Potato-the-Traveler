extends AudioStreamPlayer

func _ready():
	connect("finished", Callable(self, "queue_free"))
