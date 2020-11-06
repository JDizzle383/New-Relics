/// @func gamepad_free( gamepad_id );
/// @params {int} gamepad_id    the id of the gamepad to return to the gamepad queue
function gamepad_free(argument0) {
	log( object_get_name( other.object_index ), " gave up controller ", argument0 );

	gamepad_add_to_queue( argument0 );


}
