__gamepadPool = ds_list_create();        // a list of available gamepads

depth = -1;

instance_create_depth(0, 0, -1, oGamepadManager_Seek);

#macro DEADZONE 0.05
