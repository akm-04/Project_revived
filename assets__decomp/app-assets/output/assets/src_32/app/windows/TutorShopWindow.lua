local var_0_0 = class("TutorShopWindow", import("app.windows.ShopWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = "skeletons/ui_effect/effect_shop_refresh/effect_shop_refresh1"
local var_0_3 = "skeletons/ui_effect/effect_shop_refresh/effect_shop_refresh2"
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = import("app.model.Hero")
local var_0_6 = xyd.tables.model
local var_0_7 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	xyd.AssetLoader.get():loadSprite("team_dungeon_coin.png")
	dump(arg_2_0.shopType_)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("type_list_bg"):setVisible(false)
	arg_2_0:nodeByName("type_scroll"):setVisible(false)
end

function var_0_0.getOpenList(arg_3_0)
	return {
		34
	}
end

function var_0_0.didOpen(arg_4_0)
	var_0_0.super.didOpen(arg_4_0)
	arg_4_0:nodeByName("refresh_button"):setVisible(false)
	arg_4_0:nodeByName("img_currency"):setVisible(false)
	arg_4_0:nodeByName("cost_txt"):setVisible(false)
	xyd.setPositionBy(arg_4_0.timeLabel, cc.p(-50, 0))
end

function var_0_0.loadOpenList(arg_5_0)
	dump("22222222222222222222222")

	arg_5_0.openList = {
		34
	}
end

function var_0_0.updateView_(arg_6_0, arg_6_1)
	var_0_0.super.updateView_(arg_6_0, arg_6_1)

	local var_6_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_6_0.timeLabel:setString(var_0_7:translation("TUTOR_INSTRUCTOR_TIP_TEXT"))
	arg_6_0:nodeByName("refresh_button"):setVisible(false)
end

return var_0_0
