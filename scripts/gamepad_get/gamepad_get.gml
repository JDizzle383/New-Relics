/// @func gamepad_get( *index );
/// @params *index    optional: the 'slot' to get the gamepad from
function gamepad_get() {
	with ( oGamepadManager ) {
	    var _id        = ( argument_count > 0 ? argument[ 0 ] : 0 );
	    var _total    = ds_list_size( __gamepadPool );
	    var _pad;

	    if ( _total == 0 || _id >= _total ) {
	        log( object_get_name( other.object_index ), " couldn't get controller, list is empty!" );
        
	        return undefined;
        
	    }
	    log( object_get_name( other.object_index ), " got controller ", _id );
    
	    _pad    = __gamepadPool[| _id ];
    
	    ds_list_delete( __gamepadPool, _id );
    
	    return _pad;

	}


}
