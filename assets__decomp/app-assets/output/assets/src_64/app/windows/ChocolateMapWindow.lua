local var_0_0 = class("ChocolateMapWindow", import("app.windows.ActivityBaseMapWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc
local var_0_4 = {
	HARD = 3,
	STORY = 1,
	ITEM = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2 or {})
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initMapData()
	arg_2_0:createMap()
	arg_2_0:addAssetWindow(560, 674)
	arg_2_0:bonusSetup(xyd.mid.CHOCOLATE_STAR_AWARD)
	arg_2_0:updateItemBag()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)

	if arg_3_0.mapInfo.base_info.first_enter == 1 then
		arg_3_0:firstEnterAction()
		arg_3_0.chocolate:firstEnterMap(function()
			arg_3_0.mapInfo.base_info.first_enter = 0
		end)
	end
end

function var_0_0.baseDefine(arg_5_0)
	arg_5_0.linePath = "windows/chocolate/map/line.png"
	arg_5_0.rewardEffect = "skeletons/ui_effect/campaign_map/reward_hint"
	arg_5_0.bonusNumPath = "windows/chocolate/map/"
	arg_5_0.guideWndPath = "windows/chocolate/map/guide_wnd.csb"
	arg_5_0.npcClipPath = "windows/chocolate/map/npc_clip.png"
	arg_5_0.campUnlockTip = "skeletons/ui_effect/chocolate_map/campaign_tip"
	arg_5_0.hardPointChangeEffect = "skeletons/ui_effect/chocolate_map/camp_unlock"
	arg_5_0.activityID = 1177
	arg_5_0.bagItems = {}
	arg_5_0.bagItems[1] = var_0_3.activityChocolateItem
	arg_5_0.bagItems[2] = var_0_3.activityChocolateCampaignSweepItem
	arg_5_0.bagItems[3] = var_0_3.activityChocolateFruitItem
	arg_5_0.bagItems[4] = var_0_3.activityChocolateSlotMachineItemCoin
	arg_5_0.bagItems[5] = var_0_3.activityChocolatePoolResetItem
	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_5_0.backpack = arg_5_0.selfPlayer:getBackpack()
	arg_5_0.chocolate = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_5_0.mapInfo = arg_5_0.chocolate.mapInfo
	arg_5_0.activityItemInfo = arg_5_0.mapInfo.act_item_change_ and arg_5_0.mapInfo.act_item_change_[tostring(arg_5_0.activityID)]
	arg_5_0.stars = arg_5_0.mapInfo.base_info.total_star
	arg_5_0.starAward = arg_5_0.mapInfo.base_info.star_award
	arg_5_0.campaignTable = xyd.tables.chocolateCampaignTable
	arg_5_0.bonusTable = xyd.tables.chocolateStarBonusTable
	arg_5_0.onBattleEnd = not arg_5_0.chocolate.mapNeedReload
	arg_5_0.chocolate.mapNeedReload = true
	arg_5_0.battleResult = arg_5_0.chocolate.battleResult
end

function var_0_0.initMapData(arg_6_0)
	arg_6_0.mapDetail = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.mapInfo.campaign_list) do
		arg_6_0.mapDetail[tonumber(iter_6_0)] = clone(iter_6_1)
	end

	arg_6_0:nodeByName("bonus"):getChildByName("txt"):enableOutline(cc.c4b(66, 48, 55, 255), 2)
	arg_6_0:nodeByName("bonus_title_txt"):setString(var_0_2:translation("ACTIVITY_CHOCOLATE_MAP_TIP1"))
	arg_6_0:nodeByName("title_txt"):setString(var_0_2:translation("ACTIVITY_CHOCOLATE_MAP_TIP2"))
	arg_6_0:nodeByName("bag_title"):setString(var_0_2:translation("ACTIVITY_CHOCOLATE_MAP_TIP3"))
	arg_6_0:nodeByName("btn_tips"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("pic_tip", {
				path = "windows/chocolate/rule/img6.png"
			})
		end
	end)
end

