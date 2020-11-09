/// @description Check health bar step by step

// Calcul of current health
hpPercent = playerCurrentHP / playerMaxHP ; 

#region PARAMETER GENERAL

// Restart game

if keyboard_check(ord("R")) {
	game_restart();
}

// Quit game

if keyboard_check(vk_escape) {
	game_end();
}

#endregion

// Test damage
if keyboard_check_pressed(vk_space){
	//show_message("Damage");
	playerCurrentHP -= 10;
}

// Check no health
if (playerCurrentHP == 0) {
	playerCurrentHP = 0; // Prevent the bar from going to negative values
	//show_message("You are dead !");
	game_restart(); // restart room
}


