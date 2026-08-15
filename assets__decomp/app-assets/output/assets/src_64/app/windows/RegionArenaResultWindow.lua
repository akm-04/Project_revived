local var_0_0 = class("RegionArenaResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.star = arg_1_2.star
	arg_1_0.oldStar = arg_1_2.oldStar
	arg_1_0.battleResult = arg_1_2.battleResult
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(arg_3_0.star)

	if var_3_0 == xyd.tables.regionArenaLevel.level[#xyd.tables.regionArenaLevel.level] then
		arg_3_0:nodeByName("king_level"):setString(var_0_1:translation("REGION_ARENA_RULE6"))
	else
		arg_3_0:nodeByName("king_level"):setString("Lv." .. var_3_0)
	end

	arg_3_0:nodeByName("king_level"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName("king_level_name"):setString(xyd.tables.regionArenaLevel:getName(var_3_0))

	if arg_3_0.star - arg_3_0.oldStar >= 2 then
		arg_3_0:nodeByName("continue_wins_desc"):setVisible(true)
	else
		arg_3_0:nodeByName("continue_wins_desc"):setVisible(false)
	end

	arg_3_0:nodeByName("continue_wins_desc"):setString(var_0_1:translation("REGION_ARENA_TIP49"))
	arg_3_0:nodeByName("continue_wins_desc"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:layoutLevelFrame(var_3_0)

	if arg_3_0.battleResult == 1 then
		local var_3_1 = "skeletons/ui_effect/common_effect_spin3/common_effect_spin3"
		local var_3_2 = var_3_1 .. ".json"
		local var_3_3 = var_3_1 .. ".atlas"
		local var_3_4 = var_0_2.new(var_3_2, var_3_3, 1)

		var_3_4:addTo(arg_3_0:nodeByName("background"))
		var_3_4:setPosition(arg_3_0:nodeByName("effect_pos"):getPosition())
		var_3_4:play(nil, true)
		var_3_4:setLocalZOrder(-1)

		local var_3_5 = "skeletons/ui_effect/common_effect_win/common_effect_win"
		local var_3_6 = var_3_5 .. ".json"
		local var_3_7 = var_3_5 .. ".atlas"
		local var_3_8 = var_0_2.new(var_3_6, var_3_7, 1)

		var_3_8:addTo(arg_3_0:nodeByName("background"))
		var_3_8:setPosition(arg_3_0:nodeByName("effect_pos"):getPosition())
		var_3_8:play(nil, false)
	else
		local var_3_9 = "skeletons/ui_effect/common_effect_defeat_spin/common_effect_defeat_spin"
		local var_3_10 = var_3_9 .. ".json"
		local var_3_11 = var_3_9 .. ".atlas"
		local var_3_12 = var_0_2.new(var_3_10, var_3_11, 1)

		var_3_12:addTo(arg_3_0:nodeByName("background"))
		var_3_12:setPosition(arg_3_0:nodeByName("effect_pos"):getPosition())
		var_3_12:play(nil, true)
		var_3_12:setLocalZOrder(-1)

		local var_3_13 = "skeletons/ui_effect/common_effect_defeat/common_effect_defeat"
		local var_3_14 = var_3_13 .. ".json"
		local var_3_15 = var_3_13 .. ".atlas"
		local var_3_16 = var_0_2.new(var_3_14, var_3_15, 1)

		var_3_16:addTo(arg_3_0:nodeByName("background"))
		var_3_16:setPosition(arg_3_0:nodeByName("effect_pos"):getPosition())
		var_3_16:play(nil, false)
	end
end

function var_0_0.layoutLevelFrame(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:nodeByName("background")
	local var_4_1 = var_4_0:getChildByName("icon_container")

	arg_4_0:setCutLevelIcon(arg_4_1, var_4_1)

	local var_4_2 = xyd.tables.regionArenaLevel:getLevelStarType()
	local var_4_3 = arg_4_0.regionArena:getStar() - xyd.tables.regionArenaLevel:getStar(arg_4_1 - 1)

	for iter_4_0, iter_4_1 in pairs(var_4_2) do
		if xyd.tables.regionArenaLevel:getlevelStar(arg_4_1) == iter_4_1 then
			var_4_0:getChildByName("lev_index" .. iter_4_1):setVisible(true)

			local var_4_4 = var_4_0:getChildByName("lev_index" .. iter_4_1)

			for iter_4_2 = 1, iter_4_1 do
				if iter_4_2 <= var_4_3 then
					var_4_4:getChildByName("stone_" .. iter_4_2):setVisible(true)
				else
					var_4_4:getChildByName("stone_" .. iter_4_2):setVisible(false)
				end
			end
		else
			var_4_0:getChildByName("lev_index" .. iter_4_1):setVisible(false)
		end
	end
end

function var_0_0.setCutLevelIcon(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/main_wnd/level_icon/" .. arg_5_1 .. ".png")
	local var_5_1 = xyd.AssetLoader:get():loadSprite("windows/across_arena/across_arena/main_wnd/level_frame/mask.png")

	var_5_0:setAnchorPoint(cc.p(0, 0))
	var_5_1:setAnchorPoint(cc.p(0, 0))

	local var_5_2 = var_5_0:getWidth()

	var_5_1:setScale(var_5_2 / var_5_1:getWidth())
	var_5_1:setPosition(0, 0)

	local var_5_3 = cc.ClippingNode:create()

	var_5_3:setStencil(var_5_1)
	var_5_3:setInverted(true)
	var_5_3:setAlphaThreshold(0)
	var_5_3:addChild(var_5_0)
	var_5_3:addTo(arg_5_2)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
