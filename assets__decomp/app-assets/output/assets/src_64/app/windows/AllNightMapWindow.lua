local var_0_0 = class("AllNightMapWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = 1007
local var_0_4 = 2007
local var_0_5 = var_0_2:getValue("activity_polar_night_campaign_unlock")[1]
local var_0_6 = var_0_2:getValue("activity_polar_night_boss_unlock")[1]
local var_0_7 = 1
local var_0_8 = {
	Blue = 2,
	Red = 1
}
local var_0_9 = {
	STORY = 1,
	HARD = 2
}
local var_0_10 = {
	normal = var_0_1:translation("ACTIVITY_POLAR_NIGHT_2"),
	hard = var_0_1:translation("ACTIVITY_POLAR_NIGHT_4"),
	bonus = var_0_1:translation("FOURTH_ANNI_MAP_BONUS"),
	pointClose = var_0_1:translation("FOURTH_ANNI_MAP_POINT_CLOSE"),
	routeClose = var_0_1:translation("FOURTH_ANNI_MAP_ROUTE_CLOSE"),
	canAward = var_0_1:translation("FOURTH_ANNI_MAP_CAN_AWARD"),
	nowProcess = var_0_1:translation("FOURTH_ANNI_MAP_NOW_PROCESS"),
	notAward = var_0_1:translation("FOURTH_ANNI_MAP_NOT_AWARD"),
	awardFalse = var_0_1:translation("FOURTH_ANNI_MAP_AWARD_FALSE"),
	hasWin = var_0_1:translation("FOURTH_ANNI_MAP_ALREADY_PASS"),
	notStory = var_0_1:translation("FOURTH_ANNI_MAP_NOT_STORY"),
	hasEnd = var_0_1:translation("SAKURA_CLOSED")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2 or {})

	arg_1_0.mapMode = arg_1_2.mapMode or 1

	arg_1_0:baseDefine()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:initMapFuncOpen()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)

	if arg_3_0.baseInfo.first_enter == 1 then
		arg_3_0.allNight:firstEnterMap(function()
			arg_3_0.baseInfo.first_enter = 0
		end)
	end
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	var_0_0.super.didClose(arg_5_0, arg_5_1)

	arg_5_0.allNight.onBattleEnd = false
end

function var_0_0.baseDefine(arg_6_0)
	arg_6_0.lineRed = "windows/activities/1199/map/line_red.png"
	arg_6_0.lineBlue = "windows/activities/1199/map/line_grey.png"
	arg_6_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_6_0.backpack = arg_6_0.selfPlayer:getBackpack()
	arg_6_0.skinsIds = xyd.tables.misc:getValue("activity_polar_night_campaign_skin")
	arg_6_0.allNight = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)
	arg_6_0.campaignTable = xyd.tables.allNightCampaign
	arg_6_0.mapStarBonusTable = xyd.tables.allNightCampaignStarBonus
	arg_6_0.pointX = {}
	arg_6_0.pointY = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.campaignTable:ids()) do
		table.insert(arg_6_0.pointX, iter_6_1, arg_6_0.campaignTable:posX(iter_6_1))
		table.insert(arg_6_0.pointY, iter_6_1, arg_6_0.campaignTable:posY(iter_6_1))
	end

	arg_6_0.onBattleEnd = arg_6_0.allNight.onBattleEnd
	arg_6_0.baseInfo = arg_6_0.allNight.mapInfo.base_info
	arg_6_0.awardsInfo = arg_6_0.baseInfo.star_award
	arg_6_0.mapCampaign = arg_6_0.allNight.mapInfo.campaign_list
	arg_6_0.nowPoint = arg_6_0.campaignTable:ids()[1]
	arg_6_0.startPonit = arg_6_0.campaignTable:startPoints()
end

