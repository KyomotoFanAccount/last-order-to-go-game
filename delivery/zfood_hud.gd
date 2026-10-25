extends CanvasLayer
# HUD do zFood (autoload "ZFoodHUD").
#   [P] abre / fecha o app (o mouse aparece enquanto o app está aberto)
#   Painel embaixo à esquerda: pedido ativo, destino, distância, prazo e integridade da comida
#   Embaixo no centro: dinheiro, nota do entregador e a dica da tecla
#   Ao concluir: resumo da entrega com pagamento, gorjeta e a avaliação do cliente

const OPEN_KEY: Key = KEY_P
const COLOR_ACCENT: Color = Color(1.0, 0.4, 0.2)   # cor do zFood
const RESULT_SECONDS: float = 8.0                  # tempo que o resumo da entrega fica na tela

var _app_open: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

# App
var _app_panel: PanelContainer
var _app_subtitle: Label
var _app_rating: Label
var _offers_box: VBoxContainer
var _refresh_button: Button
var _cancel_button: Button

# HUD do pedido ativo
var _order_panel: PanelContainer
var _order_title: Label
var _order_target: Label
var _order_info: Label
var _integrity_label: Label
var _integrity_bar: ProgressBar
var _integrity_fill: StyleBoxFlat
var _hint_label: Label
var _message_label: Label
var _message_timer: float = 0.0

# Resumo da entrega
var _result_panel: PanelContainer
var _result_title: Label
var _result_summary: Label
var _result_pay: Label
var _result_tip: Label
var _result_total: Label
var _result_stars: Label
var _result_comment: Label
var _result_timer: float = 0.0

func _ready() -> void:
	layer = 10
	_build_hud()
	_build_result()
	_build_app()

	DeliveryManager.offers_changed.connect(_refresh_app)
	DeliveryManager.order_accepted.connect(_on_order_accepted)
	DeliveryManager.order_picked_up.connect(_on_order_picked_up)
	DeliveryManager.order_completed.connect(_on_order_completed)
	DeliveryManager.order_cancelled.connect(_on_order_cancelled)
	DeliveryManager.integrity_damaged.connect(_on_integrity_damaged)

	_refresh_app()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == OPEN_KEY:
		if _app_open:
			_close_app()
		else:
			_open_app()
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------
# Abrir / fechar o app
# ------------------------------------------------------------------

func _open_app() -> void:
	_app_open = true
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if not DeliveryManager.is_busy() and DeliveryManager.offers.is_empty():
		DeliveryManager.generate_offers()
	_refresh_app()
	_app_panel.visible = true

func _close_app() -> void:
	_app_open = false
	_app_panel.visible = false
	if _previous_mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ------------------------------------------------------------------
# Construção da interface (feita por código, sem cena)
# ------------------------------------------------------------------

