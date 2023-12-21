class_name Debug
extends PanelContainer

@onready var property_container = %VBoxContainer

func _ready():
	#Set global reference to self in Global singleton
	Global.debug = self

func _process(_delta):
	if !visible: pass #Only update UI when visible

#func _input(event): #Don't want this anymore because I'm stealing the theme for the game UI
	#if event.is_action_pressed("debug"):
		#visible = !visible

#Debug function to add and update property
func add_property(title: String, value):#, order):
	var target = property_container.find_child(title, true, false) #Try to find label with same name
	if !target: #If there is no current label for this property
		target = Label.new() #Create new label in VBox container
		property_container.add_child(target)
		target.name = title
		target.text = target.name + ": " + str(value) #Set text value
	elif visible:
		target.text = title + ": " + str(value) #Update text value
		#property_container.move_child(target, order) #Reorder property