function var_0_0.initMapFuncOpen(arg_7_0)
	if arg_7_0.onBattleEnd then
		if arg_7_0.allNight.batlleBeginStar and arg_7_0.allNight.batlleBeginId and arg_7_0.allNight.batlleBeginStar == 0 and arg_7_0.mapCampaign[tostring(arg_7_0.allNight.batlleBeginId)].star ~= 0 and arg_7_0.allNight.batlleBeginId == var_0_5 then
			local var_7_0 = {}

			var_7_0.funcID = 93

			if xyd.WindowManager.get():isWindowOpen("levelup") then
				xyd.WindowManager.get():getWindow("levelup"):addFuncID(var_7_0)
			else
				xyd.WindowManager.get():openWindow("function_show", var_7_0)
			end
		end

		if arg_7_0.allNight.batlleBeginStar and arg_7_0.allNight.batlleBeginId and arg_7_0.allNight.batlleBeginStar == 0 and arg_7_0.mapCampaign[tostring(arg_7_0.allNight.batlleBeginId)].star ~= 0 and arg_7_0.allNight.batlleBeginId == var_0_6 then
			local var_7_1 = {}

			var_7_1.funcID = 94

			if xyd.WindowManager.get():isWindowOpen("levelup") then
				xyd.WindowManager.get():getWindow("levelup"):addFuncID(var_7_1)
			else
				xyd.WindowManager.get():openWindow("function_show", var_7_1)
			end
		end
	end
end

function var_0_0.layout(arg_8_0)
	arg_8_0:nodeByName("background"):setTouchSwallowEnabled(true)

	local var_8_0 = xyd.tables.misc:getValue("activity_polar_night_campaign_rate_add") * 100

	arg_8_0:nodeByName("txt_tips"):setString(string.format(var_0_10.bonus, var_8_0))

	local var_8_1 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfPlayer.heros_) do
		local var_8_2 = iter_8_1:getSkinDatas()

		for iter_8_2, iter_8_3 in ipairs(var_8_2) do
			for iter_8_4, iter_8_5 in ipairs(arg_8_0.skinsIds) do
				if iter_8_3.skinItem == iter_8_5 and iter_8_3.isHave then
					table.insert(var_8_1, iter_8_5)
				end
			end
		end
	end

	for iter_8_6, iter_8_7 in ipairs(arg_8_0.skinsIds) do
		if arg_8_0.backpack:getItemNumByID(iter_8_7) > 0 then
			table.insert(var_8_1, iter_8_7)
		end
	end

	for iter_8_8, iter_8_9 in ipairs(arg_8_0.skinsIds) do
		local var_8_3 = display.newNode()

		var_8_3:setContentSize(70, 70)
		var_8_3:setAnchorPoint(cc.p(0, 0))
		xyd.setItemAndAddTips(var_8_3, iter_8_9)
		var_8_3:addTo(arg_8_0:nodeByName("list_item"))
		var_8_3:setPosition(cc.p(120 * (iter_8_8 - 1), 5))

		local var_8_4 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/map/bg_get.png")

		var_8_4:setAnchorPoint(cc.p(0, 0))
		var_8_4:addTo(arg_8_0:nodeByName("list_item"))
		var_8_4:setPosition(cc.p(120 * (iter_8_8 - 1), 5))

		for iter_8_10, iter_8_11 in ipairs(var_8_1) do
			if iter_8_11 == iter_8_9 then
				var_8_4:setVisible(false)
			end
		end
	end

	if arg_8_0.onBattleEnd then
		local var_8_5 = arg_8_0.allNight.battleEndId

		arg_8_0:storyEvent(var_8_5, function(arg_9_0)
			return
		end)
	end

	arg_8_0:updateBonus()
	arg_8_0:initModeBtn()
	arg_8_0:createMap()
end

