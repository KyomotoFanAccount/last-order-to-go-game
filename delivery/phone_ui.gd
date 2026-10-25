class_name PhoneUI
extends Control
# Celular do entregador, estilo Android / GTA V (canto inferior direito da tela).
# Apps: zFood (pedidos), Z Casino (só visual) e Calculadora (funcional).
# Botões de baixo: ◀ voltar  |  ● início  |  ■ apps recentes
# Quem abre e fecha o celular é o zfood_hud.gd (tecla P). Tudo é construído por código.

signal closed   # avisa o HUD quando o celular fecha (para devolver o mouse ao jogo)

const PHONE_W: float = 340.0
const PHONE_H: float = 680.0
const MARGIN: float = 24.0              # distância da borda da tela
const BEZEL: float = 12.0               # moldura preta em volta da tela
const STATUS_H: float = 30.0            # barra de cima (hora, sinal, bateria)
const NAV_H: float = 52.0               # barra de baixo (3 botões)
const SCREEN_W: float = PHONE_W - BEZEL * 2.0
const SCREEN_H: float = PHONE_H - BEZEL * 2.0
const SCREEN_RADIUS: int = 34
const HIDDEN_SLIDE: float = 1000.0      # quanto o celular desce para sumir da tela

const ZF_RED: Color = Color(0.918, 0.114, 0.173)
const CALC_MAX_DIGITS: int = 11
const CALC_KEYS: Array[String] = ["C", "⌫", "%", "÷", "7", "8", "9", "×", "4", "5", "6", "−", "1", "2", "3", "+", "±", "0", ".", "="]
const CASINO_SYMBOLS: Array[String] = ["7", "BAR", "★", "◆", "$"]
const APP_ORDER: Array[String] = ["zfood", "casino", "calc"]
const APP_INFO: Dictionary = {
	"zfood": {"name": "zFood", "glyph": "z", "color": Color(0.918, 0.114, 0.173)},
	"casino": {"name": "Z Casino", "glyph": "7", "color": Color(0.45, 0.2, 0.75)},
	"calc": {"name": "Calculadora", "glyph": "÷", "color": Color(0.15, 0.6, 0.45)},
}
const STATUS_COLORS: Dictionary = {
	"home": Color(0.07, 0.09, 0.2),
	"zfood": Color(0.918, 0.114, 0.173),
	"casino": Color(0.12, 0.05, 0.2),
	"calc": Color(0.125, 0.129, 0.141),
	"recents": Color(0.08, 0.08, 0.1),
}

var is_open: bool = false
var _tween: Tween = null
var _page: String = "home"
var _recent_apps: Array[String] = []
var _pages: Dictionary = {}
var _bold_font: SystemFont = null

# Estrutura do celular
var _screen: Panel
var _status_panel: Panel
var _status_clock: Label
var _content: Control
var _nav_panel: Panel

# Tela inicial e apps recentes
var _home_clock: Label
var _home_date: Label
var _recents_box: VBoxContainer

# zFood
var _zf_status: Label
var _zf_offers_section: VBoxContainer
var _zf_offers_box: VBoxContainer
var _zf_active_box: VBoxContainer
var _zf_active_title: Label
var _zf_active_target: Label
var _zf_active_info: Label
var _zf_int_label: Label
var _zf_int_bar: ProgressBar
var _zf_int_fill: StyleBoxFlat

# Z Casino
var _casino_reels: Array[Label] = []
var _casino_message: Label

# Calculadora
var _calc_tokens: Array = []              # número, operador, número, operador...
var _calc_input: String = ""              # o que está sendo digitado
var _calc_just_evaluated: bool = false
var _calc_error: bool = false
var _calc_expression_text: String = ""
var _calc_expression_label: Label
var _calc_result_label: Label

func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	_set_slide(HIDDEN_SLIDE)
	pivot_offset = Vector2(PHONE_W, PHONE_H)   # o tamanho muda a partir do canto inferior direito
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_build_frame()
	_build_home()
	_build_zfood()
	_build_casino()
	_build_calc()
	_build_recents()
	_build_status_bar()
	_build_nav_bar()

	DeliveryManager.offers_changed.connect(_refresh_zfood)

	get_viewport().size_changed.connect(_update_scale)
	_update_scale()
	_show_page("home")

# Ajusta o tamanho do celular ao tamanho da janela
func _update_scale() -> void:
	var viewport_height = get_viewport().get_visible_rect().size.y
	var factor = clampf(viewport_height * 0.88 / (PHONE_H + MARGIN), 0.5, 1.3)
	scale = Vector2(factor, factor)

