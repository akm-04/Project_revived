local var_0_0 = class("HunqiCombConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.items = arg_1_2.items
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = #arg_4_0.items
	local var_4_1 = 30

	if var_4_0 > 5 then
		var_4_1 = 10
	elseif var_4_0 > 4 then
		var_4_1 = 20
	end

	arg_4_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_4_0:nodeByName("txt_sure"):setString(var_0_1:translation("SURE"))
	arg_4_0:nodeByName("txt_title"):setString(string.format(var_0_1:translation("HUNQI_TEXT_76"), var_4_0))

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.items) do
		local var_4_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/comb_confirm_item.csb")
		local var_4_3 = arg_4_0.selfPlayer:getHeroByID(iter_4_1.is_equip)
		local var_4_4 = var_4_2:getChildByName("node_item")
		local var_4_5 = var_4_2:getChildByName("avatar"):getContentSize().width

		xyd.setAvatarBorderNewUI(var_4_3, var_4_2:getChildByName("avatar"))
		var_4_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_4_4:setContentSize(xyd.HunqiDefualtSize, xyd.HunqiDefualtSize)

		local var_4_6 = {
			noBorder = true,
			levShowTop = true,
			container = var_4_4,
			item = iter_4_1
		}

		xyd.setHunqiBorder(var_4_6)
		var_4_2:setPosition((var_4_5 + var_4_1) * (iter_4_0 - 0.5 * var_4_0 - 0.5), 0)
		arg_4_0:nodeByName("pos_item"):addChild(var_4_2)
	end

	xyd.nodeEventSample(arg_4_0:nodeByName("btn_cancel"), nil, function()
		arg_4_0:close()
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_sure"), nil, function()
		arg_4_0.callback()
		arg_4_0:close()
	end)
end

return var_0_0