function var_0_0.createMap(arg_10_0)
	arg_10_0:nodeByName("map"):removeAllChildren()

	arg_10_0.mapResource = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/map/map_detail.csb")

	arg_10_0.mapResource:addTo(arg_10_0:nodeByName("map"))

	arg_10_0.map = arg_10_0.mapResource:getChildByName("container")

	if arg_10_0.mapMode == 1 then
		arg_10_0:nodeByName("tips_reward"):setVisible(false)
		arg_10_0.mapResource:getChildByName("bg_top"):setVisible(true)
		arg_10_0.mapResource:getChildByName("bg_bottom"):setVisible(false)
	elseif arg_10_0.mapMode == 2 then
		arg_10_0:nodeByName("tips_reward"):setVisible(true)
		arg_10_0.mapResource:getChildByName("bg_top"):setVisible(false)
		arg_10_0.mapResource:getChildByName("bg_bottom"):setVisible(true)
	end

	arg_10_0.map:removeAllChildren()

	local var_10_0 = 1
	local var_10_1 = {}

	table.insert(var_10_1, arg_10_0.startPonit[arg_10_0.mapMode])

	while var_10_0 <= #var_10_1 do
		local var_10_2 = var_10_1[var_10_0]
		local var_10_3 = arg_10_0.campaignTable:lastCampaignId(var_10_2)
		local var_10_4 = arg_10_0.pointX[var_10_2]
		local var_10_5 = arg_10_0.pointY[var_10_2]
		local var_10_6 = arg_10_0.campaignTable:campaignType(var_10_2)

		if arg_10_0.onBattleEnd and arg_10_0.mapCampaign[tostring(var_10_2)].star == 0 then
			-- block empty
		else
			local var_10_7

			if var_10_6 == 2 then
				var_10_7 = arg_10_0:createHardPoint(var_10_2)
			else
				var_10_7 = arg_10_0:createNormalPoint(var_10_2)
			end

			var_10_7:addTo(arg_10_0.map)
			var_10_7:pos(var_10_4, var_10_5)

			if var_10_3 ~= 0 then
				arg_10_0:createRoad(var_10_3, var_10_2, false)
			end
		end

		local var_10_8 = arg_10_0.campaignTable:nextCampaignId(var_10_2)

		if var_10_8[1] ~= 0 and arg_10_0.mapCampaign[tostring(var_10_8[1])] and next(arg_10_0.mapCampaign[tostring(var_10_8[1])]) then
			table.insert(var_10_1, var_10_8[1])
		end

		var_10_0 = var_10_0 + 1
	end

	arg_10_0:onFightResult(var_10_1)
end

