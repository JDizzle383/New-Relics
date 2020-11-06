#define input_ini

/// @arg maxplayers,axis_deadzone,button_count

// Device handling
global.Input_Device_List = ds_list_create();			// Stores a list of all connected devices
global.Input_Player_Device = ds_map_create();			// Used to tag a device to a player
global.Input_Data_List = ds_list_create();				// Stores a list of player inputs
global.Input_Axis_Map = ds_map_create();				// Axis state data
global.Input_Axis_Directional_Deadzone = 0.4;			// Axis "pressed" and "released" deadzone
global.Input_Player_Limit = argument0;					// The max number of players
global.Input_Bypass_Device_Lock = false;				// Whether devices can be binded to multiple players
global.Input_Debug = false;

global.Input_Ignore = false;

// Input system configuration
global.Input_Max_Players = argument0;
global.Input_Axis_Deadzone = argument1;
global.Input_Axis_Deadzone_Player = array_create(argument0,argument1);			// Axis "pressed" and "released" deadzone

// Setup input device lists
for ( var i = 0; i < global.Input_Max_Players; ++ i; ) {
	global.Input_Player_Device[? i] = ds_list_create();
}

ds_list_add(global.Input_Device_List,-1);

// Action mapping
global.Input_Action_Map = ds_map_create();

// Buffer delay system
global.Input_Buffer = ds_list_create();
global.Input_Buffer_Reference = ds_list_create();
global.Input_Buffer_Delay = 0;

// We need separate maps, one for each possible player
repeat ( argument0 ) {
	var _map = ds_map_create();
	ds_list_add(global.Input_Buffer_Reference,_map);
	
	/*
		There needs to be a list for each button in 
		case we have multiple presses queued
	*/
	
	for ( var i = 0; i < argument2; ++ i; ) {
		ds_map_add(_map,i,ds_list_create());
	}
}

enum InputBuffer {
	Player,
	BindIndex,
	Button,
	State,
	Value,
	Delay,
	Ready,
	Size
}

enum InputBufferStates {
	Pressed,
	Held,
	Released
}

#define input_device_locking_set

/// @arg enable

global.Input_Bypass_Device_Lock = argument0;

#define input_device_locking_get

return global.Input_Bypass_Device_Lock;

#define input_axis_deadzone

/// @arg player,axis_deadzone

global.Input_Axis_Deadzone_Player[argument0] = argument1;

#define input_process

switch ( async_load[? "event_type"] ) {
	
	case "gamepad lost":

		var
		_device_count = gamepad_get_device_count(),
		_str,
		_map,
		_current_device_count = ds_list_size(global.Input_Device_List);
		
		for ( var i = 0; i < _current_device_count; ++ i; ) {
			if ( global.Input_Device_List[| i] != -1 && global.Input_Device_List[| i] != undefined && !gamepad_is_connected(global.Input_Device_List[| i]) ) {
				if ( global.Input_Debug ) {
					show_debug_message("Removed " + string(gamepad_get_description(global.Input_Device_List[| i])));
				}
				if ( ds_map_exists(global.Input_Axis_Map,global.Input_Device_List[| i]) ) {
					ds_list_destroy(global.Input_Axis_Map[? global.Input_Device_List[| i]]);
					ds_map_delete(global.Input_Axis_Map,global.Input_Device_List[| i]);
				}
				
				ds_list_delete(global.Input_Device_List,i);
				-- _current_device_count;
				-- i;
			}
		}
		
	break;
		
	case "gamepad discovered":
		
		if ( gamepad_is_connected(async_load[? "pad_index"]) ) {
			if ( global.Input_Debug ) {
				show_debug_message("Added " + string(gamepad_get_description(async_load[? "pad_index"])));
			}
			ds_list_add(global.Input_Device_List,async_load[? "pad_index"]);
			ds_map_add(global.Input_Axis_Map,async_load[? "pad_index"],ds_list_create());
			ds_list_add(global.Input_Axis_Map[? async_load[? "pad_index"]],0,0,0,0,0,0,0,0);	// Add 8 axis directions and axis deadzone
			gamepad_set_axis_deadzone(async_load[? "pad_index"],global.Input_Axis_Deadzone);
		}

	break;
}

#define input_debug_set
/// @arg enable

global.Input_Debug = argument0;

#define input_debug_get

return global.Input_Debug;

#define input_player_device_assign

/// @desc Connects a controller to a player
/// @arg player,<devices>

var
_list = global.Input_Player_Device[? argument[0]],
_device_taken = array_create(argument_count);


for ( var i = 1; i < argument_count; ++ i; ) {
	
	// Reset the state of _device_taken
	_device_taken[i-1] = false;
	
	// Check all of our player device lists to see if the device has already been binded to a player
	if ( global.Input_Bypass_Device_Lock ) {
		for ( var t = 0; t < ds_map_size(global.Input_Player_Device); ++ t; ) {
			_device_taken[i-1] = (ds_list_find_index(global.Input_Player_Device[? t],argument[i]) != -1);
			if ( _device_taken[i-1] ) {
				if ( global.Input_Debug ) {
					show_debug_message("Device is currently binded to a player");
				}
				break;
			}
		}
	}
	
	if ( !_device_taken[i-1] ) {	// If the device hasn't been taken
		
		if ( argument[i] != -1 ) {	// Check if it's a gamepad
			if ( gamepad_is_connected(argument[i]) ) {
				ds_list_add(_list,argument[i]);
				if ( global.Input_Debug ) {
					show_debug_message("Device (" + string(argument[i]) + ") is now connected to player (" + string(argument[0]) + ").");
				}
				return true;
			} else {
				if ( global.Input_Debug ) {
					show_debug_message("Device (" + string(argument[i]) + ") is not connected or is an invalid device ID.");
				}
			}
		} else {	// Check if it's a keyboard
			ds_list_add(_list,-1);
			if ( global.Input_Debug ) {
				show_debug_message("Keyboard is now connected to player (" + string(argument[0]) + ").");
			}
			return true;
		}
		
	} else {
		if ( global.Input_Debug ) {
			show_debug_message("Device (" + string(argument[i]) + ") is already connected to player (" + string(_device_taken[i-1]) + ").");
		}
	}
	
}

return false;

#define input_player_device_remove

/// @desc Removes a controller(s) from a player's device list
/// @arg player,<devices>

var
_list = global.Input_Player_Device[? argument[0]],
_index;

for ( var i = 1; i < argument_count; ++ i; ) {
	_index = ds_list_find_index(_list,argument[i]);
	if ( _index != -1 ) {
		ds_list_delete(_list,_index);
		if ( global.Input_Debug ) {
			show_debug_message("Device (" + string(argument[i]) + ") removed from player (" + string(argument[0]) + ").");
		}
	}
}

