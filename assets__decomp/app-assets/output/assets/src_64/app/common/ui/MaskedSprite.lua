local var_0_0 = class("MaskedSprite", function(...)
	return xyd.AssetLoader.get():loadSprite(...)
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 0.5)

	arg_2_0:setupShader_()
end

function var_0_0.setMaskColor(arg_3_0, arg_3_1)
	arg_3_0.hasMask = true

	local var_3_0 = arg_3_1 or arg_3_0.maskColor

	arg_3_0:getGLProgramState():setUniformVec4(arg_3_0.MaskColorLocation_, cc.v4Fromc4(var_3_0))
end

function var_0_0.unsetMaskColor(arg_4_0)
	arg_4_0.hasMask = false

	arg_4_0:getGLProgramState():setUniformVec4(arg_4_0.MaskColorLocation_, cc.v4Fromc4(cc.c4f(0, 0, 0, 0)))
end

function var_0_0.setupShader_(arg_5_0)
	if var_0_0.VERT_STRING == nil or var_0_0.FERG_STRING == nil then
		var_0_0.VERT_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/no_mvp.vsh")
		var_0_0.FERG_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/masked_sprite_no_vert_color.fsh")
	end

	local var_5_0 = cc.GLProgram:createWithByteArrays(var_0_0.VERT_STRING, var_0_0.FERG_STRING)
	local var_5_1 = cc.GLProgramState:create(var_5_0)

	arg_5_0.MaskColorLocation_ = gl.getUniformLocation(var_5_0:getProgram(), "maskColor")

	arg_5_0:setGLProgramState(var_5_1)
end

return var_0_0
