local var_0_0 = class("FourthAnniversaryMap", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = {
	Blue = 1,
	Pink = 0,
	Yellow = 2,
	Grey = 3
}
local var_0_4 = {
	120,
	356,
	560,
	798,
	958,
	1160,
	1453,
	1673,
	1928,
	2125,
	2380,
	327,
	552,
	804,
	1138,
	1390,
	1638,
	1827,
	1967,
	2173,
	2425,
	120,
	356,
	560,
	798,
	958,
	1160,
	1453,
	1673,
	1928,
	2125,
	2380,
	327,
	552,
	804,
	1138,
	1390,
	1638,
	1827,
	1967,
	2173,
	2425
}
local var_0_5 = {
	320,
	430,
	520,
	440,
	302,
	368,
	295,
	497,
	464,
	362,
	417,
	185,
	252,
	130,
	175,
	109,
	173,
	284,
	120,
	189,
	185,
	320,
	430,
	520,
	440,
	302,
	368,
	295,
	497,
	464,
	362,
	417,
	185,
	252,
	130,
	175,
	109,
	173,
	284,
	120,
	189,
	185
}
local var_0_6 = {
	normal = var_0_1:translation("MAP_WINDOW_TYPE_1"),
	hard = var_0_1:translation("MAP_WINDOW_TYPE_2"),
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

	arg_1_0.baseInfo = arg_1_2.base_info
	arg_1_0.awardsInfo = arg_1_2.awards_info
	arg_1_0.storyType = arg_1_2.base_info.story_type
	arg_1_0.mapNormalDetail = arg_1_2.campaigns[1]
	arg_1_0.mapHardDetail = arg_1_2.campaigns[2]

	arg_1_0:baseDefine()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.didClose(arg_3_0, arg_3_1)
	var_0_0.super.didClose(arg_3_0, arg_3_1)

	arg_3_0.fourthAnniversary.onBattleEnd = false
	arg_3_0.fourthAnniversary.mapState = arg_3_0.mapState
	arg_3_0.fourthAnniversary.mapMode = arg_3_0.mapMode
end

function var_0_0.initMapData(arg_4_0)
	return
end

function var_0_0.baseDefine(arg_5_0)
	arg_5_0.lineBlue = "windows/anniversary4th/story_map/map/line_blue.png"
	arg_5_0.lineYellow = "windows/anniversary4th/story_map/map/line_yellow.png"
	arg_5_0.lineGrey = "windows/anniversary4th/story_map/map/line_grey1.png"
	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_5_0.backpack = arg_5_0.selfPlayer:getBackpack()
	arg_5_0.skinsIds = xyd.tables.misc:getValue("activity_anni4_campaign_skin")
	arg_5_0.fourthAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)
	arg_5_0.campaignTable = xyd.tables.activityAnni4thCampaignTable
	arg_5_0.mapProcessTable = xyd.tables.activityAnni4thCampaignProcessTable
	arg_5_0.mapHardStarTable = xyd.tables.activityAnni4thCampaignStarsTable
	arg_5_0.pointX = {}
	arg_5_0.pointY = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.campaignTable:ids()) do
		table.insert(arg_5_0.pointX, iter_5_1, var_0_4[iter_5_0])
		table.insert(arg_5_0.pointY, iter_5_1, var_0_5[iter_5_0])
	end

	arg_5_0.onBattleEnd = arg_5_0.fourthAnniversary.onBattleEnd

	local var_5_0 = arg_5_0.campaignTable:ids()

	arg_5_0.nowPoint = var_5_0[1]

	for iter_5_2, iter_5_3 in ipairs(var_5_0) do
		local var_5_1 = arg_5_0.mapNormalDetail[tostring(iter_5_3)]

		if var_5_1 and var_5_1 % 10 ~= 0 then
			arg_5_0.nowPoint = iter_5_3
		end
	end

	arg_5_0.normalStartPonit = arg_5_0.campaignTable:startPoints()[1]
	arg_5_0.hardStartPonit = arg_5_0.campaignTable:startPoints()[2]
	arg_5_0.endPoints = arg_5_0.campaignTable:endPoints()
	arg_5_0.mapState = arg_5_0.fourthAnniversary.mapState or 0
	arg_5_0.mapMode = arg_5_0.fourthAnniversary.mapMode or 1
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("background"):setTouchSwallowEnabled(true)

	local var_6_0 = xyd.tables.misc:getValue("activity_anni4_campaign_skin_add") * 100

	arg_6_0:nodeByName("txt_tips"):setString(string.format(var_0_6.bonus, var_6_0))

	local var_6_1 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfPlayer.heros_) do
		local var_6_2 = iter_6_1:getSkinDatas()

		for iter_6_2, iter_6_3 in ipairs(var_6_2) do
			for iter_6_4, iter_6_5 in ipairs(arg_6_0.skinsIds) do
				if iter_6_3.skinItem == iter_6_5 and iter_6_3.isHave then
					table.insert(var_6_1, iter_6_5)
				end
			end
		end
	end

	arg_6_0:nodeByName("red_p"):setVisible(false)
	arg_6_0:nodeByName("red_p2"):setVisible(false)

	if arg_6_0.mapNormalDetail[tostring(arg_6_0.endPoints[1])] ~= 0 or arg_6_0.mapNormalDetail[tostring(arg_6_0.endPoints[2])] ~= 0 then
		local var_6_3 = arg_6_0.campaignTable:ids()
		local var_6_4 = 0

		for iter_6_6, iter_6_7 in ipairs(var_6_3) do
			local var_6_5 = tostring(iter_6_7)

			if arg_6_0.mapHardDetail[var_6_5] then
				var_6_4 = var_6_4 + arg_6_0.mapHardDetail[var_6_5]
			end
		end

		if var_6_4 == 0 then
			arg_6_0:nodeByName("red_p"):setVisible(true)
			arg_6_0:nodeByName("red_p2"):setVisible(true)
		end
	end

	for iter_6_8, iter_6_9 in ipairs(arg_6_0.skinsIds) do
		local var_6_6 = display.newNode()

		var_6_6:setContentSize(70, 70)
		var_6_6:setAnchorPoint(cc.p(0, 0))
		xyd.setItemAndAddTips(var_6_6, iter_6_9)
		var_6_6:addTo(arg_6_0:nodeByName("list_item"))
		var_6_6:setPosition(cc.p(120 * (iter_6_8 - 1), 5))

		local var_6_7 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/story_map/map/bg_get.png")

		var_6_7:setAnchorPoint(cc.p(0, 0))
		var_6_7:addTo(arg_6_0:nodeByName("list_item"))
		var_6_7:setPosition(cc.p(120 * (iter_6_8 - 1), 5))

		for iter_6_10, iter_6_11 in ipairs(var_6_1) do
			if iter_6_11 == iter_6_9 then
				var_6_7:setVisible(false)
			end
		end
	end

	arg_6_0:updateBonus()
	arg_6_0:initModeBtn()
	arg_6_0:createMap()
	arg_6_0:initBtn()
