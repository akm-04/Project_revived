local var_0_0 = class("RagnarokMapWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = 1006
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
	arg_1_0:baseDefine()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)

	if arg_3_0.baseInfo.first_enter == 1 then
		arg_3_0.ragnarok:firstEnterMap(function()
			arg_3_0.baseInfo.first_enter = 0
		end)
	end
end

function var_0_0.didClose(arg_5_0, arg_5_1)
	var_0_0.super.didClose(arg_5_0, arg_5_1)

	arg_5_0.ragnarok.onBattleEnd = false
end

function var_0_0.baseDefine(arg_6_0)
	arg_6_0.lineRed = "windows/activities/1203/map/line_red.png"
	arg_6_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_6_0.backpack = arg_6_0.selfPlayer:getBackpack()
	arg_6_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_6_0.campaignTable = xyd.tables.ragnarokMapCampaignTable
	arg_6_0.pointX = {}
	arg_6_0.pointY = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.campaignTable:ids()) do
		table.insert(arg_6_0.pointX, iter_6_1, arg_6_0.campaignTable:posX(iter_6_1))
		table.insert(arg_6_0.pointY, iter_6_1, arg_6_0.campaignTable:posY(iter_6_1))
	end

	arg_6_0.onBattleEnd = arg_6_0.ragnarok.onBattleEnd
	arg_6_0.baseInfo = arg_6_0.ragnarok.mapInfo.base_info
	arg_6_0.mapCampaign = arg_6_0.ragnarok.mapInfo.campaign_list
	arg_6_0.nowPoint = arg_6_0.campaignTable:ids()[1]
	arg_6_0.startPonit = arg_6_0.campaignTable:startPoints()
end

function var_0_0.layout(arg_7_0)
	arg_7_0:nodeByName("background"):setTouchSwallowEnabled(true)

	if arg_7_0.onBattleEnd then
		local var_7_0 = arg_7_0.ragnarok.battleEndId

		arg_7_0:storyEvent(var_7_0, function(arg_8_0)
			return
		end)
	end

	arg_7_0:createMap()
end

function var_0_0.createMap(arg_9_0)
	arg_9_0:nodeByName("map"):removeAllChildren()

	arg_9_0.mapResource = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/map/map_detail.csb")

	arg_9_0.mapResource:addTo(arg_9_0:nodeByName("map"))

	arg_9_0.map = arg_9_0.mapResource:getChildByName("container")

	arg_9_0.map:removeAllChildren()

	local var_9_0 = 1
	local var_9_1 = {}

	table.insert(var_9_1, arg_9_0.startPonit[1])

	while var_9_0 <= #var_9_1 do
		local var_9_2 = var_9_1[var_9_0]
		local var_9_3 = arg_9_0.campaignTable:lastCampaignId(var_9_2)
		local var_9_4 = arg_9_0.pointX[var_9_2]
		local var_9_5 = arg_9_0.pointY[var_9_2]
		local var_9_6 = arg_9_0.campaignTable:campaignType(var_9_2)

		if arg_9_0.onBattleEnd and arg_9_0.mapCampaign[tostring(var_9_2)].star == 0 then
			-- block empty
		else
			local var_9_7

			if var_9_6 == 2 then
				var_9_7 = arg_9_0:createHardPoint(var_9_2)
			else
				var_9_7 = arg_9_0:createNormalPoint(var_9_2)
			end

			var_9_7:addTo(arg_9_0.map)
			var_9_7:pos(var_9_4, var_9_5)

			if var_9_3 ~= 0 then
				arg_9_0:createRoad(var_9_3, var_9_2, false)
			end
		end

		local var_9_8 = arg_9_0.campaignTable:nextCampaignId(var_9_2)

		if var_9_8[1] ~= 0 and arg_9_0.mapCampaign[tostring(var_9_8[1])] and next(arg_9_0.mapCampaign[tostring(var_9_8[1])]) then
			table.insert(var_9_1, var_9_8[1])
		end

		var_9_0 = var_9_0 + 1
	end

	arg_9_0:onFightResult(var_9_1)
end

