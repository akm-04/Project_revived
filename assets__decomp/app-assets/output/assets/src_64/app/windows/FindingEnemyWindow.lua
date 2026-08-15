local var_0_0 = class("FindingEnemyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	if arg_1_2 then
		arg_1_0.message = arg_1_2.message
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0

	if arg_3_0.message then
		var_3_0 = arg_3_0.message
	else
		var_3_0 = var_0_1:translation("REGION_ARENA_TIP5")
	end

	arg_3_0:nodeByName("finding_txt"):setString(var_3_0)

	local var_3_1 = 0

	arg_3_0.handle = var_0_2.scheduleGlobal(function()
		local var_4_0 = var_3_0

		var_3_1 = var_3_1 + 1
		count = var_3_1 % 7

		for iter_4_0 = 1, count do
			var_4_0 = var_4_0 .. "."
		end

		local var_4_1 = xyd.WindowManager.get():getWindow("finding_enemy")

		if not var_4_1 then
			return
		else
			var_4_1:nodeByName("finding_txt"):setString(var_4_0)
		end
	end, 0.5)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
end

function var_0_0.willClose(arg_6_0, arg_6_1)
	if arg_6_0.handle then
		var_0_2.unscheduleGlobal(arg_6_0.handle)
	end
end

return var_0_0