end

function var_0_0.initRount(arg_7_0)
	local var_7_0 = {}
	local var_7_1 = arg_7_0.campaignTable:ids()

	if arg_7_0.mapMode == 1 then
		for iter_7_0, iter_7_1 in ipairs(var_7_1) do
			if iter_7_0 == 1 then
				table.insert(var_7_0, arg_7_0.normalStartPonit)
			else
				local var_7_2 = tostring(iter_7_1)

				if arg_7_0.mapNormalDetail[var_7_2] and arg_7_0.mapNormalDetail[var_7_2] ~= 0 then
					table.insert(var_7_0, iter_7_1)
				end
			end
		end
	elseif arg_7_0.mapMode == 2 then
		for iter_7_2, iter_7_3 in ipairs(var_7_1) do
			local var_7_3 = tostring(iter_7_3)

			if arg_7_0.mapNormalDetail[var_7_3] and arg_7_0.mapNormalDetail[var_7_3] ~= 0 then
				local var_7_4 = arg_7_0.campaignTable:linkCampaign(iter_7_3)

				for iter_7_4 = 1, #var_7_4 do
					table.insert(var_7_0, var_7_4[iter_7_4])
				end
			end
		end
	end

	return var_7_0
end

function var_0_0.createMap(arg_8_0)
	arg_8_0:nodeByName("map"):removeAllChildren()

	arg_8_0.mapResource = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map/map_detail.csb")

	arg_8_0.mapResource:addTo(arg_8_0:nodeByName("map"))

	arg_8_0.map = arg_8_0.mapResource:getChildByName("container")

	if arg_8_0.mapState == 0 then
		arg_8_0.mapResource:setPosition(cc.p(0, 0))
	elseif arg_8_0.mapState == 1 then
		arg_8_0.mapResource:setPosition(cc.p(-1280, 0))
	end

	if arg_8_0.mapMode == 1 then
		arg_8_0.mapResource:getChildByName("bg_top"):setVisible(true)
		arg_8_0.mapResource:getChildByName("bg_bottom"):setVisible(false)
	elseif arg_8_0.mapMode == 2 then
		arg_8_0.mapResource:getChildByName("bg_top"):setVisible(false)
		arg_8_0.mapResource:getChildByName("bg_bottom"):setVisible(true)
	end

	arg_8_0.map:removeAllChildren()

	local var_8_0 = arg_8_0:initRount()
	local var_8_1 = 1

	while var_8_1 <= #var_8_0 do
		local var_8_2 = tonumber(var_8_0[var_8_1])
		local var_8_3 = arg_8_0.campaignTable:lastCampaign(var_8_2)
		local var_8_4 = arg_8_0.pointX[var_8_2]
		local var_8_5 = arg_8_0.pointY[var_8_2]
		local var_8_6
		local var_8_7 = arg_8_0:createPoint(var_8_2)

		var_8_7:addTo(arg_8_0.map)
		var_8_7:pos(var_8_4, var_8_5)

		if var_8_3 ~= 0 then
			arg_8_0:createRoad(var_8_3, var_8_2, false)
		end

		local var_8_8 = arg_8_0.campaignTable:nextCampaign(var_8_2)

		for iter_8_0 = 1, #var_8_8 do
			if var_8_8[iter_8_0] == 0 or arg_8_0.onBattleEnd then
				break
			end

			if arg_8_0.mapMode == 1 and arg_8_0.storyType ~= 0 and arg_8_0.mapNormalDetail[tostring(var_8_0[var_8_1])] ~= 0 and arg_8_0.mapNormalDetail[tostring(var_8_8[iter_8_0])] then
				table.insert(var_8_0, var_8_8[iter_8_0])
			end
		end

		var_8_1 = var_8_1 + 1
	end

	local var_8_9 = arg_8_0.mapNormalDetail[tostring(arg_8_0.normalStartPonit)]

	if arg_8_0.onBattleEnd or var_8_9 % 10 ~= 0 and arg_8_0.storyType == 0 then
		if arg_8_0.mapMode == 2 then
			return
		end

		if arg_8_0.nowPoint == arg_8_0.normalStartPonit and arg_8_0.storyType ~= 0 then
			return
		end

		arg_8_0:storyEvent(function(arg_9_0)
			if arg_9_0 then
				arg_8_0.storyType = arg_9_0
			end

			if arg_8_0.map:getChildByName("point" .. arg_8_0.normalStartPonit):getChildByName("arrow") then
				arg_8_0.map:getChildByName("point" .. arg_8_0.normalStartPonit):getChildByName("arrow"):setVisible(false)
			end

			arg_8_0:onFightResult(var_8_0, arg_9_0)
		end)
	end
