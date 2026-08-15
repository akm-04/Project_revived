local var_0_0 = class("GrayedSprite", function(...)
	return xyd.AssetLoader.get():loadSprite(...)
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:setupShader_()
end

function var_0_0.setupShader_(arg_3_0)
	if var_0_0.VERT_STRING == nil or var_0_0.FERG_STRING == nil then
		var_0_0.VERT_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/no_mvp.vsh")
		var_0_0.FERG_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/grayed_sprite.fsh")
	end

	local var_3_0 = cc.GLProgram:createWithByteArrays(var_0_0.VERT_STRING, var_0_0.FERG_STRING)
	local var_3_1 = cc.GLProgramState:create(var_3_0)

	arg_3_0:setGLProgramState(var_3_1)
end

return var_0_0
