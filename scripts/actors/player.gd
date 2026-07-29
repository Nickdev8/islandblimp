class_name OldmanPlayer extends CharacterBody2D

@onready var skin: AnimatedSprite2D = $sprites/skin
@onready var hair: AnimatedSprite2D = $sprites/hair
@onready var cloth: AnimatedSprite2D = $sprites/cloth
@onready var outline: AnimatedSprite2D = $sprites/outline


var speed = 100  # speed in pixels/sec
#50
func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down").normalized()
	velocity = direction * speed
	
	var animators: Array[AnimatedSprite2D] = [skin, hair, cloth, outline]
	
	for anim in animators:
		if direction.x < 0:
			anim.flip_h = true
		elif direction.x > 0:
			anim.flip_h = false

		if direction == Vector2.ZERO:
			anim.play("idle")
		else:
			anim.play("walk")

	move_and_slide()