#define input_player_device_remove_all

/// @desc Removes all controller(s) from a player's device list
/// @arg player

var
_list = global.Input_Player_Device[? argument0],
_index;

for ( var i = 0; i < ds_list_size(global.Input_Device_List); ++ i; ) {
	_index = ds_list_find_index(_list,global.Input_Device_List[| i]);
	if ( _index != -1 ) {
		ds_list_delete(_list,_index);
		if ( global.Input_Debug ) {
			show_debug_message("Device (" + string(global.Input_Device_List[| i]) + ") removed from player (" + string(argument[0]) + ").");
		}
	}
}

#define input_player_device_list

/// @desc Returns a list of devices binded to a player
/// @arg player

return global.Input_Player_Device[? argument[0]];

#define input_device_check_any

/// @arg device

if ( global.Input_Ignore ) {
	return false;
}

if ( argument0 == -1 ) {	// Check keyboard
	
	if ( keyboard_check(vk_anykey) ) {
		return keyboard_lastkey;
	} else {
		if ( mouse_check_button(mb_any) ) {
			return mouse_lastbutton;
		}
	}
	
} else {	// Check gamepads
	
	for ( var i = gp_face1; i < gp_axisrv + 1; ++ i; ) {
		if ( i == gp_axislh || i == gp_axislv || i == gp_axisrh || i == gp_axisrv ) {
			var _axis_value = gamepad_axis_value(argument0,i);
			if ( _axis_value != 0 ) {
				if ( i == gp_axislh ) {
					if ( _axis_value > 0 ) {
						return input_axislr;
					} else {
						return input_axisll;
					}
				}
				
				if ( i == gp_axislv ) {
					if ( _axis_value > 0 ) {
						return input_axisld;
					} else {
						return input_axislu;
					}
				}
				
				if ( i == gp_axisrh ) {
					if ( _axis_value > 0 ) {
						return input_axisrr;
					} else {
						return input_axisrl;
					}
				}
				
				if ( i == gp_axisrv ) {
					if ( _axis_value > 0 ) {
						return input_axisrd;
					} else {
						return input_axisru;
					}
				}
			}
		} else {
			if ( gamepad_button_check(argument0,i) ) { return i; }
		}
	}
	
}

return false;

#define input_device_get_all

return global.Input_Device_List;

#define input_device_check_any_pressed

/// @arg device

if ( global.Input_Ignore ) {
	return false;
}

if ( argument0 == -1 ) {	// Check keyboard
	
	if ( keyboard_check_pressed(vk_anykey) ) {
		return keyboard_lastkey;
	} else {
		if ( mouse_check_button_pressed(mb_any) ) {
			return mouse_lastbutton;
		}
	}
	
} else {	// Check gamepads
	
	for ( var i = gp_face1; i < gp_axisrv + 1; ++ i; ) {
		if ( i == gp_axislh || i == gp_axislv || i == gp_axisrh || i == gp_axisrv ) {
			var _axis_value = gamepad_axis_value(argument0,i);
			if ( _axis_value != 0 ) {
				if ( i == gp_axislh ) {
					if ( _axis_value > 0 ) {
						return input_axislr;
					} else {
						return input_axisll;
					}
				}
				
				if ( i == gp_axislv ) {
					if ( _axis_value > 0 ) {
						return input_axisld;
					} else {
						return input_axislu;
					}
				}
				
				if ( i == gp_axisrh ) {
					if ( _axis_value > 0 ) {
						return input_axisrr;
					} else {
						return input_axisrl;
					}
				}
				
				if ( i == gp_axisrv ) {
					if ( _axis_value > 0 ) {
						return input_axisrd;
					} else {
						return input_axisru;
					}
				}
			}
		} else {
			if ( gamepad_button_check_pressed(argument0,i) ) { return i; }
		}
	}
	
}

return false;

#define input_device_check_any_released

/// @arg device

if ( global.Input_Ignore ) {
	return false;
}

if ( argument0 == -1 ) {	// Check keyboard
	
	if ( keyboard_check_released(vk_anykey) ) {
		return keyboard_lastkey;
	} else {
		if ( mouse_check_button_released(mb_any) ) {
			return mouse_lastbutton;
		}
	}
	
} else {	// Check gamepads
	
	for ( var i = gp_face1; i < gp_axisrv + 1; ++ i; ) {
		if ( i == gp_axislh || i == gp_axislv || i == gp_axisrh || i == gp_axisrv ) {
			var _axis_value = gamepad_axis_value(argument0,i);
			if ( _axis_value != 0 ) {
				if ( i == gp_axislh ) {
					if ( _axis_value > 0 ) {
						return input_axislr;
					} else {
						return input_axisll;
					}
				}
				
				if ( i == gp_axislv ) {
					if ( _axis_value > 0 ) {
						return input_axisld;
					} else {
						return input_axislu;
					}
				}
				
				if ( i == gp_axisrh ) {
					if ( _axis_value > 0 ) {
						return input_axisrr;
					} else {
						return input_axisrl;
					}
				}
				
				if ( i == gp_axisrv ) {
					if ( _axis_value > 0 ) {
						return input_axisrd;
					} else {
						return input_axisru;
					}
				}
			}
		} else {
			if ( gamepad_button_check_released(argument0,i) ) { return i; }
		}
	}
	
}

return false;

#define input_check

/// @arg player,keycode

if ( global.Input_Ignore ) {
	return false;
}

var _list = global.Input_Player_Device[? argument0];

for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
	if ( _list[| i] != -1 && argument1 >= gp_face1 && argument1 <= gp_axisrv && gamepad_button_check(_list[| i],argument1) ) {
		return true;
	} else if ( argument1 >= input_axislu && argument1 <= input_axisrr ) {
		return input_check_axis_pressed(argument0,argument1) || input_check_axis_held(argument0,argument1);
	} else if ( _list[| i] == -1 && argument1 != -1 && mouse_check_button(argument1) ) {
		return true;
	} else if ( _list[| i] == -1 && argument1 != 1 && keyboard_check(argument1) ) {
		return true;
	}
}

return false;

#define input_check_pressed

/// @arg player,keycode

if ( global.Input_Ignore ) {
	return false;
}

var _list = global.Input_Player_Device[? argument0];

