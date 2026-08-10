extends Node

class_name GameState

# Основная валюта
var beans: int = 0
var total_beans: int = 0
var max_beans: int = 0

# Дракон
var dragon_level: int = 1
var dracoins: int = 0
var dracoins_earned_total: int = 0

# Статистика
var total_clicks: int = 0
var play_time: int = 0
var upgrades_bought: int = 0
var total_coffee_made: int = 0
var drinks_sold: int = 0

# Улучшения плантации
var upgrades: Dictionary = {
	"upgrade1": {"level": 0, "cost": 10, "max_level": 5, "type": "click"},
	"upgrade2": {"level": 0, "cost": 10000, "max_level": -1, "type": "donation"},
	"upgrade3": {"level": 0, "cost": 500, "max_level": 5, "type": "auto"},
	"upgrade4": {"level": 0, "cost": 2500, "max_level": 5, "type": "auto"},
	"upgrade5": {"level": 0, "cost": 10000, "max_level": -1, "type": "waste"},
	"upgrade6": {"level": 0, "cost": 50000, "max_level": 10, "type": "bonus"},
	"upgrade7": {"level": 0, "cost": 10000, "max_level": -1, "type": "evolution"},
	"grinder": {"level": 0, "cost": 50, "max_level": 5, "type": "auto"}
}

# Множители
var global_bonus: float = 1.0
var click_multiplier: float = 1.0
var click_multiplier_remaining: float = 0.0

# Кофейня
var coffee_shop_unlocked: bool = true
var coffee_shop_level: int = 1
var unique_drinks_made: Array = []
var coffee_upgrades_bought: int = 0

# Страницы кофейни
var coffee_pages: Dictionary = {
	"current_page": 0,
	"unlocked_pages": [0],
	"pages_unlock_level": 0
}

# Размеры партий
var batch_sizes: Dictionary = {
	"current": 1,
	"available": [1, 5, 10]
}

# Производство кофе
var coffee_production: Dictionary = {
	"active_slots": 1,
	"max_slots": 1,
	"productions": [],
	"speed_multiplier": 1.0,
	"cost_multiplier": 1.0,
	"price_multiplier": 1.0
}

# Улучшения кофейни
var coffee_shop_upgrades: Array = [
	{"id": 1, "name": "Скорость", "level": 0, "cost": 100, "max_level": 10},
	{"id": 2, "name": "Прибыль", "level": 0, "cost": 150, "max_level": 10},
	{"id": 3, "name": "Слоты", "level": 0, "cost": 200, "max_level": 5},
	{"id": 4, "name": "Бонус", "level": 0, "cost": 300, "max_level": 10},
	{"id": 5, "name": "Страницы", "level": 0, "cost": 500, "max_level": 3},
	{"id": 6, "name": "Бариста", "level": 0, "cost": 1000, "max_level": 1},
	{"id": 7, "name": "Экономия", "level": 0, "cost": 400, "max_level": 10},
	{"id": 8, "name": "Премиум", "level": 0, "cost": 600, "max_level": 10}
]

# Авто-производство
var auto_production_enabled: bool = false
var last_auto_production_time: int = 0

# Достижения
var achievements: Dictionary = {}
var coffee_achievements: Dictionary = {}

# Пользователь
var user_id: String = ""
var user_name: String = ""
var user_avatar: String = "default"

# Очки активности
var daily_points: Dictionary = {
	"clicks": 0,
	"time": 0,
	"beans_collected": 0,
	"beans_spent": 0,
	"dracoins_earned": 0,
	"upgrades_bought": 0,
	"total": 0
}
var total_points: int = 0
var last_daily_reset: int = 0

# Сессионные данные
var session_drinks_made: int = 0
var production_starts: Array = []

# Настройки дракона
var dragon_state: String = "idle"  # idle, clicked, thanks
var has_seen_dragon_message: bool = false
var upgrade5_wasted: int = 0
var current_max_level: int = 5

# Временные метки
var last_save_timestamp: int = 0
var last_play_day: String = ""
var consecutive_days: int = 0


