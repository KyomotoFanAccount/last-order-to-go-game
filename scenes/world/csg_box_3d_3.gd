extends Node3D
# Corrimão para grind (a moto desliza em cima dele).
#
# A linha do corrimão vai de uma ponta à outra ao longo do eixo Z da peça
# (a seta azul no editor). O comprimento é "length" multiplicado pela escala Z
# da peça: para esticar o corrimão, mude a Escala (Scale) Z no Inspetor.
#
# Esta peça NÃO tem colisão de propósito: a moto só interage com ela pelo
# sistema de grind do Motorcycle.gd.

@export var length: float = 13.688   # comprimento em metros quando a escala Z = 1 (igual ao modelo)

func _ready() -> void:
	add_to_group("grind_rail")

# Ponta de trás do corrimão (posição no mundo)
func get_start() -> Vector3:
	return global_transform.origin - global_transform.basis.z * length * 0.5

# Ponta da frente do corrimão (posição no mundo)
func get_end() -> Vector3:
	return global_transform.origin + global_transform.basis.z * length * 0.5