function var_0_0.onFightResult(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1[#arg_11_1]
	local var_11_1 = arg_11_0.campaignTable:lastCampaignId(var_11_0)
	local var_11_2 = arg_11_0.mapCampaign[tostring(var_11_0)].star
	local var_11_3 = arg_11_0.campaignTable:campaignType(var_11_0)

	if var_11_2 ~= 0 then
		return
	end

	local var_11_4
	local var_11_5

	if arg_11_0.onBattleEnd then
		if arg_11_0.allNight.batlleBeginStar and arg_11_0.allNight.batlleBeginId and arg_11_0.allNight.batlleBeginStar == 0 and arg_11_0.mapCampaign[tostring(arg_11_0.allNight.batlleBeginId)].star ~= arg_11_0.allNight.batlleBeginStar then
			var_11_5 = true
		else
			var_11_5 = false
		end
	else
		var_11_5 = false
	end

	if arg_11_0.map:getChildByName("point" .. var_11_0) then
		arg_11_0.map:getChildByName("point" .. var_11_0):setVisible(false)
	end

	local var_11_6

	if var_11_3 == 2 then
		var_11_6 = arg_11_0:createHardPoint(var_11_0)
	else
		var_11_6 = arg_11_0:createNormalPoint(var_11_0)
	end

	local var_11_7 = arg_11_0.pointX[var_11_0]
	local var_11_8 = arg_11_0.pointY[var_11_0]

	if var_11_5 then
		var_11_6:setVisible(false)
		var_11_6:getChildByName("container"):setScale(0)
		var_11_6:getChildByName("container"):setOpacity(0)
		var_11_6:getChildByName("container"):setRotation(0)
		var_11_6:getChildByName("container"):setTouchEnabled(false)
		var_11_6:addTo(arg_11_0.map)
		var_11_6:pos(var_11_7, var_11_8)

		if var_11_1 ~= 0 then
			arg_11_0:createRoad(var_11_1, var_11_0, var_11_5)
		end

		local var_11_9 = 0.03333333333333333

		var_11_6:getChildByName("container"):runAction(cc.Sequence:create({
			cc.DelayTime:create(var_0_7),
			cc.CallFunc:create(function()
				var_11_6:setVisible(true)
			end),
			cc.Spawn:create({
				cc.FadeIn:create(var_11_9 * 2),
				cc.Sequence:create({
					cc.ScaleTo:create(var_11_9, 0.21),
					cc.ScaleTo:create(var_11_9 * 3, 1.155),
					cc.DelayTime:create(var_11_9 * 3),
					cc.ScaleTo:create(var_11_9 * 2, 1),
					cc.RotateTo:create(var_11_9 * 2, -18),
					cc.RotateTo:create(var_11_9 * 3, 9),
					cc.RotateTo:create(var_11_9 * 3, 0),
					cc.RotateTo:create(var_11_9 * 2, -14),
					cc.RotateTo:create(var_11_9 * 5, 9),
					cc.RotateTo:create(var_11_9 * 3, 0)
				})
			}),
			cc.CallFunc:create(function()
				var_11_6:getChildByName("container"):setTouchEnabled(true)
			end)
		}))
	else
		var_11_6:addTo(arg_11_0.map)
		var_11_6:pos(var_11_7, var_11_8)

		if var_11_1 ~= 0 then
			arg_11_0:createRoad(var_11_1, var_11_0, var_11_5)
		end
	end
end

function var_0_0.storyEvent(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0.campaignTable:victoryStory(arg_14_1)

	if var_14_0 == 0 then
		return
	end

	xyd.WindowManager.get():openWindow("all_night_map_story", {
		dialogueID = var_14_0,
		callback = arg_14_2
	})
end

function var_0_0.createNormalPoint(arg_15_0, arg_15_1)
	local var_15_0

	if arg_15_0.mapCampaign[tostring(arg_15_1)] and next(arg_15_0.mapCampaign) then
		var_15_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/map/map_item.csb")

		local var_15_1 = arg_15_0.mapCampaign[tostring(arg_15_1)].star
		local var_15_2 = var_15_0:getChildByName("container")

		var_15_0:getChildByName("bg_clear"):setVisible(var_15_1 ~= 0)
		var_15_0:getChildByName("star1"):setVisible(false)
		var_15_0:getChildByName("star2"):setVisible(false)
		var_15_0:getChildByName("star3"):setVisible(false)
		var_15_0:setName("point" .. arg_15_1)
		var_15_2:getChildByName("start"):setVisible(false)

		local var_15_3 = arg_15_0.campaignTable:avatar(arg_15_1)
		local var_15_4 = xyd.SpriteLoader.new(var_15_3, nil, nil, xyd.DefaultImageType.CAMPAIGN_CARD)

		var_15_4:addTo(var_15_2)
		var_15_4:setPosition(var_15_2:getChildByName("start"):getPosition())

		local var_15_5

		var_15_2:getChildByName("bg_pos"):setVisible(false)

		local var_15_6 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/map/level_red.png")

		var_15_6:addTo(var_15_2, -1)
		var_15_6:setPosition(var_15_2:getChildByName("bg_pos"):getPosition())

		local var_15_7 = true
		local var_15_8 = display.newNode()

		var_15_8:setContentSize(cc.size(120, 150))
		var_15_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_15_8:addTo(var_15_2)
		var_15_8:setPosition(var_15_2:getChildByName("start"):getPosition())
		var_15_8:setTouchEnabled(true)
		var_15_8:setTouchSwallowEnabled(false)
		var_15_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
			if arg_16_0.name == "began" then
				return true
			elseif arg_16_0.name == "ended" then
				arg_15_0.allNight.onBattleEnd = false

				if not var_15_7 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_10.routeClose
					})

					return
				end

				local var_16_0 = arg_15_0.campaignTable:preWarStory(arg_15_1)

				xyd.WindowManager.get():openWindow("all_night_map_story", {
					dialogueID = var_16_0,
					callback = function()
						arg_15_0:openMapDetailWindow(arg_15_1)
					end
				})
			end
		end)

		local var_15_9 = true
		local var_15_10 = arg_15_0.campaignTable:nextCampaignId(arg_15_1)

		for iter_15_0, iter_15_1 in ipairs(var_15_10) do
			if arg_15_0.mapCampaign[tostring(iter_15_1)] and next(arg_15_0.mapCampaign[tostring(iter_15_1)]) then
				var_15_9 = false

				break
			end
		end

		if arg_15_1 == var_0_3 and arg_15_0.mapCampaign[tostring(var_0_3)].star ~= 0 then
			var_15_9 = false
		end

		if var_15_9 then
			local var_15_11 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/map/arrow.png")

			var_15_11:addTo(var_15_0)
			var_15_11:setName("arrow")
			var_15_11:setPosition(cc.p(0, 200))

			local var_15_12 = transition.sequence({
				cc.MoveBy:create(1, cc.p(0, -35)),
				cc.MoveBy:create(1, cc.p(0, 35))
			})
			local var_15_13 = cc.RepeatForever:create(var_15_12)

			var_15_11:runAction(var_15_13)
		end
	end

	return var_15_0