function var_0_0.createCheckPoint(arg_8_0, arg_8_1)
	local var_8_0
	local var_8_1 = arg_8_0.campaignTable:itemCampaignId(arg_8_1)
	local var_8_2

	if arg_8_0.mapDetail[var_8_1] and next(arg_8_0.mapDetail[var_8_1]) then
		var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/map/item_point.csb")

		local var_8_3 = arg_8_0.mapDetail[var_8_1]
		local var_8_4 = var_8_0:getChildByName("bg")

		var_8_4:getChildByName("icon"):setVisible(var_8_3.count == 0)
		var_8_4:getChildByName("star1"):setVisible(var_8_3.star == 1)
		var_8_4:getChildByName("star2"):setVisible(var_8_3.star == 2)
		var_8_4:getChildByName("star3"):setVisible(var_8_3.star == 3)

		var_8_2 = var_8_1
	else
		var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/map/story_point.csb")

		local var_8_5 = arg_8_0.campaignTable:avatar(arg_8_1)
		local var_8_6 = xyd.SpriteLoader.new(var_8_5, nil, nil, xyd.DefaultImageType.CAMPAIGN_CARD)

		var_8_6:addTo(var_8_0:getChildByName("bg"):getChildByName("avatar_pos"))
		var_8_6:setAnchorPoint(0.5, 0)
		var_8_6:pos(0, 8)

		local var_8_7 = arg_8_0.campaignTable:nextCampaignId(arg_8_1)
		local var_8_8 = true

		for iter_8_0 = 1, #var_8_7 do
			if arg_8_0.mapDetail[iter_8_0] and next(arg_8_0.mapDetail[iter_8_0]) then
				var_8_8 = false

				break
			end
		end

		if var_8_8 then
			var_8_0:getChildByName("arrow"):setVisible(true)
			arg_8_0:downArrowAction(var_8_0:getChildByName("arrow"))
		else
			var_8_0:getChildByName("arrow"):setVisible(true)
		end

		var_8_2 = arg_8_1
	end

	var_8_0:getChildByName("bg"):setTouchEnabled(true)
	var_8_0:getChildByName("bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "ended" then
			arg_8_0:openMapDetailWindow(var_8_2)
		end

		return true
	end)
	var_8_0:setName("point" .. var_8_2)

	return var_8_0
end