func _set_slide(slide: float) -> void:
	offset_left = -(PHONE_W + MARGIN)
	offset_right = -MARGIN
	offset_top = -(PHONE_H + MARGIN) + slide
	offset_bottom = -MARGIN + slide

# ------------------------------------------------------------------
# Abrir / fechar (com animação de subir e descer)
# ------------------------------------------------------------------

func open_phone() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_show_page(_page)
	_slide_to(0.0)

func close_phone() -> void:
	if not is_open:
		return
	is_open = false
	var tween = _slide_to(HIDDEN_SLIDE)
	tween.finished.connect(_on_close_finished)
	closed.emit()

func _on_close_finished() -> void:
	if not is_open:
		visible = false

func _slide_to(slide: float) -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "offset_top", -(PHONE_H + MARGIN) + slide, 0.3)
	_tween.tween_property(self, "offset_bottom", -MARGIN + slide, 0.3)
	return _tween

# ------------------------------------------------------------------
# Atualização a cada quadro (relógio e pedido ativo)
# ------------------------------------------------------------------

func _process(_delta: float) -> void:
	if not is_open:
		return

	var now = Time.get_datetime_dict_from_system()
	var clock_text = "%02d:%02d" % [now["hour"], now["minute"]]
	_status_clock.text = clock_text
	_home_clock.text = clock_text
	_home_date.text = "%02d/%02d/%d" % [now["day"], now["month"], now["year"]]

	_zf_status.text = "R$ %.2f  •  %s" % [DeliveryManager.money, _rating_text()]
	if _page == "zfood" and DeliveryManager.is_busy():
		_update_zfood_active()

# ------------------------------------------------------------------
# Moldura, barra de cima e barra de baixo
# ------------------------------------------------------------------

func _build_frame() -> void:
	var body = Panel.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_theme_stylebox_override("panel", _style(Color(0.04, 0.04, 0.05), 46, 0.0, 0.0, Color(0.3, 0.3, 0.35), 3))
	add_child(body)

	_screen = Panel.new()
	_screen.position = Vector2(BEZEL, BEZEL)
	_screen.size = Vector2(SCREEN_W, SCREEN_H)
	_screen.clip_contents = true
	_screen.add_theme_stylebox_override("panel", _style(Color(0.1, 0.1, 0.14), SCREEN_RADIUS))
	add_child(_screen)

	_content = Control.new()
	_content.position = Vector2(0.0, STATUS_H)
	_content.size = Vector2(SCREEN_W, SCREEN_H - STATUS_H - NAV_H)
	_content.clip_contents = true
	_screen.add_child(_content)

func _build_status_bar() -> void:
	_status_panel = Panel.new()
	_status_panel.position = Vector2.ZERO
	_status_panel.size = Vector2(SCREEN_W, STATUS_H)
	_screen.add_child(_status_panel)

	_status_clock = _label("00:00", 15, Color.WHITE, true)
	_status_clock.position = Vector2(20.0, 4.0)
	_status_panel.add_child(_status_clock)

	var right = _label("4G  87%", 14, Color.WHITE)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -130.0
	right.offset_right = -20.0
	right.offset_top = 5.0
	_status_panel.add_child(right)

func _build_nav_bar() -> void:
	_nav_panel = Panel.new()
	_nav_panel.position = Vector2(0.0, SCREEN_H - NAV_H)
	_nav_panel.size = Vector2(SCREEN_W, NAV_H)
	_nav_panel.add_theme_stylebox_override("panel", _style_bottom(Color(0.0, 0.0, 0.0), SCREEN_RADIUS))
	_screen.add_child(_nav_panel)

	var row = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	_nav_panel.add_child(row)

	var back = _nav_button("◀")
	back.pressed.connect(_on_back)
	row.add_child(back)

	var home = _nav_button("●")
	home.pressed.connect(_show_page.bind("home"))
	row.add_child(home)

	var recents = _nav_button("■")
	recents.pressed.connect(_on_recents)
	row.add_child(recents)

func _nav_button(glyph: String) -> Button:
	var button = Button.new()
	button.text = glyph
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.6, 0.6, 0.6))
	return button

# Voltar: dentro de um app volta para o início; no início fecha o celular
func _on_back() -> void:
	if _page == "home":
		close_phone()
	else:
		_show_page("home")

func _on_recents() -> void:
	if _page == "recents":
		_show_page("home")
	else:
		_show_page("recents")

