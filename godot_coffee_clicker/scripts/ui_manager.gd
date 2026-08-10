extends Control

class_name UIManager

@export var game_manager: GameManager
@export var dragon_sprite: Sprite2D
@export var beans_label: Label
@export var dracoins_label: Label
@export var dragon_level_label: Label
@export var click_power_label: Label
@export var bps_label: Label
@export var total_beans_label: Label
@export var total_clicks_label: Label
@export var play_time_label: Label

# Панели улучшений
@export var upgrades_container: VBoxContainer
@export var coffee_shop_container: VBoxContainer

# Вкладки
@export var plantation_tab: Button
@export var coffee_shop_tab: Button
@export var plantation_content: Control
@export var coffee_shop_content: Control

var current_batch_size: int = 1
var batch_sizes: Array = [1, 5, 10]


func _ready():
	if game_manager:
		game_manager.beans_changed.connect(_on_beans_changed)
		game_manager.dracoins_changed.connect(_on_dracoins_changed)
		game_manager.dragon_level_changed.connect(_on_dragon_level_changed)
		game_manager.ui_update_needed.connect(_on_ui_update_needed)
	
	setup_tabs()
	update_ui()


func setup_tabs():
	if plantation_tab:
		plantation_tab.pressed.connect(_on_plantation_tab_pressed)
	if coffee_shop_tab:
		coffee_shop_tab.pressed.connect(_on_coffee_shop_tab_pressed)


func _on_plantation_tab_pressed():
	if plantation_content:
		plantation_content.visible = true
	if coffee_shop_content:
		coffee_shop_content.visible = false
	
	if plantation_tab:
		plantation_tab.button_pressed = true
	if coffee_shop_tab:
		coffee_shop_tab.button_pressed = false


func _on_coffee_shop_tab_pressed():
	if plantation_content:
		plantation_content.visible = false
	if coffee_shop_content:
		coffee_shop_content.visible = true
	
	if plantation_tab:
		plantation_tab.button_pressed = false
	if coffee_shop_tab:
		coffee_shop_tab.button_pressed = true
	
	update_coffee_shop_ui()


func update_ui():
	_on_ui_update_needed()


func _on_ui_update_needed():
	if not game_manager or not game_manager.game_state:
		return
	
	var state = game_manager.game_state
	
	# Обновление основных значений
	if beans_label:
		beans_label.text = format_number(state.beans) + " 🌱"
	if dracoins_label:
		dracoins_label.text = format_number(state.dracoins) + " 🪙"
	if dragon_level_label:
		dragon_level_label.text = "Ур. " + str(state.dragon_level)
	if click_power_label:
		click_power_label.text = "+" + format_number(state.get_click_power()) + " за клик"
	if bps_label:
		bps_label.text = format_number(state.get_beans_per_second()) + " / сек"
	if total_beans_label:
		total_beans_label.text = format_number(state.total_beans)
	if total_clicks_label:
		total_clicks_label.text = format_number(state.total_clicks)
	if play_time_label:
		play_time_label.text = format_time(state.play_time)
	
	update_upgrades_ui()
	update_coffee_shop_ui()


func _on_beans_changed(new_value: int):
	if beans_label:
		beans_label.text = format_number(new_value) + " 🌱"


func _on_dracoins_changed(new_value: int):
	if dracoins_label:
		dracoins_label.text = format_number(new_value) + " 🪙"


func _on_dragon_level_changed(new_value: int):
	if dragon_level_label:
		dragon_level_label.text = "Ур. " + str(new_value)


func format_number(num: int) -> String:
	if num >= 1000000000:
		return "%.2fB" % (num / 1000000000.0)
	elif num >= 1000000:
		return "%.2fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	else:
		return str(num)


