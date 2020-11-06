/// @description Insert description here
// You can write your code in this editor
if room = room0
{
    with ( oGamepadManager ) 
    {
        var _stop    = ds_list_size( __gamepadPool );
        var _slot;
    
        for ( var _i = 0; _i < _stop; _i++ ) 
        {
            _slot    = __gamepadPool[| _i ];
        
            if ( gamepad_button_check( _slot, 11 ) ) 
            {
            break; 
            }
            
        }
        if ( _i < _stop )
        {
        for ( var _u = 0; _u < array_length_1d( global.player_slots ); _u++ ) 
            {
            if ( global.player_slots[ _u ] == -1 )
                {
                global.player_slots[ _u ]    = gamepad_get( _i );
                
                with ( instance_create_layer( other.x, other.y, "Instances", oSelection ) ) 
                    {
                    playerId = _u;
                    
                    }
                
                }
                break;
            
            }
        }
    }
}