for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
	if ( _list[| i] != -1 && argument1 >= gp_face1 && argument1 <= gp_axisrv && gamepad_button_check_pressed(_list[| i],argument1) ) {
		return true;
	} else if ( argument1 >= input_axislu && argument1 <= input_axisrr ) {
		return input_check_axis_pressed(argument0,argument1);
	} else if ( _list[| i] == -1 && argument1 != -1 && mouse_check_button_pressed(argument1) ) {
		return true;
	} else if ( _list[| i] == -1 && argument1 != 1 && keyboard_check_pressed(argument1) ) {
		return true;
	}
}

return false;

#define input_check_released

/// @arg player,keycode

if ( global.Input_Ignore ) {
	return false;
}

var _list = global.Input_Player_Device[? argument0];

for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
	if ( _list[| i] != -1 && argument1 >= gp_face1 && argument1 <= gp_axisrv && gamepad_button_check_released(_list[| i],argument1) ) {
		return true;
	} else if ( argument1 >= input_axislu && argument1 <= input_axisrr ) {
		return input_check_axis_released(argument0,argument1);
	} else if ( _list[| i] == -1 && argument1 != -1 && mouse_check_button_released(argument1) ) {
		return true;
	} else if ( _list[| i] == -1 && argument1 != 1 && keyboard_check_released(argument1) ) {
		return true;
	}
}

return false;

#define input_action_check_all

/// @arg action

for ( var i = 0; i < global.Input_Max_Players; ++ i; ) {
	if ( input_action_check(i,0,argument0) ) {
		return true;
	}
}

return false;

#define input_action_check_pressed_all

/// @arg action

for ( var i = 0; i < global.Input_Max_Players; ++ i; ) {
	if ( input_action_check_pressed(i,0,argument0) ) {
		return true;
	}
}

return false;

#define input_action_check_released_all

/// @arg action

for ( var i = 0; i < global.Input_Max_Players; ++ i; ) {
	if ( input_action_check_released(i,0,argument0) ) {
		return true;
	}
}

return false;

#define input_action_check_axis_all

/// @arg action

var _axis = 0;

for ( var i = 0; i < global.Input_Max_Players; ++ i; ) {
	_axis += input_action_check_axis(i,0,argument0);
}

return _axis;

#define input_check_axis

/// @arg player,keycode

if ( global.Input_Ignore ) {
	return false;
}

var
_list = global.Input_Player_Device[? argument0],
_axis_value = 0;

for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
	if ( _list[| i] != -1 ) {
		switch ( argument1 ) {
			case input_axislu:
				if ( gamepad_axis_value(_list[| i],gp_axislv) < 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axislv);
				}
			break;
			
			case input_axisld:
				if ( gamepad_axis_value(_list[| i],gp_axislv) > 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axislv);
				}
			break;
			
			case input_axisll:
				if ( gamepad_axis_value(_list[| i],gp_axislh) < 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axislh);
				}
			break;
			
			case input_axislr:
				if ( gamepad_axis_value(_list[| i],gp_axislh) > 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axislh);
				}
			break;
			
			case input_axisru:
				if ( gamepad_axis_value(_list[| i],gp_axisrv) < 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axisrv);
				}
			break;
			
			case input_axisrd:
				if ( gamepad_axis_value(_list[| i],gp_axisrv) > 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axisrv);
				}
			break;
			
			case input_axisrl:
				if ( gamepad_axis_value(_list[| i],gp_axisrh) < 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axisrh);
				}
			break;
			
			case input_axisrr:
				if ( gamepad_axis_value(_list[| i],gp_axisrh) > 0 ) {
					_axis_value = gamepad_axis_value(_list[| i],gp_axisrh);
				}
			break;
		}
	}
	
	if ( _axis_value != 0 ) {
		return _axis_value;
	}
}

return 0;

#define input_check_axis_pressed

/// @arg player,keycode

if ( global.Input_Ignore ) {
	return false;
}

var
_list = global.Input_Player_Device[? argument0],
_axis_list;

for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
	if ( _list[| i] != -1 && ds_list_find_index(global.Input_Device_List,_list[| i]) != -1 ) {
		_axis_list = global.Input_Axis_Map[? _list[| i]];
		switch ( argument1 ) {
			case input_axislu:
				if ( _axis_list[| 0] == 1 ) {
					return true;
				}
			break;
			
			case input_axisld:
				if ( _axis_list[| 1] == 1 ) {
					return true;
				}
			break;
			
			case input_axisll:
				if ( _axis_list[| 2] == 1 ) {
					return true;
				}
			break;
			
			case input_axislr:
				if ( _axis_list[| 3] == 1 ) {
					return true;
				}
			break;
			
			case input_axisru:
				if ( _axis_list[| 4] == 1 ) {
					return true;
				}
			break;
			
			case input_axisrd:
				if ( _axis_list[| 5] == 1 ) {
					return true;
				}
			break;
			
			case input_axisrl:
				if ( _axis_list[| 6] == 1 ) {
					return true;
				}
			break;
			
			case input_axisrr:
				if ( _axis_list[| 7] == 1 ) {
					return true;
				}
			break;
		}
	}
}

return 0;

#define input_check_axis_held

/// @arg player,keycode

if ( global.Input_Ignore ) {
	return false;
}

var
_list = global.Input_Player_Device[? argument0],
_axis_list;

for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
	if ( _list[| i] != -1 && ds_list_find_index(global.Input_Device_List,_list[| i]) != -1 ) {
		_axis_list = global.Input_Axis_Map[? _list[| i]];
		switch ( argument1 ) {
			case input_axislu:
				if ( _axis_list[| 0] == 2 ) {
					return true;
				}
			break;
			
			case input_axisld:
				if ( _axis_list[| 1] == 2 ) {
					return true;
				}
			break;
			
			case input_axisll:
				if ( _axis_list[| 2] == 2 ) {
					return true;
				}
			break;
			
			case input_axislr:
				if ( _axis_list[| 3] == 2 ) {
					return true;
				}
			break;
			
			case input_axisru:
				if ( _axis_list[| 4] == 2 ) {
					return true;
				}
			break;
			
			case input_axisrd:
				if ( _axis_list[| 5] == 2 ) {
					return true;
				}
			break;
			
			case input_axisrl:
				if ( _axis_list[| 6] == 2 ) {
					return true;
				}
			break;
			
			case input_axisrr:
				if ( _axis_list[| 7] == 2 ) {
					return true;
				}
			break;
		}
	}
}

return 0;

#define input_check_axis_released

/// @arg player,keycode

if ( global.Input_Ignore ) {
	return false;
}

var
_list = global.Input_Player_Device[? argument0],
_axis_list;

