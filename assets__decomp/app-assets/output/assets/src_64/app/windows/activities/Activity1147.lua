local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc.activityTestPaperNum

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if not var_2_0 then
		return
	end

	arg_2_0.container = var_2_0:getChildByName("container")

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setPosition(-5, 5)
	arg_2_0.container:getChildByName("rule_txt"):setString(var_0_1:translation("ACTIVITY_TEXT_PAPER_RULE_TEXT"))
	arg_2_0.container:getChildByName("rule_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	arg_2_0.goBtn = arg_2_0.container:getChildByName("go_btn")

	arg_2_0.goBtn:addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_2_0.goBtn, arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_2_0.noTimes then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NO_LEFT_TIMES")
				})

				return
			end

			if arg_2_0.details.base_info.quiz_count > 0 then
				xyd.WindowManager.get():openWindow("activity_text_paper_quiz", arg_2_0.activity)
			else
				local var_3_0 = string.format(xyd.tables.translation:translation("ACTIVITY_TEXT_PAPER_OPEN"), var_0_2)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_3_0, function()
					xyd.Backend.get():request(xyd.mid.TEXT_PAPER_QUIZ_START, {}, function(arg_5_0, arg_5_1)
						if arg_5_0 == xyd.error.OK then
							if arg_5_1 and arg_5_1.base_info then
								arg_2_0.details.base_info = arg_5_1.base_info
							end

							local function var_5_0()
								arg_2_0:update()
							end

							local var_5_1 = {
								details = arg_2_0.details,
								callback = var_5_0
							}

							xyd.WindowManager.get():openWindow("activity_text_paper_quiz", var_5_1)
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end
	end)

	arg_2_0.leftLable = arg_2_0.container:getChildByName("answer_chance_txt")

	arg_2_0.leftLable:enableOutline(cc.c4b(255, 255, 255, 255), 3)
	arg_2_0:update()
end

function var_0_0.update(arg_7_0)
	arg_7_0.noTimes = false

	arg_7_0.container:getChildByName("answer_chance_txt"):setString(string.format(var_0_1:translation("ACTIVITY_TEXT_PAPER_TIMES"), arg_7_0.details.base_info.left_times, 1))

	local var_7_0 = arg_7_0.goBtn:getChildByName("txt")

	if arg_7_0.details.base_info.quiz_count > 0 then
		var_7_0:setString(var_0_1:translation("ACTIVITY_1147_TEXT1"))
	elseif arg_7_0.details.base_info.left_times > 0 then
		var_7_0:setString(var_0_1:translation("BUTTON_NAME_GO"))
	else
		arg_7_0.noTimes = true

		var_7_0:setString(var_0_1:translation("BUTTON_NAME_GO"))
		xyd.GrayNode(arg_7_0.goBtn)
	end
end

return var_0_0
