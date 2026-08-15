local var_0_0 = class("NewTearTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout(arg_2_1)
end

function var_0_0.createLabel(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	local var_3_0 = {
		color = arg_3_2,
		size = arg_3_1
	}
	local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)

	var_3_1:setMaxLineWidth(290)

	if arg_3_3 then
		var_3_1:setString(arg_3_3)
	end

	var_3_1:addTo(arg_3_4)

	return var_3_1
end

function var_0_0.layout(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:createLabel(22, cc.c3b(255, 255, 255), arg_4_1, arg_4_0:nodeByName("skill_container"))

	var_4_0:setAnchorPoint(cc.p(0, 1))
	var_4_0:setName("skill_desc1")

	local var_4_1 = var_4_0:getContentSize().height
	local var_4_2 = 0

	arg_4_0.tipHeight = var_4_1 + var_4_2 + 50

	arg_4_0:setSkillTipPosition(var_4_0, desc2, var_4_1, var_4_2)

	local var_4_3 = arg_4_0:nodeByName("container")

	var_4_3:height(arg_4_0.tipHeight)

	local var_4_4 = var_4_3:getPositionY()

	arg_4_0:nodeByName("jiantou"):y(var_4_4 - 55)
end

function var_0_0.setSkillTipPosition(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	if arg_5_0.tipHeight <= 100 then
		arg_5_0.tipHeight = 110
	end

	local var_5_0 = 0

	if arg_5_4 > 0 and arg_5_3 > 0 then
		var_5_0 = (arg_5_0.tipHeight - arg_5_3 - arg_5_4 - 10) / 2
	else
		var_5_0 = (arg_5_0.tipHeight - arg_5_3 - arg_5_4) / 2
	end

	arg_5_1:y(162 - var_5_0)

	if arg_5_0.skillLevel and arg_5_0.skillLevel > 0 then
		if arg_5_3 > 0 then
			arg_5_2:y(162 - var_5_0 - arg_5_3 - 10)
		else
			arg_5_2:y(162 - var_5_0)
		end
	end
end

function var_0_0.getTipHeight(arg_6_0)
	return arg_6_0.tipHeight
end

function var_0_0.reloadTip(arg_7_0)
	local var_7_0 = arg_7_0:nodeByName("skill_container"):getChildByName("skill_desc1")

	var_7_0:setString(xyd.tables.skill:desc(arg_7_0.id))

	local var_7_1 = var_7_0:getContentSize().height
	local var_7_2 = 0

	arg_7_0.tipHeight = var_7_1 + var_7_2 + 50

	arg_7_0:setSkillTipPosition(var_7_0, desc2, var_7_1, var_7_2)

	local var_7_3 = arg_7_0:nodeByName("container")

	var_7_3:height(arg_7_0.tipHeight)

	local var_7_4 = var_7_3:getPositionY()

	arg_7_0:nodeByName("jiantou"):y(var_7_4 - arg_7_0.tipHeight / 2)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayerClickClose(cc.c4b(0, 0, 0, 0), nil, nil, 2)
end

function var_0_0.willClose(arg_9_0, arg_9_1)
	var_0_0.super:willClose(arg_9_1)
end

return var_0_0
