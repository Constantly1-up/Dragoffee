extends Node2D

@onready var dragon_container: CenterContainer = $DragonContainer
@onready var dragon_sprite: Sprite2D = $DragonContainer/DragonSprite
@onready var click_area: Area2D = $DragonContainer/ClickArea
@onready var ui: CanvasLayer = $UI

var game_manager: GameManager
var ui_manager: UIManager

# Ссылки на UI элементы
@onready var beans_label: Label = $UI/TopBar/BeansLabel
@onready var dracoins_label: Label = $UI/TopBar/DracoinsLabel
@onready var dragon_level_label: Label = $UI/TopBar/DragonLevelLabel
@onready var total_beans_label: Label = $UI/StatsPanel/VBox/TotalBeansLabel
@onready var total_clicks_label: Label = $UI/StatsPanel/VBox/TotalClicksLabel
@onready var play_time_label: Label = $UI/StatsPanel/VBox/PlayTimeLabel
@onready var click_power_label: Label = $UI/StatsPanel/VBox/ClickPowerLabel
@onready var bps_label: Label = $UI/StatsPanel/VBox/BPSLabel
@onready var plantation_tab: Button = $UI/TabsContainer/PlantationTab
@onready var coffee_shop_tab: Button = $UI/TabsContainer/CoffeeShopTab
@onready var plantation_content: ScrollContainer = $UI/ContentContainer/TabsContent/PlantationContent
@onready var coffee_shop_content: ScrollContainer = $UI/ContentContainer/TabsContent/CoffeeShopContent
@onready var upgrades_container: VBoxContainer = $UI/ContentContainer/TabsContent/PlantationContent/UpgradesContainer
@onready var coffee_shop_container: VBoxContainer = $UI/ContentContainer/TabsContent/CoffeeShopContent/CoffeeShopContainer


func _ready():
	# Создаем менеджер игры
	game_manager = GameManager.new()
	add_child(game_manager)
	
	# Создаем менеджер UI
	ui_manager = UIManager.new()
	add_child(ui_manager)
	
	# Настраиваем связи
	game_manager.ui_manager = ui_manager
	ui_manager.game_manager = game_manager
	ui_manager.dragon_sprite = dragon_sprite
	ui_manager.beans_label = beans_label
	ui_manager.dracoins_label = dracoins_label
	ui_manager.dragon_level_label = dragon_level_label
	ui_manager.total_beans_label = total_beans_label
	ui_manager.total_clicks_label = total_clicks_label
	ui_manager.play_time_label = play_time_label
	ui_manager.click_power_label = click_power_label
	ui_manager.bps_label = bps_label
	ui_manager.plantation_tab = plantation_tab
	ui_manager.coffee_shop_tab = coffee_shop_tab
	ui_manager.plantation_content = plantation_content
	ui_manager.coffee_shop_content = coffee_shop_content
	ui_manager.upgrades_container = upgrades_container
	ui_manager.coffee_shop_container = coffee_shop_container
	
	# Настройка области клика
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(200, 200)
	collision_shape.shape = shape
	click_area.add_child(collision_shape)
	
	# Подключение сигнала клика
	click_area.input_event.connect(_on_dragon_click)
	
	# Подключение вкладок
	plantation_tab.pressed.connect(_on_plantation_tab_pressed)
	coffee_shop_tab.pressed.connect(_on_coffee_shop_tab_pressed)
	
	# Инициализация UI
	ui_manager.setup_tabs()
	ui_manager.update_ui()
	
	print("🎮 Coffee Dragon Clicker запущен!")
	print("📊 Версия Godot: ", Engine.get_version_info())


func _on_dragon_click(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_dragon_clicked()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_dragon_clicked()


func _on_dragon_clicked():
	if game_manager:
		game_manager.on_dragon_click()
	
	if ui_manager:
		ui_manager.on_dragon_clicked()
	
	# Эффект клика - создаем всплывающий текст
	var click_label = Label.new()
	click_label.text = "+%d" % game_manager.game_state.get_click_power()
	click_label.add_theme_font_size_override("font_size", 20)
	click_label.add_theme_color_override("font_color", Color.WHITE)
	click_label.position = get_global_mouse_position() + Vector2(-20, -40)
	add_child(click_label)
	
	var tween = create_tween()
	tween.tween_property(click_label, "position", click_label.position + Vector2(0, -50), 0.5)
	tween.tween_property(click_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(click_label.queue_free)


func _on_plantation_tab_pressed():
	ui_manager._on_plantation_tab_pressed()


func _on_coffee_shop_tab_pressed():
	ui_manager._on_coffee_shop_tab_pressed()


func _process(delta):
	if game_manager:
		game_manager.update_productions()
