local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.lukangCost
local var_0_3 = xyd.tables.lukangExtraReward
local var_0_4 = xyd.tables.lukangReward
local var_0_5 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("txt_word"):setString(var_0_1:translation("ACTIVITY_1207_TIPS"))

	for iter_3_0 = 1, 4 do
		arg_3_0.container:getChildByName("txt_gift_" .. iter_3_0):setString("x" .. var_0_3:progress(iter_3_0))
	end

	arg_3_0:setBtnClick()
	arg_3_0:updateItems()
	arg_3_0:updateGifts()
	arg_3_0:updateProgress()
end

function var_0_0.setBtnClick(arg_4_0)
	xyd.nodeEventSample(arg_4_0.container:getChildByName("btn_rule"), nil, function()
		local var_5_0 = {}

		var_5_0.title_name = "ACTIVITY_1207_RULE_TITLE"
		var_5_0.rule = "ACTIVITY_1207_RULE_TEXT"

		xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
	end)
	arg_4_0.container:getChildByName("btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			if var_0_2:cost(arg_4_0.activity.details.progress + 1) <= arg_4_0.selfPlayer.crystal then
				xyd.Backend.get():request(xyd.mid.LUKANG_SUMMON, nil, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						arg_4_0.activity.details.is_awarded = arg_7_1.is_awarded
						arg_4_0.activity.details.progress = arg_7_1.progress

						arg_4_0.selfPlayer:handleRewards(arg_7_1.awards[1])
						arg_4_0:updateItems()
						arg_4_0:updateGifts()
						arg_4_0:updateProgress()
					end
				end)
			else
				local var_6_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
					local var_8_0 = {}

					var_8_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_8_0)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end
	end)

	for iter_4_0 = 1, 4 do
		arg_4_0.container:getChildByName("gift_" .. iter_4_0):addTouchEventListener(function(arg_9_0, arg_9_1)
			local var_9_0 = var_0_3:progress(iter_4_0)
			local var_9_1 = arg_4_0.activity.details.progress

			if arg_9_1 == ccui.TouchEventType.began then
				if var_9_0 <= var_9_1 then
					return true
				end

				arg_4_0:showTip(iter_4_0)
			elseif arg_9_1 == ccui.TouchEventType.canceled then
				arg_4_0:hideTip(iter_4_0)
			elseif arg_9_1 == ccui.TouchEventType.ended then
				if var_9_0 <= var_9_1 then
					xyd.Backend.get():request(xyd.mid.LUKANG_EXTRA, {
						id = iter_4_0
					}, function(arg_10_0, arg_10_1)
						if arg_10_0 == xyd.error.OK then
							arg_4_0.activity.details.extra_awarded = arg_10_1.extra_awarded

							arg_4_0.selfPlayer:handleRewards(arg_10_1.awards[1])
							arg_4_0:updateGifts()
						end
					end)
				else
					arg_4_0:hideTip(iter_4_0)
				end
			end
		end)
	end
end