for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
	if ( _list[| i] != -1 && ds_list_find_index(global.Input_Device_List,_list[| i]) != -1 ) {
		_axis_list = global.Input_Axis_Map[? _list[| i]];
		switch ( argument1 ) {
			case input_axislu:
				if ( _axis_list[| 0] == 3 ) {
					return true;
				}
			break;
			
			case input_axisld:
				if ( _axis_list[| 1] == 3 ) {
					return true;
				}
			break;
			
			case input_axisll:
				if ( _axis_list[| 2] == 3 ) {
					return true;
				}
			break;
			
			case input_axislr:
				if ( _axis_list[| 3] == 3 ) {
					return true;
				}
			break;
			
			case input_axisru:
				if ( _axis_list[| 4] == 3 ) {
					return true;
				}
			break;
			
			case input_axisrd:
				if ( _axis_list[| 5] == 3 ) {
					return true;
				}
			break;
			
			case input_axisrl:
				if ( _axis_list[| 6] == 3 ) {
					return true;
				}
			break;
			
			case input_axisrr:
				if ( _axis_list[| 7] == 3 ) {
					return true;
				}
			break;
		}
	}
}

return false;

#define input_device_check

/// @arg device,keycode

if ( global.Input_Ignore ) {
	return false;
}

var _list = argument0;

if ( argument0 == -1 ) {
	return (keyboard_check(argument1) || mouse_check_button(argument1));
} else {
	return gamepad_button_check(argument0,argument1);
}

#define input_get_keyname

/// @arg keycode

