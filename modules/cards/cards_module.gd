class_name CardsModule
extends Node

## ========== 常量 ==========
const MAX_HAND_SIZE: int = 10
const CARDS_PER_TURN: int = 3
const COMBO_WINDOW_SIZE: int = 5

const CARD_DATABASE_PATH: String = "res://modules/cards/data/configs/card_database.tres"
const COMBO_DEFINITIONS_PATH: String = "res://modules/cards/data/configs/combo_definitions.json"

## ========== 状态 ==========
var _is_initialized: bool = false
var _is_running: bool = false
var _current_turn: int = 0

## ========== 生命周期 ==========

## ========== 初始化 ==========

var _card_manager: CardManager
var _draw_driver: DrawDriver
var _rhythm_port: RhythmPort
var _combo_tracker: ComboTracker
var _effect_registry: EffectRegistry

func _init() -> void:
	pass

func initialize() -> void:
	if _is_initialized:
		return

	_card_manager = CardManager.new()
	_card_manager.initialize(CARD_DATABASE_PATH)
	_card_manager.set_max_hand_size(MAX_HAND_SIZE)

	_draw_driver = AutoDrawDriver.new(self)
	_rhythm_port = RhythmPort.new(self)
	_combo_tracker = ComboTracker.new(COMBO_WINDOW_SIZE)
	_combo_tracker.load_definitions(COMBO_DEFINITIONS_PATH)
	_effect_registry = EffectRegistry.new()

	_register_default_effect_handlers()
	_subscribe_events()
	_is_initialized = true
	
	EventBus.fire("cards:initialized", get_deck_info())

func _register_default_effect_handlers() -> void:
	register_effect_handler(AttackHandler.new())
	register_effect_handler(DefenseHandler.new())
	register_effect_handler(BuffHandler.new())
	register_effect_handler(DebuffHandler.new())
	register_effect_handler(SpecialHandler.new())

func start() -> void:
	if not _is_initialized:
		push_error("[CardsModule] 未初始化")
		return
	_is_running = true
	_draw_driver.start()

func stop() -> void:
	_is_running = false
	_draw_driver.stop()
	_rhythm_port.clear_queue()

func cleanup() -> void:
	_unsubscribe_events()
	_draw_driver.cleanup()
	_draw_driver = null
	_rhythm_port.cleanup()
	_rhythm_port = null
	_combo_tracker.cleanup()
	_combo_tracker = null
	_effect_registry = null
	_card_manager = null
	_is_initialized = false

## ========== 回合管理（业务逻辑层） ==========

func start_turn() -> void:
	if not _is_running:
		return
	_current_turn += 1
	_card_manager.start_turn(CARDS_PER_TURN)
	EventBus.fire("cards:turn_started", {
		"turn": _current_turn,
		"hand_size": get_hand().size(),
		"deck_info": get_deck_info()
	})

func end_turn() -> void:
	if not _is_running:
		return
	_rhythm_port.clear_queue()
	_card_manager.end_turn()
	EventBus.fire("cards:turn_ended", {
		"turn": _current_turn,
		"discard_size": _card_manager.get_discard_pile().size(),
		"deck_info": get_deck_info()
	})

func get_current_turn() -> int:
	return _current_turn

## ========== 牌堆统计（业务逻辑层） ==========

func get_deck_info() -> Dictionary:
	return {
		"deck_size": _card_manager.get_deck().size(),
		"hand_size": get_hand().size(),
		"discard_size": _card_manager.get_discard_pile().size(),
		"charged_size": _card_manager.get_charged_cards().size(),
		"total_cards": _get_all_cards().size(),
		"max_hand_size": MAX_HAND_SIZE,
		"current_turn": _current_turn
	}

func get_hand_summary() -> Dictionary:
	var hand := get_hand()
	var summary := {
		"total": hand.size(),
		"by_type": {},
		"by_charge": {},
	}

	for card in hand:
		if card.data == null:
			continue

		var card_type := card.data.card_type
		if not summary.by_type.has(card_type):
			summary.by_type[card_type] = 0
		summary.by_type[card_type] += 1

		var charge_req := str(card.data.required_charge)
		if not summary.by_charge.has(charge_req):
			summary.by_charge[charge_req] = 0
		summary.by_charge[charge_req] += 1

	return summary