function var_0_0.createHardPoint(arg_10_0, arg_10_1)
	local var_10_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/map/hard_point.csb")
	local var_10_1 = arg_10_0.campaignTable:avatar(arg_10_1)
	local var_10_2 = xyd.SpriteLoader.new(var_10_1, nil, nil, xyd.DefaultImageType.CAMPAIGN_CARD)

	var_10_2:addTo(var_10_0:getChildByName("bg"):getChildByName("avatar_pos"))
	var_10_2:setAnchorPoint(0.5, 0)
	var_10_2:pos(-1, 7)

	local var_10_3 = arg_10_0.mapDetail[arg_10_1]

	xyd.nodeEventSample(var_10_0:getChildByName("bg"), {
		scale = 1
	}, function()
		if var_10_3.is_open == 1 then
			arg_10_0:openMapDetailWindow(arg_10_1)
		else
			arg_10_0.chocolate:unlockCampaign(arg_10_1, function(arg_12_0)
				arg_10_0.mapDetail[arg_10_1].is_open = 1

				arg_10_0:hardPointChange(arg_10_1)
			end)
		end
	end)

	local var_10_4 = var_10_0:getChildByName("bg"):getChildByName("unlock")

	var_10_4:setVisible(var_10_3.is_open == 1)
	var_10_4:getChildByName("star1"):setVisible(var_10_3.star == 1)
	var_10_4:getChildByName("star2"):setVisible(var_10_3.star == 2)
	var_10_4:getChildByName("star3"):setVisible(var_10_3.star == 3)

	local var_10_5 = var_10_0:getChildByName("bg"):getChildByName("locked")

	var_10_5:setVisible(var_10_3.is_open == 0)
	var_10_5:getChildByName("clip"):setTouchSwallowEnabled(false)
	xyd.nodeEventSample(var_10_5:getChildByName("clip"), {
		scale = 1
	}, function()
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("CHOCOLATE_CAMPAIGN_TIP3")
		})
	end)

	local var_10_6 = arg_10_0.campaignTable:inCampItem(arg_10_1)
	local var_10_7 = arg_10_0.campaignTable:inCampNum(arg_10_1)
	local var_10_8 = var_10_7 >= 0 and tostring(var_10_6) or "-" .. tostring(var_10_6)
	local var_10_9 = arg_10_0.activityItemInfo and arg_10_0.activityItemInfo[var_10_8] or 0

	if math.abs(var_10_9) >= math.abs(var_10_7) and var_10_3.is_open == 0 then
		arg_10_0:onHardPointCanUnlock(var_10_0)
	else
		var_10_5:getChildByName("desc"):setString(var_0_2:translation("CHOCOLATE_CAMPAIGN_TIP1"))
		var_10_5:getChildByName("bar"):setPercent(var_10_9 / var_10_7 * 100)
		var_10_5:getChildByName("bar_num"):setString(math.abs(var_10_9) .. "/" .. math.abs(var_10_7))
		var_10_5:getChildByName("bar_num"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	var_10_0:setName("point" .. arg_10_1)

	return var_10_0
end

function var_0_0.onHardPointCanUnlock(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_1:getChildByName("bg"):getChildByName("locked")

	var_14_0:getChildByName("desc"):setString(var_0_2:translation("CHOCOLATE_CAMPAIGN_TIP2"))
	var_14_0:getChildByName("bar"):setVisible(false)
	var_14_0:getChildByName("bar_bg"):setVisible(false)
	var_14_0:getChildByName("bar_num"):setVisible(false)
	var_14_0:getChildByName("clip"):setTouchSwallowEnabled(false)
	var_14_0:getChildByName("clip"):setTouchEnabled(false)

	if arg_14_1:getChildByName("bg"):getChildByName("effect1") then
		return
	end

	local var_14_1 = xyd.createEffect(arg_14_0.campUnlockTip)

	var_14_1:addTo(arg_14_1:getChildByName("bg"))
	var_14_1:pos(arg_14_1:getChildByName("bg"):getWidth() / 2, arg_14_1:getChildByName("bg"):getHeight() / 2)
	var_14_1:play(nil, true)
	var_14_1:setName("effect1")
end

function var_0_0.updateHardPoint(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_0:nodeByName("map"):getChildByName("point" .. arg_15_1)
	local var_15_1 = var_15_0:getChildByName("bg"):getChildByName("locked")
	local var_15_2 = arg_15_0.campaignTable:inCampNum(arg_15_1)

	if math.abs(arg_15_2) >= math.abs(var_15_2) then
		arg_15_0:onHardPointCanUnlock(var_15_0)
	else
		var_15_1:getChildByName("bar"):setPercent(arg_15_2 / var_15_2 * 100)
		var_15_1:getChildByName("bar_num"):setString(math.abs(arg_15_2) .. "/" .. math.abs(var_15_2))
	end
end

function var_0_0.openMapDetailWindow(arg_16_0, arg_16_1)
	if not arg_16_0.mapDetail[arg_16_1] or not next(arg_16_0.mapDetail[arg_16_1]) then
		return
	end

	local var_16_0 = {
		star = arg_16_0.mapDetail[arg_16_1].star,
		campaignID = arg_16_1,
		callback = function()
			arg_16_0:updateItemBag()
		end,
		tipMessage = arg_16_0:getSkinAddTxt()
	}

	if not arg_16_0.selfPlayer:getBackpack() then
		arg_16_0.selfPlayer:loadBackpack(function(arg_18_0)
			if arg_18_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("chocolate_map_detail", var_16_0)
			end
		end)
	else
		xyd.WindowManager.get():openWindow("chocolate_map_detail", var_16_0)
	end
end

function var_0_0.getSkinAddTxt(arg_19_0)
	local var_19_0 = var_0_3:getValue("activity_chocolate_campaign_skin")
	local var_19_1 = var_0_3:getValue("activity_chocolate_campaign_skin_add")
	local var_19_2 = 0

	for iter_19_0 = 1, #var_19_0 do
		if arg_19_0.selfPlayer:hasSkin(var_19_0[iter_19_0]) then
			var_19_2 = var_19_2 + 1
		end
	end

	if var_19_2 == 0 then
		return
	end

	return string.format(var_0_2:translation("ACTIVITY_MAP_SWEEP_ADD_TXT"), var_19_2, var_19_2 * var_19_1 * 100)
end

function var_0_0.onFightResult(arg_20_0)
	xyd.WindowManager.get():closeWindow("chocolate_map_detail")
	arg_20_0.super.onFightResult(arg_20_0)
end

function var_0_0.didClose(arg_21_0, arg_21_1)
	arg_21_0.super.didClose(arg_21_1)
	arg_21_0:refreshModelData()

	local var_21_0 = xyd.WindowManager.get():getWindow("chocolate_award_pools")

	if var_21_0 then
		var_21_0:updateItemNum()
	end
end

function var_0_0.refreshModelData(arg_22_0)
	arg_22_0.mapInfo.campaign_list = {}

	for iter_22_0, iter_22_1 in pairs(arg_22_0.mapDetail) do
		arg_22_0.mapInfo.campaign_list[tostring(iter_22_0)] = clone(iter_22_1)
	end

	arg_22_0.mapInfo.base_info.total_star = arg_22_0.stars
	arg_22_0.mapInfo.base_info.star_award = arg_22_0.starAward
end

return var_0_0
