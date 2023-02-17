extends Node2D

var rng = RandomNumberGenerator.new()
var play = false
var music = true
var c = 0 # correct characters
var ready_chains # chains those are ready to be shown
var p = 0 # points
var correct = 0 # number of correct answers
var level = 1 # level (lev * 7)
var lev = 1 # sub-level (every word is 1 lev)
var word = "" # word that will be shown
var bbword = ""
var broken = false # next chain broken or not
var difficulty = 0
var chars = ""
var correct_chars


func _ready():
	for b in get_tree().get_nodes_in_group("keyboard_keys"):
		b.connect("pressed", self, "_keyboard_pressed", [b])
	rng.randomize()
	ready_chains = [$Chains/Chain, $Chains/Chain2, $Chains/Chain3, $Chains/Chain4, $Chains/Chain5, $Chains/Chain6, $Chains/Chain7, $Chains/Chain8, $Chains/Chain9, $Chains/Chain10]
# warning-ignore:return_value_discarded


func _process(_delta):
	if not $Music.playing and play and music:
		$Music.play()
	if not $Rumble.playing and play:
		$Rumble.play()
	if broken:
		var x = rng.randi_range(0,99)
		level = int(lev / 7) + 1
		word = Variables.all[lev%7][x].to_upper()
		$Word.bbcode_text = "[center]" + word + "[/center]"
		lev += 1
		broken = false
	for i in $Chains.get_children():
		if i.position.y > 2000 and not ready_chains.has(i):
			ready_chains.append(i)
	Variables.speed = (200 + lev * 2) * difficulty
	$SpeedLbl.text = "Speed\n" + str(stepify(Variables.speed / 8, 1)) + " MPH"
	$LevelLbl.text = "Level\n" + str(level)


func start_game():
	set_process(true)
	correct_chars = ""
	chars = ""
	$Typed.text = ""
	play = true
	c = 0
	p = 0
	correct = 0
	level = 1
	lev = 1
	broken = false
	Variables.started = 1
	Variables.speed = 200
	word = Variables.four[rng.randi_range(0, 99)].to_upper()
	$Word.bbcode_text = "[center]" + word + "[/center]"
	$Word.show()
	$Chains/Chain.position.y = -48
	$Chains/Chain.texture = load("res://res/Chain.png")
	$Chains/Chain.show()
	$Chains/Chain/ChainArea/CollisionShape2D.disabled = false
#	OS.show_virtual_keyboard()


func _on_PoopArea_body_entered(_body):
	game_over()


func game_over():
	set_process(false)
	play = false
	if $Music.playing:
		$Music.stop()
	if $Rumble.playing:
		$Rumble.stop()
#	OS.hide_virtual_keyboard()
	$GameOver.show()
	$GameOver/PointsLabel.text = str(int(p)) + "\nPOINTS"
	if p <= 100:
		$GameOver/PointsLabel.set("custom_colors/font_color", Color(1 - p/200, 0, 0 + p/200))
	elif p <= 200:
		$GameOver/PointsLabel.set("custom_colors/font_color", Color(0, 0 + p/200, 0 - p/200))
	else:
		$GameOver/PointsLabel.set("custom_colors/font_color", Color(0, 1, 0))


func _on_Retry_pressed():
	ready_chains = [$Chains/Chain, $Chains/Chain2, $Chains/Chain3, $Chains/Chain4, $Chains/Chain5, $Chains/Chain6, $Chains/Chain7, $Chains/Chain8, $Chains/Chain9, $Chains/Chain10]
	for i in $Chains.get_children():
		i.get_child(0).get_child(0).disabled = true
		i.hide()
	$GameOver.hide()
	start_game()


func _on_Quit_pressed():
	get_tree().quit()


func _on_PlayerArea_area_shape_entered(_ar_rid, _ar, _ar_shp_idx, _loc_shp_idx):
	game_over()


func _keyboard_pressed(b):
	chars += b.name
	$Typed.text = chars
	if c < len(word):
		if b.name == word[c]:
			c += 1
	if word.substr(0, c) == chars:
		correct_chars = word.substr(0, c)
		$Word.bbcode_text = "[center][color=#4ab3ff]" + correct_chars + "[/color]" + word.substr(c, -1) + "[/center]"
	if chars == word:
		chars = ""
		$Typed.text = ""
		for i in range(len(ready_chains)):
			if ready_chains[i]:
				$ShootSFX.play()
				broken = true
				ready_chains[i].texture = load("res://res/Broken Chain.png")
				ready_chains[i].get_children()[0].get_children()[0].disabled = true
				p += stepify(len(word) * Variables.speed / 800, 1)
				if len(ready_chains) > 1:
					ready_chains[i+1].show()
					ready_chains[i+1].texture = load("res://res/Chain.png")
					ready_chains[i+1].position.y = -48
					ready_chains[i+1].get_children()[0].get_children()[0].disabled = false
				else:
					$GameOver.show()
					$GameOver/Retry.hide()
					$GameOver/PointsLabel.text = "Your speed is unmeasurable!\n Please go do something else."
				ready_chains.remove(i)
				c = 0
				break


func _on_Erase_pressed():
	chars = chars.substr(0, len(chars) - 1)
	$Typed.text = chars


func _on_ToggleMusic_toggled(_button_pressed):
	music = !music
	if not music:
		$Music.stop()


func _on_EasyBtn_pressed():
	difficulty = 0.75
	$Menu.hide()
	start_game()


func _on_NormalBtn_pressed():
	difficulty = 1
	$Menu.hide()
	start_game()


func _on_HardBtn_pressed():
	difficulty = 1.5
	$Menu.hide()
	start_game()


func _on_QuitBtn_pressed():
	get_tree().quit()
