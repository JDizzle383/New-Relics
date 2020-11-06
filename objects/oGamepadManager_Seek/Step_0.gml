/// @desc Find all plugged in gamepads
with ( oGamepadManager ) {
    var _gp_num = gamepad_get_device_count();
    
    for (var _i = 0; _i < _gp_num; _i++;) {
       if gamepad_is_connected( _i ) {
            gamepad_add_to_queue( _i );
            
        }
   
    }

}
room_goto_next();
