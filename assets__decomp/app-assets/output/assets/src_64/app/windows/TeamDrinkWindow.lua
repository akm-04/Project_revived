local var_0_0 = class("TeamDrinkWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.guildExchangeDrinkInit

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	for iter_3_0 = 1, 3 do
		arg_3_0:nodeByName("left_time_words" .. iter_3_0):setString(var_0_2:translation("TEAM_DRINK_LEFT_TIME"))
		arg_3_0:nodeByName("left_num_words" .. iter_3_0):setString(var_0_2:translation("TEAM_DRINK_LEFT_NUM"))
	end

	arg_3_0:nodeByName("titile"):setString(var_0_2:translation("TEAM_DRINK_SELF_TITLE"))
	arg_3_0:nodeByName("exchange_btn"):setVisible(false)

	arg_3_0.handle_ = var_0_1.scheduleGlobal(function()
		if arg_3_0.normal_time and arg_3_0.normal_time > 0 then
			arg_3_0.normal_time = arg_3_0.normal_time - 1

			local var_4_0 = arg_3_0.normal_time % 60
			local var_4_1 = math.floor(arg_3_0.normal_time % 3600 / 60)
			local var_4_2 = math.floor(arg_3_0.normal_time / 3600)

			arg_3_0:nodeByName("left_time_text_2"):setString(string.format("%02d:%02d:%02d", var_4_2, var_4_1, var_4_0))
		else
			arg_3_0:nodeByName("left_time_words2"):setVisible(false)
			arg_3_0:nodeByName("left_num_words2"):setVisible(false)
			arg_3_0:nodeByName("left_time_text_2"):setVisible(false)
			arg_3_0:nodeByName("left_num_text_2"):setVisible(false)
			arg_3_0:nodeByName("sell_over_words_2"):setVisible(true)
		end

		if arg_3_0.special_time and arg_3_0.special_time > 0 then
			arg_3_0.special_time = arg_3_0.special_time - 1

			local var_4_3 = arg_3_0.special_time % 60
			local var_4_4 = math.floor(arg_3_0.special_time % 3600 / 60)
			local var_4_5 = math.floor(arg_3_0.special_time / 3600)

			arg_3_0:nodeByName("left_time_text_3"):setString(string.format("%02d:%02d:%02d", var_4_5, var_4_4, var_4_3))
		else
			arg_3_0:nodeByName("left_time_words3"):setVisible(false)
			arg_3_0:nodeByName("left_num_words3"):setVisible(false)
			arg_3_0:nodeByName("left_time_text_3"):setVisible(false)
			arg_3_0:nodeByName("left_num_text_3"):setVisible(false)
			arg_3_0:nodeByName("sell_over_words_3"):setVisible(true)
		end
	end, 1)

	arg_3_0:nodeByName("sell_over_words_3"):setString(xyd.tables.translation:translation("TEAM_DRINK_IS_NONE_WORDS"))
	arg_3_0:nodeByName("sell_over_words_2"):setString(xyd.tables.translation:translation("TEAM_DRINK_IS_NONE_WORDS"))

	arg_3_0.can_drinks = {
		true,
		false,
		false
	}

	for iter_3_1 = 1, 3 do
		local var_3_0 = xyd.tables.misc["drinkEnergyNum" .. iter_3_1]

		arg_3_0:nodeByName("tili_num_text_" .. iter_3_1):setString(var_3_0)
	end

	arg_3_0:nodeByName("left_time_text_1"):setString(var_0_2:translation("FOREVER"))
	arg_3_0:nodeByName("left_num_text_1"):setString(var_0_2:translation("ENDLESS"))

	arg_3_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	if arg_3_0.guild.free_have_drink == 0 then
		arg_3_0:nodeByName("already_drink_1"):setVisible(false)
	else
		arg_3_0:nodeByName("already_drink_1"):setVisible(true)
	end

	if arg_3_0.guild.normal_have_drink == 0 then
		arg_3_0:nodeByName("already_drink_2"):setVisible(false)
	else
		arg_3_0:nodeByName("already_drink_2"):setVisible(true)
	end

	if arg_3_0.guild.special_have_drink == 0 then
		arg_3_0:nodeByName("already_drink_3"):setVisible(false)
	else
		arg_3_0:nodeByName("already_drink_3"):setVisible(true)
	end

	arg_3_0:updateBtn()
	arg_3_0:nodeByName("red_cup"):setTouchEnabled(true)
	arg_3_0:nodeByName("ji_cup"):setTouchEnabled(true)
	arg_3_0:nodeByName("beer_cup"):setTouchEnabled(true)
	arg_3_0:nodeByName("red_cup"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		arg_3_0:updateBtn()

		if arg_5_0.name == "ended" then
			xyd.playButtonSound()
			arg_3_0:nodeByName("red_cup"):setScale(1)
			arg_3_0:doDrink(3)

			return true
		elseif arg_5_0.name == "began" then
			arg_3_0:nodeByName("red_cup"):setScale(0.9)

			return true
		end
	end)
	arg_3_0:nodeByName("ji_cup"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		arg_3_0:updateBtn()

		if arg_6_0.name == "ended" then
			xyd.playButtonSound()
			arg_3_0:nodeByName("ji_cup"):setScale(1)
			arg_3_0:doDrink(2)

			return true
		elseif arg_6_0.name == "began" then
			arg_3_0:nodeByName("ji_cup"):setScale(0.9)

			return true
		end
	end)
	arg_3_0:nodeByName("beer_cup"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		arg_3_0:updateBtn()

		if arg_7_0.name == "ended" then
			xyd.playButtonSound()
			arg_3_0:nodeByName("beer_cup"):setScale(1)
			arg_3_0:doDrink(1)

			return true
		elseif arg_7_0.name == "began" then
			arg_3_0:nodeByName("beer_cup"):setScale(0.9)

			return true
		end
	end)

	if arg_3_0.guild.job == xyd.GuildJobType.LEADER and arg_3_0.guild.normal_drink_times >= var_0_4 then
		arg_3_0:nodeByName("exchange_btn"):setVisible(true)
		arg_3_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if xyd.tables.misc.guildVitalityGuildLimit <= arg_3_0.guild.huoyue then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("GUILD_HUOYUE_IS_FULL")
					})
				elseif xyd.tables.misc.dayExchangeDrinkLimit - arg_3_0.guild.daily_exchange < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("GUILD_EXCHANGE_NUM_IS_FULL")
					})
				else
					xyd.WindowManager.get():openWindow("exchange_drink")
				end
			end
		end)
	end
