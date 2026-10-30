extends CSGBox3D
# Ponto de entrega PROVISÓRIO: um bloco que faz o papel de restaurante ou de casa.
# Coloque este script em um CSGBox3D e escolha o tipo no Inspetor:
#   Restaurante = onde o pedido é retirado (ponto A)
#   Casa        = onde o pedido é entregue (ponto B)
# Quando a cidade tiver modelos 3D de verdade, é só colocar este script (ou um nó com os
# mesmos métodos) no prédio/casa que o sistema de entregas continua funcionando.

enum Kind { RESTAURANTE, CASA }

@export var kind: Kind = Kind.CASA
@export var display_name: String = ""     # nome mostrado no app; se ficar vazio, usa o nome do nó
@export var solid: bool = true            # true = a moto bate no bloco
@export var paint: bool = true            # true = pinta o bloco (laranja = restaurante, azul = casa)
@export var show_label: bool = true       # nome flutuando em cima do bloco
@export var arrive_extra: float = 5.0     # m além da parede do bloco para contar que chegou

func _ready() -> void:
	if kind == Kind.RESTAURANTE:
		add_to_group("pickup_point")
	else:
		add_to_group("dropoff_point")

	if solid:
		use_collision = true

	var point_color = Color(0.3, 0.55, 1.0)
	if kind == Kind.RESTAURANTE:
		point_color = Color(1.0, 0.5, 0.1)

	if paint:
		var material_new = StandardMaterial3D.new()
		material_new.albedo_color = point_color
		material = material_new

	if show_label:
		var label = Label3D.new()
		label.text = get_point_name()
		label.font_size = 96
		label.pixel_size = 0.01
		label.outline_size = 24
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = point_color.lightened(0.4)
		label.position = Vector3(0.0, size.y * 0.5 + 2.0, 0.0)
		add_child(label)

# Nome mostrado no app
func get_point_name() -> String:
	if display_name != "":
		return display_name
	return str(name).replace("_", " ")

# Distância (a partir do centro do bloco) em que a moto já conta como "chegou"
func get_arrive_radius() -> float:
	return Vector2(size.x, size.z).length() * 0.5 + arrive_extra
