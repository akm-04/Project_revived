local var_0_0 = class("ChampionsLeagueShopWindow", import("app.windows.ShopWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = "skeletons/ui_effect/effect_shop_refresh/effect_shop_refresh1"
local var_0_3 = "skeletons/ui_effect/effect_shop_refresh/effect_shop_refresh2"
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = import("app.model.Hero")
local var_0_6 = xyd.tables.model
local var_0_7 = xyd.tables.translation
local var_0_8 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	xyd.AssetLoader.get():loadSprite("team_dungeon_coin.png")
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("type_list_bg"):setVisible(false)
	arg_2_0:nodeByName("type_scroll"):setVisible(false)
	arg_2_0:nodeByName("frame"):setPositionX(arg_2_0:nodeByName("frame"):getPositionX() + 50)
	arg_2_0:nodeByName("list"):setPositionX(arg_2_0:nodeByName("list"):getPositionX() + 50)
end

function var_0_0.updateAssetsContainer(arg_3_0)
	if not arg_3_0.assetContainer then
		local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_widgets/eco_display_sidebar.csb")

		arg_3_0:addChild(var_3_0)
		var_3_0:setPosition(cc.p(440, 674))
		var_3_0:setName("asset_container")
		arg_3_0:parseChildren_(var_3_0)
		var_3_0:setVisible(false)

		for iter_3_0 = 2, 4 do
			arg_3_0:nodeByName("eco_" .. iter_3_0):setVisible(false)
		end

		arg_3_0.assetContainer = var_3_0
	end

	local var_3_1 = var_0_8:getValue("cross_arena_magic_cube_new")

	if var_3_1 then
		local var_3_2 = "windows/champions_league/icon_cube.png"
		local var_3_3 = xyd.AssetLoader.get():loadSprite(var_3_2)

		arg_3_0:nodeByName("pos_icon_1"):removeAllChildren()
		var_3_3:addTo(arg_3_0:nodeByName("pos_icon_1"))
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.CHAMPIONS_ECONOMY_AFTER, function(arg_4_0)
			local var_4_0 = arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_3_1)

			arg_3_0:nodeByName("txt_eco_val_1"):setString(xyd.num2ThousandsStr(var_4_0))

			local var_4_1 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_4_2 = cc.Spawn:create(var_4_1)

			arg_3_0:nodeByName("txt_eco_val_1"):runAction(var_4_2)
		end)

		local var_3_4 = arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_3_1)

		arg_3_0:nodeByName("txt_eco_val_1"):setString(xyd.num2ThousandsStr(var_3_4))
	end

	arg_3_0:updateAssetsShowState()
end

function var_0_0.getOpenList(arg_5_0)
	return {
		35
	}
end

function var_0_0.didOpen(arg_6_0)
	var_0_0.super.didOpen(arg_6_0)
	arg_6_0:nodeByName("refresh_button"):setVisible(false)
	arg_6_0:nodeByName("img_currency"):setVisible(false)
	arg_6_0:nodeByName("cost_txt"):setVisible(false)
	xyd.setPositionBy(arg_6_0.timeLabel, cc.p(-50, 0))
end

function var_0_0.loadOpenList(arg_7_0)
	arg_7_0.openList = {
		35
	}
end

function var_0_0.updateView_(arg_8_0, arg_8_1)
	var_0_0.super.updateView_(arg_8_0, arg_8_1)

	local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_8_0.timeLabel:setString(var_0_7:translation("CROSS_ARENA_SHOP_DESC"))
	arg_8_0:nodeByName("refresh_button"):setVisible(false)
end

return var_0_0
