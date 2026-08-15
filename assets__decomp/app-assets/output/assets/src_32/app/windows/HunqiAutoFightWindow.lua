local var_0_0 = class("HunqiAutoFightWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.spiritSuit
local var_0_3 = xyd.tables.spiritCampaign
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.common.ui.SpriteNodeButton")
local var_0_6 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.campaignType = xyd.CampaignType.HUNQI
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.response = arg_1_2
	arg_1_0.baseInfo = arg_1_0.response.base_info
	arg_1_0.campaignInfos = arg_1_0.response.campaign_infos
	arg_1_0.day = arg_1_0.response.day
	arg_1_0.dayInfo = arg_1_0.response.day_info
	arg_1_0.times = 1
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0.maxTimes = xyd.tables.misc:getValue("spirit_auto_limit")

	local var_2_0 = arg_2_0.selfPlayer.spiritEnergy
	local var_2_1 = var_0_3:winCostNum(arg_2_0.campaignID)
	local var_2_2 = math.floor(var_2_0 / var_2_1)

	arg_2_0.maxTimes = math.min(arg_2_0.maxTimes, var_2_2)

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.setText(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("HUNQI_TEXT_14"))
	arg_4_0:nodeByName("text_desc_1"):setString("Consume       Stamina，about     mins to finish.")
	arg_4_0:nodeByName("text_desc_2"):setString(var_0_1:translation("HUNQI_TEXT_17"))
	arg_4_0:nodeByName("text_max"):setString(var_0_1:translation("MAX"))
	arg_4_0:nodeByName("text_battle"):setString(var_0_1:translation("HUNQI_TEXT_18"))
	arg_4_0:nodeByName("text_title"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
end

function var_0_0.setBtns(arg_5_0)
	arg_5_0:nodeByName("btn_max"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_5_0.times = arg_5_0.maxTimes

			arg_5_0:update()
		end
	end)
	arg_5_0:nodeByName("btn_battle"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {
				campaign_id = arg_5_0.campaignID,
				times = arg_5_0.times
			}

			xyd.Backend.get():request(xyd.mid.HUNQI_AUTO_FIGHT, var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():getWindow("hunqi_campaign"):updateAutoFight(arg_8_1)
					arg_5_0:close()
				end
			end)
		end
	end)

	local var_5_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_5_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_0:setScale(1, 1)
	var_5_0:addTo(arg_5_0:nodeByName("decrease_button"))
	var_5_0:setName("jiandian")

	local var_5_1 = false

	var_5_0:onButtonPressed(function(arg_9_0)
		local var_9_0 = 0

		local function var_9_1()
			var_9_0 = var_9_0 + 0.03

			if arg_5_0.decreaseCurrentNum then
				arg_5_0:decreaseCurrentNum()
			end
		end

		local function var_9_2()
			var_9_0 = var_9_0 + 0.1

			if var_9_0 > 0.5 and var_9_0 <= 4 then
				var_5_1 = true

				if arg_5_0.decreaseCurrentNum then
					arg_5_0:decreaseCurrentNum()
				end
			elseif var_9_0 > 4 then
				arg_5_0.handler[2] = var_0_6.scheduleGlobal(var_9_1, 0.03)

				var_0_6.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_1 = false
			end
		end

		var_5_1 = false
		arg_5_0.handler[1] = var_0_6.scheduleGlobal(var_9_2, 0.1)
	end)
	var_5_0:onButtonRelease(function(arg_12_0)
		if arg_5_0.handler[1] ~= nil then
			var_0_6.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_6.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_1 == false and arg_5_0.decreaseCurrentNum then
			arg_5_0:decreaseCurrentNum()
		end
	end)

	local var_5_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_5_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_2:setScale(1, 1)
	var_5_2:addTo(arg_5_0:nodeByName("increase_button"))
	var_5_2:setName("jiadian")

	local var_5_3 = false

	var_5_2:onButtonPressed(function(arg_13_0)
		local var_13_0 = 0

		local function var_13_1()
			var_13_0 = var_13_0 + 0.03

			if arg_5_0.addCurrentNum then
				arg_5_0:addCurrentNum()
			end
		end

		local function var_13_2()
			var_13_0 = var_13_0 + 0.1

			if var_13_0 > 0.5 and var_13_0 <= 4 then
				var_5_3 = true

				if arg_5_0.addCurrentNum then
					arg_5_0:addCurrentNum()
				end
			elseif var_13_0 > 4 then
				arg_5_0.handler[2] = var_0_6.scheduleGlobal(var_13_1, 0.03)

				var_0_6.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_3 = false
			end
		end

		var_5_3 = false
		arg_5_0.handler[1] = var_0_6.scheduleGlobal(var_13_2, 0.1)
	end)
	var_5_2:onButtonRelease(function(arg_16_0)
		if arg_5_0.handler[1] ~= nil then
			var_0_6.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_6.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_3 == false and arg_5_0.addCurrentNum then
			arg_5_0:addCurrentNum()
		end
	end)
end

function var_0_0.decreaseCurrentNum(arg_17_0)
	if arg_17_0.times - 1 <= 0 then
		return
	else
		arg_17_0.times = arg_17_0.times - 1
	end

	arg_17_0:update()
end

function var_0_0.addCurrentNum(arg_18_0)
	if arg_18_0.times >= arg_18_0.maxTimes then
		return
	else
		arg_18_0.times = arg_18_0.times + 1
	end

	arg_18_0:update()
end

function var_0_0.layout(arg_19_0)
	arg_19_0:setText()
	arg_19_0:setBtns()
	arg_19_0:update()
end

function var_0_0.update(arg_20_0)
	arg_20_0:nodeByName("text_num"):setString(arg_20_0.times .. "/" .. arg_20_0.maxTimes)
	arg_20_0:nodeByName("tili"):setString(arg_20_0.times * var_0_3:winCostNum(arg_20_0.campaignID))
	arg_20_0:nodeByName("time"):setString(arg_20_0.times * xyd.tables.misc:getValue("spirit_auto_time"))
end

return var_0_0
