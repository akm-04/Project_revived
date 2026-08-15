local var_0_0 = class("BeachEnterWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.beach = xyd.ModelManager.get():loadModel(xyd.ModelType.BEACH_ACTIVITY)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.tables.misc.beachBuyGamePrice
	local var_4_1 = 0

	if arg_4_0.beach:getStartTimes() > 0 then
		if arg_4_0.beach:getStartTimes() + 1 > #var_4_0 then
			var_4_1 = var_4_0[#var_4_0]
		else
			var_4_1 = var_4_0[arg_4_0.beach:getStartTimes() + 1]
		end
	end

	arg_4_0:nodeByName("cost_txt"):setString(var_0_1:translation("MANA_COST"))
	arg_4_0:nodeByName("cost_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0:nodeByName("left_time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_4_2 = arg_4_0.beach:getEndTime() - xyd.ServerTime.get():getServerTime()

	arg_4_0:updateTimeTxt(var_4_2)

	arg_4_0.beachHandle = var_0_4.scheduleGlobal(function()
		var_4_2 = var_4_2 - 1

		arg_4_0:updateTimeTxt(var_4_2)
	end, 1)

	arg_4_0:nodeByName("cost_txt_num"):setString(var_4_1)
	arg_4_0:nodeByName("cost_txt_num"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0:nodeByName("start_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_4_0.beach:getStartTimes() >= xyd.tables.misc.beachBuyGameLimit then
				local var_6_0 = var_0_1:translation("BEACH_LIMIT_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_0
				})

				return
			end

			local function var_6_1()
				arg_4_0.beach:startBeach(function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("beach_main_wnd")
						xyd.WindowManager.get():closeWindow(arg_4_0.name)
					end
				end)
			end

			if var_4_1 > 0 then
				local var_6_2 = string.format(var_0_1:translation("BEACH_START_COST"), var_4_1)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_2, function()
					if var_4_1 > arg_4_0.selfPlayer.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_10_0 = {}

							var_10_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
						end, nil, nil, arg_4_0.colorMode)
					else
						var_6_1()
					end
				end, nil, 0, arg_4_0.colorMode)
			else
				var_6_1()
			end
		end
	end)
	arg_4_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				title_name = "BEACH_RULE_TITLE",
				rule = "BEACH_RULE"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_11_0)
		end
	end)
	arg_4_0:nodeByName("reward_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("reward_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("reward_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		elseif arg_12_1 == ccui.TouchEventType.ended then
			arg_4_0:nodeByName("reward_btn"):setBrightStyle(ccui.BrightStyle.normal)
			xyd.WindowManager.get():openWindow("beach_detail")
		end
	end)
end

function var_0_0.updateTimeTxt(arg_13_0, arg_13_1)
	if not tolua.isnull(arg_13_0) then
		arg_13_0:nodeByName("left_time"):setString(string.format(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT6"), xyd.secondsToString1(arg_13_1)))
	end

	if arg_13_1 < 0 then
		if not tolua.isnull(arg_13_0) then
			var_0_4.unscheduleGlobal(arg_13_0.beachHandle)
		end

		xyd.WindowManager.get():closeWindow(arg_13_0)
	end
end

function var_0_0.willClose(arg_14_0)
	var_0_0.super:willClose()

	if arg_14_0.beachHandle ~= nil then
		var_0_4.unscheduleGlobal(arg_14_0.beachHandle)

		arg_14_0.beachHandle = nil
	end
end

return var_0_0