end

function var_0_0.updateBtn(arg_9_0)
	if arg_9_0.guild.normal_drink_times >= var_0_4 and arg_9_0.guild.job == xyd.GuildJobType.LEADER then
		arg_9_0:nodeByName("exchange_btn"):setVisible(true)
	else
		arg_9_0:nodeByName("exchange_btn"):setVisible(false)
	end

	if arg_9_0.guild.normal_drink_times > 0 and arg_9_0.guild.normal_time > 0 then
		arg_9_0.normal_time = arg_9_0.guild.normal_time

		if arg_9_0.spriteji_ then
			arg_9_0.spriteji_:clearFilter()
		end

		arg_9_0.can_drinks[2] = true

		arg_9_0:nodeByName("left_time_words2"):setVisible(true)
		arg_9_0:nodeByName("left_num_words2"):setVisible(true)
		arg_9_0:nodeByName("left_time_text_2"):setVisible(true)
		arg_9_0:nodeByName("left_num_text_2"):setVisible(true)
		arg_9_0:nodeByName("sell_over_words_2"):setVisible(false)
		arg_9_0:nodeByName("left_num_text_2"):setString(arg_9_0.guild.normal_drink_times)

		local var_9_0 = arg_9_0.normal_time % 60
		local var_9_1 = math.floor(arg_9_0.normal_time % 3600 / 60)
		local var_9_2 = math.floor(arg_9_0.normal_time / 3600)

		arg_9_0:nodeByName("left_time_text_2"):setString(string.format("%02d:%02d:%02d", var_9_2, var_9_1, var_9_0))
	else
		arg_9_0.normal_time = 0
		arg_9_0.can_drinks[2] = false
		arg_9_0.spriteji_ = display.newFilteredSprite("windows/corporation_window/afternoon_tea_window/drink_self_window/ji_cup.png", "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})

		arg_9_0.spriteji_:setAnchorPoint(cc.p(0, 0))
		arg_9_0:nodeByName("ji_cup"):addChild(arg_9_0.spriteji_)
		arg_9_0:nodeByName("left_time_words2"):setVisible(false)
		arg_9_0:nodeByName("left_num_words2"):setVisible(false)
		arg_9_0:nodeByName("left_time_text_2"):setVisible(false)
		arg_9_0:nodeByName("left_num_text_2"):setVisible(false)
		arg_9_0:nodeByName("sell_over_words_2"):setVisible(true)
	end

	if arg_9_0.guild.special_drink_times > 0 and arg_9_0.guild.special_time > 0 then
		arg_9_0.special_time = arg_9_0.guild.special_time

		if arg_9_0.spriteRed_ then
			arg_9_0.spriteRed_:clearFilter()
		end

		arg_9_0.can_drinks[3] = true

		arg_9_0:nodeByName("left_time_words3"):setVisible(true)
		arg_9_0:nodeByName("left_num_words3"):setVisible(true)
		arg_9_0:nodeByName("left_time_text_3"):setVisible(true)
		arg_9_0:nodeByName("left_num_text_3"):setVisible(true)
		arg_9_0:nodeByName("sell_over_words_3"):setVisible(false)
		arg_9_0:nodeByName("left_num_text_3"):setString(arg_9_0.guild.special_drink_times)

		local var_9_3 = arg_9_0.special_time % 60
		local var_9_4 = math.floor(arg_9_0.special_time % 3600 / 60)
		local var_9_5 = math.floor(arg_9_0.special_time / 3600)

		arg_9_0:nodeByName("left_time_text_3"):setString(string.format("%02d:%02d:%02d", var_9_5, var_9_4, var_9_3))
	else
		arg_9_0.guild.special_time = 0
		arg_9_0.can_drinks[3] = false
		arg_9_0.spriteRed_ = display.newFilteredSprite("windows/corporation_window/afternoon_tea_window/drink_self_window/red_cup.png", "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})

		arg_9_0.spriteRed_:setAnchorPoint(cc.p(0, 0))
		arg_9_0:nodeByName("red_cup"):addChild(arg_9_0.spriteRed_)
		arg_9_0:nodeByName("left_time_words3"):setVisible(false)
		arg_9_0:nodeByName("left_num_words3"):setVisible(false)
		arg_9_0:nodeByName("left_time_text_3"):setVisible(false)
		arg_9_0:nodeByName("left_num_text_3"):setVisible(false)
		arg_9_0:nodeByName("sell_over_words_3"):setVisible(true)
	end
end

function var_0_0.doDrink(arg_10_0, arg_10_1)
	if arg_10_0.can_drinks[arg_10_1] == true then
		local var_10_0 = false

		if arg_10_1 == 1 then
			if arg_10_0.guild.free_have_drink == 1 then
				var_10_0 = true
			else
				var_10_0 = false
			end
		elseif arg_10_1 == 2 then
			if arg_10_0.guild.normal_have_drink == 1 then
				var_10_0 = true
			else
				var_10_0 = false
			end
		elseif arg_10_1 == 3 then
			var_10_0 = arg_10_0.guild.special_have_drink == 1 and true or false
		end

		local var_10_1 = xyd.tables.misc.energyMaxLimit

		if var_10_0 == false and var_10_1 < arg_10_0.selfPlayer.energy then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_3:translation("TILI_LIMIT_INFO")
			})
		elseif var_10_0 == true then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("TEAM_DRINK_HAS_DRINK"), nil, nil, nil, arg_10_0.colorMode)
		else
			params_ = {
				type = arg_10_1
			}

			arg_10_0.guild:doDrink(params_, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_10_0:nodeByName("already_drink_" .. arg_10_1):setVisible(true)

					local var_11_0 = ""

					if arg_10_1 == 1 then
						var_11_0 = var_0_2:translation("DRINK_BEER")
					elseif arg_10_1 == 2 then
						var_11_0 = var_0_2:translation("DRINK_COCKTAIL")

						arg_10_0:nodeByName("left_num_text_2"):setString(arg_10_0.guild.normal_drink_times)
					else
						var_11_0 = var_0_2:translation("DRINK_WINE")

						arg_10_0:nodeByName("left_num_text_3"):setString(arg_10_0.guild.special_drink_times)
					end

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, string.format(xyd.tables.translation:translation("TEAM_DRINK_DRINK_ALERT"), arg_10_0.guild.treat_player, var_11_0, xyd.tables.misc["drinkEnergyNum" .. arg_10_1]), nil, nil, nil, arg_10_0.colorMode)

					return true
				end
			end)
		end
	else
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("TEAM_DRINK_IS_NONE"), nil, nil, nil, arg_10_0.colorMode)
	end
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	arg_12_0:addBlockLayer()
	var_0_0.super:didOpen(arg_12_1)
	arg_12_0:nodeByName("close_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			local var_13_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_13_0, false)
			xyd.WindowManager.get():closeWindow(arg_12_0)
		end
	end)
end

function var_0_0.willClose(arg_14_0, arg_14_1)
	var_0_0.super:willClose(arg_14_1)
	var_0_1.unscheduleGlobal(arg_14_0.handle_)
end

return var_0_0
