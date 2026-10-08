extends CanvasLayer
## Clip list, wardrobe, and timeline share this panel. Only one is open.

signal closed

@onready var hint: Label = $Hint
@onready var prompt: Label = $Prompt
@onready var list_panel: PanelContainer = $List
@onready var list_label: Label = $List/Label

signal picked(index: int)

@onready var choices: ItemList = $List/Choices

func show_choices(lines: PackedStringArray) -> void:
	list_panel.visible = true
	choices.clear()
	for line in lines:
		choices.add_item(line)

func _ready() -> void:
	list_panel.visible = false
	prompt.visible = false
	choices.item_selected.connect(func(index: int) -> void: picked.emit(index))
	list_panel.visible = false
	prompt.visible = false

func show_panel(text: String) -> void:
	list_panel.visible = true
	list_label.text = text

func hide_panel() -> void:
	list_panel.visible = false
	closed.emit()