function var_0_0.onFightResult(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1[#arg_10_1]
	local var_10_1 = arg_10_0.campaignTable:lastCampaignId(var_10_0)
	local var_10_2 = arg_10_0.mapCampaign[tostring(var_10_0)].star
	local var_10_3 = arg_10_0.campaignTable:campaignType(var_10_0)

	if var_10_2 ~= 0 then
		return
	end

	local var_10_4
	local var_10_5

	if arg_10_0.onBattleEnd then
		if arg_10_0.ragnarok.batlleBeginStar and arg_10_0.ragnarok.batlleBeginId and arg_10_0.ragnarok.batlleBeginStar == 0 and arg_10_0.mapCampaign[tostring(arg_10_0.ragnarok.batlleBeginId)].star ~= arg_10_0.ragnarok.batlleBeginStar then
			var_10_5 = true
		else
			var_10_5 = false
		end
	else
		var_10_5 = false
	end

	if arg_10_0.map:getChildByName("point" .. var_10_0) then
		arg_10_0.map:getChildByName("point" .. var_10_0):setVisible(false)
	end

	local var_10_6

	if var_10_3 == 2 then
		var_10_6 = arg_10_0:createHardPoint(var_10_0)
	else
		var_10_6 = arg_10_0:createNormalPoint(var_10_0)
	end

	local var_10_7 = arg_10_0.pointX[var_10_0]
	local var_10_8 = arg_10_0.pointY[var_10_0]

	if var_10_5 then
		var_10_6:setVisible(false)
		var_10_6:getChildByName("container"):setScale(0)
		var_10_6:getChildByName("container"):setOpacity(0)
		var_10_6:getChildByName("container"):setRotation(0)
		var_10_6:getChildByName("container"):setTouchEnabled(false)
		var_10_6:addTo(arg_10_0.map)
		var_10_6:pos(var_10_7, var_10_8)

		if var_10_1 ~= 0 then
			arg_10_0:createRoad(var_10_1, var_10_0, var_10_5)
		end

		local var_10_9 = 0.03333333333333333

		var_10_6:getChildByName("container"):runAction(cc.Sequence:create({
			cc.DelayTime:create(var_0_7),
			cc.CallFunc:create(function()
				var_10_6:setVisible(true)
			end),
			cc.Spawn:create({
				cc.FadeIn:create(var_10_9 * 2),
				cc.Sequence:create({
					cc.ScaleTo:create(var_10_9, 0.21),
					cc.ScaleTo:create(var_10_9 * 3, 1.155),
					cc.DelayTime:create(var_10_9 * 3),
					cc.ScaleTo:create(var_10_9 * 2, 1),
					cc.RotateTo:create(var_10_9 * 2, -18),
					cc.RotateTo:create(var_10_9 * 3, 9),
					cc.RotateTo:create(var_10_9 * 3, 0),
					cc.RotateTo:create(var_10_9 * 2, -14),
					cc.RotateTo:create(var_10_9 * 5, 9),
					cc.RotateTo:create(var_10_9 * 3, 0)
				})
			}),
			cc.CallFunc:create(function()
				var_10_6:getChildByName("container"):setTouchEnabled(true)
			end)
		}))
	else
		var_10_6:addTo(arg_10_0.map)
		var_10_6:pos(var_10_7, var_10_8)

		if var_10_1 ~= 0 then
			arg_10_0:createRoad(var_10_1, var_10_0, var_10_5)
		end
	end
end

function var_0_0.storyEvent(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0.campaignTable:victoryStory(arg_13_1)

	if var_13_0 == 0 then
		return
	end

	xyd.WindowManager.get():openWindow("activity_ragnarok_map_story", {
		dialogueID = var_13_0,
		callback = arg_13_2
	})
end

function var_0_0.createNormalPoint(arg_14_0, arg_14_1)
	local var_14_0

	if arg_14_0.mapCampaign[tostring(arg_14_1)] and next(arg_14_0.mapCampaign) then
		var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/map/map_item.csb")

		local var_14_1 = arg_14_0.mapCampaign[tostring(arg_14_1)].star
		local var_14_2 = var_14_0:getChildByName("container")

		var_14_0:getChildByName("bg_clear"):setVisible(var_14_1 ~= 0)
		var_14_0:getChildByName("star1"):setVisible(false)
		var_14_0:getChildByName("star2"):setVisible(false)
		var_14_0:getChildByName("star3"):setVisible(false)
		var_14_0:setName("point" .. arg_14_1)
		var_14_2:getChildByName("start"):setVisible(false)

		local var_14_3 = arg_14_0.campaignTable:avatar(arg_14_1)
		local var_14_4 = xyd.SpriteLoader.new(var_14_3, nil, nil, xyd.DefaultImageType.CAMPAIGN_CARD)

		var_14_4:addTo(var_14_2)
		var_14_4:setPosition(var_14_2:getChildByName("start"):getPosition())

		local var_14_5

		var_14_2:getChildByName("bg_pos"):setVisible(false)

		local var_14_6 = xyd.AssetLoader.get():loadSprite("windows/activities/1203/map/level_red.png")

		var_14_6:addTo(var_14_2, -1)
		var_14_6:setPosition(var_14_2:getChildByName("bg_pos"):getPosition())

		local var_14_7 = true
		local var_14_8 = display.newNode()

		var_14_8:setContentSize(cc.size(120, 150))
		var_14_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_14_8:addTo(var_14_2)
		var_14_8:setPosition(var_14_2:getChildByName("start"):getPosition())
		var_14_8:setTouchEnabled(true)
		var_14_8:setTouchSwallowEnabled(false)
		var_14_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				return true
			elseif arg_15_0.name == "ended" then
				arg_14_0.ragnarok.onBattleEnd = false

				if not var_14_7 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_10.routeClose
					})

					return
				end

				local var_15_0 = arg_14_0.campaignTable:preWarStory(arg_14_1)

				xyd.WindowManager.get():openWindow("activity_ragnarok_map_story", {
					dialogueID = var_15_0,
					callback = function()
						arg_14_0:openMapDetailWindow(arg_14_1)
					end
				})
			end
		end)

		local var_14_9 = true
		local var_14_10 = arg_14_0.campaignTable:nextCampaignId(arg_14_1)

		for iter_14_0, iter_14_1 in ipairs(var_14_10) do
			if arg_14_0.mapCampaign[tostring(iter_14_1)] and next(arg_14_0.mapCampaign[tostring(iter_14_1)]) then
				var_14_9 = false

				break
			end
		end

		if arg_14_1 == var_0_3 and arg_14_0.mapCampaign[tostring(var_0_3)].star ~= 0 then
			var_14_9 = false
		end

		if var_14_9 then
			local var_14_11 = xyd.AssetLoader.get():loadSprite("windows/activities/1203/map/arrow.png")

			var_14_11:addTo(var_14_0)
			var_14_11:setName("arrow")
			var_14_11:setPosition(cc.p(0, 200))

			local var_14_12 = transition.sequence({
				cc.MoveBy:create(1, cc.p(0, -35)),
				cc.MoveBy:create(1, cc.p(0, 35))
			})
			local var_14_13 = cc.RepeatForever:create(var_14_12)

			var_14_11:runAction(var_14_13)
		end
	end

	return var_14_0
