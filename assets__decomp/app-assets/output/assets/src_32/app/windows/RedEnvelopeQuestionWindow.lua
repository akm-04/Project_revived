local var_0_0 = class("RedEnvelopeQuestionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	Multiplication = 3,
	Substraction = 2,
	Addtion = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.redEnvelope = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.layout(arg_3_0)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4 = arg_3_0:getRandomQuestion()

	arg_3_0:nodeByName("question_desc"):setString(tostring(var_3_0) .. var_3_3 .. tostring(var_3_1) .. " = " .. "?")
	arg_3_0:nodeByName("question_tip_text"):setString(var_0_1:translation("RED_ENVELOP_QUESTION_TIP"))

	for iter_3_0 = 1, 4 do
		local var_3_5 = arg_3_0:nodeByName("anser_btn" .. tostring(iter_3_0))

		var_3_5:getChildByName("anser_txt"):setString(var_3_4[iter_3_0])
		var_3_5:addTouchEventListener(function(arg_4_0, arg_4_1)
			if arg_4_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if var_3_4[iter_3_0] == var_3_2 then
					arg_3_0.callback(true)
				else
					arg_3_0.callback(false)
				end

				xyd.WindowManager.get():closeWindow(arg_3_0)
			end
		end)
	end
end

function var_0_0.getRandomQuestion(arg_5_0)
	local var_5_0 = math.random(1, 3)
	local var_5_1
	local var_5_2
	local var_5_3
	local var_5_4
	local var_5_5 = {}

	if var_5_0 == var_0_2.Addtion then
		var_5_1, var_5_2 = math.random(0, 25), math.random(0, 25)
		var_5_3 = var_5_1 + var_5_2
		var_5_4 = " + "
	elseif var_5_0 == var_0_2.Substraction then
		var_5_1 = math.random(10, 50)
		var_5_2 = math.random(0, var_5_1)
		var_5_3 = var_5_1 - var_5_2
		var_5_4 = " - "
	elseif var_5_0 == var_0_2.Multiplication then
		var_5_1 = math.random(1, 5)
		var_5_2 = math.random(1, 9)
		var_5_3 = var_5_1 * var_5_2
		var_5_4 = " × "
	end

	local var_5_6 = math.max(-5, -var_5_3)

	for iter_5_0 = var_5_6, var_5_6 + 10 do
		if iter_5_0 ~= 0 then
			table.insert(var_5_5, var_5_3 + iter_5_0)
		end
	end

	local var_5_7 = xyd.shuffle(var_5_5)
	local var_5_8 = {
		var_5_7[1],
		var_5_7[2],
		var_5_7[3],
		var_5_3
	}
	local var_5_9 = xyd.shuffle(var_5_8)

	return var_5_1, var_5_2, var_5_3, var_5_4, var_5_9
end

return var_0_0
