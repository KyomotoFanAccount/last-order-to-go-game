extends RigidBody3D

# Garante que as rodas têm fricção e comportamento adequado se necessário
func _ready():
	# Podes ajustar propriedades de física da roda aqui via código se preferires
	contact_monitor = true
	max_contacts_reported = 4