end

function var_0_0.createHardPoint(arg_18_0, arg_18_1)
	local var_18_0

	if arg_18_0.mapCampaign[tostring(arg_18_1)] and next(arg_18_0.mapCampaign) then
		var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/map/map_item.csb")

		local var_18_1 = arg_18_0.mapCampaign[tostring(arg_18_1)].star
		local var_18_2 = var_18_0:getChildByName("container")

		var_18_0:getChildByName("bg_clear"):setVisible(false)
		var_18_0:getChildByName("star1"):setVisible(var_18_1 == 1)
		var_18_0:getChildByName("star2"):setVisible(var_18_1 == 2)
		var_18_0:getChildByName("star3"):setVisible(var_18_1 == 3)
		var_18_0:setName("point" .. arg_18_1)
		var_18_2:getChildByName("bg_pos"):setVisible(true)
		var_18_2:getChildByName("start"):setVisible(false)

		local var_18_3 = arg_18_0.campaignTable:avatar(arg_18_1)
		local var_18_4 = xyd.SpriteLoader.new(var_18_3, nil, nil, xyd.DefaultImageType.CAMPAIGN_CARD)

		var_18_4:addTo(var_18_2)
		var_18_4:setPosition(var_18_2:getChildByName("start"):getPosition())

		local var_18_5 = display.newNode()

		var_18_5:setContentSize(cc.size(120, 150))
		var_18_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_18_5:addTo(var_18_2)
		var_18_5:setPosition(var_18_2:getChildByName("start"):getPosition())
		var_18_5:setTouchEnabled(true)
		var_18_5:setTouchSwallowEnabled(false)
		var_18_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
			if arg_19_0.name == "began" then
				return true
			elseif arg_19_0.name == "ended" then
				arg_18_0.allNight.onBattleEnd = false

				arg_18_0:openMapDetailWindow(arg_18_1)
			end
		end)
	end

	return var_18_0
end

