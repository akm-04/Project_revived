local var_0_0 = class("ActivityExchangeHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroId = arg_1_2.heroId
	arg_1_0.tableId = arg_1_2.tableId
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.useHeros = xyd.tables.misc.enHeroExchange
	arg_1_0.canExchange = false
end

function var_0_0.didOpen(arg_2_0)
	var_0_0.super.didOpen()
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0)
	var_0_0.super.willClose()
end

function var_0_0.didClose(arg_4_0)
	if arg_4_0.skillClickHandle then
		var_0_2.unscheduleGlobal(arg_4_0.skillClickHandle)
	end

	var_0_0.super.didClose()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("des_words"):setString(var_0_1:translation("PLEASE_SELECT_EXCHANGE"))
	arg_6_0:nodeByName("mark_des"):setString(var_0_1:translation("CANT_EXCHANGE"))
	arg_6_0:nodeByName("change_to_words"):setString(var_0_1:translation("EXCHANGE_TO"))
	arg_6_0:nodeByName("to_stone_text"):setString(xyd.tables.hero:name(arg_6_0.heroId) .. var_0_1:translation("STONE"))

	if arg_6_0.selfPlayer:getHeroIgnoreAwaken(arg_6_0.heroId) then
		xyd.setAvatarBorder(arg_6_0.selfPlayer:getHeroIgnoreAwaken(arg_6_0.heroId), arg_6_0:nodeByName("to_avatar"))
	else
		xyd.setAvatarBorder(arg_6_0.heroId, arg_6_0:nodeByName("to_avatar"), 1, 0)
	end

	local var_6_0 = arg_6_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.hero:stoneID(arg_6_0.heroId))

	arg_6_0:nodeByName("own_to_num_text"):setString(string.format(var_0_1:translation("OWN_STONE"), var_6_0))

	arg_6_0.heroIndex = 1

	if arg_6_0.useHeros[arg_6_0.heroIndex] == arg_6_0.heroId then
		arg_6_0.heroIndex = 2
	end

	arg_6_0:updateUseHero()
	arg_6_0:initBtn()
end

function var_0_0.initBtn(arg_7_0)
	local var_7_0 = false
	local var_7_1 = cc.ui.UIPushButton.new({
		pressed = "windows/button/add_btn2.png",
		disabled = "windows/button/add_btn3.png",
		normal = "windows/button/add_btn1.png"
	})

	var_7_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_1:setPosition(arg_7_0:nodeByName("num_right_btn"):getPosition())
	var_7_1:addTo(arg_7_0:nodeByName("container"))
	var_7_1:setButtonEnabled(true)
	var_7_1:setScale(0.9, 0.9)
	var_7_1:onButtonPressed(function(arg_8_0)
		local var_8_0 = 0

		local function var_8_1()
			var_8_0 = var_8_0 + 0.02

			if var_8_0 > 0.3 then
				if not var_7_0 then
					var_7_0 = true
				end

				arg_7_0:addOwnNum(true)
			end
		end

		var_7_0 = false
		arg_7_0.skillClickHandle = var_0_2.scheduleGlobal(var_8_1, 0.02)
	end)
	var_7_1:onButtonRelease(function(arg_10_0)
		if arg_7_0.skillClickHandle then
			var_0_2.unscheduleGlobal(arg_7_0.skillClickHandle)
		end

		if not var_7_0 then
			arg_7_0:addOwnNum(true)
		end
	end)

	local var_7_2 = false
	local var_7_3 = cc.ui.UIPushButton.new({
		pressed = "windows/button/add_btn5.png",
		disabled = "windows/button/add_btn6.png",
		normal = "windows/button/add_btn4.png"
	})

	var_7_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_3:setPosition(arg_7_0:nodeByName("num_left_btn"):getPosition())
	var_7_3:addTo(arg_7_0:nodeByName("container"))
	var_7_3:setButtonEnabled(true)
	var_7_3:setScale(0.9, 0.9)
	var_7_3:onButtonPressed(function(arg_11_0)
		local var_11_0 = 0

		local function var_11_1()
			var_11_0 = var_11_0 + 0.02

			if var_11_0 > 0.3 then
				if not var_7_2 then
					var_7_2 = true
				end

				arg_7_0:addOwnNum(false)
			end
		end

		var_7_2 = false
		arg_7_0.skillClickHandle = var_0_2.scheduleGlobal(var_11_1, 0.02)
	end)
	var_7_3:onButtonRelease(function(arg_13_0)
		if arg_7_0.skillClickHandle then
			var_0_2.unscheduleGlobal(arg_7_0.skillClickHandle)
		end

		if not var_7_2 then
			arg_7_0:addOwnNum(false)
		end
	end)
	arg_7_0:nodeByName("hero_right_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.heroIndex = arg_7_0.heroIndex + 1

			if arg_7_0.heroIndex > #arg_7_0.useHeros then
				arg_7_0.heroIndex = 1
			end

			if arg_7_0.useHeros[arg_7_0.heroIndex] == arg_7_0.heroId then
				arg_7_0.heroIndex = arg_7_0.heroIndex + 1

				if arg_7_0.heroIndex > #arg_7_0.useHeros then
					arg_7_0.heroIndex = 1
				end
			end

			arg_7_0:updateUseHero()
		end
	end)
	arg_7_0:nodeByName("hero_left_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.heroIndex = arg_7_0.heroIndex - 1

			if arg_7_0.heroIndex < 1 then
				arg_7_0.heroIndex = #arg_7_0.useHeros
			end

			if arg_7_0.useHeros[arg_7_0.heroIndex] == arg_7_0.heroId then
				arg_7_0.heroIndex = arg_7_0.heroIndex - 1

				if arg_7_0.heroIndex < 1 then
					arg_7_0.heroIndex = #arg_7_0.useHeros
				end
			end

			arg_7_0:updateUseHero()
		end
	end)
	arg_7_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_16_0 = {}
			local var_16_1
			local var_16_2 = arg_7_0.useHeros[arg_7_0.heroIndex]

			if arg_7_0.selfPlayer:getHeroIgnoreAwaken(var_16_2) then
				var_16_1 = arg_7_0.selfPlayer:getHeroIgnoreAwaken(var_16_2)
			else
				return
			end

			if arg_7_0.selectNum <= 0 then
				return
			end

			var_16_0.activity_id = arg_7_0.tableId
			var_16_0.award_id = var_16_1:getHeroID()
			var_16_0.choice_ids = arg_7_0.selectNum
			var_16_0.sub_award_id = arg_7_0.heroId

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_16_0, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					local var_17_0 = {
						table_id = xyd.tables.hero:stoneID(arg_7_0.heroId),
						item_num = arg_17_1.exchange_stone_num
					}

					arg_7_0.selfPlayer:handleRewards({
						var_17_0
					})

					local var_17_1 = {
						itemID = xyd.tables.hero:stoneID(var_16_2),
						itemNum = var_16_0.choice_ids
					}

					arg_7_0.selfPlayer:getBackpack():removeItem(var_17_1)
					xyd.WindowManager.get():closeWindow(arg_7_0.name)
				end
			end)
		end
	end)
