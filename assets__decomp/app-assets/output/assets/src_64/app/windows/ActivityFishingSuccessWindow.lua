local var_0_0 = class("ActivityFishingSuccessWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityFish

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = tonumber(arg_1_2.fish_id)
	arg_1_0.mask = arg_1_2.fish_weight
	arg_1_0.isServerMax = arg_1_2.server_max
	arg_1_0.isSelfMax = arg_1_2.self_max
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_fish_name"):setString(var_0_2:name(arg_4_0.id))
	arg_4_0:nodeByName("txt_fish_name"):enableOutline(cc.c4b(175, 87, 15, 255), 2)
	arg_4_0:nodeByName("txt_1"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_8"))

	local var_4_0 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish/" .. arg_4_0.id .. ".png")

	arg_4_0:nodeByName("pos_fish"):addChild(var_4_0)

	local var_4_1 = var_0_2:price(arg_4_0.id)
	local var_4_2

	if arg_4_0.isServerMax == 1 then
		var_4_2 = string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_9"), arg_4_0.mask, var_4_1)
	elseif arg_4_0.isSelfMax == 1 then
		var_4_2 = string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_39"), arg_4_0.mask, var_4_1)
	else
		var_4_2 = string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_10"), arg_4_0.mask, var_4_1)
	end

	local var_4_3 = xyd.getColorlabel({
		color = cc.c3b(57, 64, 70)
	}, var_4_2)
	local var_4_4 = var_4_3:getContentSize()

	var_4_3:setAnchorPoint(0.5, 0.5)
	arg_4_0:nodeByName("pos_txt"):addChild(var_4_3)
	arg_4_0:nodeByName("coin"):setPositionX(arg_4_0:nodeByName("pos_txt"):getPositionX() + var_4_4.width / 2 + 5)
end

return var_0_0