func format_time(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return "%dч %02dм" % [hours, minutes]
	elif minutes > 0:
		return "%dм %02dс" % [minutes, secs]
	else:
		return "%dс" % secs


func update_upgrades_ui():
	if not upgrades_container:
		return
	
	# Очищаем контейнер
	for child in upgrades_container.get_children():
		child.queue_free()
	
	var state = game_manager.game_state
	
	# Создаем кнопки для каждого улучшения
	var upgrade_data = [
		{"id": "upgrade1", "name": "Улучшенный клик", "icon": "👆", "desc_template": "+%d зерно за клик"},
		{"id": "grinder", "name": "Кофемолка", "icon": "⚙️", "desc_template": "%d зерно/сек"},
		{"id": "upgrade3", "name": "Авто-сборщик", "icon": "🤖", "desc_template": "%d зерно/сек"},
		{"id": "upgrade4", "name": "Плантация", "icon": "🌿", "desc_template": "%d зерно/сек"},
		{"id": "upgrade5", "name": "Жертва", "icon": "🔥", "desc_template": "Шанс бонуса"},
		{"id": "upgrade6", "name": "Благословение", "icon": "✨", "desc_template": "Глобальный бонус x%.1f"},
		{"id": "upgrade7", "name": "Эволюция", "icon": "🐉", "desc_template": "Развитие дракона"},
		{"id": "upgrade2", "name": "Подарок дракону", "icon": "🎁", "desc_template": "Дружба с драконом"}
	]
	
	for data in upgrade_data:
		var upgrade = state.upgrades.get(data["id"])
		if not upgrade:
			continue
		
		var hbox = HBoxContainer.new()
		
		var icon = Label.new()
		icon.text = data["icon"]
		icon.custom_minimum_size.x = 40
		hbox.add_child(icon)
		
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_label = Label.new()
		name_label.text = data["name"]
		name_label.add_theme_font_size_override("font_size", 16)
		info.add_child(name_label)
		
		var desc_label = Label.new()
		match data["id"]:
			"upgrade1":
				desc_label.text = "Уровень: %d/%d" % [upgrade["level"], upgrade["max_level"]]
			"grinder", "upgrade3", "upgrade4":
				desc_label.text = "Даёт %d зерно/сек" % upgrade["level"]
			_:
				desc_label.text = "Уровень: %d" % upgrade["level"]
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info.add_child(desc_label)
		
		hbox.add_child(info)
		
		var cost_label = Label.new()
		cost_label.text = format_number(upgrade["cost"]) + " 🌱"
		cost_label.custom_minimum_size.x = 100
		hbox.add_child(cost_label)
		
		var buy_button = Button.new()
		buy_button.text = "Купить"
		buy_button.custom_minimum_size.x = 80
		
		# Проверка доступности
		var max_level_reached = upgrade["max_level"] > 0 and upgrade["level"] >= upgrade["max_level"]
		var can_afford = state.beans >= upgrade["cost"]
		
		if max_level_reached:
			buy_button.text = "МАКСИМУМ"
			buy_button.disabled = true
		elif not can_afford:
			buy_button.disabled = true
		
		buy_button.pressed.connect(_on_upgrade_buy_pressed.bind(data["id"]))
		hbox.add_child(buy_button)
		
		upgrades_container.add_child(hbox)
		
		# Разделитель
		var separator = HSeparator.new()
		upgrades_container.add_child(separator)


func _on_upgrade_buy_pressed(upgrade_id: String):
	if game_manager.buy_upgrade(upgrade_id):
		update_upgrades_ui()


func update_coffee_shop_ui():
	if not coffee_shop_container or not game_manager or not game_manager.game_state:
		return
	
	var state = game_manager.game_state
	
	# Обновляем счетчик дракоинсов
	# Очищаем и пересоздаем напитки для текущей страницы
	for child in coffee_shop_container.get_children():
		child.queue_free()
	
	var current_page = state.coffee_pages["current_page"]
	var drinks = state.get_drinks_for_page(current_page)
	
	for drink in drinks:
		var drink_card = create_drink_card(drink)
		coffee_shop_container.add_child(drink_card)
		
		var separator = HSeparator.new()
		coffee_shop_container.add_child(separator)


func create_drink_card(drink: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size.y = 80
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	
	# Название и информация
	var name_label = Label.new()
	name_label.text = drink["name"]
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	var state = game_manager.game_state
	var batch_size = state.batch_sizes["current"]
	var cost = state.calculate_drink_cost(drink["base_bean_cost"], batch_size)
	var profit = state.calculate_drink_profit(drink["base_dracoins"]) * batch_size
	var duration_str = format_time(drink["duration"] / 1000)
	
	var info_label = Label.new()
	info_label.text = "Стоимость: %s 🌱 | Прибыль: %s 🪙 | Время: %s" % [
		format_number(cost),
		format_number(profit),
		duration_str
	]
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(info_label)
	
	# Кнопка приготовления
	var make_button = Button.new()
	make_button.text = "Приготовить x%d" % batch_size
	
	var can_make = state.can_make_coffee(drink["id"], batch_size)
	var has_slot = state.has_free_production_slot()
	
	if not has_slot:
		make_button.text = "Нет свободных слотов"
		make_button.disabled = true
	elif not can_make:
		make_button.text = "Недостаточно зёрен"
		make_button.disabled = true
	else:
		make_button.pressed.connect(_on_make_coffee_pressed.bind(drink["id"], batch_size))
	
	vbox.add_child(make_button)
	
	return card


func _on_make_coffee_pressed(drink_id: int, batch_size: int):
	if game_manager.start_coffee_production(drink_id, batch_size):
		update_coffee_shop_ui()


func on_dragon_clicked():
	if game_manager:
		game_manager.on_dragon_click()
	
	# Анимация дракона
	if dragon_sprite:
		var tween = create_tween()
		tween.tween_property(dragon_sprite, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(dragon_sprite, "scale", Vector2(1.0, 1.0), 0.1)
