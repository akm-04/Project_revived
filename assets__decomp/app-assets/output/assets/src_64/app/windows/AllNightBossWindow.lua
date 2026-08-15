local var_0_0 = class("AllNightBossWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.activityPolarNightBoss
local var_0_5 = xyd.tables.activityPolarNightBossMission

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.allNight = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)
	arg_1_0.allNight.dayCount = math.ceil((xyd.ServerTime.get():getServerTime() - arg_1_0.allNight.startTime) / xyd.OneDaySec)
	arg_1_0.battleID = var_0_4:battleID(arg_1_0.allNight.dayCount)
	arg_1_0.rank = arg_1_0.allNight.bossInfo.rank
	arg_1_0.ticket = arg_1_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc:getValue("activity_polar_night_boss_ticket"))
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:setBtns()
	arg_3_0:initBoss()
	arg_3_0:initMission()
end

function var_0_0.setTexts(arg_4_0)
	arg_4_0:nodeByName("text_skill"):setString(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_1"))
	arg_4_0:nodeByName("text_rank"):setString(var_0_1:translation("RANKING"))

	if arg_4_0.rank == 0 then
		arg_4_0:nodeByName("text_rank_num"):setString("")
	else
		arg_4_0:nodeByName("text_rank_num"):setString(string.format(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_2"), arg_4_0.rank))
	end

	arg_4_0:nodeByName("text_battle"):setString(var_0_1:translation("ALL_NIGHT_BOSS_TEXT_3"))
	arg_4_0:nodeByName("text_top_num"):setString(arg_4_0.ticket)
	arg_4_0:nodeByName("text_stone_num"):setString("： 1")
end

function var_0_0.setBtns(arg_5_0)
	local var_5_0 = var_0_2.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_5_0:addTo(arg_5_0)
	var_5_0:setAnchorPoint(0.5, 0.5)
	var_5_0:setPosition(50, 695)
	var_5_0:setName("return_btn")

	arg_5_0.returnBtn = var_5_0

	arg_5_0.returnBtn:addTouchEvent(function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {}

			var_7_0.title_name = "ALL_NIGHT_BOSS_RULE_TITLE"
			var_7_0.rule = "ALL_NIGHT_BOSS_RULE_TEXT"
			var_7_0.style = xyd.RuleStyle.BLUE

			xyd.WindowManager.get():openWindow("all_night_boss_rule", var_7_0)
		end
	end)
	arg_5_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_BOSS_RANK, nil, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("all_night_boss_rank", arg_9_1)
				end
			end)
		end
	end)
	arg_5_0:nodeByName("btn_battle"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_5_0.ticket < 1 then
				local var_10_0 = var_0_1:translation("ALL_NIGHT_BOSS_TEXT_9")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_0
				})
			else
				local var_10_1 = xyd.SelectTeamType.ALL_NIGHT_BOSS
				local var_10_2 = {
					type = var_10_1,
					battleID = arg_5_0.battleID,
					campaignType = xyd.CampaignType.ALL_NIGHT_BOSS
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_10_2)
			end
		end
	end)
end

function var_0_0.initBoss(arg_11_0)
	local var_11_0 = xyd.tables.battle:fight1(arg_11_0.battleID)[1]
	local var_11_1 = var_0_3:modelID(var_11_0)
	local var_11_2 = xyd.HeroAnimation.new(var_11_0, var_11_1, xyd.tables.model:uiScale(var_11_1), {})

	if var_11_2 then
		var_11_2:idle()
	end

	var_11_2:addTo(arg_11_0:nodeByName("node_hero"))

	local var_11_3 = arg_11_0:nodeByName("container_skill"):getHeight()

	for iter_11_0 = 1, 4 do
		local var_11_4 = display.newNode()

		var_11_4:setContentSize(var_11_3, var_11_3)

		local var_11_5 = var_0_3:getSkill(var_11_0, iter_11_0)

		xyd.setSkillBorder(var_11_4, var_11_5, true)
		var_11_4:setTouchEnabled(true)
		var_11_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				local var_12_0 = {
					has_jiantou = false,
					id = var_11_5
				}

				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_12_1 = xyd.WindowManager.get():openWindow("skill_tips", var_12_0)

					xyd.adaptToWorldPosition(var_11_4, var_12_1)
				end

				return true
			elseif arg_12_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
		var_11_4:addTo(arg_11_0:nodeByName("container_skill"))
		var_11_4:setPositionX((var_11_3 + 18) * (iter_11_0 - 1))
	end
end