function var_0_0.openMapDetailWindow(arg_20_0, arg_20_1)
	arg_20_0.allNight.mapMode = arg_20_0.mapMode

	local var_20_0 = {
		star = arg_20_0.mapCampaign[tostring(arg_20_1)].star,
		campaignID = arg_20_1
	}

	arg_20_0.allNight.batlleBeginId = arg_20_1
	arg_20_0.allNight.batlleBeginStar = arg_20_0.mapCampaign[tostring(arg_20_1)].star

	if not arg_20_0.selfPlayer:getBackpack() then
		arg_20_0.selfPlayer:loadBackpack(function(arg_21_0)
			if arg_21_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("all_night_map_detail", var_20_0)
			end
		end)
	else
		xyd.WindowManager.get():openWindow("all_night_map_detail", var_20_0)
	end
end

function var_0_0.createProgressBar(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0

	if arg_22_2 == var_0_8.Red then
		var_22_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_22_0.lineRed))
	elseif arg_22_2 == var_0_8.Blue then
		var_22_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_22_0.lineBlue))
	end

	var_22_0:setAnchorPoint(cc.p(0, 0.5))
	var_22_0:setMidpoint(cc.p(0, 0))
	var_22_0:setBarChangeRate(cc.p(1, 0))
	var_22_0:setType(display.PROGRESS_TIMER_BAR)

	var_22_0.maxPercentage = math.min(arg_22_1 / var_22_0:getContentSize().width)

	return var_22_0
end