func get_click_power() -> int:
	var base_power: int = 1
	base_power += upgrades["upgrade1"].level
	
	# Бонус за каждые 5 уровней
	var tier: int = floor(upgrades["upgrade1"].level / 5) + 1
	base_power += tier
	
	return int(base_power * global_bonus * click_multiplier)


func get_beans_per_second() -> int:
	var bps: int = 0
	bps += upgrades["grinder"].level * 1
	bps += upgrades["upgrade3"].level * 5
	bps += upgrades["upgrade4"].level * 25
	return int(bps * global_bonus)


func can_afford_upgrade(upgrade_id: String) -> bool:
	var upgrade = upgrades.get(upgrade_id)
	if not upgrade:
		return false
	return beans >= upgrade["cost"]


func buy_upgrade(upgrade_id: String) -> bool:
	var upgrade = upgrades.get(upgrade_id)
	if not upgrade:
		return false
	
	if beans < upgrade["cost"]:
		return false
	
	# Проверка максимального уровня
	if upgrade["max_level"] > 0 and upgrade["level"] >= upgrade["max_level"]:
		return false
	
	beans -= upgrade["cost"]
	upgrade["level"] += 1
	upgrades_bought += 1
	total_beans += upgrade["cost"]
	
	# Увеличение стоимости
	match upgrade_id:
		"upgrade1":
			upgrade["cost"] = int(upgrade["cost"] * 1.5)
		"grinder":
			upgrade["cost"] = int(upgrade["cost"] * 1.4)
		"upgrade3":
			upgrade["cost"] = int(upgrade["cost"] * 1.6)
		"upgrade4":
			upgrade["cost"] = int(upgrade["cost"] * 1.8)
		"upgrade5":
			upgrade["cost"] = int(upgrade["cost"] * 3.0)
		"upgrade6":
			upgrade["cost"] = int(upgrade["cost"] * 2.0)
		"upgrade7":
			upgrade["cost"] = int(upgrade["cost"] * 2.5)
		"upgrade2":
			upgrade["cost"] = int(upgrade["cost"] * 1.3)
	
	# Применение эффектов
	apply_upgrade_effect(upgrade_id)
	
	return true


func apply_upgrade_effect(upgrade_id: String):
	match upgrade_id:
		"upgrade5":
			upgrade5_wasted += 1
			if upgrade5_wasted >= 10:
				global_bonus += 0.5
		"upgrade6":
			global_bonus += 0.5 * upgrade["level"]
		"upgrade7":
			if dragon_level < 10:
				dragon_level += 1


func can_make_coffee(drink_id: int, batch_size: int) -> bool:
	var drink = get_drink_data(drink_id)
	if not drink:
		return false
	
	var total_cost = calculate_drink_cost(drink["base_bean_cost"], batch_size)
	return beans >= total_cost


func calculate_drink_cost(base_cost: int, batch_size: int) -> int:
	var cost_mult = coffee_production["cost_multiplier"]
	return int(base_cost * batch_size * cost_mult)


func calculate_drink_profit(base_profit: int) -> int:
	var profit_mult = coffee_production["price_multiplier"]
	return int(base_profit * profit_mult)


func get_active_productions_count() -> int:
	var productions: Array = coffee_production["productions"]
	var count: int = 0
	for prod in productions:
		if prod is Dictionary and not prod.get("completed", true):
			count += 1
	return count


func has_free_production_slot() -> bool:
	return get_active_productions_count() < coffee_production["active_slots"]