function var_0_0.initMission(arg_13_0)
	arg_13_0:initData()

	arg_13_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_13_0:nodeByName("list"):getWidth(), arg_13_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_13_0:nodeByName("list")):onScroll(handler(arg_13_0, arg_13_0.scrollListener))

	arg_13_0.list:setBounceable(true)
	arg_13_0.list:setDelegate(handler(arg_13_0, arg_13_0.delegate))
	arg_13_0.list:reload()
end

function var_0_0.initData(arg_14_0)
	arg_14_0.missionIndex = {}

	local var_14_0 = arg_14_0.allNight.bossInfo.person_awarded

	for iter_14_0 = 1, #var_14_0 do
		if var_14_0[iter_14_0] == 0 then
			table.insert(arg_14_0.missionIndex, iter_14_0)
		end
	end

	for iter_14_1 = 1, #var_14_0 do
		if var_14_0[iter_14_1] ~= 0 then
			table.insert(arg_14_0.missionIndex, iter_14_1)
		end
	end
end

function var_0_0.delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = #arg_15_0.missionIndex

	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return var_15_0
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		if var_15_0 < arg_15_3 then
			return nil
		end

		local var_15_1 = arg_15_0.list:dequeueItem()

		if not var_15_1 then
			var_15_1 = arg_15_0.list:newItem()
		else
			var_15_1:removeAllChildren(true)
		end

		local var_15_2 = display.newNode()

		arg_15_0:initCell(var_15_2, arg_15_3)

		local var_15_3 = display.newNode()

		var_15_3:addChild(var_15_2)
		var_15_3:setContentSize(var_15_2:getContentSize())
		var_15_1:setItemSize(var_15_2:getContentSize().width, var_15_2:getContentSize().height)
		var_15_1:addContent(var_15_3)

		return var_15_1
	end
end

function var_0_0.initCell(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_0.missionIndex[arg_16_2]
	local var_16_1
	local var_16_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/boss/mission_item.csb")
	local var_16_3 = var_16_2:getChildByName("container")
	local var_16_4 = var_16_3:getContentSize()

	var_16_3:getChildByName("title"):setString(var_0_5:title(var_16_0))
	var_16_3:getChildByName("desc"):setString(var_0_5:desc(var_16_0))
	arg_16_0:rewardFormat(var_16_3:getChildByName("award_container"), var_0_5:gift(var_16_0), nil, 8)

	if arg_16_0.allNight.bossInfo.person_awarded[var_16_0] ~= 0 then
		var_16_3:getChildByName("text_progress"):setVisible(false)
		var_16_3:getChildByName("btn"):setBright(false)
		var_16_3:getChildByName("btn"):getChildByName("text_btn"):setString(var_0_1:translation("ACTIVITY_1130_TIP3"))
	elseif arg_16_0.allNight.bossInfo.self_damage >= var_0_5:damage(var_16_0) then
		var_16_3:getChildByName("text_progress"):setVisible(false)
		var_16_3:getChildByName("btn"):getChildByName("text_btn"):setString(var_0_1:translation("ACTIVITY_1130_TIP2"))
		var_16_3:getChildByName("btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
			xyd.buttonScaleAnim(arg_17_0, arg_17_1)

			if arg_17_1 == ccui.TouchEventType.ended then
				local var_17_0 = {
					idx = var_16_0
				}

				xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_BOSS_GET_AWARD, var_17_0, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						arg_16_0.selfPlayer:handleRewards(arg_18_1.awards)

						arg_16_0.allNight.bossInfo.person_awarded[var_16_0] = 1

						arg_16_0:initData()
						arg_16_0.list:reload()
					end
				end)
			end
		end)
	else
		var_16_3:getChildByName("btn"):setVisible(false)

		local var_16_5
		local var_16_6

		if arg_16_0.allNight.bossInfo.self_damage >= 100000000 then
			var_16_5 = math.floor(arg_16_0.allNight.bossInfo.self_damage / 100000000) .. "00M"
		else
			var_16_5 = math.floor(arg_16_0.allNight.bossInfo.self_damage / 10000) .. "0K"
		end

		if var_0_5:damage(var_16_0) >= 100000000 then
			var_16_6 = math.floor(var_0_5:damage(var_16_0) / 100000000) .. "00M"
		else
			var_16_6 = math.floor(var_0_5:damage(var_16_0) / 10000) .. "0K"
		end

		var_16_3:getChildByName("text_progress"):setString(var_16_5 .. "/" .. var_16_6)
	end

	var_16_2:addTo(arg_16_1)
	arg_16_1:setContentSize(arg_16_0:nodeByName("list"):getWidth(), var_16_4.height + 9)
end