function var_0_0.showTip(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_0.container:getChildByName("tip")
	local var_11_1 = arg_11_0.container:getChildByName("tip_arrow")
	local var_11_2 = var_0_3:gift(arg_11_1)
	local var_11_3 = var_0_5:items(var_11_2)
	local var_11_4 = var_0_5:itemNum(var_11_2)
	local var_11_5 = #var_11_3
	local var_11_6 = var_11_0:getContentSize()

	var_11_0:removeAllChildren()
	var_11_0:setContentSize(var_11_6.width, 90 * var_11_5 + 10)

	local var_11_7 = arg_11_0.container:getChildByName("gift_" .. arg_11_1):getPositionY()

	var_11_0:setPositionY(var_11_7 + 30)
	var_11_1:setPositionY(var_11_7)

	for iter_11_0 = 1, var_11_5 do
		local var_11_8 = display.newNode()

		var_11_8:setContentSize(76, 76)
		xyd.setItemBorder(var_11_8, var_11_3[iter_11_0])
		var_11_8:addTo(var_11_0)
		var_11_8:setPosition(40, 90 * (var_11_5 - iter_11_0) + 14)

		local var_11_9 = xyd.createLabel(20, cc.c3b(136, 238, 238))

		var_11_9:addTo(var_11_0)
		var_11_9:setPosition(130, 90 * (var_11_5 - iter_11_0) + 50)
		var_11_9:setString("x " .. var_11_4[iter_11_0])
	end

	var_11_0:setVisible(true)
	var_11_1:setVisible(true)
end

function var_0_0.hideTip(arg_12_0, arg_12_1)
	arg_12_0.container:getChildByName("tip"):setVisible(false)
	arg_12_0.container:getChildByName("tip_arrow"):setVisible(false)
end

function var_0_0.updateItems(arg_13_0)
	for iter_13_0 = 1, 10 do
		local var_13_0 = arg_13_0.container:getChildByName("item_" .. iter_13_0)
		local var_13_1 = var_0_4:gift(iter_13_0)
		local var_13_2 = var_0_5:items(var_13_1)[1]
		local var_13_3 = var_0_5:itemNum(var_13_1)[1]

		var_13_0:removeAllChildren()
		xyd.setItemAndAddTips(var_13_0, var_13_2, var_13_3)

		if arg_13_0.activity.details.is_awarded[iter_13_0] == 1 then
			arg_13_0:addBlock(iter_13_0)
		end
	end
end

function var_0_0.addBlock(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_0.container:getChildByName("item_" .. arg_14_1)
	local var_14_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1207/block.png")
	local var_14_2 = xyd.AssetLoader.get():loadSprite("windows/common/chosen_green.png")

	var_14_1:addTo(var_14_0)
	var_14_1:setAnchorPoint(0, 0)
	var_14_1:setPosition(0, 0)
	var_14_2:addTo(var_14_0)
	var_14_2:setAnchorPoint(0, 0)
	var_14_2:setPosition(43, 2)
end

function var_0_0.updateGifts(arg_15_0)
	local var_15_0 = arg_15_0.activity.details.progress

	for iter_15_0 = 1, 4 do
		local var_15_1 = var_0_3:progress(iter_15_0)

		arg_15_0.container:getChildByName("gift_open_" .. iter_15_0):setVisible(arg_15_0.activity.details.extra_awarded[iter_15_0] == 1)
		arg_15_0.container:getChildByName("gift_" .. iter_15_0):setVisible(arg_15_0.activity.details.extra_awarded[iter_15_0] == 0)
		arg_15_0.container:getChildByName("gift_" .. iter_15_0):setBright(var_15_1 <= var_15_0)
	end
end

function var_0_0.updateProgress(arg_16_0)
	local var_16_0 = arg_16_0.activity.details.progress
	local var_16_1 = var_0_2:cost(var_16_0 + 1)
	local var_16_2 = arg_16_0.container:getChildByName("btn")

	if var_16_0 == 0 then
		var_16_2:getChildByName("txt_cost"):setVisible(false)
		var_16_2:getChildByName("icon_crystal"):setVisible(false)
		var_16_2:getChildByName("txt_btn"):setString(var_0_1:translation("ACTIVITY_1207_BUTTON_2"))
		var_16_2:getChildByName("txt_btn"):setPositionY(40)
	elseif var_16_0 == 10 then
		var_16_2:getChildByName("txt_cost"):setVisible(false)
		var_16_2:getChildByName("icon_crystal"):setVisible(false)
		var_16_2:getChildByName("txt_btn"):setString(var_0_1:translation("ACTIVITY_1207_BUTTON_1"))
		var_16_2:getChildByName("txt_btn"):setPositionY(40)
		var_16_2:getChildByName("txt_btn"):setColor(cc.c3b(44, 44, 44))
		var_16_2:setBright(false)
		var_16_2:setTouchEnabled(false)
	else
		var_16_2:getChildByName("txt_cost"):setVisible(true)
		var_16_2:getChildByName("icon_crystal"):setVisible(true)
		var_16_2:getChildByName("txt_btn"):setString(var_0_1:translation("ACTIVITY_1207_BUTTON_1"))
		var_16_2:getChildByName("txt_btn"):setPositionY(51)
		var_16_2:getChildByName("txt_cost"):setString(var_16_1)
	end

	arg_16_0.container:getChildByName("bg_bar"):getChildByName("bar"):setPercent(var_16_0 / 10 * 100)
end

return var_0_0