function var_0_0.createRoad(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	local var_23_0 = arg_23_0.pointX[arg_23_1]
	local var_23_1 = arg_23_0.pointY[arg_23_1]
	local var_23_2 = arg_23_0.pointX[arg_23_2]
	local var_23_3 = arg_23_0.pointY[arg_23_2]
	local var_23_4 = math.sqrt(math.pow(var_23_0 - var_23_2, 2) + math.pow(var_23_1 - var_23_3, 2))
	local var_23_5

	if math.floor(arg_23_2 / 1000) == arg_23_0.mapMode then
		var_23_5 = var_0_8.Red
	else
		var_23_5 = var_0_8.Blue
	end

	local var_23_6 = arg_23_0:createProgressBar(var_23_4, var_23_5)

	var_23_6:addTo(arg_23_0.map, -1)
	var_23_6:pos(var_23_0, var_23_1)

	local var_23_7 = math.atan2(var_23_3 - var_23_1, var_23_2 - var_23_0) / math.pi * -180

	var_23_6:setRotation(var_23_7)

	if arg_23_3 then
		var_23_6:runAction(cc.ProgressTo:create(1, var_23_6.maxPercentage * 100))
	else
		var_23_6:setPercentage(var_23_6.maxPercentage * 100)
	end
end

function var_0_0.updateBonus(arg_24_0)
	arg_24_0:nodeByName("pos_award"):removeAllChildren()

	if arg_24_0.mapMode == 2 then
		arg_24_0:initHardStarAward():addTo(arg_24_0:nodeByName("pos_award"))
	end
end

function var_0_0.initHardStarAward(arg_25_0)
	local var_25_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/map/star_award.csb")
	local var_25_1 = var_25_0:getChildByName("container")
	local var_25_2 = arg_25_0.baseInfo.total_star
	local var_25_3 = arg_25_0.mapStarBonusTable:ids()
	local var_25_4 = arg_25_0.mapStarBonusTable:starNums(#var_25_3)
	local var_25_5 = math.min(var_25_2 / var_25_4 * 100, 100)

	var_25_1:getChildByName("bar"):setPercent(var_25_5)
	var_25_1:getChildByName("txt_star_num"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	var_25_1:getChildByName("txt_star_num"):setString("x " .. var_25_2)

	local var_25_6 = 0

	for iter_25_0, iter_25_1 in ipairs(var_25_3) do
		if var_25_2 >= arg_25_0.mapStarBonusTable:starNums(iter_25_1) then
			var_25_6 = iter_25_1
		end
	end

	local function var_25_7(arg_26_0, arg_26_1)
		local var_26_0 = arg_25_0.mapStarBonusTable:awardIDs(arg_26_1)
		local var_26_1 = arg_25_0.mapStarBonusTable:awardNums(arg_26_1)
		local var_26_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/map/gift_tips.csb")

		var_26_2:getChildByName("container"):setContentSize(200, 80 * #var_26_0 + 70)

		for iter_26_0, iter_26_1 in ipairs(var_26_0) do
			local var_26_3 = display.newNode()

			var_26_3:setContentSize(cc.size(70, 70))
			var_26_3:setAnchorPoint(cc.p(0, 0))
			xyd.setItemBorder(var_26_3, iter_26_1)
			var_26_3:addTo(var_26_2:getChildByName("container"))
			var_26_3:setPosition(cc.p(35, 80 * iter_26_0 - 45))

			local var_26_4 = {
				size = 24,
				color = cc.c3b(16, 196, 255)
			}
			local var_26_5 = xyd.AssetLoader.get():loadLabel(var_26_4)

			var_26_5:setMaxLineWidth(70)
			var_26_5:setLineHeight(49)
			var_26_5:setString("x" .. var_26_1[iter_26_0])
			var_26_5:addTo(var_26_2:getChildByName("container"))
			var_26_5:setPosition(cc.p(130, 80 * iter_26_0 - 20))
		end

		var_26_2:addTo(var_25_1)

		local var_26_6, var_26_7 = arg_26_0:getPosition()

		var_26_2:setPosition(cc.p(var_26_6 - 40, var_26_7 + 40))
		var_26_2:setVisible(false)
		var_26_2:setTouchSwallowEnabled(true)

		local var_26_8 = display.newNode()

		var_26_8:setContentSize(cc.size(70, 70))
		var_26_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_26_8:addTo(arg_26_0)
		var_26_8:setTouchEnabled(true)
		var_26_8:setTouchSwallowEnabled(false)
		var_26_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
			if arg_27_0.name == "began" then
				var_26_2:setVisible(true)

				return true
			elseif arg_27_0.name == "ended" then
				var_26_2:setVisible(false)
				var_26_2:setTouchSwallowEnabled(true)
			end
		end)
	end

	local var_25_8 = arg_25_0.awardsInfo
	local var_25_9 = 0

	for iter_25_2, iter_25_3 in ipairs(var_25_8) do
		if iter_25_3 == 0 then
			var_25_9 = iter_25_2

			break
		end
	end

	if var_25_9 ~= 0 and var_25_9 <= var_25_6 then
		var_25_1:getChildByName("txt_process"):setString(var_0_10.canAward)
	else
		var_25_1:getChildByName("txt_process"):setString(var_0_10.nowProcess)
	end

	for iter_25_4, iter_25_5 in ipairs(var_25_3) do
		if var_25_1:getChildByName("pos_" .. iter_25_5) then
			local var_25_10

			if var_25_8[iter_25_5] == 1 then
				var_25_10 = xyd.AssetLoader:get():loadSprite("windows/activities/1199/map/bag_open.png")
			else
				var_25_10 = xyd.AssetLoader:get():loadSprite("windows/activities/1199/map/bag_close.png")

				if var_25_6 < iter_25_5 then
					xyd.GrayNode(var_25_10)
				end
			end

			var_25_10:addTo(var_25_1:getChildByName("pos_" .. iter_25_5))
			var_25_10:setAnchorPoint(cc.p(0.5, 0.5))

			if iter_25_4 <= var_25_9 and var_25_9 <= var_25_6 and var_25_8[iter_25_5] ~= 1 then
				local var_25_11 = var_25_1:getChildByName("pos_" .. iter_25_5)

				var_25_11:setTouchEnabled(true)
				var_25_11:setTouchSwallowEnabled(false)
				var_25_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
					if arg_28_0.name == "began" then
						var_25_11:setScale(0.9)

						return true
					elseif arg_28_0.name == "ended" then
						var_25_11:setScale(1)

						local var_28_0 = {}

						var_28_0.mode = 1

						if var_25_9 == 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_10.notAward
							})

							return
						elseif var_25_9 > var_25_6 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_10.notAward
							})

							return
						else
							var_28_0.award_id = var_25_9
						end

						arg_25_0.allNight:getMapAward(var_28_0, function(arg_29_0, arg_29_1)
							if arg_29_0 == xyd.error.OK then
								arg_25_0.selfPlayer:handleRewards(arg_29_1.awards)

								arg_25_0.awardsInfo = arg_29_1.base_info.star_award

								arg_25_0:updateBonus()
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.ALL_NIGHT_ECONOMY_UPDATE
								})
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_10.awardFalse
								})

								return
							end
						end)
					end
				end)
			else
				var_25_7(var_25_1:getChildByName("pos_" .. iter_25_5), iter_25_5)
			end
		end

		if var_25_1:getChildByName("txt_process_" .. iter_25_5) then
			var_25_1:getChildByName("txt_process_" .. iter_25_5):setString(arg_25_0.mapStarBonusTable:starNums(iter_25_5))
			var_25_1:getChildByName("txt_process_" .. iter_25_5):enableOutline(cc.c4b(0, 0, 0, 255), 2)
		end
	end

	return var_25_0