function var_0_0.scrollListener(arg_19_0, arg_19_1)
	if arg_19_1.name == "began" then
		arg_19_0.startClick_ = true
		arg_19_0.prevX_ = arg_19_1.x
	elseif arg_19_1.name == "moved" and 20 <= math.abs(arg_19_1.x - arg_19_0.prevX_) then
		arg_19_0.startClick_ = false
	end
end

function var_0_0.rewardFormat(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4)
	local var_20_0 = arg_20_1:getContentSize().height
	local var_20_1 = arg_20_4 or var_20_0 / 4
	local var_20_2 = xyd.tables.gift:items(arg_20_2)

	if #var_20_2 == 1 and var_20_2[1] == 0 then
		var_20_2 = {}
	end

	local var_20_3 = xyd.tables.gift:itemNum(arg_20_2)
	local var_20_4 = #var_20_2

	for iter_20_0 = 1, #var_20_2 do
		local var_20_5 = display.newNode()

		var_20_5:setContentSize(var_20_0, var_20_0)

		if xyd.tables.item:type(var_20_2[iter_20_0]) == -1 then
			xyd.setAvatarBorderNewUI(var_20_2[iter_20_0], var_20_5, 1, xyd.tables.hero:initialStar(var_20_2[iter_20_0]))
		else
			xyd.setItemBorder(var_20_5, var_20_2[iter_20_0], false, false, var_20_3[iter_20_0])
		end

		var_20_5:addTo(arg_20_1)
		var_20_5:setAnchorPoint(cc.p(0, 0))
		var_20_5:setPosition((iter_20_0 - 1) * (var_20_0 + var_20_1), 0)

		local var_20_6 = {
			id = var_20_2[iter_20_0],
			lev = xyd.tables.item:level(var_20_2[iter_20_0])
		}

		if xyd.tables.item:type(var_20_2[iter_20_0]) == -1 then
			var_20_6.tipsType = 0
			var_20_6.desc1 = xyd.tables.hero:getDes(var_20_2[iter_20_0])
		elseif specialItem then
			var_20_6.tipsType = 1
			var_20_6.id = -3
		else
			var_20_6.tipsType = 1
			var_20_6.desc1 = xyd.tables.item:desc1(var_20_2[iter_20_0])
			var_20_6.desc2 = xyd.tables.item:desc2(var_20_2[iter_20_0])
		end

		var_20_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_20_2[iter_20_0])
		var_20_6.name = xyd.tables.item:name(var_20_2[iter_20_0])

		xyd.addTips(var_20_5, var_20_6)
	end

	local var_20_7 = xyd.tables.gift:skinFragment(arg_20_2)

	if var_20_7 and var_20_7 > 0 then
		local var_20_8 = display.newNode()

		var_20_8:setContentSize(var_20_0, var_20_0)
		xyd.setItemBorder(var_20_8, -101, false, false, var_20_7)
		var_20_8:addTo(arg_20_1)
		var_20_8:setAnchorPoint(cc.p(0, 0))
		var_20_8:setPosition(var_20_4 * (var_20_0 + var_20_1), 0)

		local var_20_9 = {}

		var_20_9.id = -101
		var_20_9.tipsType = 1

		xyd.addTips(var_20_8, var_20_9)

		var_20_4 = var_20_4 + 1
	end

	local var_20_10 = xyd.tables.gift:crystal(arg_20_2)

	if var_20_10 and var_20_10 > 0 then
		local var_20_11 = display.newNode()

		var_20_11:setContentSize(var_20_0, var_20_0)
		xyd.setItemBorder(var_20_11, -1, false, false, var_20_10)
		var_20_11:addTo(arg_20_1)
		var_20_11:setAnchorPoint(cc.p(0, 0))
		var_20_11:setPosition(var_20_4 * (var_20_0 + var_20_1), 0)

		local var_20_12 = {}

		var_20_12.id = -1
		var_20_12.tipsType = 1

		xyd.addTips(var_20_11, var_20_12)

		var_20_4 = var_20_4 + 1
	end

	local var_20_13 = xyd.tables.gift:mana(arg_20_2)

	if var_20_13 and var_20_13 > 0 then
		local var_20_14 = display.newNode()

		var_20_14:setContentSize(var_20_0, var_20_0)
		xyd.setItemBorder(var_20_14, -2, false, false, var_20_13)
		var_20_14:addTo(arg_20_1)
		var_20_14:setAnchorPoint(cc.p(0, 0))
		var_20_14:setPosition(var_20_4 * (var_20_0 + var_20_1), 0)

		local var_20_15 = {}

		var_20_15.id = -2
		var_20_15.tipsType = 1

		xyd.addTips(var_20_14, var_20_15)

		local var_20_16 = var_20_4 + 1
	end

	return arg_20_1
end

return var_0_0
