local var_0_0 = class("ColoredSprite", function(...)
	return xyd.AssetLoader.get():loadSprite(...)
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0.color_ = cc.c4f(1, 1, 1, 1)

	arg_2_0:setupShader_()
	arg_2_0:setColorDelta(cc.c4b(255, 255, 255, 255))
end

function var_0_0.setColorDelta(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	if arg_3_0.callback_ ~= nil then
		arg_3_0.callback_()
	end

	if arg_3_2 == nil or arg_3_2 <= 0 then
		arg_3_0.color_ = cc.c4fFromc4b(arg_3_1)

		arg_3_0:getGLProgramState():setUniformVec4(arg_3_0.colorDeltaLocation_, cc.v4Fromc4(arg_3_0.color_))

		if arg_3_3 ~= nil then
			arg_3_3()
		end

		return
	end

	arg_3_0.fromColor_ = cc.c4f(arg_3_0.color_.r, arg_3_0.color_.g, arg_3_0.color_.b, arg_3_0.color_.a)
	arg_3_0.toColor_ = cc.c4fFromc4b(arg_3_1)
	arg_3_0.duration_ = arg_3_2
	arg_3_0.callback_ = arg_3_3
	arg_3_0.elapsed_ = 0

	arg_3_0:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(arg_3_0, arg_3_0.onEnterFrame_))
	arg_3_0:scheduleUpdate()
end

function var_0_0.setOpacity(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = cc.c4bFromc4f(arg_4_0.toColor_ or arg_4_0.color_)

	var_4_0.a = arg_4_1

	arg_4_0:setColorDelta(var_4_0, arg_4_2, arg_4_3)
end

function var_0_0.setupShader_(arg_5_0)
	if var_0_0.VERT_STRING == nil or var_0_0.FERG_STRING == nil then
		var_0_0.VERT_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/no_mvp.vsh")
		var_0_0.FERG_STRING = cc.FileUtils:getInstance():getStringFromFile("shaders/colored_sprite.fsh")
	end

	local var_5_0 = cc.GLProgram:createWithByteArrays(var_0_0.VERT_STRING, var_0_0.FERG_STRING)
	local var_5_1 = cc.GLProgramState:create(var_5_0)

	arg_5_0.colorDeltaLocation_ = gl.getUniformLocation(var_5_0:getProgram(), "colordelta")

	arg_5_0:setGLProgramState(var_5_1)
end

function var_0_0.onEnterFrame_(arg_6_0, arg_6_1)
	arg_6_0.elapsed_ = arg_6_0.elapsed_ + arg_6_1

	if arg_6_0.elapsed_ < arg_6_0.duration_ then
		local var_6_0 = arg_6_1 / arg_6_0.duration_

		arg_6_0.color_.r = arg_6_0.color_.r + var_6_0 * (arg_6_0.toColor_.r - arg_6_0.fromColor_.r)
		arg_6_0.color_.g = arg_6_0.color_.g + var_6_0 * (arg_6_0.toColor_.g - arg_6_0.fromColor_.g)
		arg_6_0.color_.b = arg_6_0.color_.b + var_6_0 * (arg_6_0.toColor_.b - arg_6_0.fromColor_.b)
		arg_6_0.color_.a = arg_6_0.color_.a + var_6_0 * (arg_6_0.toColor_.a - arg_6_0.fromColor_.a)
	else
		arg_6_0.color_ = arg_6_0.toColor_

		arg_6_0:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
		arg_6_0:unscheduleUpdate()

		if arg_6_0.callback_ ~= nil then
			arg_6_0.callback_()

			arg_6_0.callback_ = nil
		end

		arg_6_0.fromColor_ = nil
		arg_6_0.toColor_ = nil
		arg_6_0.duration_ = nil
		arg_6_0.callback_ = nil
		arg_6_0.elapsed_ = nil
	end

	arg_6_0:getGLProgramState():setUniformVec4(arg_6_0.colorDeltaLocation_, cc.v4Fromc4(arg_6_0.color_))
end

return var_0_0
