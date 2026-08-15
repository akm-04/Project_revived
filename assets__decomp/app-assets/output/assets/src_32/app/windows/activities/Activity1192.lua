local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc:getValue("activity_charge_reward_rate")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1192/1192.csb")

	var_2_0:addTo(arg_2_0.parent)

	local var_2_1 = var_2_0:getChildByName("container")

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0.activity.details.base_info.charge
	local var_3_1 = arg_3_0.activity.details.base_info.has_month_card

	arg_3_1:getChildByName("item1_reward"):setString(var_3_0 * var_0_2)
	arg_3_1:getChildByName("item2_reward"):setString(var_3_1)

	local var_3_2 = arg_3_1:getChildByName("label_node")
	local var_3_3 = xyd.createLabel(22, cc.c3b(146, 57, 48))

	var_3_3:addTo(var_3_2)
	var_3_3:setString(var_0_1:translation("CHARGE_REWARD_TEXT1"))
	var_3_3:setWidth(470)
	var_3_3:setLineHeight(35)
	var_3_3:setAnchorPoint(cc.p(0, 0))
	var_3_3:setPosition(cc.p(0, -2))
end

return var_0_0
