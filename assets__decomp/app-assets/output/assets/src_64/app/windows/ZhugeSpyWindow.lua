local var_0_0 = class("ZhugeSpyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.zhugeSweepExploreCost

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.baseInfo = arg_1_0.zhugeModel:getBaseInfo()
	arg_1_0.leastCost = arg_1_0.baseInfo.least_use_cost
	arg_1_0.costInfo = var_0_2:getCostInfo(arg_1_0.leastCost)
	arg_1_0.ranges = table.keys(arg_1_0.costInfo)

	table.sort(arg_1_0.ranges, function(arg_2_0, arg_2_1)
		return arg_2_0 < arg_2_1
	end)

	arg_1_0.idx = #arg_1_0.ranges
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("origin_energy_text"):setString(var_0_1:translation("ZHUGELIANG_ORG_ENERGY_TEXT"))
	arg_5_0:nodeByName("rule_txt"):setString(var_0_1:translation("ZHUGE_SWEEP_TIP"))
	arg_5_0:nodeByName("spy_txt"):setString(var_0_1:translation("ZHUGELIANG_SPY_TEXT"))
	arg_5_0:nodeByName("cost_text"):setString(var_0_1:translation("ZHUGELIANG_CHANGE_COST_TEXT"))
	arg_5_0:nodeByName("limit_tip_txt"):setString(var_0_1:translation("ZHUGELIANG_LIMIT_SPY_TEXT"))
	arg_5_0:nodeByName("origin_energy_txt"):setString(arg_5_0.baseInfo.least_use_cost)
	arg_5_0:nodeByName("num_txt"):setString(80)
	arg_5_0:nodeByName("cost_txt"):setString(5000)
	arg_5_0:updateCost()
	arg_5_0:nodeByName("limit_tip_txt"):setVisible(false)

	if #arg_5_0.ranges <= 1 then
		arg_5_0:nodeByName("limit_tip_txt"):setVisible(true)
		arg_5_0:nodeByName("spy_btn"):setVisible(false)
	end

	arg_5_0:setButtonClick()
end

function var_0_0.updateCost(arg_6_0)
	arg_6_0:nodeByName("right_button"):setBright(true)
	arg_6_0:nodeByName("left_button"):setBright(true)

	arg_6_0.idx = math.min(#arg_6_0.ranges, arg_6_0.idx)
	arg_6_0.idx = math.max(1, arg_6_0.idx)

	if arg_6_0.idx >= #arg_6_0.ranges then
		arg_6_0:nodeByName("right_button"):setBright(false)
	end

	if arg_6_0.idx <= 1 then
		arg_6_0:nodeByName("left_button"):setBright(false)
	end

	arg_6_0:nodeByName("num_txt"):setString(arg_6_0.ranges[arg_6_0.idx])
	arg_6_0:nodeByName("cost_txt"):setString(arg_6_0.costInfo[arg_6_0.ranges[arg_6_0.idx]])
end

function var_0_0.setButtonClick(arg_7_0)
	local function var_7_0()
		arg_7_0.idx = arg_7_0.idx - 1

		arg_7_0:updateCost()
	end

	local function var_7_1(...)
		arg_7_0.idx = arg_7_0.idx + 1

		arg_7_0:updateCost()
	end

	xyd.buttonLongTouch(arg_7_0:nodeByName("left_button"), var_7_0, var_7_0)
	xyd.buttonLongTouch(arg_7_0:nodeByName("right_button"), var_7_1, var_7_1)
	arg_7_0:nodeByName("spy_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_10_0 = {
				goal_energy = arg_7_0.ranges[arg_7_0.idx]
			}

			if var_10_0.goal_energy <= 0 then
				xyd.WindowManager.get():closeWindow(arg_7_0)

				return
			end

			if arg_7_0.selfPlayer.crystal < arg_7_0.costInfo[var_10_0.goal_energy] then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_11_0 = {}

					var_11_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
				end, nil, nil, arg_7_0.colorMode)

				return
			end

			local var_10_1 = string.format(var_0_1:translation("ZHUGELIANG_SURE_SPY_TEXT"), arg_7_0.costInfo[var_10_0.goal_energy])

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_1, function()
				arg_7_0.zhugeModel:spy(var_10_0, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						if arg_7_0.callback then
							arg_7_0.callback()
						end

						xyd.WindowManager.get():closeWindow(arg_7_0)
					end
				end)
			end, nil, nil, arg_7_0.colorMode)
		end
	end)
end

return var_0_0