# Troca a página que aparece na tela
func _show_page(page_name: String) -> void:
	_page = page_name
	for key in _pages:
		_pages[key].visible = (key == page_name)

	var status_color: Color = STATUS_COLORS.get(page_name, Color(0.07, 0.09, 0.2))
	_status_panel.add_theme_stylebox_override("panel", _style_top(status_color, SCREEN_RADIUS))

	if page_name == "zfood":
		if not DeliveryManager.is_busy() and DeliveryManager.offers.is_empty():
			DeliveryManager.generate_offers()   # isso já atualiza a lista
		else:
			_refresh_zfood()
	elif page_name == "recents":
		_refresh_recents()

func _open_app(app_id: String) -> void:
	_recent_apps.erase(app_id)
	_recent_apps.push_front(app_id)
	while _recent_apps.size() > 4:
		_recent_apps.pop_back()
	_show_page(app_id)

# ------------------------------------------------------------------
# Tela inicial (ícones dos apps)
# ------------------------------------------------------------------

func _build_home() -> void:
	var page = _new_page("home", Color(0.07, 0.09, 0.2))

	_home_clock = _label("00:00", 60, Color.WHITE, true)
	_home_clock.position = Vector2(24.0, 24.0)
	page.add_child(_home_clock)

	_home_date = _label("", 18, Color(0.8, 0.82, 0.95))
	_home_date.position = Vector2(28.0, 96.0)
	page.add_child(_home_date)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(14.0, 170.0)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 18)
	page.add_child(grid)

	for app_id in APP_ORDER:
		var info: Dictionary = APP_INFO[app_id]
		grid.add_child(_make_app_icon(app_id, info["glyph"], info["name"], info["color"]))

func _make_app_icon(app_id: String, glyph: String, app_name: String, color: Color) -> Control:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(68.0, 0.0)
	box.add_theme_constant_override("separation", 6)

	var button = Button.new()
	button.text = glyph
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(58.0, 58.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, 16))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.15), 16))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.2), 16))
	button.pressed.connect(_open_app.bind(app_id))
	box.add_child(button)

	var name_label = _label(app_name, 13, Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	return box

# ------------------------------------------------------------------
# Apps recentes
# ------------------------------------------------------------------

func _build_recents() -> void:
	var page = _new_page("recents", Color(0.08, 0.08, 0.1))
	var box = _new_margin_box(page, 16)

	box.add_child(_label("Apps recentes", 24, Color.WHITE, true))

	_recents_box = VBoxContainer.new()
	_recents_box.add_theme_constant_override("separation", 10)
	_recents_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_recents_box)

	var clear = _make_button("Limpar tudo", Color(0.25, 0.25, 0.3))
	clear.pressed.connect(_on_clear_recents)
	box.add_child(clear)

func _on_clear_recents() -> void:
	_recent_apps.clear()
	_refresh_recents()

func _refresh_recents() -> void:
	for child in _recents_box.get_children():
		_recents_box.remove_child(child)
		child.queue_free()

	if _recent_apps.is_empty():
		_recents_box.add_child(_label("Nenhum app recente", 16, Color(0.6, 0.6, 0.65)))
		return

	for app_id in _recent_apps:
		var info: Dictionary = APP_INFO[app_id]
		var button = _make_button("%s    %s" % [info["glyph"], info["name"]], info["color"])
		button.pressed.connect(_open_app.bind(app_id))
		_recents_box.add_child(button)

# ------------------------------------------------------------------
# App zFood (visual inspirado no iFood, com "z")
# ------------------------------------------------------------------

