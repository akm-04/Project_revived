local var_0_0 = class("GardenTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.landId = arg_1_2.land_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.garden:getLandInfo(arg_3_0.landId)

	arg_3_0:nodeByName("text1"):setString(var_0_1:translation("GARDEN_TIP_TEXT1"))
	arg_3_0:nodeByName("title_text"):setString(string.format(var_0_1:translation("GARDEN_TIP_TITLE_TEXT"), arg_3_0.landId))

	local var_3_1 = arg_3_0.garden:getFlowerInfos(var_3_0.seed_id, var_3_0)
	local var_3_2 = {
		1,
		2,
		3,
		4,
		5,
		6
	}
	local var_3_3 = var_3_1.txts

	for iter_3_0, iter_3_1 in pairs(var_3_2) do
		arg_3_0:nodeByName("text" .. iter_3_1):setString(var_0_1:translation("GARDEN_TIP_TEXT" .. iter_3_1))
		arg_3_0:nodeByName("desc_txt" .. iter_3_1):setString(var_3_3[iter_3_1])
	end

	arg_3_0:nodeByName("state_text"):setString(var_3_1.state_text)
	xyd.setSpriteBorder(arg_3_0:nodeByName("icon_container"), var_3_1.iconPath, 5)
end

return var_0_0
