local var_0_0 = class("LotteryAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityLottery

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.stage = arg_1_2.dayStage
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = display.newNode()
	local var_3_1 = arg_3_0:nodeByName("bg"):getContentSize().width
	local var_3_2 = arg_3_0:nodeByName("bg"):getContentSize().height

	var_3_0:setContentSize(var_3_1, var_3_2)

	local var_3_3 = xyd.AssetLoader:get():loadSprite(var_0_3:photo(arg_3_0.stage))

	var_3_3:addTo(arg_3_0:nodeByName("bg"))
	var_3_3:setAnchorPoint(0, 0)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

return var_0_0