func get_drink_data(drink_id: int) -> Dictionary:
	# Базовые данные о напитках
	var drinks: Dictionary = {
		1: {"name": "Эспрессо", "base_bean_cost": 10, "base_dracoins": 15, "duration": 2000, "page": 0},
		2: {"name": "Американо", "base_bean_cost": 20, "base_dracoins": 35, "duration": 3000, "page": 0},
		3: {"name": "Капучино", "base_bean_cost": 30, "base_dracoins": 55, "duration": 4000, "page": 0},
		4: {"name": "Латте", "base_bean_cost": 40, "base_dracoins": 75, "duration": 5000, "page": 0},
		5: {"name": "Моккачино", "base_bean_cost": 50, "base_dracoins": 95, "duration": 6000, "page": 0},
		6: {"name": "Флэт Уайт", "base_bean_cost": 100, "base_dracoins": 180, "duration": 7000, "page": 1},
		7: {"name": "Кортадо", "base_bean_cost": 150, "base_dracoins": 280, "duration": 8000, "page": 1},
		8: {"name": "Раф", "base_bean_cost": 200, "base_dracoins": 380, "duration": 9000, "page": 1},
		9: {"name": "Глясе", "base_bean_cost": 500, "base_dracoins": 950, "duration": 10000, "page": 2},
		10: {"name": "Айс Латте", "base_bean_cost": 750, "base_dracoins": 1400, "duration": 12000, "page": 2},
		11: {"name": "Фраппе", "base_bean_cost": 1000, "base_dracoins": 1900, "duration": 14000, "page": 2},
		12: {"name": "Ирландский", "base_bean_cost": 2000, "base_dracoins": 3800, "duration": 16000, "page": 3},
		13: {"name": "Ристретто", "base_bean_cost": 3000, "base_dracoins": 5700, "duration": 18000, "page": 3},
		14: {"name": "Доппио", "base_bean_cost": 5000, "base_dracoins": 9500, "duration": 20000, "page": 3}
	}
	return drinks.get(drink_id, {})


func get_drinks_for_page(page: int) -> Array:
	var result: Array = []
	var drinks_data = {
		1: {"id": 1, "name": "Эспрессо", "base_bean_cost": 10, "base_dracoins": 15, "duration": 2000, "page": 0},
		2: {"id": 2, "name": "Американо", "base_bean_cost": 20, "base_dracoins": 35, "duration": 3000, "page": 0},
		3: {"id": 3, "name": "Капучино", "base_bean_cost": 30, "base_dracoins": 55, "duration": 4000, "page": 0},
		4: {"id": 4, "name": "Латте", "base_bean_cost": 40, "base_dracoins": 75, "duration": 5000, "page": 0},
		5: {"id": 5, "name": "Моккачино", "base_bean_cost": 50, "base_dracoins": 95, "duration": 6000, "page": 0},
		6: {"id": 6, "name": "Флэт Уайт", "base_bean_cost": 100, "base_dracoins": 180, "duration": 7000, "page": 1},
		7: {"id": 7, "name": "Кортадо", "base_bean_cost": 150, "base_dracoins": 280, "duration": 8000, "page": 1},
		8: {"id": 8, "name": "Раф", "base_bean_cost": 200, "base_dracoins": 380, "duration": 9000, "page": 1},
		9: {"id": 9, "name": "Глясе", "base_bean_cost": 500, "base_dracoins": 950, "duration": 10000, "page": 2},
		10: {"id": 10, "name": "Айс Латте", "base_bean_cost": 750, "base_dracoins": 1400, "duration": 12000, "page": 2},
		11: {"id": 11, "name": "Фраппе", "base_bean_cost": 1000, "base_dracoins": 1900, "duration": 14000, "page": 2},
		12: {"id": 12, "name": "Ирландский", "base_bean_cost": 2000, "base_dracoins": 3800, "duration": 16000, "page": 3},
		13: {"id": 13, "name": "Ристретто", "base_bean_cost": 3000, "base_dracoins": 5700, "duration": 18000, "page": 3},
		14: {"id": 14, "name": "Доппио", "base_bean_cost": 5000, "base_dracoins": 9500, "duration": 20000, "page": 3}
	}
	
	for drink in drinks_data.values():
		if drink["page"] == page:
			result.append(drink)
	
	return result


