local var_0_0 = class("SuperRichDescWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityRichMap
local var_0_3 = xyd.tables.misc.activityRichBoutiqueGain

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.info = arg_1_2.info
	arg_1_0.gridType = arg_1_2.grid_type
	arg_1_0.baseInfo = arg_1_0.superRich.baseInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.baseInfo.total_move + (arg_4_0.info.move or 0)

	arg_4_0:nodeByName("name_txt"):setString(var_0_2:name(arg_4_0.pos))
	arg_4_0:nodeByName("lev_txt"):setString(string.format("LV.%d", arg_4_0.info.lev or 0))
	arg_4_0:nodeByName("desc_txt"):setString(var_0_2:desc(arg_4_0.pos))
	arg_4_0:nodeByName("award_text2"):setString(var_0_1:translation("SUPER_RICH_DESC_TEXT2"))
	arg_4_0:nodeByName("award_text1"):setString(var_0_1:translation("SUPER_RICH_DESC_TEXT1"))

	if arg_4_0.gridType ~= 5 then
		local var_4_1 = var_0_3[arg_4_0.info.lev or 0] or 0

		arg_4_0:nodeByName("award_txt1"):setString(var_4_1)
		arg_4_0:nodeByName("award_txt2"):setString(var_4_1 * var_4_0)
	else
		local var_4_2 = (arg_4_0.info.lev or 0) * xyd.tables.misc.activityRichBankGain

		arg_4_0:nodeByName("award_txt1"):setString(var_4_2)
		arg_4_0:nodeByName("award_txt2"):setString(var_4_2 * var_4_0)

		local var_4_3 = xyd.AssetLoader.get():loadSprite("images/icon/eco/yuanbao.png")

		arg_4_0:nodeByName("jinbi"):setSpriteFrame(var_4_3:getSpriteFrame())
		arg_4_0:nodeByName("jinbi1"):setSpriteFrame(var_4_3:getSpriteFrame())
	end
end

return var_0_0
