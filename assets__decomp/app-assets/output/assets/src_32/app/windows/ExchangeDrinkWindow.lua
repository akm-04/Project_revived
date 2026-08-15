local var_0_0 = class("ExchangeDrinkWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.maxBar = xyd.tables.misc.dayExchangeDrinkLimit - arg_1_0.guild.daily_exchange
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("tip_text"):setString(string.format(var_0_2:translation("EXCHANGE_DRINK_TIP"), 1, xyd.tables.misc.drinkExchangeActive))
	arg_3_0:nodeByName("num_text"):setString(1)

	arg_3_0.cup_num = 1

	local var_3_0 = cc.ui.UISlider.new(display.LEFT_TO_RIGHT, {
		bar = "windows/kite/scroll_bar_bg.png",
		button = "windows/kite/scorll_point.png"
	}, {
		scale9 = true
	}):setSliderValue(0):addTo(arg_3_0:nodeByName("slider_pos")):onSliderValueChanged(function(arg_4_0)
		local var_4_0 = math.floor(arg_4_0.value / 100 * (arg_3_0.maxBar - 1)) + 1

		arg_3_0:nodeByName("num_text"):setString(var_4_0)
		arg_3_0:nodeByName("tip_text"):setString(string.format(var_0_2:translation("EXCHANGE_DRINK_TIP"), var_4_0, var_4_0 * xyd.tables.misc.drinkExchangeActive))

		arg_3_0.cup_num = var_4_0
	end)

	var_3_0:setScale(0.9, 1)
	arg_3_0:nodeByName("minus"):setTouchEnabled(true)
	arg_3_0:nodeByName("minus"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			if arg_3_0.cup_num - 2 >= 0 then
				var_3_0:setSliderValue((arg_3_0.cup_num - 2) / (arg_3_0.maxBar - 1) * 100)

				if arg_3_0.add_cup and arg_3_0.add_cup == arg_3_0.cup_num + 2 then
					var_3_0:setSliderValue((arg_3_0.cup_num + 0.5) / (arg_3_0.maxBar - 1) * 100)
				end

				arg_3_0.add_cup = arg_3_0.cup_num
			elseif arg_3_0.cup_num == 2 then
				var_3_0:setSliderValue(0)
			end
		end
	end)
	arg_3_0:nodeByName("plus"):setTouchEnabled(true)
	arg_3_0:nodeByName("plus"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			if arg_3_0.cup_num + 1 <= arg_3_0.maxBar then
				var_3_0:setSliderValue(arg_3_0.cup_num / (arg_3_0.maxBar - 1) * 100)

				if arg_3_0.add_cup and arg_3_0.add_cup == arg_3_0.cup_num then
					var_3_0:setSliderValue((arg_3_0.cup_num + 0.5) / (arg_3_0.maxBar - 1) * 100)
				end

				arg_3_0.add_cup = arg_3_0.cup_num
			elseif arg_3_0.cup_num == arg_3_0.maxBar - 1 then
				var_3_0:setSliderValue(100)
			end
		end
	end)
	arg_3_0:nodeByName("right_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0.guild:loadDrinkInfo(function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					if arg_3_0.cup_num * xyd.tables.misc.drinkExchangeActive + arg_3_0.guild.huoyue > xyd.tables.misc.guildVitalityGuildLimit then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("GUILD_HUOYUE_IS_FULL")
						})

						arg_3_0.cup_num = math.floor((xyd.tables.misc.guildVitalityGuildLimit - arg_3_0.guild.huoyue) / xyd.tables.misc.drinkExchangeActive) - 1

						if arg_3_0.cup_num < 0 then
							arg_3_0.cup_num = 0
						end

						var_3_0:setSliderValue(arg_3_0.cup_num / (arg_3_0.maxBar - 1) * 100)
					elseif arg_3_0.guild.daily_exchange + arg_3_0.cup_num > xyd.tables.misc.dayExchangeDrinkLimit then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("GUILD_EXCHANGE_NUM_IS_FULL")
						})

						if xyd.tables.misc.dayExchangeDrinkLimit - arg_3_0.guild.daily_exchange <= 0 then
							arg_3_0.cup_num = 0
						else
							arg_3_0.cup_num = xyd.tables.misc.dayExchangeDrinkLimit - arg_3_0.guild.daily_exchange
						end

						var_3_0:setSliderValue(arg_3_0.cup_num / (arg_3_0.maxBar - 1) * 100)
					else
						arg_3_0.guild:setExchangeDrink({
							num = arg_3_0.cup_num
						}, function(arg_9_0)
							if arg_9_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("toast", {
									message = string.format(var_0_2:translation("GUILD_EXCHANGE_HUOYUE_OK"), arg_3_0.cup_num * xyd.tables.misc.drinkExchangeActive)
								})
								xyd.WindowManager.get():closeWindow(arg_3_0)

								local var_9_0 = xyd.WindowManager.get():getWindow("drink_self")

								if var_9_0 then
									var_9_0:updateBtn()
								end

								return true
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = string.format(var_0_2:translation("GUILD_DRINK_INIT_NUM_LIMIT"), xyd.tables.misc.guildExchangeDrinkInit)
								})

								return true
							end
						end)
					end
				end
			end)
		end
	end)
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	arg_10_0:addBlockLayer()
	var_0_0.super:didOpen(arg_10_1)
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	var_0_0.super:willClose(arg_11_1)
end

return var_0_0