end

function var_0_0.initModeBtn(arg_30_0)
	local var_30_0 = arg_30_0:nodeByName("btn_mode_top")
	local var_30_1 = arg_30_0:nodeByName("btn_mode_bottom")
	local var_30_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/map/icon_normal.png")
	local var_30_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/map/icon_challenge.png")

	var_30_0:getChildByName("node_mode_top"):removeAllChildren()
	var_30_1:getChildByName("node_mode_bottom"):removeAllChildren()

	if arg_30_0.mapMode == var_0_9.STORY then
		var_30_2:addTo(var_30_0:getChildByName("node_mode_top"))
		var_30_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_30_0:getChildByName("txt_mode_top"):setString(var_0_10.normal)
		var_30_3:addTo(var_30_1:getChildByName("node_mode_bottom"))
		var_30_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_30_1:getChildByName("txt_mode_bottom"):setString(var_0_10.hard)
	elseif arg_30_0.mapMode == var_0_9.HARD then
		var_30_3:addTo(var_30_0:getChildByName("node_mode_top"))
		var_30_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_30_0:getChildByName("txt_mode_top"):setString(var_0_10.hard)
		var_30_2:addTo(var_30_1:getChildByName("node_mode_bottom"))
		var_30_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_30_1:getChildByName("txt_mode_bottom"):setString(var_0_10.normal)
	end

	if not arg_30_0.mapCampaign[tostring(var_0_5)] or arg_30_0.mapCampaign[tostring(var_0_5)].star == 0 then
		var_30_1:setVisible(false)

		return
	end

	arg_30_0:initBtn()
end

function var_0_0.initBtn(arg_31_0)
	local var_31_0 = arg_31_0:nodeByName("btn_mode_top")
	local var_31_1 = arg_31_0:nodeByName("btn_mode_bottom")
	local var_31_2 = false

	var_31_1:setVisible(var_31_2)
	var_31_0:addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.ended or arg_32_1 == ccui.TouchEventType.canceled then
			var_31_2 = not var_31_2

			var_31_1:setVisible(var_31_2)
		end
	end)
	var_31_1:addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended or arg_33_1 == ccui.TouchEventType.canceled then
			if arg_31_0.mapMode == 1 then
				arg_31_0.mapMode = 2

				arg_31_0:initModeBtn()
				arg_31_0:updateBonus()

				arg_31_0.onBattleEnd = false

				arg_31_0:createMap()
				var_31_1:setVisible(false)
			elseif arg_31_0.mapMode == 2 then
				arg_31_0.mapMode = 1

				arg_31_0:initModeBtn()
				arg_31_0:updateBonus()

				arg_31_0.onBattleEnd = false

				arg_31_0:createMap()
				var_31_1:setVisible(false)
			end
		end
	end)
end

return var_0_0
