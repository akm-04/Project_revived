local var_0_0 = class("NewMonthCardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("text_container"):getContentSize()
	local var_4_1 = 0
	local var_4_2 = var_4_0.height
	local var_4_3 = 15
	local var_4_4 = 110
	local var_4_5 = ""

	if arg_4_0.player.leftCardDay > 0 then
		var_4_5 = var_0_1:translation("MONTHLY_CARD_TEXT_1") .. string.format(var_0_1:translation("MONTHLY_CARD_TEXT_3"), arg_4_0.player.leftCardDay)
	else
		var_4_5 = var_0_1:translation("MONTHLY_CARD_TEXT_1") .. var_0_1:translation("MONTHLY_CARD_TEXT_2")
	end

	arg_4_0:createText(0, var_4_2, 24, var_4_5)

	local var_4_6 = var_4_2 - 24 - var_4_3
	local var_4_7 = var_0_1:translation("MONTHLY_CARD_TEXT_4")

	arg_4_0:createText(var_4_4, var_4_6, 22, var_4_7)

	local var_4_8 = var_4_6 - 22 - var_4_3

	if arg_4_0.player.leftEnergyMonthCardDay > 0 then
		var_4_7 = var_0_1:translation("MONTHLY_CARD_TEXT_5") .. string.format(var_0_1:translation("MONTHLY_CARD_TEXT_3"), arg_4_0.player.leftEnergyMonthCardDay)
	else
		var_4_7 = var_0_1:translation("MONTHLY_CARD_TEXT_5") .. var_0_1:translation("MONTHLY_CARD_TEXT_2")
	end

	arg_4_0:createText(0, var_4_8, 24, var_4_7)

	local var_4_9 = var_4_8 - 24 - var_4_3
	local var_4_10 = var_0_1:translation("MONTHLY_CARD_TEXT_6")

	arg_4_0:createText(var_4_4, var_4_9, 22, var_4_10)

	local var_4_11 = var_4_9 - 22 - var_4_3
	local var_4_12 = var_0_1:translation("MONTHLY_CARD_TEXT_7")

	arg_4_0:createText(0, var_4_11, 24, var_4_12)

	local var_4_13 = var_4_11 - 24 - var_4_3
	local var_4_14 = xyd.split(var_0_1:translation("MONTHLY_CARD_TEXT_8"), "\n")

	for iter_4_0 = 1, #var_4_14 do
		local var_4_15 = var_4_14[iter_4_0]

		arg_4_0:createText(var_4_4, var_4_13, 22, var_4_15)

		var_4_13 = var_4_13 - 22 - var_4_3
	end

	if arg_4_0.player.privilegeLeftCardDay > 0 then
		var_4_12 = var_0_1:translation("MONTHLY_CARD_TEXT_9") .. string.format(var_0_1:translation("MONTHLY_CARD_TEXT_3"), arg_4_0.player.privilegeLeftCardDay)
	else
		var_4_12 = var_0_1:translation("MONTHLY_CARD_TEXT_9") .. var_0_1:translation("MONTHLY_CARD_TEXT_2")
	end

	arg_4_0:createText(0, var_4_13, 24, var_4_12)

	local var_4_16 = var_4_13 - 24 - var_4_3
	local var_4_17 = var_0_1:translation("MONTHLY_CARD_TEXT_10")

	arg_4_0:createText(var_4_4, var_4_16, 22, var_4_17)

	local var_4_18 = var_4_16 - 22 - var_4_3

	arg_4_0:nodeByName("Text_2"):setString(var_0_1:translation("MONTHLY_CARD_TITLE"))

	local var_4_19, var_4_20 = arg_4_0:nodeByName("Text_2"):getPosition()

	arg_4_0:nodeByName("Text_2"):setPosition(var_4_19 - 30, var_4_20)
	arg_4_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("vip_recharge")
		end
	end)

	local var_4_21 = "windows/new_rule/close.png"

	arg_4_0.icon = xyd.AssetLoader.get():loadSprite(var_4_21)

	arg_4_0:nodeByName("container"):add(arg_4_0.icon)
	arg_4_0.icon:setAnchorPoint(0.5, 0.5)
	arg_4_0.icon:setPosition(776, 506)
	arg_4_0.icon:setTouchEnabled(true)
	arg_4_0.icon:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			arg_4_0.icon:setScale(0.9)

			return true
		elseif arg_6_0.name == "moved" then
			arg_4_0.icon:setScale(1)
		elseif arg_6_0.name == "ended" then
			arg_4_0.icon:setScale(1)
			xyd.WindowManager.get():closeWindow(arg_4_0.name)
		end
	end)
end

function var_0_0.createText(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = arg_7_0:nodeByName("text_container")
	local var_7_1 = {
		size = arg_7_3,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c3b(0, 0, 0)
	}
	local var_7_2 = xyd.createMultiColorTxt(arg_7_4, xyd.color.BLACK, arg_7_3, false)

	var_7_2:addTo(var_7_0)
	var_7_2:setPosition(cc.p(arg_7_1, arg_7_2))
	var_7_2:setAnchorPoint(cc.p(0, 1))
end

function var_0_0.createTextLabel(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0 = {
		text = arg_8_1,
		align = arg_8_3,
		color = arg_8_5,
		size = arg_8_4,
		dimensions = cc.size(arg_8_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_8_0))
end

return var_0_0