switch ( argument0 ) {
    case $00: { return "<none>"; } //none
    case mb_left: { return "LMB"; } //Left mouse button
    case mb_right: { return "RMB"; } //Right mouse button
    case mb_middle: { return "MMB"; } //Middle mouse button (three-button mouse: { return ""; } //    
    case $05: { return "XB1"; } //Windows 2000/XP: { return ""; } X1 mouse button        
    case $06: { return "XB2"; } //Windows 2000/XP: { return ""; } X2 mouse button        
    case $08: { return "BACK"; } //BACKSPACE key        
    case $09: { return "TAB"; } //TAB key
    case $0C: { return "CLEAR"; } //CLEAR key
    case $0D: { return "ENTER"; } //ENTER key
    case $10: { return "SHFT"; } //SHIFT key        
    case $11: { return "CTRL"; } //CTRL key        
    case $12: { return "ALT"; } //ALT key        
    case $13: { return "PAUSE"; } //PAUSE key        
    case $14: { return "CAPS"; } //CAPS LOCK key        
    case $15: { return "HANGUL"; } //IME Hangul mode        
    case $17: { return "JUNJA"; } //IME Junja mode        
    case $18: { return "FINAL"; } //IME final mode        
    case $19: { return "HANJA"; } //IME Hanja mode            
    case $1B: { return "ESC"; } //ESC key        
    case $1C: { return "CONV"; } //IME convert        
    case $1D: { return "NCONV"; } //IME nonconvert        
    case $1E: { return "ACC"; } //IME accept        
    case $1F: { return "MC"; } //IME mode change request        
    case $20: { return "SPC"; } //SPACEBAR        
    case $21: { return "PGUP"; } //PAGE UP key        
    case $22: { return "PGDN"; } //PAGE DOWN key        
    case $23: { return "END"; } //END key        
    case $24: { return "HOME"; } //HOME key        
    case $25: { return "ARROW LEFT"; } //LEFT ARROW key        
    case $26: { return "ARROW UP"; } //UP ARROW key        
    case $27: { return "ARROW RIGHT"; } //RIGHT ARROW key        
    case $28: { return "ARROW DOWN"; } //DOWN ARROW key        
    case $29: { return "SEL"; } //SELECT key        
    case $2A: { return "PRINT"; } //PRINT key        
    case $2B: { return "EXE"; } //EXECUTE key        
    case $2C: { return "PRINT SCR"; } //PRINT SCREEN key        
    case $2D: { return "INS"; } //INS key        
    case $2E: { return "DEL"; } //DEL key        
    case $2F: { return "HELP"; } //HELP key        
    case $30: { return "[0]"; } //0 key        
    case $31: { return "[1]"; } //1 key        
    case $32: { return "[2]"; } //2 key        
    case $33: { return "[3]"; } //3 key        
    case $34: { return "[4]"; } //4 key        
    case $35: { return "[5]"; } //5 key        
    case $36: { return "[6]"; } //6 key        
    case $37: { return "[7]"; } //7 key        
    case $38: { return "[8]"; } //8 key        
    case $39: { return "[9]"; } //9 key        
    case $41: { return "[A]"; } //A key        
    case $42: { return "[B]"; } //B key        
    case $43: { return "[C]"; } //C key        
    case $44: { return "[D]"; } //D key        
    case $45: { return "[E]"; } //E key        
    case $46: { return "[F]"; } //F key        
    case $47: { return "[G]"; } //G key        
    case $48: { return "[H]"; } //H key        
    case $49: { return "[I]"; } //I key        
    case $4A: { return "[J]"; } //J key        
    case $4B: { return "[K]"; } //K key        
    case $4C: { return "[L]"; } //L key        
    case $4D: { return "[M]"; } //M key        
    case $4E: { return "[N]"; } //N key        
    case $4F: { return "[O]"; } //O key        
    case $50: { return "[P]"; } //P key        
    case $51: { return "[Q]"; } //Q key        
    case $52: { return "[R]"; } //R key        
    case $53: { return "[S]"; } //S key        
    case $54: { return "[T]"; } //T key        
    case $55: { return "[U]"; } //U key        
    case $56: { return "[V]"; } //V key        
    case $57: { return "[W]"; } //W key        
    case $58: { return "[X]"; } //X key        
    case $59: { return "[Y]"; } //Y key        
    case $5A: { return "[Z]"; } //Z key        
    case $5B: { return "LWIN"; } //Left Windows key (Microsoft Natural keyboard: { return ""; }        
    case $5C: { return "RWIN"; } //Right Windows key (Natural keyboard: { return ""; } //    
    case $5D: { return "APPS"; } //Applications key (Natural keyboard: { return ""; } //    
    case $5F: { return "SLEEP"; } //Computer Sleep key        
    case $60: { return "NUM0"; } //Numeric keypad 0 key        
    case $61: { return "NUM1"; } //Numeric keypad 1 key        
    case $62: { return "NUM2"; } //Numeric keypad 2 key        
    case $63: { return "NUM3"; } //Numeric keypad 3 key        
    case $64: { return "NUM4"; } //Numeric keypad 4 key        
    case $65: { return "NUM5"; } //Numeric keypad 5 key        
    case $66: { return "NUM6"; } //Numeric keypad 6 key        
    case $67: { return "NUM7"; } //Numeric keypad 7 key        
    case $68: { return "NUM8"; } //Numeric keypad 8 key        
    case $69: { return "NUM9"; } //Numeric keypad 9 key        
    case $6A: { return "*"; } //Multiply key        
    case $6B: { return "+"; } //Add key        
    case $6C: { return "SEP"; } //Separator key        
    case $6D: { return "-"; } //Subtract key        
    case $6E: { return ","; } //Decimal key        
    case $6F: { return "/"; } //Divide key        
    case $70: { return "F1"; } //F1 key        
    case $71: { return "F2"; } //F2 key        
    case $72: { return "F3"; } //F3 key        
    case $73: { return "F4"; } //F4 key        
    case $74: { return "F5"; } //F5 key        
    case $75: { return "F6"; } //F6 key        
    case $76: { return "F7"; } //F7 key        
    case $77: { return "F8"; } //F8 key        
    case $78: { return "F9"; } //F9 key        
    case $79: { return "F10"; } //F10 key        
    case $7A: { return "F11"; } //F11 key        
    case $7B: { return "F12"; } //F12 key        
    case $7C: { return "F13"; } //F13 key        
    case $7D: { return "F14"; } //F14 key        
    case $7E: { return "F15"; } //F15 key        
    case $7F: { return "F16"; } //F16 key        
    case $80: { return "F17"; } //F17 key        
    case $81: { return "F18"; } //F18 key        
    case $82: { return "F19"; } //F19 key        
    case $83: { return "F20"; } //F20 key        
    case $84: { return "F21"; } //F21 key        
    case $85: { return "F22"; } //F22 key        
    case $86: { return "F23"; } //F23 key        
    case $87: { return "F24"; } //F24 key        
    case $90: { return "NUMLOCK"; } //NUM LOCK key        
    case $91: { return "SCROLL"; } //SCROLL LOCK key        
    case $A0: { return "LSHIFT"; } //Left SHIFT key        
    case $A1: { return "RSHIFT"; } //Right SHIFT key        
    case $A2: { return "LCTRL"; } //Left CONTROL key        
    case $A3: { return "RCTRL"; } //Right CONTROL key        
    case $A4: { return "LALT"; } //Left MENU key        
    case $A5: { return "RALT"; } //Right MENU key        
    case $A6: { return "BRBACK"; } //Windows 2000/XP: { return ""; } Browser Back key        
    case $A7: { return "BRFORWARD"; } //Windows 2000/XP: { return ""; } Browser Forward key        
    case $A8: { return "BRREFRESH"; } //Windows 2000/XP: { return ""; } Browser Refresh key        
    case $A9: { return "BRSTOP"; } //Windows 2000/XP: { return ""; } Browser Stop key        
    case $AA: { return "BRSEARCH"; } //Windows 2000/XP: { return ""; } Browser Search key        
    case $AB: { return "BRFAVORITES"; } //Windows 2000/XP: { return ""; } Browser Favorites key        
    case $AC: { return "BRHOME"; } //Windows 2000/XP: { return ""; } Browser Start and Home key        
    case $AD: { return "VOLMUTE"; } //Windows 2000/XP: { return ""; } Volume Mute key        
    case $AE: { return "VOLDOWN"; } //Windows 2000/XP: { return ""; } Volume Down key        
    case $AF: { return "VOLUP"; } //Windows 2000/XP: { return ""; } Volume Up key        
    case $B0: { return "MEDNEXT"; } //Windows 2000/XP: { return ""; } Next Track key        
    case $B1: { return "MEDPREV"; } //Windows 2000/XP: { return ""; } Previous Track key        
    case $B2: { return "MEDSTOP"; } //Windows 2000/XP: { return ""; } Stop Media key        
    case $B3: { return "MEDPLAY"; } //Windows 2000/XP: { return ""; } Play/Pause Media key        
    case $B4: { return "MAIL"; } //Windows 2000/XP: { return ""; } Start Mail key        
    case $B5: { return "MEDIA"; } //Windows 2000/XP: { return ""; } Select Media key        
    case $B6: { return "APP1"; } //Windows 2000/XP: { return ""; } Start Application 1 key        
    case $B7: { return "APP2"; } //Windows 2000/XP: { return ""; } Start Application 2 key        
    case $BA: { return ":"; } //Used for miscellaneous characters; it can vary by keyboard.        
    case $BB: { return "+"; } //Windows 2000/XP: { return ""; } For any country/region, the '+' key        
    case $BC: { return ","; } //Windows 2000/XP: { return ""; } For any country/region, the ',' key        
    case $BD: { return "-"; } //Windows 2000/XP: { return ""; } For any country/region, the '-' key        
    case $BE: { return "."; } //Windows 2000/XP: { return ""; } For any country/region, the '.' key        
    case $BF: { return "?"; } //Used for miscellaneous characters; it can vary by keyboard.        
    case $C0: { return "~"; } //Used for miscellaneous characters; it can vary by keyboard.        
    case $DB: { return "["; } //Used for miscellaneous characters; it can vary by keyboard.        
    case $DC: { return "\\"; } //Used for miscellaneous characters; it can vary by keyboard.        
    case $DD: { return "]"; } //Used for miscellaneous characters; it can vary by keyboard.        
    case $DE: { return "'"; } //Used for miscellaneous characters; it can vary by keyboard.        
    case $E5: { return "PROCESS"; } //Windows 95/98/Me, Windows NT 4.0, Windows 2000/XP: { return ""; } IME PROCESS key        
    case $E7: { return "PACKET"; } //Windows 2000/XP: { return ""; } Used to pass Unicode characters as if they were keystrokes. The PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT, SendInput, WM_KEYDOWN, and WM_KEYUP        
    case $F6: { return "ATTN"; } //Attn key  
    case $F7: { return "CRSEL"; } //CrSel key  
    case $F8: { return "EXSEL"; } //ExSel key  
    case $F9: { return "EREOF"; } //Erase EOF key  
    case $FA: { return "PLAY"; } //Play key  
    case $FB: { return "ZOOM"; } //Zoom key  
    case $FD: { return "PA1"; } //PA1 key  
    case $FE: { return "CLEAR"; } //Clear key
	case gp_face1: {return "A"; }
	case gp_face2: { return "B"; }
	case gp_face3: { return "X"; }
	case gp_face4: { return "Y"; }
	case gp_shoulderl: { return "LB"; }
	case gp_shoulderr: { return "RB"; }
	case gp_shoulderlb: { return "LT"; }
	case gp_shoulderrb: { return "RT"; }
	case gp_select: { return "SELECT"; }
	case gp_start: { return "START"; }
	case gp_stickl: { return "L STICK"; }
	case gp_stickr: { return "R STICK"; }
	case gp_padu: { return "DPAD UP"; }
	case gp_padd: { return "DPAD DOWN"; }
	case gp_padl: { return "DPAD LEFT"; }
	case gp_padr: { return "DPAD RIGHT"; }
	case input_axislu: { return "L AXIS UP"; }
	case input_axisld: { return "L AXIS DOWN"; }
	case input_axisll: { return "L AXIS LEFT"; }
	case input_axislr: { return "L AXIS RIGHT"; }
	case input_axisru: { return "R AXIS UP"; }
	case input_axisrd: { return "R AXIS DOWN"; }
	case input_axisrl: { return "R AXIS LEFT"; }
	case input_axisrr: { return "R AXIS RIGHT"; }

    default: { return "UNSUPPORTED"; }    
}


