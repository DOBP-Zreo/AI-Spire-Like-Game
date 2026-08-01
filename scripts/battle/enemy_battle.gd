# EnemyBattle.gd
# 敌人战斗节点 — 显示敌人形象、血量、格挡、意图
# 附着在主战斗场景中（通过 BattleManager 的 EnemyArea）

extends Control

@onready var enemy_sprite: ColorRect = $EnemySprite
@onready var enemy_sprite_tex: TextureRect = $EnemySpriteTex
@onready var enemy_name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_text: Label = $HPBar/HPText
@onready var block_label: Label = $BlockLabel
@onready var intent_icon: TextureRect = $IntentArea/IntentIcon
@onready var intent_label: Label = $IntentArea/IntentLabel
@onready var intent_value: Label = $IntentArea/IntentValue
@onready var poison_label: Label = $PoisonLabel

var enemy_textures: Dictionary = {
	"slime_green": "res://assets/art/enemies/slime_green.png",
	"slime_red": "res://assets/art/enemies/slime_red.png",
	"skeleton": "res://assets/art/enemies/skeleton.png",
	"fire_elemental": "res://assets/art/enemies/fire_elemental.png",
	"goblin_captain": "res://assets/art/enemies/goblin_captain.png",
	"slime_king": "res://assets/art/enemies/slime_king.png",
	"dark_knight": "res://assets/art/enemies/dark_knight.png",
	"shadow_mage": "res://assets/art/enemies/shadow_mage.png",
	"fire_lord": "res://assets/art/enemies/fire_elemental.png",
	"spire_heart": "res://assets/art/enemies/slime_king.png",
	"cursed_knight": "res://assets/art/enemies/cursed_knight.png",
	"frost_wolf": "res://assets/art/enemies/frost_wolf.png",
}

func _ready() -> void:
	CombatState.state_updated.connect(_refresh)
	CombatState.combat_started.connect(_on_combat_start)
	CombatState.player_turn_started.connect(_on_player_turn_started)

func _on_combat_start() -> void:
	_load_enemy_sprite()
	_refresh()
	_on_player_turn_started()

func _load_enemy_sprite() -> void:
	if not CombatState.current_enemy_resource:
		return
	var enemy_id = CombatState.current_enemy_resource.id
	if enemy_textures.has(enemy_id):
		var tex_path = enemy_textures[enemy_id]
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path) as Texture2D
			if tex:
				enemy_sprite_tex.texture = tex
				enemy_sprite_tex.visible = true
				enemy_sprite.visible = false
				return
	enemy_sprite_tex.visible = false
	enemy_sprite.visible = true

func _refresh() -> void:
	if not CombatState.is_combat_active:
		return
	var enemy = CombatState.current_enemy_resource
	if enemy == null:
		return
	
	enemy_name_label.text = enemy.enemy_name
	
	hp_bar.max_value = CombatState.enemy_max_hp
	hp_bar.value = CombatState.enemy_hp
	hp_text.text = "%d / %d" % [CombatState.enemy_hp, CombatState.enemy_max_hp]
	
	if CombatState.enemy_hp <= CombatState.enemy_max_hp * 0.3:
		hp_bar.modulate = Color.RED
	elif CombatState.enemy_hp <= CombatState.enemy_max_hp * 0.6:
		hp_bar.modulate = Color.ORANGE
	else:
		hp_bar.modulate = Color.GREEN
	
	if CombatState.enemy_block > 0:
		block_label.text = "格挡 %d" % CombatState.enemy_block
		block_label.visible = true
	else:
		block_label.visible = false
	
	if CombatState.enemy_poison > 0:
		if poison_label: poison_label.text = "中毒 %d" % CombatState.enemy_poison
		if poison_label: poison_label.visible = true
	elif poison_label:
		poison_label.visible = false
	
	# 敌人状态标签
	var e_str = get_node_or_null("EStrengthLabel")
	var e_vul = get_node_or_null("EVulnerableLabel")
	var e_weak = get_node_or_null("EWeakLabel")
	
	if e_str:
		e_str.text = "力量: %d" % CombatState.enemy_strength
		e_str.visible = CombatState.enemy_strength > 0
	if e_vul:
		e_vul.text = "易伤: %d" % CombatState.enemy_vulnerable
		e_vul.visible = CombatState.enemy_vulnerable > 0
	if e_weak:
		e_weak.text = "虚弱: %d" % CombatState.enemy_weak
		e_weak.visible = CombatState.enemy_weak > 0

func _on_player_turn_started() -> void:
	# 仅在玩家回合开始时刷新一次意图，回合中保持不变
	var intent = CombatState.get_enemy_intent()
	_refresh_intent(intent)

func _refresh_intent(intent: Dictionary) -> void:
	var action = intent.get("action", "attack")
	if action.is_empty():
		action = "attack"
	var buff_type = intent.get("buff_type", "")
	var buff_amount = intent.get("buff_amount", 0)
	
	match action:
		"attack":
			intent_icon.texture = load("res://assets/art/ui/intents/intent_attack.png")
			intent_label.text = "攻击"
			intent_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		"block":
			intent_icon.texture = load("res://assets/art/ui/intents/intent_defend.png")
			intent_label.text = "防御"
			intent_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
		"buff":
			var buff_name = _buff_type_name(buff_type)
			intent_icon.texture = load("res://assets/art/ui/intents/intent_buff.png")
			intent_label.text = buff_name
			intent_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		"debuff":
			var debuff_name = _buff_type_name(buff_type)
			intent_icon.texture = load("res://assets/art/ui/intents/intent_debuff.png")
			intent_label.text = debuff_name
			intent_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
		"none":
			intent_icon.texture = null
			intent_label.text = ""
			intent_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_:
			intent_icon.texture = load("res://assets/art/ui/intents/intent_attack.png")
			intent_label.text = "攻击"
			intent_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	if action in ["attack", "block"]:
		intent_value.text = str(intent.get("value", 0))
		intent_value.visible = true
	elif buff_amount > 0:
		intent_value.text = "+%d" % buff_amount
		intent_value.visible = true
	else:
		intent_value.text = ""
		intent_value.visible = false

func _buff_type_name(t: String) -> String:
	match t:
		"strength":  return "力量"
		"dexterity": return "敏捷"
		"vulnerable": return "易伤"
		"weak":      return "虚弱"
		"poison":    return "中毒"
	return t