func _build_zfood() -> void:
	var page = _new_page("zfood", Color(0.965, 0.965, 0.972))

	var column = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	page.add_child(column)

	# Cabeçalho vermelho com logo e busca
	var header = PanelContainer.new()
	header.add_theme_stylebox_override("panel", _style(ZF_RED, 0, 14.0, 10.0))
	column.add_child(header)

	var header_box = VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 10)
	header.add_child(header_box)

	var top_row = HBoxContainer.new()
	header_box.add_child(top_row)
	top_row.add_child(_label("zfood", 32, Color.WHITE, true))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	_zf_status = _label("R$ 0.00  •  ★ --", 13, Color.WHITE)
	_zf_status.size_flags_vertical = Control.SIZE_SHRINK_END
	top_row.add_child(_zf_status)

	var search = PanelContainer.new()
	search.mouse_filter = Control.MOUSE_FILTER_PASS
	search.add_theme_stylebox_override("panel", _style(Color.WHITE, 22, 14.0, 9.0))
	search.add_child(_label("Busque por item ou loja", 14, Color(0.55, 0.55, 0.6)))
	header_box.add_child(search)

	# Conteúdo com rolagem
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)

	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)

	# Categorias (só enfeite, como no app de verdade)
	var chips = HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	body.add_child(chips)
	var chip_names = ["Restaurantes", "Mercado", "Farmácia", "Bebidas"]
	for i in chip_names.size():
		var selected = (i == 0)
		var chip = PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		if selected:
			chip.add_theme_stylebox_override("panel", _style(Color(1.0, 0.9, 0.91), 16, 9.0, 5.0, ZF_RED, 1))
		else:
			chip.add_theme_stylebox_override("panel", _style(Color.WHITE, 16, 9.0, 5.0, Color(0.85, 0.85, 0.88), 1))
		var chip_color = ZF_RED if selected else Color(0.4, 0.4, 0.45)
		chip.add_child(_label(chip_names[i], 12, chip_color))
		chips.add_child(chip)

	# Pedidos disponíveis
	_zf_offers_section = VBoxContainer.new()
	_zf_offers_section.add_theme_constant_override("separation", 10)
	body.add_child(_zf_offers_section)

	_zf_offers_section.add_child(_label("Pedidos para você", 18, Color(0.1, 0.1, 0.12), true))
	_zf_offers_box = VBoxContainer.new()
	_zf_offers_box.add_theme_constant_override("separation", 10)
	_zf_offers_section.add_child(_zf_offers_box)

	var refresh = _make_button("Atualizar pedidos", Color(1.0, 1.0, 1.0), ZF_RED)
	refresh.pressed.connect(_on_zf_refresh)
	_zf_offers_section.add_child(refresh)

	# Entrega em andamento
	_zf_active_box = VBoxContainer.new()
	_zf_active_box.add_theme_constant_override("separation", 10)
	body.add_child(_zf_active_box)

	var active_card = PanelContainer.new()
	active_card.mouse_filter = Control.MOUSE_FILTER_PASS
	active_card.add_theme_stylebox_override("panel", _style(Color.WHITE, 16, 14.0, 14.0, ZF_RED, 2))
	_zf_active_box.add_child(active_card)

	var active_column = VBoxContainer.new()
	active_column.add_theme_constant_override("separation", 6)
	active_card.add_child(active_column)

	active_column.add_child(_label("ENTREGA EM ANDAMENTO", 12, ZF_RED, true))
	_zf_active_title = _label("", 20, Color(0.1, 0.1, 0.12), true)
	_zf_active_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_zf_active_title.clip_text = true
	active_column.add_child(_zf_active_title)
	_zf_active_target = _label("", 15, Color(0.15, 0.15, 0.18))
	active_column.add_child(_zf_active_target)
	_zf_active_info = _label("", 14, Color(0.4, 0.4, 0.45))
	active_column.add_child(_zf_active_info)
	_zf_int_label = _label("", 14, Color(0.1, 0.5, 0.25))
	active_column.add_child(_zf_int_label)

	_zf_int_bar = ProgressBar.new()
	_zf_int_bar.min_value = 0.0
	_zf_int_bar.max_value = 100.0
	_zf_int_bar.value = 100.0
	_zf_int_bar.show_percentage = false
	_zf_int_bar.custom_minimum_size = Vector2(0.0, 14.0)
	var bar_background = _style(Color(0.88, 0.88, 0.9), 6)
	_zf_int_fill = _style(Color(0.3, 0.8, 0.4), 6)
	_zf_int_bar.add_theme_stylebox_override("background", bar_background)
	_zf_int_bar.add_theme_stylebox_override("fill", _zf_int_fill)
	active_column.add_child(_zf_int_bar)

	var cancel = _make_button("Cancelar entrega", Color(1.0, 1.0, 1.0), ZF_RED)
	cancel.pressed.connect(_on_zf_cancel)
	_zf_active_box.add_child(cancel)

# Reconstrói a lista de pedidos
func _refresh_zfood() -> void:
	if _zf_offers_box == null:
		return

	for child in _zf_offers_box.get_children():
		_zf_offers_box.remove_child(child)
		child.queue_free()

	var busy = DeliveryManager.is_busy()
	_zf_active_box.visible = busy
	_zf_offers_section.visible = not busy
	if busy:
		_update_zfood_active()
		return

	if DeliveryManager.offers.is_empty():
		_zf_offers_box.add_child(_label("Nenhum pedido agora. Toque em Atualizar.", 14, Color(0.4, 0.4, 0.45)))
	for order in DeliveryManager.offers:
		_zf_offers_box.add_child(_make_offer_card(order))