func to_dict() -> Dictionary:
	return {
		"beans": beans,
		"total_beans": total_beans,
		"max_beans": max_beans,
		"dragon_level": dragon_level,
		"dracoins": dracoins,
		"dracoins_earned_total": dracoins_earned_total,
		"total_clicks": total_clicks,
		"play_time": play_time,
		"upgrades_bought": upgrades_bought,
		"total_coffee_made": total_coffee_made,
		"drinks_sold": drinks_sold,
		"upgrades": upgrades,
		"global_bonus": global_bonus,
		"click_multiplier": click_multiplier,
		"click_multiplier_remaining": click_multiplier_remaining,
		"coffee_shop_unlocked": coffee_shop_unlocked,
		"coffee_shop_level": coffee_shop_level,
		"unique_drinks_made": unique_drinks_made,
		"coffee_upgrades_bought": coffee_upgrades_bought,
		"coffee_pages": coffee_pages,
		"batch_sizes": batch_sizes,
		"coffee_production": coffee_production,
		"coffee_shop_upgrades": coffee_shop_upgrades,
		"auto_production_enabled": auto_production_enabled,
		"last_auto_production_time": last_auto_production_time,
		"achievements": achievements,
		"coffee_achievements": coffee_achievements,
		"user_id": user_id,
		"user_name": user_name,
		"user_avatar": user_avatar,
		"daily_points": daily_points,
		"total_points": total_points,
		"last_daily_reset": last_daily_reset,
		"session_drinks_made": session_drinks_made,
		"production_starts": production_starts,
		"dragon_state": dragon_state,
		"has_seen_dragon_message": has_seen_dragon_message,
		"upgrade5_wasted": upgrade5_wasted,
		"current_max_level": current_max_level,
		"last_save_timestamp": last_save_timestamp,
		"last_play_day": last_play_day,
		"consecutive_days": consecutive_days
	}


static func from_dict(data: Dictionary) -> GameState:
	var state = GameState.new()
	
	state.beans = data.get("beans", 0)
	state.total_beans = data.get("total_beans", 0)
	state.max_beans = data.get("max_beans", 0)
	state.dragon_level = data.get("dragon_level", 1)
	state.dracoins = data.get("dracoins", 0)
	state.dracoins_earned_total = data.get("dracoins_earned_total", 0)
	state.total_clicks = data.get("total_clicks", 0)
	state.play_time = data.get("play_time", 0)
	state.upgrades_bought = data.get("upgrades_bought", 0)
	state.total_coffee_made = data.get("total_coffee_made", 0)
	state.drinks_sold = data.get("drinks_sold", 0)
	
	if data.has("upgrades"):
		state.upgrades = data["upgrades"]
	
	state.global_bonus = data.get("global_bonus", 1.0)
	state.click_multiplier = data.get("click_multiplier", 1.0)
	state.click_multiplier_remaining = data.get("click_multiplier_remaining", 0.0)
	state.coffee_shop_unlocked = data.get("coffee_shop_unlocked", true)
	state.coffee_shop_level = data.get("coffee_shop_level", 1)
	state.unique_drinks_made = data.get("unique_drinks_made", [])
	state.coffee_upgrades_bought = data.get("coffee_upgrades_bought", 0)
	
	if data.has("coffee_pages"):
		state.coffee_pages = data["coffee_pages"]
	if data.has("batch_sizes"):
		state.batch_sizes = data["batch_sizes"]
	if data.has("coffee_production"):
		state.coffee_production = data["coffee_production"]
	if data.has("coffee_shop_upgrades"):
		state.coffee_shop_upgrades = data["coffee_shop_upgrades"]
	
	state.auto_production_enabled = data.get("auto_production_enabled", false)
	state.last_auto_production_time = data.get("last_auto_production_time", 0)
	
	if data.has("achievements"):
		state.achievements = data["achievements"]
	if data.has("coffee_achievements"):
		state.coffee_achievements = data["coffee_achievements"]
	
	state.user_id = data.get("user_id", "")
	state.user_name = data.get("user_name", "")
	state.user_avatar = data.get("user_avatar", "default")
	
	if data.has("daily_points"):
		state.daily_points = data["daily_points"]
	state.total_points = data.get("total_points", 0)
	state.last_daily_reset = data.get("last_daily_reset", 0)
	
	state.session_drinks_made = data.get("session_drinks_made", 0)
	state.production_starts = data.get("production_starts", [])
	
	state.dragon_state = data.get("dragon_state", "idle")
	state.has_seen_dragon_message = data.get("has_seen_dragon_message", false)
	state.upgrade5_wasted = data.get("upgrade5_wasted", 0)
	state.current_max_level = data.get("current_max_level", 5)
	state.last_save_timestamp = data.get("last_save_timestamp", 0)
	state.last_play_day = data.get("last_play_day", "")
	state.consecutive_days = data.get("consecutive_days", 0)
	
	return state