end

function var_0_0.onFightResult(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_0.campaignTable:nextCampaign(arg_10_0.nowPoint)

	if arg_10_0.nowPoint == arg_10_0.normalStartPonit and arg_10_0.storyType == 0 then
		return
	end

	if arg_10_0.nowPoint == arg_10_0.normalStartPonit then
		arg_10_0.nextShowCampaign = var_10_0[arg_10_0.storyType]
	else
		arg_10_0.nextShowCampaign = var_10_0[1]
	end

	if arg_10_0.nextShowCampaign == 0 then
		return
	end

	if arg_10_0.nextShowCampaign == 1106 or arg_10_0.nextShowCampaign == 1205 then
		arg_10_0.mapState = 1

		arg_10_0:mapChange(arg_10_0.mapState)
	end

	local var_10_1 = true

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		if arg_10_0.nextShowCampaign == iter_10_1 then
			var_10_1 = false
		end
	end

	local var_10_2 = arg_10_0.nextShowCampaign
	local var_10_3 = arg_10_0.campaignTable:lastCampaign(var_10_2)
	local var_10_4 = arg_10_0.mapNormalDetail[tostring(var_10_2)]
	local var_10_5 = arg_10_0.campaignTable:campaignType(var_10_2)

	if var_10_2 == 0 then
		return
	end

	if arg_10_0.map:getChildByName("point" .. var_10_2) then
		arg_10_0.map:getChildByName("point" .. var_10_2):setVisible(false)
	end

	local var_10_6 = arg_10_0:createPoint(var_10_2)
	local var_10_7 = arg_10_0.pointX[var_10_2]
	local var_10_8 = arg_10_0.pointY[var_10_2]

	if var_10_1 then
		var_10_6:setVisible(false)
		var_10_6:getChildByName("container"):setScale(0)
		var_10_6:getChildByName("container"):setOpacity(0)
		var_10_6:getChildByName("container"):setRotation(0)
		var_10_6:getChildByName("container"):setTouchEnabled(false)
		var_10_6:addTo(arg_10_0.map)
		var_10_6:pos(var_10_7, var_10_8)
		arg_10_0:createRoad(var_10_3, var_10_2, var_10_1)

		local var_10_9 = 0.03333333333333333

		var_10_6:getChildByName("container"):runAction(cc.Sequence:create({
			cc.DelayTime:create(var_0_2),
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
		arg_10_0:createRoad(var_10_3, var_10_2, var_10_1)

		if arg_10_2 then
			arg_10_0.onBattleEnd = false

			arg_10_0:createMap()
		end
	end
end

function var_0_0.storyEvent(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.campaignTable:behindStory(arg_13_0.nowPoint)

	xyd.WindowManager.get():openWindow("fourth_annni_map_story", {
		dialogueID = var_13_0,
		callback = arg_13_1
	})
end

function var_0_0.createPoint(arg_14_0, arg_14_1)
	local var_14_0

	if arg_14_0.mapNormalDetail[tostring(arg_14_1)] and next(arg_14_0.mapNormalDetail) then
		var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map/map_item.csb")

		local var_14_1 = arg_14_0.mapNormalDetail[tostring(arg_14_1)] % 10
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

		local var_14_6 = math.floor(arg_14_1 / 100) % 10

		if var_14_6 == 0 then
			var_14_2:getChildByName("bg_pos"):setVisible(true)

			var_14_5 = true
		elseif var_14_6 == arg_14_0.storyType then
			if var_14_6 == var_0_3.Blue then
				local var_14_7 = xyd.createSpriteFromPlist("windows/anniversary4th/story_map/map/level_blue.png", "windows/anniversary4th/story_map/map/mapPlist")

				var_14_7:addTo(var_14_2, -1)
				var_14_7:setPosition(var_14_2:getChildByName("bg_pos"):getPosition())
			else
				local var_14_8 = xyd.createSpriteFromPlist("windows/anniversary4th/story_map/map/level_yellow.png", "windows/anniversary4th/story_map/map/mapPlist")

				var_14_8:addTo(var_14_2, -1)
				var_14_8:setPosition(var_14_2:getChildByName("bg_pos"):getPosition())
			end

			var_14_5 = true
		else
			var_14_2:getChildByName("bg_pos"):setVisible(true)

			var_14_5 = false

			xyd.GrayNode(var_14_2)
		end

		local var_14_9 = display.newNode()

		var_14_9:setContentSize(cc.size(120, 150))
		var_14_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_14_9:addTo(var_14_2)
		var_14_9:setPosition(var_14_2:getChildByName("start"):getPosition())
		var_14_9:setTouchEnabled(true)
		var_14_9:setTouchSwallowEnabled(false)
		var_14_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				return true
			elseif arg_15_0.name == "ended" then
				arg_14_0.fourthAnniversary.onBattleEnd = false

				local var_15_0 = arg_14_0.campaignTable:lastCampaign(arg_14_1)

				arg_14_0.stage = arg_14_0.fourthAnniversary:getStage()

				if arg_14_0.stage ~= 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6.hasEnd
					})

					return
				end

				if var_14_1 ~= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6.hasWin
					})

					return
				end

				if var_15_0 ~= 0 and arg_14_0.mapNormalDetail[tostring(var_15_0)] % 10 == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6.pointClose
					})

					return
				end

				if not var_14_5 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6.routeClose
					})

					return
				end

				if arg_14_0.mapNormalDetail[tostring(arg_14_1)] % 10 == 0 then
					local var_15_1 = arg_14_0.campaignTable:frontStory(arg_14_1)

					xyd.WindowManager.get():openWindow("fourth_annni_map_story", {
						dialogueID = var_15_1,
						callback = function()
							arg_14_0:openMapDetailWindow(arg_14_1)
						end
					})
				else
					arg_14_0:openMapDetailWindow(arg_14_1)
				end
			end
		end)

		local var_14_10

		if arg_14_0.storyType == 0 then
			var_14_10 = arg_14_0.nowPoint
		elseif arg_14_0.nowPoint == arg_14_0.normalStartPonit then
			var_14_10 = arg_14_0.campaignTable:nextCampaign(arg_14_0.nowPoint)[arg_14_0.storyType]
		else
			var_14_10 = arg_14_0.campaignTable:nextCampaign(arg_14_0.nowPoint)[1]
		end

		if var_14_10 == arg_14_1 then
			local var_14_11 = xyd.createSpriteFromPlist("windows/anniversary4th/story_map/map/arrow.png", "windows/anniversary4th/story_map/map/mapPlist")

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
	elseif arg_14_0.mapHardDetail[tostring(arg_14_1)] and next(arg_14_0.mapHardDetail) then
		var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map/map_item.csb")

		local var_14_14 = arg_14_0.mapHardDetail[tostring(arg_14_1)] % 10
		local var_14_15 = var_14_0:getChildByName("container")

		var_14_0:getChildByName("bg_clear"):setVisible(false)
		var_14_0:getChildByName("star1"):setVisible(var_14_14 == 1)
		var_14_0:getChildByName("star2"):setVisible(var_14_14 == 2)
		var_14_0:getChildByName("star3"):setVisible(var_14_14 == 3)
		var_14_0:setName("point" .. arg_14_1)
		var_14_15:getChildByName("bg_pos"):setVisible(true)
		var_14_15:getChildByName("start"):setVisible(false)

		local var_14_16 = arg_14_0.campaignTable:avatar(arg_14_1)
		local var_14_17 = xyd.AssetLoader.get():loadSprite(var_14_16)

		var_14_17:addTo(var_14_15)
		var_14_17:setPosition(var_14_15:getChildByName("start"):getPosition())

		local var_14_18 = display.newNode()

		var_14_18:setContentSize(cc.size(120, 150))
		var_14_18:setAnchorPoint(cc.p(0.5, 0.5))
		var_14_18:addTo(var_14_15)
		var_14_18:setPosition(var_14_15:getChildByName("start"):getPosition())
		var_14_18:setTouchEnabled(true)
		var_14_18:setTouchSwallowEnabled(false)
		var_14_18:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				return true
			elseif arg_17_0.name == "ended" then
				arg_14_0.fourthAnniversary.onBattleEnd = false
				arg_14_0.stage = arg_14_0.fourthAnniversary:getStage()

				if arg_14_0.stage ~= 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6.hasEnd
					})

					return
				end

				arg_14_0:openMapDetailWindow(arg_14_1)
			end
		end)
	end

	return var_14_0