func _build_hud() -> void:
	# Painel do pedido ativo (embaixo à esquerda)
	_order_panel = PanelContainer.new()
	_order_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_order_panel.add_theme_stylebox_override("panel", _make_style(Color(0.08, 0.08, 0.1, 0.85), 14))
	_order_panel.anchor_left = 0.0
	_order_panel.anchor_right = 0.0
	_order_panel.anchor_top = 1.0
	_order_panel.anchor_bottom = 1.0
	_order_panel.offset_left = 30.0
	_order_panel.offset_right = 470.0
	_order_panel.offset_top = -270.0
	_order_panel.offset_bottom = -60.0
	_order_panel.visible = false
	add_child(_order_panel)

	var box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	_order_panel.add_child(box)

	_order_title = _make_label(26, Color.WHITE)
	_order_target = _make_label(20, Color(1.0, 0.85, 0.4))
	_order_info = _make_label(20, Color.WHITE)
	_integrity_label = _make_label(20, Color(0.8, 1.0, 0.8))
	box.add_child(_order_title)
	box.add_child(_order_target)
	box.add_child(_order_info)
	box.add_child(_integrity_label)

	_integrity_bar = ProgressBar.new()
	_integrity_bar.min_value = 0.0
	_integrity_bar.max_value = 100.0
	_integrity_bar.value = 100.0
	_integrity_bar.show_percentage = false
	_integrity_bar.custom_minimum_size = Vector2(0.0, 18.0)
	_integrity_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_background = _make_style(Color(0.2, 0.2, 0.24), 6)
	bar_background.set_content_margin_all(0.0)
	_integrity_fill = _make_style(Color(0.3, 0.9, 0.4), 6)
	_integrity_fill.set_content_margin_all(0.0)
	_integrity_bar.add_theme_stylebox_override("background", bar_background)
	_integrity_bar.add_theme_stylebox_override("fill", _integrity_fill)
	box.add_child(_integrity_bar)

	# Dica + dinheiro + nota (embaixo no centro)
	_hint_label = _make_label(24, Color.WHITE)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 8)
	_hint_label.anchor_left = 0.5
	_hint_label.anchor_right = 0.5
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.offset_left = -400.0
	_hint_label.offset_right = 400.0
	_hint_label.offset_top = -50.0
	_hint_label.offset_bottom = -15.0
	add_child(_hint_label)

	# Mensagens rápidas (topo, no centro)
	_message_label = _make_label(34, Color.WHITE)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_message_label.add_theme_constant_override("outline_size", 10)
	_message_label.anchor_left = 0.5
	_message_label.anchor_right = 0.5
	_message_label.offset_left = -450.0
	_message_label.offset_right = 450.0
	_message_label.offset_top = 60.0
	_message_label.offset_bottom = 120.0
	_message_label.visible = false
	add_child(_message_label)

# Resumo que aparece quando a entrega termina
func _build_result() -> void:
	_result_panel = PanelContainer.new()
	_result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_theme_stylebox_override("panel", _make_style(Color(0.06, 0.1, 0.07, 0.94), 18))
	_result_panel.anchor_left = 0.5
	_result_panel.anchor_right = 0.5
	_result_panel.anchor_top = 0.0
	_result_panel.anchor_bottom = 0.0
	_result_panel.offset_left = -300.0
	_result_panel.offset_right = 300.0
	_result_panel.offset_top = 130.0
	_result_panel.offset_bottom = 420.0
	_result_panel.visible = false
	add_child(_result_panel)

	var box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	_result_panel.add_child(box)

	_result_title = _make_label(32, Color(0.4, 1.0, 0.5), "ENTREGA CONCLUÍDA")
	_result_summary = _make_label(20, Color.WHITE)
	_result_pay = _make_label(20, Color.WHITE)
	_result_tip = _make_label(20, Color(1.0, 0.85, 0.4))
	_result_total = _make_label(34, Color(0.4, 1.0, 0.5))
	_result_stars = _make_label(30, Color(1.0, 0.85, 0.2))
	_result_comment = _make_label(20, Color(0.85, 0.85, 0.9))
	box.add_child(_result_title)
	box.add_child(_result_summary)
	box.add_child(_result_pay)
	box.add_child(_result_tip)
	box.add_child(_result_total)
	box.add_child(_result_stars)
	box.add_child(_result_comment)

func _build_app() -> void:
	_app_panel = PanelContainer.new()
	_app_panel.add_theme_stylebox_override("panel", _make_style(Color(0.1, 0.1, 0.13, 0.97), 22))
	_app_panel.anchor_left = 0.5
	_app_panel.anchor_right = 0.5
	_app_panel.anchor_top = 0.5
	_app_panel.anchor_bottom = 0.5
	_app_panel.offset_left = -300.0
	_app_panel.offset_right = 300.0
	_app_panel.offset_top = -300.0
	_app_panel.offset_bottom = 300.0
	_app_panel.visible = false
	add_child(_app_panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_app_panel.add_child(root)

	root.add_child(_make_label(46, COLOR_ACCENT, "zFood"))
	_app_rating = _make_label(20, Color(1.0, 0.85, 0.2))
	root.add_child(_app_rating)
	_app_subtitle = _make_label(20, Color(0.7, 0.7, 0.75), "Pedidos disponíveis")
	root.add_child(_app_subtitle)

	_offers_box = VBoxContainer.new()
	_offers_box.add_theme_constant_override("separation", 10)
	_offers_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_offers_box)

	var buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	root.add_child(buttons)

	_refresh_button = _make_button("Atualizar pedidos")
	_refresh_button.pressed.connect(_on_refresh_pressed)
	buttons.add_child(_refresh_button)

	_cancel_button = _make_button("Cancelar entrega")
	_cancel_button.pressed.connect(_on_cancel_pressed)
	buttons.add_child(_cancel_button)

	var close_button = _make_button("Fechar [P]")
	close_button.pressed.connect(_close_app)
	buttons.add_child(close_button)