end

function var_0_0.openMapDetailWindow(arg_17_0, arg_17_1)
	local var_17_0 = {
		star = arg_17_0.mapCampaign[tostring(arg_17_1)].star,
		campaignID = arg_17_1
	}

	arg_17_0.ragnarok.batlleBeginId = arg_17_1
	arg_17_0.ragnarok.batlleBeginStar = arg_17_0.mapCampaign[tostring(arg_17_1)].star

	if not arg_17_0.selfPlayer:getBackpack() then
		arg_17_0.selfPlayer:loadBackpack(function(arg_18_0)
			if arg_18_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activity_ragnarok_map_detail", var_17_0)
			end
		end)
	else
		xyd.WindowManager.get():openWindow("activity_ragnarok_map_detail", var_17_0)
	end
end

function var_0_0.createProgressBar(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0

	if arg_19_2 == var_0_8.Red then
		var_19_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_19_0.lineRed))
	elseif arg_19_2 == var_0_8.Blue then
		var_19_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_19_0.lineBlue))
	end

	var_19_0:setAnchorPoint(cc.p(0, 0.5))
	var_19_0:setMidpoint(cc.p(0, 0))
	var_19_0:setBarChangeRate(cc.p(1, 0))
	var_19_0:setType(display.PROGRESS_TIMER_BAR)

	var_19_0.maxPercentage = math.min(arg_19_1 / var_19_0:getContentSize().width)

	return var_19_0
end

function var_0_0.createRoad(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = arg_20_0.pointX[arg_20_1]
	local var_20_1 = arg_20_0.pointY[arg_20_1]
	local var_20_2 = arg_20_0.pointX[arg_20_2]
	local var_20_3 = arg_20_0.pointY[arg_20_2]
	local var_20_4 = math.sqrt(math.pow(var_20_0 - var_20_2, 2) + math.pow(var_20_1 - var_20_3, 2))
	local var_20_5 = var_0_8.Red
	local var_20_6 = arg_20_0:createProgressBar(var_20_4, var_20_5)

	var_20_6:addTo(arg_20_0.map, -1)
	var_20_6:pos(var_20_0, var_20_1)

	local var_20_7 = math.atan2(var_20_3 - var_20_1, var_20_2 - var_20_0) / math.pi * -180

	var_20_6:setRotation(var_20_7)

	if arg_20_3 then
		var_20_6:runAction(cc.ProgressTo:create(1, var_20_6.maxPercentage * 100))
	else
		var_20_6:setPercentage(var_20_6.maxPercentage * 100)
	end
end

function var_0_0.initBtn(arg_21_0)
	return
end

return var_0_0