#define input_action_check

/// @arg player,bind_index,action

if ( global.Input_Ignore ) {
	return false;
}

var _list = input_action_get_key(argument0,argument1,argument2);

if ( _list != -1 ) {
	for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
		if ( input_check(argument0,_list[| i]) || input_buffer_get(argument0,argument1,argument2) ) {
			return true;
		}
	}
}

return false;

#define input_action_check_axis

/// @arg player,bind_index,action

if ( global.Input_Ignore ) {
	return false;
}

var
_list = input_action_get_key(argument0,argument1,argument2),
_axis_value = 0;

if ( _list != -1 ) {
	for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
		_axis_value += input_check_axis(argument0,_list[| i]);
	}
}

if ( abs(_axis_value) > .4 ) {
	_axis_value = sign(_axis_value);
}

return _axis_value;

#define input_action_check_axis_pressed

/// @arg player,bind_index,action

if ( global.Input_Ignore ) {
	return false;
}

var _list = input_action_get_key(argument0,argument1,argument2);

if ( _list != -1 ) {
	for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
		if ( input_check_axis_pressed(argument0,_list[| i]) ) {
			return true;
		}
	}
}

return false;

#define input_action_check_axis_held

/// @arg player,bind_index,action

if ( global.Input_Ignore ) {
	return false;
}

var _list = input_action_get_key(argument0,argument1,argument2);

if ( _list != -1 ) {
	for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
		if ( input_check_axis_held(argument0,_list[| i]) ) {
			return true;
		}
	}
}

return false;

#define input_action_check_axis_released

/// @arg player,bind_index,action

if ( global.Input_Ignore ) {
	return false;
}

var _list = input_action_get_key(argument0,argument1,argument2);

if ( _list != -1 ) {
	for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
		if ( input_check_axis_released(argument0,_list[| i]) ) {
			return true;
		}
	}
}

return false;

#define input_action_check_pressed

/// @arg player,bind_index,action

if ( global.Input_Ignore ) {
	return false;
}

var _list = input_action_get_key(argument0,argument1,argument2);
var _devices = input_player_device_list(argument0);

if ( _list != -1 ) 
{
	for ( var i = 0; i < ds_list_size(_list); ++ i; ) 
	{
		if (_list[| i] >= input_axislu && _list[| i] <= input_axisrr ) 
		{
			if ( input_check_axis_pressed(argument0,_list[| i]) ) 
			{
				return true;
			}
		} 
		else if ( input_check_pressed(argument0,_list[| i]) || input_buffer_get_pressed(argument0,argument1,argument2) ) 
		{
			return true;
		}
	}
}

return false;

#define input_action_check_released

/// @arg player,bind_index,action

if ( global.Input_Ignore ) {
	return false;
}

var _list = input_action_get_key(argument0,argument1,argument2);
var _devices = input_player_device_list(argument0);

if ( _list != -1 ) {
	for ( var i = 0; i < ds_list_size(_list); ++ i; ) {
		if ( _list[| i] >= input_axislu && _list[| i] <= input_axisrr ) {
			if ( input_check_axis_released(argument0,_list[| i]) ) {
				return true;
			}
		} else if ( input_check_released(argument0,_list[| i]) || input_buffer_get_released(argument0,argument1,argument2) ) {
			return true;
		}
	}
}

return false;

#define input_device_assign_pressed

/// @arg player

var _device = input_device_get_any_pressed();
if ( _device != noone && ds_list_find_index(input_player_device_list(argument0),_device) == -1 ) {
	if ( input_player_device_assign(argument0,_device) ) {
		return true;
	}
}

return false;

#define input_device_get_any_pressed

var _key_pressed = false;
for ( var i = 0; i < ds_list_size(global.Input_Device_List); ++ i; ) {
	if ( input_device_check_any_pressed(global.Input_Device_List[| i]) ) {
		return global.Input_Device_List[| i];
	}
}

return noone;

#define input_action_assign_key

/// @arg player,bind_index,action,<keys>

// bind_index should start from 0 and go up

var _bind_index = argument[1];

// Add a ds list for all of our bindings
if ( !ds_map_exists(global.Input_Action_Map,argument[0]) ) {
	global.Input_Action_Map[? argument[0]] = ds_list_create();
}

var _list = global.Input_Action_Map[? argument[0]];
if ( _list[| argument[1]] == undefined ) {
	ds_list_add(_list,ds_map_create());
	_bind_index = ds_list_size(_list) - 1;
}

var _map = _list[| _bind_index];
// Assign _list to our binding list for the action
if ( ds_map_exists(_map,argument[2]) ) {
	_list = _map[? argument[2]];
} else {
	_map[? argument[2]] = ds_list_create();
	_list = _map[? argument[2]];
}

// Assign keys to our action
for ( var i = 3; i < argument_count; ++ i; ) {
	ds_list_add(_list,argument[i]);
}

return true;

#define input_action_get_key

/// @arg player,bind_index,action

// bind_index should start from 0 and go up

var _bind_index = argument[1];

if ( !ds_map_exists(global.Input_Action_Map,argument[0]) ) {
	return -1;
}

var _list = global.Input_Action_Map[? argument[0]];
if ( _list[| argument[1]] == undefined ) {
	return -1;
}

// Get our list of keys
var _map = _list[| _bind_index];
if ( ds_map_exists(_map,argument[2]) ) {
	return _map[? argument[2]];
} else {
	return -1;
}

#define input_action_remove_key

/// @arg player,bind_index,action,<keys>

// bind_index should start from 0 and go up

var _bind_index = argument[1];

// Add a ds list for all of our bindings
if ( !ds_map_exists(global.Input_Action_Map,argument[0]) ) {
	return false;
}