end

function var_0_0.openMapDetailWindow(arg_18_0, arg_18_1)
	arg_18_0.fourthAnniversary.mapState = arg_18_0.mapState
	arg_18_0.fourthAnniversary.mapMode = arg_18_0.mapMode

	local var_18_0 = {
		star = arg_18_0.mapNormalDetail[tostring(arg_18_1)] or arg_18_0.mapHardDetail[tostring(arg_18_1)],
		campaignID = arg_18_1
	}

	if not arg_18_0.selfPlayer:getBackpack() then
		arg_18_0.selfPlayer:loadBackpack(function(arg_19_0)
			if arg_19_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("fourth_annni_map_detail", var_18_0)
			end
		end)
	else
		xyd.WindowManager.get():openWindow("fourth_annni_map_detail", var_18_0)
	end
end

function var_0_0.createProgressBar(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0

	if arg_20_2 == var_0_3.Blue then
		var_20_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_20_0.lineBlue))
	elseif arg_20_2 == var_0_3.Yellow then
		var_20_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_20_0.lineYellow))
	else
		var_20_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_20_0.lineGrey))
	end

	var_20_0:setAnchorPoint(cc.p(0, 0.5))
	var_20_0:setMidpoint(cc.p(0, 0))
	var_20_0:setBarChangeRate(cc.p(1, 0))
	var_20_0:setType(display.PROGRESS_TIMER_BAR)

	var_20_0.maxPercentage = math.min(arg_20_1 / var_20_0:getContentSize().width)

	return var_20_0