# Cartão de um pedido (parecido com a lista de lojas do iFood)
func _make_offer_card(order: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel", _style(Color.WHITE, 16, 12.0, 12.0, Color(0.9, 0.9, 0.92), 1))

	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	row.add_child(_make_avatar(order["pickup_name"]))

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	row.add_child(info)

	var name_label = _label(order["pickup_name"], 17, Color(0.1, 0.1, 0.12), true)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	info.add_child(name_label)

	var food_label = _label("★ %.1f  •  %s" % [_fake_rating(order["pickup_name"]), order["food"]], 13, Color(0.45, 0.45, 0.5))
	food_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	food_label.clip_text = true
	info.add_child(food_label)

	var to_label = _label("Entregar em: %s" % order["dropoff_name"], 13, Color(0.45, 0.45, 0.5))
	to_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	to_label.clip_text = true
	info.add_child(to_label)

	info.add_child(_label("%d m  •  prazo %s" % [roundi(order["distance"]), _format_time(order["time_limit"])], 13, Color(0.45, 0.45, 0.5)))

	var bottom = HBoxContainer.new()
	column.add_child(bottom)

	var price = _label("R$ %.2f" % order["reward"], 20, Color(0.1, 0.6, 0.3), true)
	price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(price)

	var accept = _make_button("Aceitar", ZF_RED)
	accept.pressed.connect(_on_accept.bind(order["id"]))
	bottom.add_child(accept)

	return card

func _on_accept(order_id: int) -> void:
	DeliveryManager.accept_order(order_id)
	close_phone()

func _on_zf_refresh() -> void:
	DeliveryManager.generate_offers()

func _on_zf_cancel() -> void:
	DeliveryManager.cancel_order()
	DeliveryManager.generate_offers()

# Atualiza os textos da entrega em andamento
func _update_zfood_active() -> void:
	var order = DeliveryManager.active_order
	if order.is_empty():
		return

	_zf_active_title.text = "%s  •  R$ %.2f" % [order["food"], order["reward"]]

	if DeliveryManager.is_carrying():
		_zf_active_target.text = "Entregar para %s\n%s" % [order["customer"], order["dropoff_name"]]
	else:
		_zf_active_target.text = "Retirar em:\n%s" % order["pickup_name"]

	var distance_text = "--"
	if DeliveryManager.distance_to_target >= 0.0:
		distance_text = "%d m" % roundi(DeliveryManager.distance_to_target)
	if DeliveryManager.time_left >= 0.0:
		_zf_active_info.text = "Faltam %s  •  Prazo %s" % [distance_text, _format_time(DeliveryManager.time_left)]
	else:
		_zf_active_info.text = "Faltam %s  •  ATRASADO %s" % [distance_text, _format_time(-DeliveryManager.time_left)]

	var carrying = DeliveryManager.is_carrying()
	_zf_int_label.visible = carrying
	_zf_int_bar.visible = carrying
	if carrying:
		var value = DeliveryManager.integrity
		_zf_int_label.text = "Integridade da comida: %d%%" % roundi(value)
		_zf_int_bar.value = value
		if value > 60.0:
			_zf_int_fill.bg_color = Color(0.3, 0.8, 0.4)
		elif value > 30.0:
			_zf_int_fill.bg_color = Color(1.0, 0.75, 0.2)
		else:
			_zf_int_fill.bg_color = Color(0.95, 0.3, 0.25)

# Bolinha colorida com a letra da loja
func _make_avatar(shop_name: String) -> Control:
	var colors = [Color(0.91, 0.3, 0.24), Color(0.95, 0.61, 0.07), Color(0.15, 0.68, 0.38), Color(0.16, 0.5, 0.73), Color(0.56, 0.27, 0.68), Color(0.09, 0.63, 0.52)]
	var avatar = Panel.new()
	avatar.custom_minimum_size = Vector2(52.0, 52.0)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	avatar.mouse_filter = Control.MOUSE_FILTER_PASS
	avatar.add_theme_stylebox_override("panel", _style(colors[absi(shop_name.hash()) % colors.size()], 26))

	var last_word = shop_name.get_slice(" ", shop_name.get_slice_count(" ") - 1)
	var letter = _label(last_word.substr(0, 1).to_upper(), 26, Color.WHITE, true)
	letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(letter)
	return avatar

# Nota "de enfeite" da loja (sempre a mesma para o mesmo nome)
func _fake_rating(seed_text: String) -> float:
	return 4.2 + float(absi(seed_text.hash()) % 8) / 10.0

func _rating_text() -> String:
	if DeliveryManager.rating_count == 0:
		return "★ --"
	return "★ %.1f" % DeliveryManager.get_rating_average()

# ------------------------------------------------------------------
# App Z Casino (só visual: sem dinheiro de verdade)
# ------------------------------------------------------------------

func _build_casino() -> void:
	var page = _new_page("casino", Color(0.12, 0.05, 0.2))
	var box = _new_margin_box(page, 16)
	box.add_theme_constant_override("separation", 12)

	var gold = Color(1.0, 0.82, 0.25)
	box.add_child(_label("Z CASINO", 30, gold, true))
	box.add_child(_label("Modo demonstração  •  sem dinheiro de verdade", 12, Color(0.75, 0.65, 0.9)))

	var balance = PanelContainer.new()
	balance.add_theme_stylebox_override("panel", _style(Color(0.2, 0.1, 0.32), 14, 14.0, 10.0))
	balance.add_child(_label("Saldo demo:  R$ 1.000,00", 18, Color.WHITE))
	box.add_child(balance)

	var machine = PanelContainer.new()
	machine.add_theme_stylebox_override("panel", _style(Color(0.08, 0.03, 0.14), 18, 14.0, 14.0, gold, 3))
	box.add_child(machine)

	var machine_column = VBoxContainer.new()
	machine_column.add_theme_constant_override("separation", 12)
	machine.add_child(machine_column)

	var reels = HBoxContainer.new()
	reels.alignment = BoxContainer.ALIGNMENT_CENTER
	reels.add_theme_constant_override("separation", 8)
	machine_column.add_child(reels)
	var start_symbols = ["7", "7", "7"]
	for i in 3:
		var reel = PanelContainer.new()
		reel.custom_minimum_size = Vector2(78.0, 88.0)
		reel.add_theme_stylebox_override("panel", _style(Color(0.96, 0.95, 0.9), 12, 4.0, 4.0))
		var symbol = _label(start_symbols[i], 34, Color(0.75, 0.1, 0.15), true)
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		symbol.size_flags_vertical = Control.SIZE_EXPAND_FILL
		reel.add_child(symbol)
		reels.add_child(reel)
		_casino_reels.append(symbol)

	var spin = _make_button("GIRAR", gold, Color(0.2, 0.1, 0.0))
	spin.pressed.connect(_casino_spin)
	machine_column.add_child(spin)

	_casino_message = _label("Boa sorte!", 16, Color(0.9, 0.85, 1.0))
	_casino_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_casino_message)

	var games = GridContainer.new()
	games.columns = 2
	games.add_theme_constant_override("h_separation", 8)
	games.add_theme_constant_override("v_separation", 8)
	box.add_child(games)
	for game_name in ["Roleta", "Blackjack", "Poker", "Bingo"]:
		var game_button = _make_button(game_name, Color(0.3, 0.15, 0.5))
		game_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		game_button.pressed.connect(_casino_soon.bind(game_name))
		games.add_child(game_button)