end

function var_0_0.addOwnNum(arg_18_0, arg_18_1)
	if arg_18_0.canExchange == true then
		if arg_18_1 then
			if arg_18_0.selectNum + xyd.tables.misc.enHeroExchangeRate <= arg_18_0.exchangeOwnNum then
				arg_18_0.selectNum = arg_18_0.selectNum + xyd.tables.misc.enHeroExchangeRate
			end
		elseif arg_18_0.selectNum - xyd.tables.misc.enHeroExchangeRate >= 0 then
			arg_18_0.selectNum = arg_18_0.selectNum - xyd.tables.misc.enHeroExchangeRate
		end
	end

	arg_18_0:updateSelectNum()
end

function var_0_0.updateUseHero(arg_19_0)
	arg_19_0.selectNum = 0

	local var_19_0 = arg_19_0.useHeros[arg_19_0.heroIndex]
	local var_19_1 = arg_19_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.hero:stoneID(var_19_0))

	arg_19_0.exchangeOwnNum = var_19_1

	arg_19_0:nodeByName("own_use_num_text"):setString(string.format(var_0_1:translation("OWN_STONE"), var_19_1))
	arg_19_0:nodeByName("use_stone_text"):setString(xyd.tables.hero:name(var_19_0) .. var_0_1:translation("STONE"))

	local var_19_2

	if arg_19_0.selfPlayer:getHeroIgnoreAwaken(var_19_0) then
		xyd.setAvatarBorder(arg_19_0.selfPlayer:getHeroIgnoreAwaken(var_19_0), arg_19_0:nodeByName("use_avatar"))

		var_19_2 = arg_19_0.selfPlayer:getHeroIgnoreAwaken(var_19_0)
	else
		xyd.setAvatarBorder(var_19_0, arg_19_0:nodeByName("use_avatar"), 1, 0)
	end

	if var_19_1 < xyd.tables.misc.enHeroExchangeRate then
		arg_19_0:nodeByName("avatar_mask"):setVisible(true)
		arg_19_0:nodeByName("mark_des"):setVisible(true)
		arg_19_0:nodeByName("red_text"):setString(var_0_1:translation("STONE_NOT_ENOUGH"))
		arg_19_0:nodeByName("own_use_num_text"):setVisible(false)
		arg_19_0:nodeByName("red_text"):setVisible(true)

		arg_19_0.canExchange = false
	elseif not var_19_2 or var_19_2:getStar() < 5 then
		arg_19_0:nodeByName("avatar_mask"):setVisible(true)
		arg_19_0:nodeByName("mark_des"):setVisible(true)
		arg_19_0:nodeByName("red_text"):setString(var_0_1:translation("HERO_NOT_FIVE_STAR"))
		arg_19_0:nodeByName("own_use_num_text"):setVisible(false)
		arg_19_0:nodeByName("red_text"):setVisible(true)

		arg_19_0.canExchange = false
	else
		arg_19_0:nodeByName("avatar_mask"):setVisible(false)
		arg_19_0:nodeByName("mark_des"):setVisible(false)
		arg_19_0:nodeByName("own_use_num_text"):setVisible(true)
		arg_19_0:nodeByName("red_text"):setVisible(false)

		arg_19_0.canExchange = true
	end

	arg_19_0:updateSelectNum()
end

function var_0_0.updateSelectNum(arg_20_0)
	arg_20_0:nodeByName("num_select_text"):setString(string.format(var_0_1:translation("NUM_STONE"), arg_20_0.selectNum))
	arg_20_0:nodeByName("num_to_text"):setString(string.format(var_0_1:translation("NUM_STONE"), math.floor(arg_20_0.selectNum / xyd.tables.misc.enHeroExchangeRate)))
end

return var_0_0