end

function var_0_0.createRoad(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = arg_21_0.pointX[arg_21_1]
	local var_21_1 = arg_21_0.pointY[arg_21_1]
	local var_21_2 = arg_21_0.pointX[arg_21_2]
	local var_21_3 = arg_21_0.pointY[arg_21_2]
	local var_21_4 = math.sqrt(math.pow(var_21_0 - var_21_2, 2) + math.pow(var_21_1 - var_21_3, 2))
	local var_21_5
	local var_21_6 = math.floor(arg_21_2 / 100) % 10

	if var_21_6 == arg_21_0.storyType then
		if var_21_6 == var_0_3.Blue then
			var_21_5 = var_0_3.Blue
		else
			var_21_5 = var_0_3.Yellow
		end
	else
		var_21_5 = var_0_3.Grey
	end

	local var_21_7 = arg_21_0:createProgressBar(var_21_4, var_21_5)

	var_21_7:addTo(arg_21_0.map, -1)
	var_21_7:pos(var_21_0, var_21_1)

	local var_21_8 = math.atan2(var_21_3 - var_21_1, var_21_2 - var_21_0) / math.pi * -180

	var_21_7:setRotation(var_21_8)

	if arg_21_3 then
		var_21_7:runAction(cc.ProgressTo:create(1, var_21_7.maxPercentage * 100))
	else
		var_21_7:setPercentage(var_21_7.maxPercentage * 100)
	end
end

function var_0_0.mapChange(arg_22_0, arg_22_1)
	if not arg_22_0.mapResource or tolua.isnull(arg_22_0.mapResource) then
		return
	end

	arg_22_0:nodeByName("btn_right"):setVisible(false)
	arg_22_0:nodeByName("btn_left"):setVisible(false)

	if arg_22_1 == 0 then
		local var_22_0 = cc.MoveTo:create(0.5, cc.p(0, 0))

		arg_22_0.mapResource:runActionOnce(var_22_0, false, function()
			arg_22_0:nodeByName("btn_right"):setVisible(true)
			arg_22_0:nodeByName("btn_left"):setVisible(false)
		end)
	elseif arg_22_1 == 1 then
		local var_22_1 = cc.MoveTo:create(0.5, cc.p(-1280, 0))

		arg_22_0.mapResource:runActionOnce(var_22_1, false, function()
			arg_22_0:nodeByName("btn_right"):setVisible(false)
			arg_22_0:nodeByName("btn_left"):setVisible(true)
		end)
	end
end

function var_0_0.updateBonus(arg_25_0)
	arg_25_0:nodeByName("pos_award"):removeAllChildren()

	if arg_25_0.mapMode == 1 then
		arg_25_0:initStoryProcessAward():addTo(arg_25_0:nodeByName("pos_award"))
	elseif arg_25_0.mapMode == 2 then
		arg_25_0:initHardStarAward():addTo(arg_25_0:nodeByName("pos_award"))
	end
end

function var_0_0.initStoryProcessAward(arg_26_0)
	local var_26_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map/story_award.csb")
	local var_26_1 = var_26_0:getChildByName("container")
	local var_26_2 = arg_26_0.baseInfo.normal_process
	local var_26_3 = arg_26_0.mapProcessTable:ids()
	local var_26_4 = arg_26_0.mapProcessTable:process(#var_26_3)
	local var_26_5 = math.min(var_26_2 / var_26_4 * 100, 100)

	var_26_1:getChildByName("bar"):setPercent(var_26_5)

	local var_26_6 = 0

	for iter_26_0, iter_26_1 in ipairs(var_26_3) do
		if var_26_2 >= arg_26_0.mapProcessTable:process(iter_26_1) then
			var_26_6 = iter_26_1
		end
	end

	local function var_26_7(arg_27_0, arg_27_1)
		local var_27_0 = xyd.tables.gift:items(arg_27_1)
		local var_27_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map/gift_tips.csb")

		var_27_1:getChildByName("container"):setContentSize(200, 80 * #var_27_0 + 70)

		for iter_27_0, iter_27_1 in ipairs(var_27_0) do
			local var_27_2 = display.newNode()

			var_27_2:setContentSize(cc.size(70, 70))
			var_27_2:setAnchorPoint(cc.p(0, 0))
			xyd.setItemBorder(var_27_2, iter_27_1)
			var_27_2:addTo(var_27_1:getChildByName("container"))
			var_27_2:setPosition(cc.p(35, 80 * iter_27_0 - 45))

			local var_27_3 = {
				size = 24,
				color = cc.c3b(16, 196, 255)
			}
			local var_27_4 = xyd.AssetLoader.get():loadLabel(var_27_3)

			var_27_4:setMaxLineWidth(70)
			var_27_4:setLineHeight(49)
			var_27_4:setString("x" .. xyd.tables.gift:itemNum(arg_27_1)[iter_27_0])
			var_27_4:addTo(var_27_1:getChildByName("container"))
			var_27_4:setPosition(cc.p(130, 80 * iter_27_0 - 20))
		end

		var_27_1:addTo(var_26_1)

		local var_27_5, var_27_6 = arg_27_0:getPosition()

		var_27_1:setPosition(cc.p(var_27_5 - 40, var_27_6 + 40))
		var_27_1:setVisible(false)
		var_27_1:setTouchSwallowEnabled(true)

		local var_27_7 = display.newNode()

		var_27_7:setContentSize(cc.size(70, 70))
		var_27_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_27_7:addTo(arg_27_0)
		var_27_7:setTouchEnabled(true)
		var_27_7:setTouchSwallowEnabled(false)
		var_27_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
			if arg_28_0.name == "began" then
				var_27_1:setVisible(true)

				return true
			elseif arg_28_0.name == "ended" then
				var_27_1:setVisible(false)
				var_27_1:setTouchSwallowEnabled(true)
			end
		end)
	end

	local var_26_8 = arg_26_0.awardsInfo[arg_26_0.mapMode]
	local var_26_9 = 0

	for iter_26_2, iter_26_3 in ipairs(var_26_8) do
		if iter_26_3 == 0 then
			var_26_9 = iter_26_2

			break
		end
	end

	if var_26_9 ~= 0 and var_26_9 <= var_26_6 then
		var_26_1:getChildByName("txt_process"):setString(var_0_6.canAward)
	else
		var_26_1:getChildByName("txt_process"):setString(var_0_6.nowProcess)
	end

	for iter_26_4, iter_26_5 in ipairs(var_26_3) do
		if var_26_1:getChildByName("pos_" .. iter_26_5) then
			local var_26_10

			if var_26_8[iter_26_5] == 1 then
				var_26_10 = xyd.AssetLoader:get():loadSprite("windows/anniversary4th/story_map/map/bag_open.png")
			else
				var_26_10 = xyd.AssetLoader:get():loadSprite("windows/anniversary4th/story_map/map/bag_close.png")

				if var_26_6 < iter_26_5 then
					xyd.GrayNode(var_26_10)
				end
			end

			var_26_10:addTo(var_26_1:getChildByName("pos_" .. iter_26_5))
			var_26_10:setAnchorPoint(cc.p(0.5, 0.5))

			if iter_26_4 <= var_26_9 and var_26_9 <= var_26_6 and var_26_8[iter_26_5] ~= 1 then
				local var_26_11 = var_26_1:getChildByName("pos_" .. iter_26_5)

				var_26_11:setTouchEnabled(true)
				var_26_11:setTouchSwallowEnabled(false)
				var_26_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
					if arg_29_0.name == "began" then
						var_26_11:setScale(0.9)

						return true
					elseif arg_29_0.name == "ended" then
						var_26_11:setScale(1)

						local var_29_0 = {}

						var_29_0.mode = 1

						if var_26_9 == 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_6.notAward
							})

							return
						elseif var_26_9 > var_26_6 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_6.notAward
							})

							return
						else
							var_29_0.award_id = var_26_9
						end

						arg_26_0.fourthAnniversary:getMapAward(var_29_0, function(arg_30_0, arg_30_1)
							if arg_30_0 == xyd.error.OK then
								arg_26_0.selfPlayer:handleRewards(arg_30_1.awards)

								arg_26_0.awardsInfo = arg_30_1.awards_info

								arg_26_0:updateBonus()
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_6.awardFalse
								})

								return
							end
						end)
					end
				end)
			else
				local var_26_12 = arg_26_0.mapProcessTable:giftId(iter_26_5)

				var_26_7(var_26_1:getChildByName("pos_" .. iter_26_5), var_26_12)
			end
		end

		if var_26_1:getChildByName("txt_process_" .. iter_26_5) then
			var_26_1:getChildByName("txt_process_" .. iter_26_5):setString(arg_26_0.mapProcessTable:process(iter_26_5))
			var_26_1:getChildByName("txt_process_" .. iter_26_5):enableOutline(cc.c4b(0, 0, 0, 255), 2)
		end
	end

	return var_26_0
