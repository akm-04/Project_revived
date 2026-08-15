local var_0_0 = class("MyHouseCheckWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.dormHouse

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didClose(arg_3_0, arg_3_1)
	var_0_0.super:didClose(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text1"):setString(var_0_1:translation("DORM_HOUSE_CHECK_TEXT1"))
	arg_4_0:nodeByName("text2"):setString(var_0_1:translation("DORM_HOUSE_CHECK_TEXT2"))
	arg_4_0:nodeByName("text3"):setString(var_0_1:translation("DORM_HOUSE_CHECK_TEXT3"))
	arg_4_0:nodeByName("text1"):enableOutline(cc.c4b(116, 71, 28, 255), 2)
	arg_4_0:nodeByName("text2"):enableOutline(cc.c4b(116, 71, 28, 255), 2)
	arg_4_0:nodeByName("text3"):enableOutline(cc.c4b(116, 71, 28, 255), 2)

	local var_4_0 = {}

	for iter_4_0 = 1, 3 do
		var_4_0[iter_4_0] = {}

		for iter_4_1 = 1, 3 do
			var_4_0[iter_4_0][iter_4_1] = {}
		end
	end

	local var_4_1 = var_0_3:getIds()

	for iter_4_2, iter_4_3 in pairs(var_4_1) do
		if var_0_3:maintype(iter_4_3) ~= 1 then
			table.insert(var_4_0[var_0_3:maintype(iter_4_3) - 1][var_0_3:type(iter_4_3)], var_0_3:name(iter_4_3))
		end
	end

	for iter_4_4 = 1, 3 do
		for iter_4_5 = 1, 3 do
			for iter_4_6, iter_4_7 in pairs(var_4_0[iter_4_4][iter_4_5]) do
				arg_4_0:nodeByName("text" .. iter_4_4 .. "-" .. iter_4_5 .. "-" .. iter_4_6):setString(var_4_0[iter_4_4][iter_4_5][iter_4_6])
			end
		end
	end
end

return var_0_0
