xyd = xyd or {}

local var_0_0 = {
	MVP_VERT_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/masked_sprite.vsh"),
	MVP_FRAG_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/masked_sprite.fsh"),
	NO_MVP_VERT_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/no_mvp.vsh"),
	NO_MVP_FRAG_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/no_mvp.fsh"),
	GRAY_FRAG_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/grayed_sprite.fsh"),
	Default_Dusk_Color = cc.c4f(0.35, 0.35, 0.35, 1),
	Default_Color = cc.c4f(1, 1, 1, 1),
	Clear_Color = cc.c4f(0, 0, 0, 0)
}

var_0_0.Default_Gray_Ratio = 0
xyd.shader = var_0_0
