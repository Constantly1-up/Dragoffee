extends Control

class_name GameManager

@export var game_state: GameState
@export var ui_manager: Control

var save_file_path: String = "user://savegame.json"
var auto_collect_timer: Timer
var auto_production_timer: Timer
var play_time_timer: Timer

# Сигналы для UI
signal beans_changed(new_value: int)
signal dracoins_changed(new_value: int)
signal dragon_level_changed(new_value: int)
signal click_power_changed(new_value: int)
signal bps_changed(new_value: int)
signal ui_update_needed()


func _ready():
	if not game_state:
		game_state = GameState.new()
		add_child(game_state)
	
	setup_timers()
	load_game()


func setup_timers():
	# Таймер авто-сбора (каждую секунду)
	auto_collect_timer = Timer.new()
	auto_collect_timer.wait_time = 1.0
	auto_collect_timer.timeout.connect(_on_auto_collect)
	add_child(auto_collect_timer)
	auto_collect_timer.start()
	
	# Таймер авто-производства кофе (каждые 30 сек если включено)
	auto_production_timer = Timer.new()
	auto_production_timer.wait_time = 30.0
	auto_production_timer.timeout.connect(_on_auto_production_check)
	add_child(auto_production_timer)
	auto_production_timer.start()
	
	# Таймер игрового времени
	play_time_timer = Timer.new()
	play_time_timer.wait_time = 1.0
	play_time_timer.timeout.connect(_on_play_time_tick)
	add_child(play_time_timer)
	play_time_timer.start()


func _on_auto_collect():
	var bps = game_state.get_beans_per_second()
	if bps > 0:
		add_beans(bps)


func _on_auto_production_check():
	if game_state.auto_production_enabled:
		try_auto_produce_coffee()


func _on_play_time_tick():
	game_state.play_time += 1
	
	# Автосохранение каждые 2 минуты
	if game_state.play_time % 120 == 0:
		save_game()


func add_beans(amount: int):
	game_state.beans += amount
	game_state.total_beans += amount
	if game_state.beans > game_state.max_beans:
		game_state.max_beans = game_state.beans
	beans_changed.emit(game_state.beans)
	ui_update_needed.emit()


func add_dracoins(amount: int):
	game_state.dracoins += amount
	game_state.dracoins_earned_total += amount
	dracoins_changed.emit(game_state.dracoins)
	ui_update_needed.emit()


func on_dragon_click():
	game_state.total_clicks += 1
	var click_power = game_state.get_click_power()
	add_beans(click_power)
	click_power_changed.emit(click_power)


func buy_upgrade(upgrade_id: String) -> bool:
	if game_state.buy_upgrade(upgrade_id):
		ui_update_needed.emit()
		return true
	return false


func start_coffee_production(drink_id: int, batch_size: int) -> bool:
	if not game_state.can_make_coffee(drink_id, batch_size):
		return false
	
	if not game_state.has_free_production_slot():
		return false
	
	var drink_data = game_state.get_drink_data(drink_id)
	if drink_data.is_empty():
		return false
	
	var cost = game_state.calculate_drink_cost(drink_data["base_bean_cost"], batch_size)
	game_state.beans -= cost
	
	var profit = game_state.calculate_drink_profit(drink_data["base_dracoins"])
	
	var production = {
		"id": randi(),
		"drink_id": drink_id,
		"start_time": Time.get_ticks_msec(),
		"duration": drink_data["duration"],
		"completed": false,
		"batch_size": batch_size,
		"profit_per_unit": profit
	}
	
	game_state.coffee_production["productions"].append(production)
	game_state.session_drinks_made += batch_size
	game_state.production_starts.append(Time.get_ticks_msec())
	
	if not drink_id in game_state.unique_drinks_made:
		game_state.unique_drinks_made.append(drink_id)
	
	ui_update_needed.emit()
	return true


