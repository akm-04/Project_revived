local var_0_0 = class("MakeFurnitureSuccessWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.item = arg_1_2.itemID
	arg_1_0.num = arg_1_2.itemNum
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
end

function var_0_0.showTopEffect(arg_5_0)
	local var_5_0 = xyd.HeroAnimation.new(40001110, 40001110, xyd.tables.model:uiScale(40001110), {})

	var_5_0:attack(5)

	local var_5_1 = cc.p(arg_5_0:nodeByName("effect"):getPosition())

	var_5_0:align(display.CENTER, var_5_1.x, var_5_1.y):addTo(arg_5_0:nodeByName("effect"))
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = cc.Sequence:create({
		cc.DelayTime:create(2.5)
	})

	arg_6_0:showTopEffect()
	arg_6_0:nodeByName("effect"):runActionOnce(var_6_0, false, function()
		local var_7_0 = {
			table_id = arg_6_0.item,
			item_num = arg_6_0.num
		}
		local var_7_1 = {}

		table.insert(var_7_1, var_7_0)
		arg_6_0.selfPlayer:showRewards(var_7_1)
		xyd.WindowManager.get():closeWindow(arg_6_0)
	end)
end

return var_0_0