# Só sorteia símbolos (não mexe em dinheiro nenhum)
func _casino_spin() -> void:
	var results: Array[String] = []
	for reel in _casino_reels:
		var symbol: String = CASINO_SYMBOLS.pick_random()
		reel.text = symbol
		results.append(symbol)

	if results[0] == results[1] and results[1] == results[2]:
		_casino_message.text = "JACKPOT! (de mentirinha)"
	elif results[0] == results[1] or results[1] == results[2] or results[0] == results[2]:
		_casino_message.text = "Quase! Tente de novo."
	else:
		_casino_message.text = "Não foi dessa vez."

func _casino_soon(game_name: String) -> void:
	_casino_message.text = "%s: em breve!" % game_name

# ------------------------------------------------------------------
# Calculadora (+, −, ×, ÷, %, ±, decimais)
# ------------------------------------------------------------------

func _build_calc() -> void:
	var page = _new_page("calc", Color(0.125, 0.129, 0.141))

	var column = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	page.add_child(column)

	# Visor
	var display = PanelContainer.new()
	display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.add_theme_stylebox_override("panel", _style(Color(0.125, 0.129, 0.141), 0, 18.0, 12.0))
	column.add_child(display)

	var display_box = VBoxContainer.new()
	display_box.alignment = BoxContainer.ALIGNMENT_END
	display.add_child(display_box)

	_calc_expression_label = _label("", 18, Color(0.65, 0.66, 0.7))
	_calc_expression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_calc_expression_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_calc_expression_label.clip_text = true
	display_box.add_child(_calc_expression_label)

	_calc_result_label = _label("0", 44, Color.WHITE)
	_calc_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_calc_result_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_calc_result_label.clip_text = true
	display_box.add_child(_calc_result_label)

	# Teclas
	var keys_margin = MarginContainer.new()
	keys_margin.add_theme_constant_override("margin_left", 14)
	keys_margin.add_theme_constant_override("margin_right", 14)
	keys_margin.add_theme_constant_override("margin_top", 6)
	keys_margin.add_theme_constant_override("margin_bottom", 14)
	column.add_child(keys_margin)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	keys_margin.add_child(grid)

	for key in CALC_KEYS:
		var color = Color(0.2, 0.21, 0.23)
		if key in ["÷", "×", "−", "+"]:
			color = Color(0.25, 0.42, 0.8)
		elif key == "=":
			color = Color(0.95, 0.6, 0.15)
		elif key in ["C", "⌫", "%", "±"]:
			color = Color(0.32, 0.33, 0.37)

		var button = Button.new()
		button.text = key
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(66.0, 62.0)
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _style(color, 18))
		button.add_theme_stylebox_override("hover", _style(color.lightened(0.12), 18))
		button.add_theme_stylebox_override("pressed", _style(color.darkened(0.2), 18))
		button.pressed.connect(_on_calc_key.bind(key))
		grid.add_child(button)

	_calc_refresh()

