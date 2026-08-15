local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.is_open = arg_1_0.activity.is_open or 0
	arg_1_0.startTime = arg_1_0.activity.start_time
	arg_1_0.endTime = arg_1_0.activity.end_time

	dump(arg_1_0.activity)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	arg_2_0.serverTime = xyd.ServerTime.get():getServerTime()

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.detail = var_2_0

	local var_2_1 = var_2_0:getChildByName("container")

	var_2_1:getChildByName("charge_num"):setString(arg_2_0.activity.details.base_info.charge_count)
	var_2_1:getChildByName("return_num"):setString(arg_2_0.activity.details.base_info.return_count)
	var_2_1:getChildByName("rule"):setString(var_0_1:translation("ACTIVITY_1143_TEXT2"))
	var_2_1:getChildByName("end_time_text"):setString(var_0_1:translation("ACTIVITY_1143_TEXT1"))
	var_2_1:getChildByName("rate"):setString(tostring(arg_2_0.activity.details.base_info.rebate_rate / 100) .. "%")
	var_2_1:getChildByName("end_time"):setString(os.date(var_0_1:translation("ACTIVITY_GODESS_END_TIME"), arg_2_0.endTime))
	var_2_1:getChildByName("word1"):enableShadow(cc.c4b(196, 40, 44, 255), cc.size(1, -1), 1)
	var_2_1:getChildByName("word2"):enableShadow(cc.c4b(196, 40, 44, 255), cc.size(1, -1), 1)
	var_2_1:getChildByName("word3"):enableShadow(cc.c4b(196, 40, 44, 255), cc.size(1, -1), 1)
end

return var_0_0
