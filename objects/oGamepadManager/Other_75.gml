/// @desc Gamepad Listener
var _action = async_load[? "event_type" ];
var _pad = async_load[? "pad_index" ];

switch(_action)
{
    case "gamepad lost" :
        gamepad_remove_from_queue( _pad );
        
        break;
    
    case "gamepad discovered" :
        gamepad_add_to_queue( _pad );
        
        break;
        
}