func _on_calc_key(key: String) -> void:
	match key:
		"C":
			_calc_clear()
		"⌫":
			if _calc_just_evaluated or _calc_error:
				_calc_clear()
			elif _calc_input != "":
				_calc_input = _calc_input.left(_calc_input.length() - 1)
				if _calc_input == "-":
					_calc_input = ""
		"±":
			if _calc_error:
				_calc_clear()
			elif _calc_input != "" and _calc_input != "0":
				if _calc_input.begins_with("-"):
					_calc_input = _calc_input.substr(1)
				else:
					_calc_input = "-" + _calc_input
		"%":
			if _calc_error:
				_calc_clear()
			elif _calc_input != "":
				_calc_input = _calc_number_text(_calc_input.to_float() / 100.0)
		"+", "−", "×", "÷":
			if _calc_error:
				_calc_clear()
			_calc_operator(key)
		"=":
			_calc_equals()
		".":
			_calc_dot()
		_:
			_calc_digit(key)
	_calc_refresh()

func _calc_clear() -> void:
	_calc_tokens.clear()
	_calc_input = ""
	_calc_just_evaluated = false
	_calc_error = false
	_calc_expression_text = ""

func _calc_digit(digit: String) -> void:
	if _calc_error:
		_calc_clear()
	if _calc_just_evaluated:
		_calc_input = ""
		_calc_just_evaluated = false
	if _calc_input == "0":
		_calc_input = ""    # evita zero à esquerda
	if _calc_input.replace("-", "").replace(".", "").length() >= CALC_MAX_DIGITS:
		return
	_calc_input += digit

func _calc_dot() -> void:
	if _calc_error:
		_calc_clear()
	if _calc_just_evaluated:
		_calc_input = "0."
		_calc_just_evaluated = false
		return
	if "." in _calc_input:
		return
	if _calc_input == "":
		_calc_input = "0."
	elif _calc_input == "-":
		_calc_input = "-0."
	else:
		_calc_input += "."

func _calc_operator(op: String) -> void:
	if _calc_input != "":
		_calc_tokens.append(_calc_input.to_float())
		_calc_tokens.append(op)
		_calc_input = ""
		_calc_just_evaluated = false
	elif _calc_tokens.is_empty():
		_calc_tokens.append(0.0)       # operador sem número antes: começa de zero
		_calc_tokens.append(op)
	elif _calc_tokens.back() is String:
		_calc_tokens[_calc_tokens.size() - 1] = op    # troca o operador

func _calc_equals() -> void:
	if _calc_tokens.is_empty():
		return

	var tokens = _calc_tokens.duplicate()
	if _calc_input != "":
		tokens.append(_calc_input.to_float())
	elif tokens.back() is String:
		tokens.pop_back()      # tira o operador que sobrou no fim

	var expression_text = _tokens_text(tokens) + " ="
	var result = _calc_evaluate(tokens)
	_calc_tokens.clear()

	if is_inf(result) or is_nan(result) or absf(result) > 99999999999.0:
		_calc_error = true
		_calc_input = ""
		_calc_just_evaluated = false
		_calc_expression_text = ""
		return

	_calc_input = _calc_number_text(result)
	_calc_just_evaluated = true
	_calc_expression_text = expression_text