end

function var_0_0.initHardStarAward(arg_31_0)
	local var_31_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map/hard_award.csb")
	local var_31_1 = var_31_0:getChildByName("container")
	local var_31_2 = arg_31_0.baseInfo.super_star
	local var_31_3 = arg_31_0.mapHardStarTable:ids()
	local var_31_4 = 0

	for iter_31_0, iter_31_1 in ipairs(var_31_3) do
		if var_31_2 <= arg_31_0.mapHardStarTable:starNum(iter_31_1) then
			local var_31_5 = iter_31_1

			break
		end
	end

	local var_31_6 = arg_31_0.awardsInfo[arg_31_0.mapMode]
	local var_31_7 = #var_31_3

	for iter_31_2, iter_31_3 in ipairs(var_31_6) do
		if iter_31_3 == 0 then
			var_31_7 = iter_31_2

			break
		end
	end

	local var_31_8
	local var_31_9

	if var_31_7 ~= 0 then
		local var_31_10 = arg_31_0.mapHardStarTable:starNum(var_31_7)

		var_31_9 = math.min(var_31_2 / var_31_10 * 100, 100)
	else
		var_31_9 = 0
	end

	var_31_1:getChildByName("bonus_bar"):setPercent(var_31_9)

	local var_31_11 = arg_31_0.mapHardStarTable:starNum(var_31_7)

	var_31_1:getChildByName("bonus_txt"):setString(var_31_2 .. "/" .. var_31_11)
	var_31_1:getChildByName("bonus_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)

	if var_31_11 <= var_31_2 and var_31_6[var_31_7] == 0 then
		local var_31_12 = 0.2
		local var_31_13 = cc.Spawn:create({
			cc.Sequence:create({
				cc.MoveBy:create(var_31_12, cc.p(5, 0)),
				cc.MoveBy:create(var_31_12, cc.p(-10, 0)),
				cc.MoveBy:create(var_31_12, cc.p(5, 0)),
				cc.DelayTime:create(var_31_12 * 3)
			}),
			cc.Sequence:create({
				cc.RotateBy:create(var_31_12, 15),
				cc.RotateBy:create(var_31_12, -30),
				cc.RotateBy:create(var_31_12, 15),
				cc.DelayTime:create(var_31_12 * 3)
			})
		})

		var_31_1:getChildByName("img_star"):runAction(cc.RepeatForever:create(var_31_13))
	end

	local var_31_14 = var_31_1:getChildByName("bonus_button")

	var_31_14:addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.began then
			var_31_14:setScale(0.9)
		elseif arg_32_1 == ccui.TouchEventType.ended or arg_32_1 == ccui.TouchEventType.canceled then
			var_31_14:setScale(1)

			local var_32_0 = {}

			var_32_0.mode = 2

			if var_31_2 == 0 then
				xyd.WindowManager.get():openWindow("fourth_annni_map_story_bonus", {
					canAward = var_31_7
				}):setPosition(25, 140)

				return
			elseif arg_31_0.mapHardStarTable:starNum(var_31_7) > var_31_2 then
				xyd.WindowManager.get():openWindow("fourth_annni_map_story_bonus", {
					canAward = var_31_7
				}):setPosition(25, 140)

				return
			elseif var_31_6[#var_31_3] ~= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_6.notAward
				})

				return
			else
				var_32_0.award_id = var_31_7
			end

			arg_31_0.fourthAnniversary:getMapAward(var_32_0, function(arg_33_0, arg_33_1)
				if arg_33_0 == xyd.error.OK then
					arg_31_0.selfPlayer:handleRewards(arg_33_1.awards)

					arg_31_0.awardsInfo = arg_33_1.awards_info

					arg_31_0:updateBonus()
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6.awardFalse
					})

					return
				end
			end)
		end
	end)

	return var_31_0
