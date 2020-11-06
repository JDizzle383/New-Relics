// controls the movement of the picker
var _x    = x;
var _y    = y;
var myGamepad    = global.player_slots[ playerId ];

if ( myGamepad == -1 ) { exit; }
if ( moveTo == noone )
    {
// is the joystick being pressed?
    if gamepad_axis_value(myGamepad, gp_axislh) < 0
        {
        _x -= pickWidth
        }
    else if gamepad_axis_value(myGamepad, gp_axislh) > 0
        {
        _x += pickWidth 
        }
    if gamepad_axis_value(myGamepad, gp_axislv) < 0
        {
        _y -= pickHeight
        }
    else if gamepad_axis_value(myGamepad, gp_axislv) > 0
        {
        _y += pickHeight 
        }
    if gamepad_button_check_pressed(myGamepad, gp_face1)
        {
        room_goto_next();
        }
        
    if _x != x || _y != y 
        {
        if ( wait == 0 ) 
            {
            moveTo    = instance_position( _x, _y, oCharacter );    
            wait    = 30;
            
            }
        else 
            {
            wait -= 1; 
            }

        startX    = x;
        startY    = y;
            
        }
    else
        {
        wait        = 0;
        }
        
    }
else
    {
    if ( moveTime + 1 == moveSpeed )
        {
        x    = moveTo.x;
        y    = moveTo.y;
            
        moveTime    = 0;
        moveTo        = noone;
            
        }
    else
        {
        var _progress    = ( ++moveTime / moveSpeed );
            
        x    = lerp( startX, moveTo.x, _progress );
        y    = lerp( startY, moveTo.y, _progress );
        
        }
    
    }
    