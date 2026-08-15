local var_0_0 = class("FourthAnniMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("time_txt1"):setString(var_0_1:translation("ACTIVITY_END_TIME"))
	arg_2_0:nodeByName("time_txt2"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_AWARD_TIP14"))
	arg_2_0:nodeByName("time_txt1"):enableOutline(cc.c4b(161, 99, 87, 255), 2)
	arg_2_0:nodeByName("time_txt2"):enableOutline(cc.c4b(161, 99, 87, 255), 2)
	arg_2_0:nodeByName("time_txt3"):enableOutline(cc.c4b(161, 99, 87, 255), 2)
	arg_2_0:nodeByName("time_txt4"):enableOutline(cc.c4b(161, 99, 87, 255), 2)

	local var_2_0 = arg_2_0.model:getEndTime() - xyd.ServerTime.get():getServerTime()

	arg_2_0.stage = arg_2_0.model:getStage()

	arg_2_0:updateTimeTxt(var_2_0)

	arg_2_0.chocolateHandle = var_0_2.scheduleGlobal(function()
		var_2_0 = var_2_0 - 1

		arg_2_0:updateTimeTxt(var_2_0)
	end, 1)

	arg_2_0:nodeByName("txt_rule"):setString(var_0_1:translation("FOURTH_ANNI_MAIN_TXT1"))
	arg_2_0:nodeByName("txt_graphic"):setString(var_0_1:translation("FOURTH_ANNI_MAIN_TXT2"))
	arg_2_0:setButtonClick()
end

function var_0_0.updateTimeTxt(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1 - xyd.tables.misc:getValue("activity_chocolate_pool_times") * 60 * 60 * 24

	arg_4_0.stage = arg_4_0.model:getStage()

	if not tolua.isnull(arg_4_0) then
		arg_4_0:nodeByName("time_txt4"):setString(string.format(xyd.secondsToString1(arg_4_1)))
		arg_4_0:nodeByName("time_txt3"):setString(string.format(xyd.secondsToString1(var_4_0)))
	end

	if var_4_0 < 0 then
		arg_4_0:nodeByName("time_txt1"):setString(var_0_1:translation("ACTIVITY_CLOSED"))
		arg_4_0:nodeByName("time_txt3"):setVisible(false)

		if arg_4_1 < 0 then
			if not tolua.isnull(arg_4_0) then
				var_0_2.unscheduleGlobal(arg_4_0.chocolateHandle)
			end

			arg_4_0:nodeByName("time_txt2"):setString(var_0_1:translation("ACTIVITY_CLOSED"))
			arg_4_0:nodeByName("time_txt4"):setVisible(false)
		end
	end
end

function var_0_0.setButtonClick(arg_5_0)
	arg_5_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("rule_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = {
				title_name = "FOURTH_ANNI_RULE_TITLE",
				rule = "FOURTH_ANNI_RULE"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_6_0)
		end
	end)
	arg_5_0:nodeByName("game_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("game_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_5_0.stage == 1 then
				arg_5_0.model:ufocatcherGetInfo(nil, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						local var_8_0 = {
							award_times = arg_8_1.act_catch.award_times,
							pos_info = arg_8_1.act_catch.pos_info,
							is_catching = arg_8_1.act_catch.is_catching,
							end_time = arg_8_1.act_catch.end_time,
							refresh_times = arg_8_1.act_catch.refresh_times
						}

						xyd.WindowManager.get():openWindow("fourth_anni_ufocatcher", var_8_0)
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SAKURA_CLOSED")
				})
			end
		end
	end)
	arg_5_0:nodeByName("gold_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("gold_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("gold_main")
		end
	end)
	arg_5_0:nodeByName("paint_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("paint_btn"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_INFO, nil, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("fourth_anni_paint", arg_11_1)
				end
			end)
		end
	end)
	arg_5_0:nodeByName("event_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("event_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.model:enterMap()
		end
	end)
	arg_5_0:nodeByName("graphic_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("graphic_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = {}

			var_13_0.pageNum = 5

			xyd.WindowManager.get():openWindow("gold_graphic", var_13_0)
		end
	end)
end

function var_0_0.willClose(arg_14_0)
	var_0_0.super:willClose()

	if arg_14_0.chocolateHandle ~= nil then
		var_0_2.unscheduleGlobal(arg_14_0.chocolateHandle)

		arg_14_0.chocolateHandle = nil
	end
end

return var_0_0
