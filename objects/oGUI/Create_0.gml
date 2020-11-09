/// @description Parameter

playerCurrentHP = 100;
playerMaxHP = 100;

// Healthbar left
spriteWidth_L =  sprite_get_width(sHPLBAR);
spriteHeight_L =  sprite_get_height(sHPLBAR);
HPL_pos_x = camera_get_view_width(view_camera[0]) / 2;
HPL_pos_y = 20;

HPL_scale_x = 0.8;
HPL_scale_y = 0.8;
HPL_text_bg_x = HPL_pos_x;
HPL_text_bg_y = HPL_pos_y;
HPL_text_x = HPL_pos_x + 78;
HPL_text_y = HPL_pos_y + 20;


// Healthbar right
spriteWidth_R =  sprite_get_width(sHPRBAR);
spriteHeight_R =  sprite_get_height(sHPRBAR);
HPR_pos_x = camera_get_view_width(view_camera[0]) / 2;
HPR_pos_y = HPL_pos_y;

HPR_scale_x = 0.8;
HPR_scale_y = 0.8;
HPR_text_bg_x = HPR_pos_x;
HPR_text_bg_y = HPR_pos_y;
HPR_text_x = HPR_pos_x - spriteWidth_R + 80;
HPR_text_y = HPR_pos_y + 20;







