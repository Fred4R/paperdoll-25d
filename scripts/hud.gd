extends CanvasLayer
## Clip list, wardrobe, and timeline share this panel. Only one is open.

signal picked(index: int)
signal closed

@onready var hint: Label = $Hint
@onready var prompt: Label = $Prompt
@onready var list_panel: PanelContainer = $List
@onready var list_label: Label = $List/Rows/Label
@onready var choices: ItemList = $List/Rows/Choices

func _ready() -> void:
	list_panel.visible = false
	prompt.visible = false
	choices.visible = false
	choices.item_selected.connect(_on_pick)

## Fill the row list and open the panel. Title goes in the label above the rows.
func show_choices(lines: PackedStringArray, title: String = "") -> void:
	choices.clear()
	for line in lines:
		choices.add_item(line)
	list_label.text = title
	choices.visible = true
	list_panel.visible = true

func _on_pick(index: int) -> void:
	picked.emit(index)

## Hide the panel and tell the director it closed.
func hide_panel() -> void:
	list_panel.visible = false
	choices.visible = false
	closed.emit()
