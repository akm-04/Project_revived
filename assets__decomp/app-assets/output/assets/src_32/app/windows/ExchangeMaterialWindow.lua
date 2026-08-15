local var_0_0 = class("ExchangeMaterialWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.currencyChange = arg_1_2.currency_change
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, name, arg_2_1)

	arg_2_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title_text"):setString(var_0_2:translation("INSCRIPTION_NOTIFICATION"))

	local var_3_0 = #arg_3_0.currencyChange

	for iter_3_0 = 1, var_3_0 do
		local var_3_1 = arg_3_0.currencyChange[iter_3_0]
		local var_3_2 = arg_3_0.inscription:getMaterialIcon(var_3_1.currency)

		var_3_2:setScale(0.7)
		var_3_2:addTo(arg_3_0:nodeByName("pos" .. iter_3_0))
		arg_3_0:nodeByName("num_txt" .. iter_3_0):setString("x" .. var_3_1.change)

		if var_3_0 <= 2 then
			arg_3_0:nodeByName("pos" .. iter_3_0):setPositionY(90)
		end
	end

	arg_3_0:nodeByName("pos_line"):addChild(var_0_1.new({
		size = 500
	}))
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, name, arg_4_1)
	arg_4_0:addBlockLayer()
end

return var_0_0