func get_hand_cost() -> int:
	var total := 0
	for card in get_hand():
		if card.data != null:
			total += card.data.cost
	return total

## ========== 卡牌查询（聚合查询） ==========

func _get_all_cards() -> Array[Card]:
	var all_cards: Array[Card] = []
	all_cards.assign(_card_manager.get_deck())
	all_cards.append_array(_card_manager.get_hand())
	all_cards.append_array(_card_manager.get_discard_pile())
	all_cards.append_array(_card_manager.get_charged_cards())
	return all_cards

func find_card_by_data_id(card_id: String, stage: int = -1) -> Card:
	for card in _get_all_cards():
		if stage == -1 or card.stage == stage:
			if card.data != null and card.data.card_id == card_id:
				return card
	return null

func find_all_cards_by_data_id(card_id: String, stage: int = -1) -> Array[Card]:
	var result: Array[Card] = []
	for card in _get_all_cards():
		if stage == -1 or card.stage == stage:
			if card.data != null and card.data.card_id == card_id:
				result.append(card)
	return result

func get_hand_by_type(card_type: String) -> Array[Card]:
	var result: Array[Card] = []
	for card in get_hand():
		if card.data != null and card.data.card_type == card_type:
			result.append(card)
	return result

func get_cards_needing_charge() -> Array[Card]:
	var result: Array[Card] = []
	for card in get_hand():
		if card.stage == Card.Stage.HAND:
			result.append(card)
	return result

## ========== 重建牌堆 ==========

func rebuild_deck_from_discard() -> void:
	var count := _card_manager.get_discard_pile().size()
	if count == 0:
		return
	_card_manager.rebuild_deck_from_discard()
	EventBus.fire("cards:deck_rebuilt", {
		"rebuilt_count": count,
		"new_deck_size": _card_manager.get_deck().size()
	})

## ========== 出牌 ==========
## 玩家打出卡牌时的统一入口

func play_card(card: Card) -> bool:
	if not _is_running:
		return false
	if card.stage != Card.Stage.HAND:
		return false

	## 通知 CardManager：卡牌被玩家打出
	_card_manager.play_card(card)

	## 交给 RhythmPort 管理队列和判定
	_rhythm_port.enqueue_card(card)

	return true

## ========== 发牌驱动注入 ==========

func set_draw_driver(driver: DrawDriver) -> void:
	if _is_running:
		_draw_driver.stop()
	_draw_driver.cleanup()
	_draw_driver = driver
	if _is_running:
		_draw_driver.start()

## ========== 效果处理器注册 ==========

func register_effect_handler(handler: EffectHandler) -> void:
	_effect_registry.register(handler)

## ========== 公共接口 ==========

func get_hand() -> Array[Card]:
	return _card_manager.get_hand()

func get_discard_pile() -> Array[Card]:
	return _card_manager.get_discard_pile()

func get_rhythm_queue() -> Array[Card]:
	return _rhythm_port.get_queue()

func is_rhythm_busy() -> bool:
	return _rhythm_port.is_busy()

func request_draw() -> void:
	if not _is_running:
		return
	_card_manager.draw()

func get_card_data(card_id: String) -> CardData:
	return _card_manager.get_card_data(card_id)

## 发牌请求（由 DrawDriver 调用）
func _request_draw() -> void:
	if not _is_running:
		return
	_card_manager.draw()

## ========== 事件订阅 ==========

func _subscribe_events() -> void:
	EventBus.listen("cards:card_charged", self, "_on_card_charged")

func _unsubscribe_events() -> void:
	EventBus.unlisten("cards:card_charged", self)

## ========== 充能完成 → 触发效果 ==========
## 由 RhythmPort 在节奏轴充能完成后调用
## 负责：连携追踪 → 充能完成 → 触发效果

func _on_card_charged(card: Card) -> void:
	## 1. 通知 CardManager：充能完成
	_card_manager.complete_card(card)

	## 2. 连携追踪
	_combo_tracker.record(card)

	## 3. 触发效果
	_effect_registry.execute(card)

## ========== 效果触发后的处理 ==========
## 外部系统（如 UI、伤害系统）监听到 cards:effect_triggered 后，
## 完成动画/数值结算，然后调用此方法将卡牌移入弃牌堆

func resolve_card(card: Card) -> void:
	_card_manager.discard_to_pile(card)
