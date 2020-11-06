/// @func gamepad_add_to_queue( id )
/// @params id
function gamepad_add_to_queue(argument0) {
	with ( oGamepadManager ) {
	    var _found    = false;
    
	    for ( var _i = 0; _i < ds_list_size( __gamepadPool ); _i++ ) {
	        if ( __gamepadPool[| _i ] == argument0 ) { _found = true; }
        
	    }
	    if ( !_found ) {
	        ds_list_add( __gamepadPool, argument0 );
        
	        gamepad_set_axis_deadzone( argument0, DEADZONE );
        
	    }
    
	}


}
