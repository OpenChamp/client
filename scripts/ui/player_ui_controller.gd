extends CanvasLayer
class_name PlayerUIController

## UI References
@onready var champion_name = %ChampionName
@onready var level_label = %LevelLabel
@onready var health_bar = %HealthBar
@onready var health_text = %HealthText
@onready var mana_bar = %ManaBar
@onready var mana_text = %ManaText
@onready var gold_amount = %GoldAmount
@onready var game_timer = %GameTimer

# Ability buttons and cooldown labels
@onready var ability_buttons = {
	"Q": %QAbility,
	"W": %WAbility,
	"E": %EAbility,
	"R": %RAbility
}

@onready var cooldown_labels = {
	"Q": %QAbility/QCooldown,
	"W": %WAbility/WCooldown,
	"E": %EAbility/ECooldown,
	"R": %RAbility/RCooldown
}

# Item slots
@onready var item_slots = [
	%ItemSlot1,
	%ItemSlot2,
	%ItemSlot3,
	%ItemSlot4,
	%TrinketSlot
]

# Player stats
var player_stats = {
	"health": 100,
	"max_health": 100,
	"mana": 100,
	"max_mana": 100,
	"level": 1,
	"gold": 0,
	"champion": "Ahri"
}

var ability_cooldowns = {
	"Q": 0.0,
	"W": 0.0,
	"E": 0.0,
	"R": 0.0
}

var game_time: float = 0.0

func _ready() -> void:
	# Initialize UI
	update_champion_display()
	update_stats_display()
	
	# Connect to GameManager signals if available
	if GameManager:
		GameManager.settings_changed.connect(_on_settings_changed)
	
	print("PlayerUIController: Initialized")

func _process(delta: float) -> void:
	# Update game timer
	game_time += delta
	update_game_timer()
	
	# Update cooldowns
	update_cooldowns(delta)

## === Champion Display === ##

func set_champion(champion_name: String) -> void:
	player_stats["champion"] = champion_name
	update_champion_display()

func update_champion_display() -> void:
	champion_name.text = player_stats["champion"]
	level_label.text = str(player_stats["level"])

## === Stats Updates === ##

func set_health(current: float, max_hp: float) -> void:
	player_stats["health"] = current
	player_stats["max_health"] = max_hp
	update_stats_display()

func set_mana(current: float, max_mp: float) -> void:
	player_stats["mana"] = current
	player_stats["max_mana"] = max_mp
	update_stats_display()

func set_level(new_level: int) -> void:
	player_stats["level"] = new_level
	update_champion_display()

func set_gold(amount: float) -> void:
	player_stats["gold"] = amount
	gold_amount.text = str(int(amount))

func update_stats_display() -> void:
	# Update health bar
	health_bar.value = (player_stats["health"] / player_stats["max_health"]) * 100.0
	health_text.text = "%d / %d" % [int(player_stats["health"]), int(player_stats["max_health"])]
	
	# Update mana bar
	mana_bar.value = (player_stats["mana"] / player_stats["max_mana"]) * 100.0
	mana_text.text = "%d / %d" % [int(player_stats["mana"]), int(player_stats["max_mana"])]
	
	# Color health bar based on health percentage
	var health_percent = player_stats["health"] / player_stats["max_health"]
	if health_percent > 0.5:
		health_bar.modulate = Color(0.2, 1.0, 0.2)  # Green
	elif health_percent > 0.25:
		health_bar.modulate = Color(1.0, 0.8, 0.2)  # Yellow
	else:
		health_bar.modulate = Color(1.0, 0.2, 0.2)  # Red

## === Abilities & Cooldowns === ##

func set_ability_cooldown(ability_key: String, cooldown: float) -> void:
	if ability_key in ability_cooldowns:
		ability_cooldowns[ability_key] = cooldown
		
		# Disable button if on cooldown
		if cooldown > 0.0:
			ability_buttons[ability_key].disabled = true
		else:
			ability_buttons[ability_key].disabled = false

func update_cooldowns(delta: float) -> void:
	for ability in ability_cooldowns.keys():
		if ability_cooldowns[ability] > 0.0:
			ability_cooldowns[ability] -= delta
			
			# Update cooldown display
			var cooldown_text = "%.1f" % max(0.0, ability_cooldowns[ability])
			cooldown_labels[ability].text = cooldown_text
		else:
			cooldown_labels[ability].text = ""
			ability_buttons[ability].disabled = false

## === Items === ##

func set_item(slot: int, item_name: String) -> void:
	if slot >= 0 and slot < item_slots.size():
		item_slots[slot].text = item_name.substr(0, 1).to_upper()  # First letter
		item_slots[slot].tooltip_text = item_name

func clear_item(slot: int) -> void:
	if slot >= 0 and slot < item_slots.size():
		item_slots[slot].text = ""
		item_slots[slot].tooltip_text = ""

## === Timer === ##

func update_game_timer() -> void:
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	game_timer.text = "%02d:%02d" % [minutes, seconds]

## === Settings === ##

func _on_settings_changed() -> void:
	# Re-apply UI settings if needed (theme colors, etc.)
	pass

## === Animation Helpers === ##

func animate_damage(amount: float) -> void:
	"""Show damage number popup"""
	var tween = create_tween()
	health_bar.modulate = Color.RED
	tween.tween_callback(func(): health_bar.modulate = Color.WHITE).set_delay(0.1)

func animate_heal(amount: float) -> void:
	"""Show heal number popup"""
	var tween = create_tween()
	health_bar.modulate = Color.GREEN
	tween.tween_callback(func(): health_bar.modulate = Color.WHITE).set_delay(0.1)

## === Debug/Testing === ##

func test_stats() -> void:
	"""Testing function - remove before production"""
	set_champion("Ahri")
	set_level(5)
	set_health(150, 250)
	set_mana(75, 150)
	set_gold(2500)
	set_ability_cooldown("Q", 4.5)
	set_item(0, "Ludens")
	set_item(1, "Zhonyas")
