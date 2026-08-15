local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	local var_2_1 = var_2_0:getChildByName("container")

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1:getChildByName("bg")
	local var_3_1 = xyd.createLabel(22, cc.c3b(123, 48, 47))

	var_3_1:setAnchorPoint(0, 0.5)
	var_3_1:addTo(var_3_0)
	var_3_1:setPosition(var_3_0:getChildByName("pos_label"):getPosition())
	var_3_1:setString(xyd.tables.activities:desc(arg_3_0.activity.table_id))
	var_3_1:setWidth(420)
	var_3_1:setLineHeight(30)
end

return var_0_0
