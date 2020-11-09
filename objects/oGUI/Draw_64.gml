  /*************************************************************/
 /*                       HEALTHBAR LEFT                      */
/*************************************************************/

/* Top windows */
draw_set_alpha(1);
draw_set_color(make_color_rgb(40, 40, 40));
draw_rectangle(-1, 0, camera_get_view_width(view_camera[0]), 30, 0);


// Draw health bar left
// Draw font
draw_sprite_ext(sHPLBAR_BG, image_index, HPL_pos_x, HPL_pos_y, HPL_scale_x, HPL_scale_y, image_angle, image_blend, image_alpha);
// Draw health
draw_sprite_part_ext(sHPLBAR, image_index, 0, 0, spriteWidth_L * hpPercent, spriteHeight_L, HPL_pos_x/camera_get_view_width(view_camera[0]) + 50, HPL_pos_y, HPL_scale_x, HPL_scale_y, image_blend, image_alpha);

// Draw glow
draw_sprite_ext(sHPLBAR_glow, image_index, HPL_pos_x, HPL_pos_y, HPL_scale_x, HPL_scale_y, image_angle, image_blend, image_alpha);
// Draw border left
draw_sprite_ext(sHPLSTART1, image_index, HPL_pos_x, HPL_pos_y, HPL_scale_x, HPL_scale_y, image_angle, image_blend, image_alpha);
// Draw border right
draw_sprite_ext(sHPLEND1, image_index, HPL_pos_x - 320, HPL_pos_y, HPL_scale_x, HPL_scale_y, image_angle, image_blend, image_alpha);


// Font text HP
draw_set_alpha(0.8);
draw_set_color(c_black);
draw_roundrect(HPL_text_x/camera_get_view_width(view_camera[0]) + 110, HPL_text_y + 58, HPL_text_x - 76, HPL_text_y + 90, 0);

// Draw text HP
draw_set_alpha(1);
draw_set_color(c_aqua);
draw_text(HPL_text_x - 400, HPL_text_y + 65, "HP : " + string(playerCurrentHP) + " %");
draw_set_color(c_black);


  /*************************************************************/
 /*                      HEALTHBAR RIGHT                      */
/*************************************************************/

draw_set_alpha(1);
draw_set_color(make_color_rgb(40, 40, 40));
draw_rectangle(-1, 0, camera_get_view_width(view_camera[0]), 30, 0);


// Draw health bar right
// Draw font
draw_sprite_ext(sHPLBAR_BG, image_index, HPR_pos_x, HPR_pos_y, HPR_scale_x, HPR_scale_y, image_angle, image_blend, image_alpha);
// Draw health
draw_sprite_part_ext(sHPLBAR, image_index, 0, 0, spriteWidth_L * hpPercent, spriteHeight_L, HPR_pos_x/camera_get_view_width(view_camera[0]) + 50, HPR_pos_y, HPR_scale_x, HPR_scale_y, image_blend, image_alpha);

// Draw glow
draw_sprite_ext(sHPLBAR_glow, image_index, HPR_pos_x, HPR_pos_y, HPR_scale_x, HPR_scale_y, image_angle, image_blend, image_alpha);
// Draw border left
draw_sprite_ext(sHPLSTART1, image_index, HPR_pos_x, HPR_pos_y, HPR_scale_x, HPR_scale_y, image_angle, image_blend, image_alpha);
// Draw border right
draw_sprite_ext(sHPLEND1, image_index, HPR_pos_x - 320, HPR_pos_y, HPR_scale_x, HPR_scale_y, image_angle, image_blend, image_alpha);


// Font text HP
draw_set_alpha(0.8);
draw_set_color(c_black);
draw_roundrect(HPR_text_x/camera_get_view_width(view_camera[0]) + 110, HPR_text_y + 58, HPR_text_x - 76, HPR_text_y + 90, 0);

// Draw text HP
draw_set_alpha(1);
draw_set_color(c_aqua);
draw_text(HPR_text_x - 400, HPR_text_y + 65, "HP : " + string(playerCurrentHP) + " %");
draw_set_color(c_black);


//*****************************************************************
draw_set_color(make_color_rgb(20, 20, 20));
draw_rectangle(-1, 0, camera_get_view_width(view_camera[0]), 20 + 1, 0);
draw_set_color(make_color_rgb(0, 0, 0));
draw_rectangle(-1, 0, camera_get_view_width(view_camera[0]), 10, 0);







