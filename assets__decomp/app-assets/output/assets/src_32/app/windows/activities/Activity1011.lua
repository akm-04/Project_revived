local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.show(arg_1_0, arg_1_1)
	var_0_0.super.show(arg_1_0, arg_1_1)

	if not arg_1_0.res or arg_1_0.res == 0 then
		print("No res available.")

		return
	end

	local var_1_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1011/1011.csb")

	var_1_0:addTo(arg_1_0.parent)

	local var_1_1 = var_1_0:getChildByName("container")
	local var_1_2 = xyd.split(xyd.tables.activities:desc(arg_1_0.activity.table_id), "#")

	var_1_1:getChildByName("txt_name"):setString(xyd.tables.activities:name(arg_1_0.activity.table_id))
	var_1_1:getChildByName("txt_intro"):setString(var_1_2[1])
	var_1_1:getChildByName("txt_tip"):setString(var_1_2[2])
	var_1_1:getChildByName("txt_0"):setString(xyd.tables.translation:translation("ACTIVITY_DESC"))
	var_1_1:getChildByName("txt_1"):setString(xyd.tables.translation:translation("ACTIVITY_NAME"))
	var_1_1:getChildByName("txt_2"):setString(xyd.tables.translation:translation("ACTIVITY_INTRO"))
	var_1_1:getChildByName("txt_3"):setString(xyd.tables.translation:translation("ACTIVITY_TIP"))
	var_1_1:getChildByName("txt_1"):enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))
	var_1_1:getChildByName("txt_2"):enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))
	var_1_1:getChildByName("txt_3"):enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))
	var_1_1:getChildByName("txt_name"):enableShadow(cc.c4b(144, 15, 15, 255), cc.size(2, -2))
	var_1_1:getChildByName("txt_intro"):enableShadow(cc.c4b(144, 15, 15, 255), cc.size(2, -2))
	var_1_1:getChildByName("txt_tip"):enableShadow(cc.c4b(144, 15, 15, 255), cc.size(2, -2))
end

return var_0_0