var _list = global.Input_Action_Map[? argument[0]];
if ( _list[| argument[1]] == undefined ) {
	return false;
}

// Assign _list to our binding list for the action
var _map = _list[| _bind_index];
if ( ds_map_exists(_map,argument[2]) ) {
	_list = _map[? argument[2]];
} else {
	return false;
}

// Assign keys to our action
for ( var _index, i = 3; i < argument_count; ++ i; ) {
	_index = ds_list_find_index(_list,argument[i]);
	if ( _index != -1 ) {
		ds_list_delete(_list,_index);
	}
}

#define input_action_remove_all

/// @arg player,bind_index,action

// bind_index should start from 0 and go up

var _bind_index = argument[1];

// Add a ds list for all of our bindings
if ( !ds_map_exists(global.Input_Action_Map,argument[0]) ) {
	return false;
}

var _list = global.Input_Action_Map[? argument[0]];
if ( _list[| argument[1]] == undefined ) {
	return false;
}

// Assign _list to our binding list for the action
var _map = _list[| _bind_index];
if ( ds_map_exists(_map,argument[2]) ) {
	_list = _map[? argument[2]];
} else {
	return false;
}

ds_list_clear(_list);

#define input_update

/// @desc This should be in the begin step event

global.Input_Ignore = false;

var
_device_count = ds_list_size(global.Input_Device_List),
_device_id,
_axis_list,
_axis_value,
_axis_deadzone,
_player;

for ( var i = 0; i < _device_count; ++ i; ) {
	_device_id = global.Input_Device_List[| i];
	_player = -1;
	for ( var _player_ind = 0; _player_ind < global.Input_Player_Limit; ++ _player_ind; ) {
		if ( ds_list_find_index(global.Input_Player_Device[? _player_ind],_device_id) != -1 ) {
			_player = _player_ind;
			break;
		}
	}
	
	if ( _player != -1 ) {
		
		_axis_deadzone = global.Input_Axis_Deadzone_Player[_player];
		if ( _device_id >= 0 ) {
			_axis_list = global.Input_Axis_Map[? _device_id];
			
			#region Axis, Left Up
			_axis_value = gamepad_axis_value(_device_id,gp_axislv);
			switch ( _axis_list[| 0] ) {
				case 0:	// Untouched
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 0] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 0] = 2;
					} else if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 0] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 0] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 0] = 1;
					} else {
						_axis_list[| 0] = 0;
					}
				break;
			}
			#endregion
			#region Axis, Left Down
			_axis_value = gamepad_axis_value(_device_id,gp_axislv);
			switch ( _axis_list[| 1] ) {
				case 0:	// Untouched
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 1] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 1] = 2;
					} else if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 1] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 1] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 1] = 1;
					} else {
						_axis_list[| 1] = 0;
					}
				break;
			}
			#endregion
			#region Axis, Left Left
			_axis_value = gamepad_axis_value(_device_id,gp_axislh);
			switch ( _axis_list[| 2] ) {
				case 0:	// Untouched
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 2] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 2] = 2;
					} else if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 2] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 2] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 2] = 1;
					} else {
						_axis_list[| 2] = 0;
					}
				break;
			}
			#endregion
			#region Axis, Left Right
			_axis_value = gamepad_axis_value(_device_id,gp_axislh);
			switch ( _axis_list[| 3] ) {
				case 0:	// Untouched
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 3] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 3] = 2;
					} else if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 3] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 3] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 3] = 1;
					} else {
						_axis_list[| 3] = 0;
					}
				break;
			}
			#endregion
			#region Axis, Right Up
			_axis_value = gamepad_axis_value(_device_id,gp_axisrv);
			switch ( _axis_list[| 4] ) {
				case 0:	// Untouched
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 4] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 4] = 2;
					} else if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 4] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 4] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 4] = 1;
					} else {
						_axis_list[| 4] = 0;
					}
				break;
			}
			#endregion
			#region Axis, Right Down
			_axis_value = gamepad_axis_value(_device_id,gp_axisrv);
			switch ( _axis_list[| 5] ) {
				case 0:	// Untouched
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 5] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 5] = 2;
					} else if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 5] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 5] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 5] = 1;
					} else {
						_axis_list[| 5] = 0;
					}
				break;
			}
			#endregion
			#region Axis, Right Left
			_axis_value = gamepad_axis_value(_device_id,gp_axisrh);
			switch ( _axis_list[| 6] ) {
				case 0:	// Untouched
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 6] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 6] = 2;
					} else if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 6] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value > -_axis_deadzone ) {
						_axis_list[| 6] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value <= -_axis_deadzone ) {
						_axis_list[| 6] = 1;
					} else {
						_axis_list[| 6] = 0;
					}
				break;
			}
			#endregion
			#region Axis, Right Right
			_axis_value = gamepad_axis_value(_device_id,gp_axisrh);
			switch ( _axis_list[| 7] ) {
				case 0:	// Untouched
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 7] = 1;
					}
				break;
				
				case 1:	// Pressed
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 7] = 2;
					} else if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 7] = 0;
					}
				break;
				
				case 2:	// Held
					if ( _axis_value < _axis_deadzone ) {
						_axis_list[| 7] = 3;
					}
				break;
				
				case 3:	// Released
					if ( _axis_value >= _axis_deadzone ) {
						_axis_list[| 7] = 1;
					} else {
						_axis_list[| 7] = 0;
					}
				break;
			}
			#endregion
		}
	}
}

for ( var i = 0; i < ds_list_size(global.Input_Buffer); ++ i; ) {
	if ( ds_list_find_value(global.Input_Buffer[| i],InputBuffer.Ready) ) {
		var
		_player_reference_map = global.Input_Buffer_Reference[| ds_list_find_value(global.Input_Buffer[| i],InputBuffer.Player)],
		_button_list = _player_reference_map[? ds_list_find_value(global.Input_Buffer[| i],InputBuffer.Button)];
		
		ds_list_delete(_button_list,ds_list_find_index(_button_list,global.Input_Buffer[| i]));
		ds_list_destroy(global.Input_Buffer[| i]);
		ds_list_delete(global.Input_Buffer,i);
		-- i;
	} else if ( ds_list_find_value(global.Input_Buffer[| i],InputBuffer.Delay) + global.Input_Buffer_Reference < current_time || ds_list_find_value(global.Input_Buffer[| i],InputBuffer.Delay) == -1 ) {
		ds_list_set(global.Input_Buffer[| i],InputBuffer.Ready,true);
	}
}

#define input_buffer_delay

