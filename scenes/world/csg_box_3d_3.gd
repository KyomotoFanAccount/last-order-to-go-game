extends Node3D
# Corrimão para grind. A linha vai de uma ponta à outra ao longo do eixo X da peça
# (a seta vermelha no editor) e passa pelo CENTRO da caixa.
# Esta peça NÃO tem colisão de propósito: a moto só interage com ela pelo
# sistema de grind do Motorcycle.gd.

@export var length: float = 13.688   # mesmo valor do Size X da caixa
@export var width: float = 0.501     # mesmo valor do Size Z da caixa (espessura do corrimão)

func _ready() -> void:
	add_to_group("grind_rail")

# Ponta de trás do corrimão (posição no mundo)
func get_start() -> Vector3:
	return global_transform.origin - global_transform.basis.x * length * 0.5

# Ponta da frente do corrimão (posição no mundo)
func get_end() -> Vector3:
	return global_transform.origin + global_transform.basis.x * length * 0.5

# Metade da largura (usada pela moto para saber se a linha "tocou" no corrimão)
func get_half_width() -> float:
	return width * 0.5