end

function var_0_0.initModeBtn(arg_34_0)
	local var_34_0 = arg_34_0:nodeByName("btn_mode_top")
	local var_34_1 = arg_34_0:nodeByName("btn_mode_bottom")
	local var_34_2, var_34_3 = var_34_0:getPosition()
	local var_34_4, var_34_5 = var_34_1:getPosition()
	local var_34_6 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/story_map/map/icon_normal.png")
	local var_34_7 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/story_map/map/icon_challenge.png")

	var_34_0:getChildByName("node_mode_top"):removeAllChildren()
	var_34_1:getChildByName("node_mode_bottom"):removeAllChildren()

	if arg_34_0.mapMode == 1 then
		var_34_6:addTo(var_34_0:getChildByName("node_mode_top"))
		var_34_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_34_0:getChildByName("txt_mode_top"):setString(var_0_6.normal)
		var_34_7:addTo(var_34_1:getChildByName("node_mode_bottom"))
		var_34_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_34_1:getChildByName("txt_mode_bottom"):setString(var_0_6.hard)
	elseif arg_34_0.mapMode == 2 then
		var_34_7:addTo(var_34_0:getChildByName("node_mode_top"))
		var_34_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_34_0:getChildByName("txt_mode_top"):setString(var_0_6.hard)
		var_34_6:addTo(var_34_1:getChildByName("node_mode_bottom"))
		var_34_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_34_1:getChildByName("txt_mode_bottom"):setString(var_0_6.normal)
	end

	if arg_34_0.mapNormalDetail[tostring(arg_34_0.endPoints[1])] == 0 and arg_34_0.mapNormalDetail[tostring(arg_34_0.endPoints[2])] == 0 then
		var_34_1:setVisible(false)

		return
	end

	local var_34_8 = false

	var_34_1:setVisible(var_34_8)
	var_34_0:addTouchEventListener(function(arg_35_0, arg_35_1)
		if arg_35_1 == ccui.TouchEventType.ended or arg_35_1 == ccui.TouchEventType.canceled then
			arg_34_0:nodeByName("red_p"):setVisible(false)

			var_34_8 = not var_34_8

			var_34_1:setVisible(var_34_8)
		end
	end)
	var_34_1:addTouchEventListener(function(arg_36_0, arg_36_1)
		if arg_36_1 == ccui.TouchEventType.ended or arg_36_1 == ccui.TouchEventType.canceled then
			arg_34_0:nodeByName("red_p2"):setVisible(false)

			if arg_34_0.mapMode == 1 then
				arg_34_0:nodeByName("btn_restart"):setVisible(false)

				arg_34_0.mapMode = 2

				arg_34_0:initModeBtn()
				arg_34_0:updateBonus()

				arg_34_0.onBattleEnd = false

				arg_34_0:createMap()
			elseif arg_34_0.mapMode == 2 then
				arg_34_0:nodeByName("btn_restart"):setVisible(true)

				arg_34_0.mapMode = 1

				arg_34_0:initModeBtn()
				arg_34_0:updateBonus()

				arg_34_0.onBattleEnd = false

				arg_34_0:createMap()
			end
		end
	end)
