local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

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
	local var_2_2 = xyd.split(xyd.tables.activities:desc(arg_2_0.activity.table_id), "#")

	var_2_1:getChildByName("txt_name"):setString(xyd.tables.activities:name(arg_2_0.activity.table_id))
	var_2_1:getChildByName("txt_intro"):setString(var_2_2[1])
	var_2_1:getChildByName("txt_tip"):setString(var_2_2[2])
	var_2_1:getChildByName("txt_1"):setString(xyd.tables.translation:translation("ACTIVITY_NAME"))
	var_2_1:getChildByName("txt_2"):setString(xyd.tables.translation:translation("ACTIVITY_INTRO"))
	var_2_1:getChildByName("txt_3"):setString(xyd.tables.translation:translation("ACTIVITY_TIP"))
	var_2_1:getChildByName("txt_1"):enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))
	var_2_1:getChildByName("txt_2"):enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))
	var_2_1:getChildByName("txt_3"):enableShadow(cc.c4b(134, 26, 26, 255), cc.size(2, -2))
	var_2_1:getChildByName("txt_name"):enableShadow(cc.c4b(151, 25, 14, 255), cc.size(2, -2))
	var_2_1:getChildByName("txt_intro"):enableShadow(cc.c4b(151, 25, 14, 255), cc.size(2, -2))
	var_2_1:getChildByName("txt_tip"):enableShadow(cc.c4b(151, 25, 14, 255), cc.size(2, -2))
end

return var_0_0
