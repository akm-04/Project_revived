local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(-5, 5)

		local var_2_1 = arg_2_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.lubuMatchTicket)

		arg_2_0.container:getChildByName("bg_inner"):getChildByName("num_txt"):setString("X" .. var_2_1)
		arg_2_0.container:getChildByName("desc_bg"):getChildByName("desc_txt"):setString(var_0_1:translation("LVBU_CHARGE_RULER"))
	end
end

return var_0_0