# Resolve × e ÷ primeiro e depois + e −
func _calc_evaluate(tokens: Array) -> float:
	var terms: Array = [tokens[0]]
	var signs: Array = []
	var i = 1
	while i < tokens.size() - 1:
		var op: String = tokens[i]
		var value: float = tokens[i + 1]
		if op == "×":
			terms[terms.size() - 1] = float(terms[terms.size() - 1]) * value
		elif op == "÷":
			if value == 0.0:
				return INF
			terms[terms.size() - 1] = float(terms[terms.size() - 1]) / value
		else:
			signs.append(op)
			terms.append(value)
		i += 2

	var total: float = terms[0]
	for j in signs.size():
		if signs[j] == "+":
			total += float(terms[j + 1])
		else:
			total -= float(terms[j + 1])
	return total

# Número -> texto (sem zeros sobrando)
func _calc_number_text(value: float) -> String:
	var snapped_value = snappedf(value, 0.000000001)
	if is_equal_approx(snapped_value, roundf(snapped_value)):
		return "%d" % int(roundf(snapped_value))
	return str(snapped_value)

func _tokens_text(tokens: Array) -> String:
	var text = ""
	for token in tokens:
		if token is String:
			text += " %s " % token
		else:
			text += _calc_number_text(float(token))
	return text.replace(".", ",")

func _calc_refresh() -> void:
	var shown = _calc_input
	if _calc_error:
		shown = "Erro"
	elif shown == "":
		shown = "0"
		if not _calc_tokens.is_empty():
			var last = _calc_tokens.back()
			if last is String and _calc_tokens.size() >= 2:
				last = _calc_tokens[_calc_tokens.size() - 2]
			shown = _calc_number_text(float(last))

	_calc_result_label.text = shown.replace(".", ",")

	if _calc_just_evaluated:
		_calc_expression_label.text = _calc_expression_text
	else:
		_calc_expression_label.text = _tokens_text(_calc_tokens)

# ------------------------------------------------------------------
# Utilitários de interface
# ------------------------------------------------------------------

# Cria uma página que ocupa toda a área entre a barra de cima e a de baixo
func _new_page(page_name: String, color: Color) -> Panel:
	var page = Panel.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_stylebox_override("panel", _style(color))
	page.visible = false
	_content.add_child(page)
	_pages[page_name] = page
	return page

# Caixa vertical com margem, dentro de uma página
func _new_margin_box(page: Control, margin_size: int) -> VBoxContainer:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	page.add_child(margin)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box

func _style(color: Color, radius: int = 0, margin_h: float = 0.0, margin_v: float = 0.0, border_color: Color = Color(0, 0, 0, 0), border_width: int = 0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_h
	style.content_margin_right = margin_h
	style.content_margin_top = margin_v
	style.content_margin_bottom = margin_v
	if border_width > 0:
		style.border_color = border_color
		style.set_border_width_all(border_width)
	return style

# Só os cantos de cima arredondados
func _style_top(color: Color, radius: int) -> StyleBoxFlat:
	var style = _style(color)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	return style

# Só os cantos de baixo arredondados
func _style_bottom(color: Color, radius: int) -> StyleBoxFlat:
	var style = _style(color)
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _label(text: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bold:
		label.add_theme_font_override("font", _get_bold_font())
	return label

func _get_bold_font() -> SystemFont:
	if _bold_font == null:
		_bold_font = SystemFont.new()
		_bold_font.font_names = PackedStringArray(["Segoe UI", "Arial", "Helvetica", "Sans-Serif"])
		_bold_font.font_weight = 800
	return _bold_font

# Botão arredondado. Com texto branco (padrão) o botão é preenchido com "color".
# Com outra cor de texto, o botão ganha contorno dessa cor (usado nos botões claros).
func _make_button(text: String, color: Color, text_color: Color = Color.WHITE) -> Button:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	if text_color == Color.WHITE:
		button.add_theme_stylebox_override("normal", _style(color, 18, 16.0, 8.0))
		button.add_theme_stylebox_override("hover", _style(color.lightened(0.12), 18, 16.0, 8.0))
		button.add_theme_stylebox_override("pressed", _style(color.darkened(0.2), 18, 16.0, 8.0))
	else:
		button.add_theme_stylebox_override("normal", _style(color, 18, 16.0, 8.0, text_color, 2))
		button.add_theme_stylebox_override("hover", _style(color.darkened(0.05), 18, 16.0, 8.0, text_color, 2))
		button.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), 18, 16.0, 8.0, text_color, 2))
	return button

func _format_time(seconds: float) -> String:
	var total = maxi(roundi(seconds), 0)
	return "%d:%02d" % [floori(float(total) / 60.0), total % 60]
