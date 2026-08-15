local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.show(arg_1_0, arg_1_1)
	var_0_0.super.show(arg_1_0, arg_1_1)

	if not arg_1_0.res or arg_1_0.res == 0 then
		print("No res available.")

		return
	end

	local var_1_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1014/1014.csb")

	var_1_0:addTo(arg_1_0.parent)

	local var_1_1 = var_1_0:getChildByName("container"):getChildByName("content")

	var_1_1:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_1_1:setString(xyd.tables.activities:desc(arg_1_0.activity.table_id))
end

return var_0_0