func try_auto_produce_coffee():
	if not game_state.auto_production_enabled:
		return
	
	if not game_state.has_free_production_slot():
		return
	
	# Выбираем случайный доступный напиток
	var available_drinks = game_state.get_drinks_for_page(game_state.coffee_pages["current_page"])
	if available_drinks.is_empty():
		return
	
	var random_drink = available_drinks[randi() % available_drinks.size()]
	start_coffee_production(random_drink["id"], 1)


func update_productions():
	var now = Time.get_ticks_msec()
	var completed_any = false
	
	for production in game_state.coffee_production["productions"]:
		if production is Dictionary and not production.get("completed", true):
			var elapsed = now - production["start_time"]
			if elapsed >= production["duration"]:
				complete_production(production)
				completed_any = true
	
	if completed_any:
		# Удаляем завершенные производства
		game_state.coffee_production["productions"] = game_state.coffee_production["productions"].filter(
			func(p): return p is Dictionary and not p.get("completed", true)
		)
		ui_update_needed.emit()


func complete_production(production: Dictionary):
	var total_profit = production["profit_per_unit"] * production["batch_size"]
	
	# Проверка бариста (55% игроку, 45% забирает)
	var barista_upgrade = get_coffee_upgrade(6)
	var barista_active = barista_upgrade != null and barista_upgrade["level"] > 0
	
	if barista_active:
		var player_profit = int(total_profit * 0.55)
		add_dracoins(player_profit)
	else:
		add_dracoins(total_profit)
	
	game_state.drinks_sold += production["batch_size"]
	game_state.total_coffee_made += production["batch_size"]
	production["completed"] = true


func get_coffee_upgrade(id: int) -> Dictionary:
	for upgrade in game_state.coffee_shop_upgrades:
		if upgrade["id"] == id:
			return upgrade
	return {}


func buy_coffee_upgrade(id: int) -> bool:
	var upgrade = get_coffee_upgrade(id)
	if upgrade.is_empty():
		return false
	
	if game_state.dracoins < upgrade["cost"]:
		return false
	
	if upgrade["max_level"] > 0 and upgrade["level"] >= upgrade["max_level"]:
		return false
	
	game_state.dracoins -= upgrade["cost"]
	upgrade["level"] += 1
	game_state.coffee_upgrades_bought += 1
	
	# Увеличение стоимости
	upgrade["cost"] = int(upgrade["cost"] * (1.5 if id != 5 else 2.0))
	
	# Применение эффектов
	apply_coffee_upgrade_effect(id, upgrade["level"])
	
	ui_update_needed.emit()
	return true


func apply_coffee_upgrade_effect(id: int, level: int):
	match id:
		1: # Скорость
			game_state.coffee_production["speed_multiplier"] = pow(0.9, level)
		2: # Прибыль
			game_state.coffee_production["price_multiplier"] = pow(1.15, level)
		3: # Слоты
			game_state.coffee_production["active_slots"] = 1 + level
			game_state.coffee_production["max_slots"] = 1 + level
		4: # Бонус
			var bonus = pow(1.25, level)
			game_state.coffee_production["speed_multiplier"] *= bonus
			game_state.coffee_production["price_multiplier"] *= bonus
		5: # Страницы
			if level > 0 and game_state.coffee_pages["unlocked_pages"].size() < level + 1:
				game_state.coffee_pages["unlocked_pages"].append(level)
		6: # Бариста - эффект применяется при завершении производства
			pass
		7: # Экономия
			game_state.coffee_production["cost_multiplier"] = pow(0.8, level)
		8: # Премиум
			game_state.coffee_production["price_multiplier"] *= pow(1.3, level)


func save_game():
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var data = game_state.to_dict()
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("✅ Игра сохранена")


func load_game() -> bool:
	if not FileAccess.file_exists(save_file_path):
		print("ℹ️ Сохранение не найдено, начинаем новую игру")
		return false
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(text)
		if error == OK:
			game_state = GameState.from_dict(json.data)
			print("✅ Игра загружена")
			ui_update_needed.emit()
			return true
		else:
			print("❌ Ошибка парсинга сохранения: ", error)
	
	return false


func reset_game():
	game_state = GameState.new()
	save_game()
	ui_update_needed.emit()