end

function var_0_0.initBtn(arg_37_0)
	if arg_37_0.mapState == 0 then
		arg_37_0:nodeByName("btn_right"):setVisible(true)
		arg_37_0:nodeByName("btn_left"):setVisible(false)
	else
		arg_37_0:nodeByName("btn_right"):setVisible(false)
		arg_37_0:nodeByName("btn_left"):setVisible(true)
	end

	local var_37_0 = arg_37_0:nodeByName("btn_right")

	var_37_0:setTouchSwallowEnabled(false)
	var_37_0:addTouchEventListener(function(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.began then
			var_37_0:setScale(0.9)
		elseif arg_38_1 == ccui.TouchEventType.ended or arg_38_1 == ccui.TouchEventType.canceled then
			var_37_0:setScale(1)

			arg_37_0.mapState = 1

			arg_37_0:mapChange(arg_37_0.mapState)
		end
	end)

	local var_37_1 = arg_37_0:nodeByName("btn_left")

	var_37_1:setTouchSwallowEnabled(false)
	var_37_1:addTouchEventListener(function(arg_39_0, arg_39_1)
		if arg_39_1 == ccui.TouchEventType.began then
			var_37_1:setScale(0.9)
		elseif arg_39_1 == ccui.TouchEventType.ended or arg_39_1 == ccui.TouchEventType.canceled then
			var_37_1:setScale(1)

			arg_37_0.mapState = 0

			arg_37_0:mapChange(arg_37_0.mapState)
		end
	end)

	local var_37_2 = arg_37_0:nodeByName("btn_shop")

	var_37_2:addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.began then
			var_37_2:setScale(0.9)
		elseif arg_40_1 == ccui.TouchEventType.ended or arg_40_1 == ccui.TouchEventType.canceled then
			var_37_2:setScale(1)
			arg_37_0.fourthAnniversary:enterMapShop()
		end
	end)

	local var_37_3 = arg_37_0:nodeByName("btn_restart")

	if arg_37_0.mapMode == 2 then
		arg_37_0:nodeByName("btn_restart"):setVisible(false)
	end

	var_37_3:addTouchEventListener(function(arg_41_0, arg_41_1)
		if arg_41_1 == ccui.TouchEventType.began then
			var_37_3:setScale(0.9)
		elseif arg_41_1 == ccui.TouchEventType.ended or arg_41_1 == ccui.TouchEventType.canceled then
			var_37_3:setScale(1)

			arg_37_0.stage = arg_37_0.fourthAnniversary:getStage()

			if arg_37_0.stage ~= 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_6.hasEnd
				})

				return
			end

			xyd.WindowManager.get():openWindow("fourth_annni_map_restart", {
				callback = function(arg_42_0)
					if arg_42_0 then
						if arg_37_0.storyType == 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_6.notStory
							})

							return
						end

						arg_37_0.fourthAnniversary:mapRestart(function(arg_43_0, arg_43_1)
							if arg_43_0 == xyd.error.OK then
								local var_43_0 = xyd.WindowManager.get():getWindow("fourth_annni_map")
								local var_43_1 = xyd.tables.misc:getValue("activity_anni4_campaign_reset_item")

								arg_37_0.backpack:removeItem({
									itemNum = 1,
									itemID = var_43_1
								})

								if var_43_0 then
									arg_37_0.baseInfo = arg_43_1.base_info
									arg_37_0.storyType = arg_43_1.base_info.story_type
									arg_37_0.mapNormalDetail = arg_43_1.normal_campaigns

									local var_43_2 = arg_37_0.campaignTable:ids()

									arg_37_0.mapState = 0

									arg_37_0:nodeByName("btn_right"):setVisible(true)
									arg_37_0:nodeByName("btn_left"):setVisible(false)

									arg_37_0.mapMode = 1
									arg_37_0.nowPoint = var_43_2[1]
									arg_37_0.onBattleEnd = false

									arg_37_0:createMap()
								end
							end
						end)
					end
				end
			})
		end
	end)
end

return var_0_0