# Reconstrói a lista de pedidos do app
func _refresh_app() -> void:
	if _offers_box == null:
		return

	for child in _offers_box.get_children():
		_offers_box.remove_child(child)
		child.queue_free()

	_app_rating.text = _rating_text()

	if DeliveryManager.is_busy():
		_app_subtitle.text = "Você tem uma entrega em andamento"
		_offers_box.add_child(_make_label(22, Color.WHITE, "Termine a entrega atual (ou cancele) para ver novos pedidos."))
	else:
		_app_subtitle.text = "Pedidos disponíveis"
		if DeliveryManager.offers.is_empty():
			_offers_box.add_child(_make_label(22, Color.WHITE, "Nenhum pedido agora. Toque em Atualizar."))
		for order in DeliveryManager.offers:
			_offers_box.add_child(_make_offer_card(order))

	_refresh_button.disabled = DeliveryManager.is_busy()
	_cancel_button.visible = DeliveryManager.is_busy()

func _make_offer_card(order: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_style(Color(0.17, 0.17, 0.21), 14))

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	info.add_child(_make_label(24, Color.WHITE, "%s  •  R$ %.2f" % [order["food"], order["reward"]]))
	info.add_child(_make_label(18, Color(0.8, 0.8, 0.85), "Retirar: %s" % order["pickup_name"]))
	info.add_child(_make_label(18, Color(0.8, 0.8, 0.85), "Entregar para %s: %s" % [order["customer"], order["dropoff_name"]]))
	info.add_child(_make_label(18, Color(1.0, 0.85, 0.4), "%d m  •  prazo %s" % [roundi(order["distance"]), _format_time(order["time_limit"])]))

	var accept = _make_button("Aceitar")
	accept.custom_minimum_size = Vector2(130.0, 0.0)
	accept.pressed.connect(_on_accept_pressed.bind(order["id"]))
	row.add_child(accept)

	return card

# ------------------------------------------------------------------
# Botões e avisos
# ------------------------------------------------------------------

func _on_accept_pressed(order_id: int) -> void:
	DeliveryManager.accept_order(order_id)
	_close_app()

func _on_refresh_pressed() -> void:
	DeliveryManager.generate_offers()

func _on_cancel_pressed() -> void:
	DeliveryManager.cancel_order()

func _on_order_accepted(order: Dictionary) -> void:
	_show_message("Pedido aceito! Vá até %s" % order["pickup_name"], Color(1.0, 0.8, 0.3))

func _on_order_picked_up(order: Dictionary) -> void:
	_show_message("Pedido coletado! Entregue para %s" % order["customer"], Color(0.4, 1.0, 0.5))

# Mostra o resumo: pagamento pela integridade, gorjeta e avaliação do cliente
func _on_order_completed(order: Dictionary, result: Dictionary) -> void:
	_result_summary.text = "%s  •  integridade %d%% (%s)" % [order["food"], roundi(result["integrity"]), result["tier_name"]]
	_result_pay.text = "Pagamento: R$ %.2f  (%d%% de R$ %.2f)" % [result["payout"], roundi(result["factor"] * 100.0), result["base_reward"]]

	if result["tip"] > 0.0:
		_result_tip.text = "Gorjeta de %s: R$ %.2f" % [order["customer"], result["tip"]]
	else:
		_result_tip.text = "%s não deixou gorjeta" % order["customer"]

	_result_total.text = "TOTAL  R$ %.2f" % result["total"]

	var stars: int = result["stars"]
	_result_stars.text = "%s%s   (%d/5)" % ["★".repeat(stars), "☆".repeat(5 - stars), stars]
	_result_comment.text = "\"%s\"  —  %s" % [result["comment"], order["customer"]]

	_result_panel.visible = true
	_result_timer = RESULT_SECONDS

