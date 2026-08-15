local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.show(arg_1_0, arg_1_1)
	var_0_0.super.show(arg_1_0, arg_1_1)

	if not arg_1_0.res or arg_1_0.res == 0 then
		print("No res available.")

		return
	end

	local var_1_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1016/1016.csb")

	var_1_0:addTo(arg_1_0.parent)

	local var_1_1 = var_1_0:getChildByName("container")
	local var_1_2 = xyd.split(xyd.tables.activities:desc(arg_1_0.activity.table_id), "#")

	var_1_1:getChildByName("txt_name"):setString(xyd.tables.activities:name(arg_1_0.activity.table_id))
	var_1_1:getChildByName("txt_intro"):setString(var_1_2[1])
	var_1_1:getChildByName("txt_tip"):setString(var_1_2[2])
	var_1_1:getChildByName("txt_1"):setString(xyd.tables.translation:translation("ACTIVITY_NAME"))
	var_1_1:getChildByName("txt_2"):setString(xyd.tables.translation:translation("ACTIVITY_INTRO"))
	var_1_1:getChildByName("txt_3"):setString(xyd.tables.translation:translation("ACTIVITY_TIP"))
end

return var_0_0
