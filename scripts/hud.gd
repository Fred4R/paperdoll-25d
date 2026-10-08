extends CanvasLayer
## Clip list, wardrobe, and timeline share this panel. Only one is open.

signal closed

@onready var hint: Label = $Hint
@onready var prompt: Label = $Prompt
@onready var list_panel: PanelContainer = $List
@onready var list_label: Label = $List/Label

func _ready() -> void:
	list_panel.visible = false
	prompt.visible = false

func show_panel(text: String) -> void:
	list_panel.visible = true
	list_label.text = text

func hide_panel() -> void:
	list_panel.visible = false
	closed.emit()
