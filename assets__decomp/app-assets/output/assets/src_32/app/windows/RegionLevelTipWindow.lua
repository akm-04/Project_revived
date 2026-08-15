local var_0_0 = class("RegionLevelTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.kingLevel = arg_1_2.kingLevel
	arg_1_0.rankPercent = arg_1_2.rankPercent
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.kingLevel == xyd.tables.regionArenaLevel.level[#xyd.tables.regionArenaLevel.level] then
		arg_3_0.isMaxLevel = true
	else
		arg_3_0.isMaxLevel = false
	end

	local var_3_0 = xyd.tables.regionArenaLevel:getName(arg_3_0.kingLevel)

	arg_3_0:nodeByName("level_name"):setString(var_3_0)

	local var_3_1 = {
		size = 18,
		color = cc.c3b(255, 255, 255)
	}
	local var_3_2 = xyd.AssetLoader.get():loadLabel(var_3_1)

	var_3_2:addTo(arg_3_0:nodeByName("background"))
	var_3_2:setAnchorPoint(cc.p(0, 0))
	var_3_2:setPosition(arg_3_0:nodeByName("level_rank_pos"):getPosition())
	var_3_2:setString(var_0_1:translation("REGION_ARENA_TIP50"))

	local var_3_3 = {
		size = 20,
		color = cc.c3b(232, 237, 125)
	}
	local var_3_4 = xyd.AssetLoader.get():loadLabel(var_3_3)

	var_3_4:addTo(arg_3_0:nodeByName("background"))
	var_3_4:setAnchorPoint(cc.p(0, 0))

	local var_3_5, var_3_6 = arg_3_0:nodeByName("level_rank_pos"):getPosition()

	var_3_4:setPosition(var_3_5 + var_3_2:getContentSize().width, var_3_6)
	var_3_4:setString(arg_3_0.rankPercent .. "%")

	if not arg_3_0.isMaxLevel then
		local var_3_7 = xyd.tables.regionArenaLevel:getName(arg_3_0.kingLevel + 1)

		arg_3_0:nodeByName("next_level_txt"):setVisible(true)
		arg_3_0:nodeByName("next_level_name"):setVisible(true)
		arg_3_0:nodeByName("next_level_name"):setString(var_3_7)
		arg_3_0:nodeByName("bg"):height(193)
	else
		arg_3_0:nodeByName("next_level_txt"):setVisible(false)
		arg_3_0:nodeByName("next_level_name"):setVisible(false)
		arg_3_0:nodeByName("bg"):height(117)
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
end

return var_0_0