func _on_order_cancelled(_order: Dictionary) -> void:
	_show_message("Entrega cancelada", Color(1.0, 0.4, 0.3))

func _on_integrity_damaged(amount: float, reason: String) -> void:
	var text = "-%d%% integridade" % roundi(amount)
	if reason != "":
		text += "  (%s)" % reason
	_show_message(text, Color(1.0, 0.55, 0.2))

func _show_message(text: String, color: Color) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
	_message_label.visible = true
	_message_timer = 3.0

# ------------------------------------------------------------------
# Atualização do HUD a cada quadro
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if _hint_label == null:
		return

	_message_timer = maxf(_message_timer - delta, 0.0)
	if _message_timer <= 0.0:
		_message_label.visible = false

	_result_timer = maxf(_result_timer - delta, 0.0)
	if _result_timer <= 0.0:
		_result_panel.visible = false

	_hint_label.text = "R$ %.2f   •   %s   •   [P] zFood" % [DeliveryManager.money, _rating_text(true)]

	var active = DeliveryManager.is_busy()
	_order_panel.visible = active
	if not active:
		return

	var order = DeliveryManager.active_order
	_order_title.text = "%s  •  R$ %.2f" % [order["food"], order["reward"]]

	if DeliveryManager.is_carrying():
		_order_target.text = "Entregar para %s\n%s" % [order["customer"], order["dropoff_name"]]
	else:
		_order_target.text = "Retirar em:\n%s" % order["pickup_name"]

	var distance_text = "--"
	if DeliveryManager.distance_to_target >= 0.0:
		distance_text = "%d m" % roundi(DeliveryManager.distance_to_target)

	if DeliveryManager.time_left >= 0.0:
		_order_info.text = "Faltam: %s   •   Prazo: %s" % [distance_text, _format_time(DeliveryManager.time_left)]
		_order_info.add_theme_color_override("font_color", Color.WHITE)
	else:
		_order_info.text = "Faltam: %s   •   ATRASADO %s" % [distance_text, _format_time(-DeliveryManager.time_left)]
		_order_info.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))

	# Integridade só aparece depois de coletar o pedido
	var carrying = DeliveryManager.is_carrying()
	_integrity_label.visible = carrying
	_integrity_bar.visible = carrying
	if carrying:
		var value = DeliveryManager.integrity
		_integrity_label.text = "Integridade da comida: %d%%" % roundi(value)
		_integrity_bar.value = value
		if value > 60.0:
			_integrity_fill.bg_color = Color(0.3, 0.9, 0.4)
		elif value > 30.0:
			_integrity_fill.bg_color = Color(1.0, 0.8, 0.2)
		else:
			_integrity_fill.bg_color = Color(1.0, 0.3, 0.25)

# ------------------------------------------------------------------
# Utilitários de interface
# ------------------------------------------------------------------

# Nota do entregador. short = versão curta (para a linha de baixo da tela)
func _rating_text(short: bool = false) -> String:
	if DeliveryManager.rating_count == 0:
		if short:
			return "★ --"
		return "Sua nota: sem avaliações ainda"
	var average = DeliveryManager.get_rating_average()
	if short:
		return "★ %.1f" % average
	return "Sua nota: ★ %.1f  (%d entregas)" % [average, DeliveryManager.rating_count]

func _make_style(color: Color, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(16.0)
	return style

func _make_label(font_size: int, color: Color, text: String = "") -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.focus_mode = Control.FOCUS_NONE   # evita que Espaço/Enter "apertem" o botão por engano
	return button

func _format_time(seconds: float) -> String:
	var total = maxi(roundi(seconds), 0)
	return "%d:%02d" % [floori(float(total) / 60.0), total % 60]