/// @desc Sets a global delay for all input buffering
/// @arg Delay

global.Input_Buffer_Delay = argument0;

#define input_clear

global.Input_Ignore = true;

#define input_is_keyboard_key

/// @arg keycode

switch ( argument0 ) {
    case $00:
    case mb_left:
    case mb_right:
    case mb_middle:
    case $05:
    case $06:
    case $08:
    case $09:
    case $0C:
    case $0D:
    case $10:
    case $11:
    case $12:
    case $13:
    case $14:
    case $15:
    case $17:
    case $18:
    case $19:
    case $1B:
    case $1C:
    case $1D:
    case $1E:
    case $1F:
    case $20:
    case $21:
    case $22:
    case $23:
    case $24:
    case $25:
    case $26:
    case $27:
    case $28:
    case $29:      
    case $2A:
    case $2B:
    case $2C:
    case $2D:
    case $2E:
    case $2F:
    case $30:
    case $31:
    case $32:
    case $33:
    case $34:
    case $35:
    case $36:
    case $37:
    case $38:
    case $39:
    case $41:
    case $42:
    case $43:
    case $44:
    case $45:
    case $46:
    case $47:
    case $48:
    case $49:
    case $4A:
    case $4B:
    case $4C:
    case $4D:
    case $4E:
    case $4F:
    case $50:
    case $51:
    case $52:
    case $53:
    case $54:
    case $55:
    case $56:
    case $57:
    case $58:
    case $59:
    case $5A:
    case $5B:
    case $5C:
    case $5D:
    case $5F:
    case $60:
    case $61:
    case $62:
    case $63:
    case $64:
    case $65:
    case $66:
    case $67:
    case $68:
    case $69:
    case $6A:
    case $6B:
    case $6C:
    case $6D:
    case $6E:
    case $6F:
    case $70:
    case $71:
    case $72:
    case $73:
    case $74:
    case $75:
    case $76:
    case $77:
    case $78:
    case $79:
    case $7A:
    case $7B:
    case $7C:
    case $7D:
    case $7E:
    case $7F:
    case $80:
    case $81:
    case $82:
    case $83:
    case $84:
    case $85:
    case $86:
    case $87:
    case $90:
    case $91:
    case $A0:
    case $A1:
    case $A2:
    case $A3:
    case $A4:
    case $A5:
    case $A6:
    case $A7:
    case $A8:
    case $A9:
    case $AA:
    case $AB:
    case $AC:
    case $AD:
    case $AE:
    case $AF:
    case $B0:
    case $B1:
    case $B2:
    case $B3:
    case $B4:
    case $B5:
    case $B6:
    case $B7:
    case $BA:
    case $BB:
    case $BC:
    case $BD:
    case $BE:
    case $BF:
    case $C0:
    case $DB:
    case $DC:
    case $DD:
    case $DE:
    case $E5:
    case $E7:
    case $F6:
    case $F7:
    case $F8:
    case $F9:
    case $FA:
    case $FB:
    case $FD:
    case $FE:
	return true;
	break;

    default:
	return false;
	break;
}

#define input_buffer_add

/// @desc Add an input to the delay system
/// @arg player,bind_index,button,state,value,delay

/*
	player		-->		Player the input came from
	bind_index	-->		Bind index to use
	button		-->		Button pressed/held/released
	state		-->		Pressed, Held, or Released
	delay		-->		The time (in milliseconds) to delay the input
*/

var _list = ds_list_create();
ds_list_add(_list,argument0,argument1,argument2,argument3,argument4,current_time + argument5 + global.Input_Buffer_Delay,false);

// We're going to use nested lists to keep things nice and organized
ds_list_add(global.Input_Buffer,_list);

var
_player_inputbuffer = global.Input_Buffer_Reference[| argument0],
_player_buttonlist = _player_inputbuffer[? argument2];

ds_list_add(_player_buttonlist,_list);

#define input_buffer_get

/// @desc Check if our input is ready
/// @arg player,bind_index,button
var
_list = ds_map_find_value(global.Input_Buffer_Reference[| argument0],argument2),
_size = ds_list_size(_list);

// This is a list of all of the specificed buttons queued inputs
for ( var i = 0; i < _size; ++ i; ) {
	if (
		ds_list_find_value(_list[| i],InputBuffer.Ready) &&
		ds_list_find_value(_list[| i],InputBuffer.BindIndex) == argument1
	) {
		return ds_list_find_value(_list[| i],InputBuffer.Value);
	}
}

return false;

#define input_buffer_get_pressed

/// @desc Check if our input is ready
/// @arg player,bind_index,button

var
_list = ds_map_find_value(global.Input_Buffer_Reference[| argument0],argument2),
_size = ds_list_size(_list);

// This is a list of all of the specificed buttons queued inputs
for ( var i = 0; i < _size; ++ i; ) {
	if ( 
		ds_list_find_value(_list[| i],InputBuffer.Ready) &&
		ds_list_find_value(_list[| i],InputBuffer.BindIndex) == argument1 &&
		ds_list_find_value(_list[| i],InputBuffer.State) == InputBufferStates.Pressed
	) {
		return ds_list_find_value(_list[| i],InputBuffer.Value);
	}
}

return false;

#define input_buffer_get_released

/// @desc Check if our input is ready
/// @arg player,bind_index,button

var
_list = ds_map_find_value(global.Input_Buffer_Reference[| argument0],argument2),
_size = ds_list_size(_list);

// This is a list of all of the specificed buttons queued inputs
for ( var i = 0; i < _size; ++ i; ) {
	if ( 
		ds_list_find_value(_list[| i],InputBuffer.Ready) &&
		ds_list_find_value(_list[| i],InputBuffer.BindIndex) == argument1 &&
		ds_list_find_value(_list[| i],InputBuffer.State) == InputBufferStates.Released
	) {
		return ds_list_find_value(_list[| i],InputBuffer.Value);
	}
}

return false;

#define input_buffer_get_held

/// @desc Check if our input is ready
/// @arg player,bind_index,button

var
_list = ds_map_find_value(global.Input_Buffer_Reference[| argument0],argument2),
_size = ds_list_size(_list);

// This is a list of all of the specificed buttons queued inputs
for ( var i = 0; i < _size; ++ i; ) {
	if ( 
		ds_list_find_value(_list[| i],InputBuffer.Ready) &&
		ds_list_find_value(_list[| i],InputBuffer.BindIndex) == argument1 &&
		ds_list_find_value(_list[| i],InputBuffer.State) == InputBufferStates.Held
	) {
		return ds_list_find_value(_list[| i],InputBuffer.Value);
	}
}

return false;