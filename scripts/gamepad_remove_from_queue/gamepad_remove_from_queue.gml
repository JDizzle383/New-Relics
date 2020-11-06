/// @func gamepad_remove_from_queue( id )
/// @params id
function gamepad_remove_from_queue(argument0) {
	with ( oGamepadManager ) {
	    for ( var _i = 0; _i < ds_list_size( __gamepadPool ); _i++ ) {
	        if ( __gamepadPool[| _i ] == argument0 ) {
	            ds_list_delete( __gamepadPool, _i-- );
            
	        }
        
	    }
    
	}


}
