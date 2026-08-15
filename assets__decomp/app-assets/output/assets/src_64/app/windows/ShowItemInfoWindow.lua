local var_0_0 = class("ShowItemInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.christmasGift
local var_0_5 = 35
local var_0_6 = 1027
local var_0_7 = 50001025
local var_0_8 = 50001026
local var_0_9 = 50001027
local var_0_10 = 50001028

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.item = arg_1_2.item
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.backpack_ = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(nil, false, false, function()
		if xyd.WindowManager.get():getWindow("item_compose") then
			xyd.WindowManager.get():closeWindow("item_compose")
			xyd.WindowManager.get():closeWindow(arg_3_0)
		else
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.willClose(arg_6_0)
	local var_6_0 = xyd.WindowManager.get():getWindow("activities")

	if var_6_0 and var_6_0.openedActivities[xyd.Activities.Christmas] and var_6_0.openedActivities[xyd.Activities.Christmas]:getChristmasLayout() then
		var_6_0.openedActivities[xyd.Activities.Christmas]:getChristmasLayout():update()
	end
end

function var_0_0.layout(arg_7_0)
	local var_7_0 = arg_7_0.item
	local var_7_1 = arg_7_0:nodeByName("icon")

	var_7_1:removeAllChildren()
	xyd.setItemBorder(var_7_1, var_7_0:getTableID())
	arg_7_0:nodeByName("label_name"):setString(var_7_0:getName())
	arg_7_0:nodeByName("label_desc"):hide()
	arg_7_0:nodeByName("label_own1"):setString(var_0_2:translation("ITEM_OWN"))
	arg_7_0:nodeByName("label_own2"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))
	arg_7_0:nodeByName("label_tips1"):setString(var_0_2:translation("ITEM_BIND_TIP"))
	arg_7_0:nodeByName("label_tips2"):setString(string.format(var_0_2:translation("ITEM_EREQUIRED_LEVEL"), var_7_0:getLevel()))
	arg_7_0:nodeByName("label_attr"):setString(var_0_2:translation("PHYSICAL_ATTACK"))
	arg_7_0:nodeByName("label_attr"):setVisible(false)
	arg_7_0:nodeByName("label_attr_value1"):setVisible(false)
	arg_7_0:nodeByName("label_attr_value2"):setVisible(false)
	arg_7_0:getBtn()
	arg_7_0:update()
end

function var_0_0.update(arg_8_0)
	arg_8_0:nodeByName("label_own_value"):setString(arg_8_0.item:getSelfNum())

	local var_8_0, var_8_1 = arg_8_0:nodeByName("label_own_value"):getPosition()

	arg_8_0:nodeByName("label_own2"):x(var_8_0 + arg_8_0:nodeByName("label_own_value"):getContentSize().width + 5)

	local var_8_2 = arg_8_0.item

	if arg_8_0.labelDesc_ then
		arg_8_0.labelDesc_:removeSelf()
	end

	local var_8_3 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = arg_8_0:nodeByName("label_desc"):getX(),
		y = arg_8_0:nodeByName("word_back"):getY() - 30,
		color = cc.c3b(51, 48, 43),
		text = var_8_2:getSubDesc(),
		dimensions = cc.size(280, 200)
	}

	arg_8_0.labelDesc_ = xyd.AssetLoader.get():loadLabel(var_8_3)

	arg_8_0.labelDesc_:addTo(arg_8_0)
	arg_8_0.labelDesc_:align(display.CENTER_TOP)
	arg_8_0:nodeByName("word_back"):height(arg_8_0.labelDesc_:getStringNumLines() * 26 + 60)

	local var_8_4 = arg_8_0.item:getCompose()

	arg_8_0:nodeByName("text_ok"):hide()
	arg_8_0:nodeByName("text_compose"):hide()
	arg_8_0:nodeByName("text_equip"):hide()
	arg_8_0:nodeByName("gain_way"):hide()
	arg_8_0:nodeByName("compose_formula"):hide()
	arg_8_0:nodeByName("label_tips1"):hide()
	arg_8_0:nodeByName("label_tips2"):hide()
	arg_8_0:nodeByName("text_light"):hide()

	if var_8_2:isInBackpack() then
		arg_8_0:nodeByName("text_light"):show()

		arg_8_0.state_ = "exchange"
	elseif (#var_8_4 < 1 or var_8_4[1] == 0) and not var_8_2:isInBackpack() then
		arg_8_0:nodeByName("gain_way"):show()

		arg_8_0.state_ = "gain_way"
	else
		arg_8_0:nodeByName("compose_formula"):show()

		arg_8_0.state_ = "compose"
	end
end

function var_0_0.getBtn(arg_9_0)
	if not arg_9_0.btn_ then
		arg_9_0.btn_ = arg_9_0:nodeByName("button")

		arg_9_0.btn_:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_9_0.state_ == "exchange" then
					arg_9_0:getAwardItems()
				elseif arg_9_0.state_ == "compose" then
					local var_10_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						isActivityItem = true,
						item = arg_9_0.item
					})

					cc.EventProxy.new(var_10_0, var_10_0):addEventListener(xyd.event.ITEM_CHANGED, function(arg_11_0)
						arg_9_0:update()
					end)
				elseif arg_9_0.state_ == "gain_way" then
					local var_10_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						isActivityItem = true,
						isCompose = false,
						item = arg_9_0.item
					})
				end
			end
		end)
	end

	return arg_9_0.btn_
end

function var_0_0.getAwardItems(arg_12_0)
	if var_0_4:totalGiftCount() < 1 then
		return
	end

	local var_12_0 = {
		var_0_8,
		var_0_10,
		var_0_7,
		var_0_9
	}

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("EXCHANGE_CHRISTMAS_ITEM"), arg_12_0.item:getName(), var_0_3:name(var_0_8), var_0_3:name(var_0_10), var_0_3:name(var_0_7), var_0_3:name(var_0_9)), function()
		for iter_13_0 = 1, var_0_4:totalGiftCount() do
			if table.nums(var_0_4:items(iter_13_0)) == 1 and var_0_4:items(iter_13_0)[1] == arg_12_0.item:getTableID() then
				arg_12_0.activitiesModel:getActivityReward(var_0_6, iter_13_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						arg_12_0.backpack_:removeItem({
							itemNum = 1,
							itemID = arg_12_0.item:getTableID()
						})
						arg_12_0.selfPlayer:handleRewards(arg_14_1.awards)
						arg_12_0:update()
					end
				end)

				break
			end
		end
	end, nil, nil, arg_12_0.colorMode)
end

return var_0_0
