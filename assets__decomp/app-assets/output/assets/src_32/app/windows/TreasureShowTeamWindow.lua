local var_0_0 = class("TreasureShowTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.treasureLocation
local var_0_3 = xyd.tables.treasureType
local var_0_4 = 8
local var_0_5 = 45
local var_0_6 = xyd.tables.misc
local var_0_7 = cc.c4b(255, 120, 0, 255)
local var_0_8 = 80

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.locationId = arg_1_2.locationId
	arg_1_0.itemData = arg_1_0.treasureModel.teams[arg_1_0.locationId]
	arg_1_0.heros = arg_1_0.itemData.partners or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = 0
	local var_3_1 = string.format(var_0_1:translation("TREASURE_HERO_WORKING"), #arg_3_0.heros)

	arg_3_0:nodeByName("txt_desc"):setString(var_3_1)
	arg_3_0:nodeByName("txt_title"):setString(var_0_1:translation("TREASURE_STATE"))
	arg_3_0:nodeByName("txt_reward"):setString(var_0_1:translation("REWARD") .. var_0_1:translation("COLON"))
	arg_3_0:nodeByName("txt_ex_reward"):setString(var_0_1:translation("EX_REWARD"))

	if arg_3_0.treasureModel.teams[arg_3_0.locationId].with_external_award == 1 then
		local var_3_2 = xyd.setItemWithTextNode(-1, arg_3_0.itemData.externa_crystal_award, var_0_7, var_0_5)

		var_3_2:setAnchorPoint(cc.p(0, 0.5))
		arg_3_0:nodeByName("node_ex_reward"):addChild(var_3_2)
	else
		var_3_0 = var_0_5

		arg_3_0:nodeByName("ex_reward_container"):setVisible(false)
	end

	local var_3_3 = 1

	for iter_3_0, iter_3_1 in pairs(arg_3_0.heros) do
		if iter_3_0 <= var_0_4 then
			-- block empty
		else
			var_3_3 = iter_3_0 <= var_0_4 * 2 and 2 or 3
		end
	end

	local var_3_4 = arg_3_0:nodeByName("hero_list_1"):getHeight()
	local var_3_5

	if var_3_3 == 1 then
		var_3_5 = var_3_4 * 2 + var_3_0

		arg_3_0:nodeByName("hero_list_2"):setVisible(false)
		arg_3_0:nodeByName("hero_list_3"):setVisible(false)
	elseif var_3_3 == 2 then
		var_3_5 = var_3_4 + var_3_0

		arg_3_0:nodeByName("hero_list_3"):setVisible(false)
	else
		var_3_5 = var_3_0
	end

	arg_3_0:nodeByName("bg"):height(arg_3_0:nodeByName("bg"):getHeight() - var_3_5)
	arg_3_0:nodeByName("background"):setPositionY(arg_3_0:nodeByName("background"):getPositionY() - var_3_5 / 2)
	arg_3_0:nodeByName("close"):setPositionY(arg_3_0:nodeByName("close"):getPositionY() - var_3_5 / 2)

	if var_3_0 > 0 then
		arg_3_0:nodeByName("hero_list_1"):setPositionY(arg_3_0:nodeByName("hero_list_1"):getPositionY() + var_3_0)
		arg_3_0:nodeByName("hero_list_2"):setPositionY(arg_3_0:nodeByName("hero_list_2"):getPositionY() + var_3_0)
		arg_3_0:nodeByName("hero_list_3"):setPositionY(arg_3_0:nodeByName("hero_list_3"):getPositionY() + var_3_0)
	end

	arg_3_0:initNormalReward()
	arg_3_0:initHeros()
end

function var_0_0.initHeros(arg_4_0)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.heros) do
		local var_4_0 = math.ceil(iter_4_0 / var_0_4)
		local var_4_1 = arg_4_0.selfPlayer:getHeroByID(iter_4_1)
		local var_4_2 = display.newNode()
		local var_4_3 = arg_4_0:nodeByName("hero_list_" .. var_4_0):getHeight()

		var_4_2:setContentSize(var_0_8, var_0_8)
		var_4_2:setAnchorPoint(cc.p(0, 0))
		var_4_2:setPosition(0, 0)
		xyd.setAvatarBorderWithLevelAndHp(var_4_1, var_4_2)
		arg_4_0:nodeByName("hero_list_" .. var_4_0):addChild(var_4_2)

		local var_4_4 = iter_4_0 % var_0_4

		var_4_2:setPosition((var_4_4 - 1) % var_0_4 * (var_0_8 + 10), (var_4_3 - var_0_8) / 2)
	end
end

function var_0_0.initNormalReward(arg_5_0)
	local var_5_0 = #arg_5_0.heros
	local var_5_1 = var_0_6.treasureColorParam * arg_5_0.itemData.total_color + var_0_6.treasureStarParam * arg_5_0.itemData.total_star + var_0_6.treasureLevelParam * arg_5_0.itemData.total_lev

	arg_5_0:nodeByName("node_reward"):removeAllChildren()

	local var_5_2 = xyd.tables.vip:tresureReward(arg_5_0.selfPlayer.vip)
	local var_5_3 = math.floor(var_5_2 * (var_0_6.treasureGoldParam1 + var_0_6.treasureGoldParam2 * var_5_0 + var_5_1))
	local var_5_4 = arg_5_0.itemData.treasure_type
	local var_5_5 = xyd.getTreasureItem(var_0_3:productType(var_5_4), var_5_3)

	if arg_5_0.activities:isOpenDoubleTreasureAward() then
		var_5_5.item_num = var_5_5.item_num * 2
	end

	if var_5_0 == 0 then
		var_5_5.item_num = 0
	end

	local var_5_6 = arg_5_0.treasureModel.teams[arg_5_0.locationId].externa_crystal_award
	local var_5_7 = xyd.setItemWithTextNode(var_5_5.item_id, var_5_5.item_num, var_0_7, var_0_5)

	var_5_7:setAnchorPoint(cc.p(0, 0.5))
	arg_5_0:nodeByName("node_reward"):addChild(var_5_7)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
