/// @func *private __debug_log_values( values... )
/// @param values...
function __debug_log_values() {
	var _string = "";

	for ( var _i = 0; _i < argument_count; _i++ ) {
	    _string += string( argument[ _i ] );
    
	}
	show_debug_message( _string );

#macro log    __debug_log_values


}
