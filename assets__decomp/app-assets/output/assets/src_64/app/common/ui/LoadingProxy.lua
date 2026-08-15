local var_0_0 = class("LoadingProxy")
local var_0_1 = require("framework.scheduler")
local var_0_2 = "loading"
local var_0_3 = "new_loading"

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	arg_2_0.count_ = 0
end

function var_0_0.openLoadingWindow(arg_3_0, arg_3_1)
	if xyd.WindowManager.get():getWindow(var_0_2) == nil then
		local var_3_0 = arg_3_1 or {}
		local var_3_1 = xyd.WindowManager.get():openWindow(var_0_2, var_3_0)
	end
end

function var_0_0.openNewLoadingWindow(arg_4_0, arg_4_1)
	if xyd.WindowManager.get():getWindow(var_0_3) == nil then
		local var_4_0 = arg_4_1 or {}
		local var_4_1 = xyd.WindowManager.get():openWindow(var_0_3, var_4_0)
	end
end

function var_0_0.closeLoadingWindow(arg_5_0)
	local var_5_0 = xyd.WindowManager.get():getWindow(var_0_2)

	if var_5_0 and arg_5_0.count_ <= 0 and not var_5_0:isAnimated() then
		xyd.WindowManager.get():closeWindow(var_0_2)

		arg_5_0.count_ = 0
	elseif var_5_0 and arg_5_0.count_ <= 0 and var_5_0:isAnimated() then
		arg_5_0.count_ = 0

		var_0_1.performWithDelayGlobal(handler(arg_5_0, arg_5_0.closeWindowHandler), 1)
	end

	local var_5_1 = xyd.WindowManager.get():getWindow(var_0_3)

	if var_5_1 and arg_5_0.count_ <= 0 and not var_5_1:isAnimated() then
		xyd.WindowManager.get():closeWindow(var_0_3)

		arg_5_0.count_ = 0
	elseif var_5_1 and arg_5_0.count_ <= 0 and var_5_1:isAnimated() then
		arg_5_0.count_ = 0

		var_0_1.performWithDelayGlobal(handler(arg_5_0, arg_5_0.closeWindowHandler), 1)
	end
end

function var_0_0.closeWindowHandler(arg_6_0)
	if not arg_6_0 or arg_6_0.count_ > 0 then
		return
	end

	local var_6_0 = xyd.WindowManager.get():getWindow(var_0_2)

	if var_6_0 and not tolua.isnull(var_6_0) then
		xyd.WindowManager.get():closeWindow(var_0_2)
	end

	local var_6_1 = xyd.WindowManager.get():getWindow(var_0_3)

	if var_6_1 and not tolua.isnull(var_6_1) then
		xyd.WindowManager.get():closeWindow(var_0_3)
	end
end

function var_0_0.addLoading(arg_7_0, arg_7_1)
	arg_7_0.count_ = arg_7_0.count_ + 1

	if not xyd.WindowManager.get():getWindow(var_0_2) and arg_7_0.count_ > 0 then
		local var_7_0 = {
			delay = arg_7_1
		}

		arg_7_0:openLoadingWindow(var_7_0)
	end
end

function var_0_0.addNewLoading(arg_8_0, arg_8_1)
	arg_8_0.count_ = arg_8_0.count_ + 1

	if not xyd.WindowManager.get():getWindow(var_0_3) and arg_8_0.count_ > 0 then
		local var_8_0 = {
			delay = arg_8_1
		}

		arg_8_0:openNewLoadingWindow(var_8_0)
	end
end

function var_0_0.removeLoading(arg_9_0)
	if arg_9_0.count_ > 0 then
		arg_9_0.count_ = arg_9_0.count_ - 1
	end

	if arg_9_0.count_ <= 0 then
		arg_9_0:closeLoadingWindow()
	end
end

function var_0_0.reset(arg_10_0)
	arg_10_0.count_ = 0

	arg_10_0:closeLoadingWindow()
end

function var_0_0.openBattleLoading(arg_11_0, arg_11_1)
	local var_11_0

	if arg_11_1.isNewLoading then
		if not xyd.WindowManager.get():getWindow("battle_loading_new") then
			xyd.WindowManager.get():openWindow("battle_loading_new", arg_11_1)
		end
	elseif not xyd.WindowManager.get():getWindow("battle_loading") then
		xyd.WindowManager.get():openWindow("battle_loading", arg_11_1)
	end
end

function var_0_0.setLoadingPercent(arg_12_0, arg_12_1)
	local var_12_0 = xyd.WindowManager.get():getWindow(var_0_2)

	if var_12_0 then
		var_12_0:setPercent(arg_12_1)
	end
end

function var_0_0.setNewLoadingPercent(arg_13_0, arg_13_1)
	local var_13_0 = xyd.WindowManager.get():getWindow(var_0_3)

	if var_13_0 then
		var_13_0:setPercent(arg_13_1)
	end
end

function var_0_0.closeBattleLoading(arg_14_0)
	if xyd.WindowManager.get():getWindow("battle_loading") then
		xyd.WindowManager.get():closeWindow("battle_loading")
	end
end

return var_0_0
