# RelicResource.gd
# 遗物数据 Resource — 被动效果
# 在 Godot 中作为 .tres 资源文件使用

class_name RelicResource extends Resource

@export var id: String = ""
@export var relic_name: String = ""
@export var description: String = ""
@export var rarity: String = "common"   # starter | common | uncommon | rare | boss
@export var trigger: String = ""        # on_combat_end | on_turn_start | on_combat_start
@export var effect_type: String = ""    # heal | strength | energy | block | enemy_hp_cut
@export var effect_value: int = 0
