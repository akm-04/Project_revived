local var_0_0 = import("app.model.Hero")
local var_0_1 = class("BattleStoryScene", import("app.common.ui.BaseScene"))
local var_0_2 = import("app.modules.battle.Fighter")
local var_0_3 = xyd.tables.skill
local var_0_4 = import("app.modules.battle.SkillEffect")
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = require("app.modules.battle.SelectTarget")
local var_0_7 = xyd.tables.translation
local var_0_8 = xyd.tables.sound:getSound("battle_bg_music_1")
local var_0_9
local var_0_10
local var_0_11 = require("framework.scheduler")
local var_0_12 = require("cjson")
local var_0_13 = 1800
local var_0_14 = {}
local var_0_15 = {}
local var_0_16 = {}
local var_0_17 = {}
local var_0_18 = {}
local var_0_19 = {}
local var_0_20 = false
local var_0_21 = true
local var_0_22 = 0
local var_0_23 = 0
local var_0_24 = false
local var_0_25 = false
local var_0_26 = {}
local var_0_27 = 10002
local var_0_28 = 0
local var_0_29 = 3

function var_0_1.ctor(arg_1_0, arg_1_1)
	var_0_1.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.herosA = arg_1_1.herosA
	arg_1_0.heroGroup = arg_1_1.herosB
	arg_1_0.group_ = 1
	arg_1_0.campaignType = xyd.CampaignType.STORY
	arg_1_0.campaignID = arg_1_1.campaignID
	arg_1_0.battleID = xyd.MapBattleID.STORY
	arg_1_0.stories = {
		xyd.tables.battle:storyBefore(arg_1_0.battleID)
	}
	arg_1_0.dropMana = arg_1_1.dropMana
	arg_1_0.dropItems = arg_1_1.drops
	arg_1_0.dropManaCount = 0
	arg_1_0.dropAwardCount = 0
	arg_1_0.showAward_ = {}
	arg_1_0.star_ = arg_1_1.star or 0
	arg_1_0.withRobot = arg_1_1.withRobot
	arg_1_0.enemyHeroes = arg_1_1.enemyHeroes
	arg_1_0.fighterInfo = arg_1_1.fighterInfo
	arg_1_0.heroStatus = arg_1_1.heroStatus
	arg_1_0.herosA = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_1.herosA) do
		local var_1_0 = var_0_0.new()

		var_1_0:populateWithTableID(iter_1_1)
		table.insert(arg_1_0.herosA, var_1_0)
	end

	table.sort(arg_1_0.herosA, function(arg_2_0, arg_2_1)
		return arg_2_0:getDistance() < arg_2_1:getDistance()
	end)

	arg_1_0.mapID_ = xyd.tables.battle:maps(arg_1_0.battleID)
	arg_1_0.isBattleEnded_ = false
end

function var_0_1.onEnterTransitionFinish(arg_3_0)
	var_0_1.super.onEnterTransitionFinish(arg_3_0)
	arg_3_0:setupBackground_()
	arg_3_0:init()
end

function var_0_1.onEnter(arg_4_0)
	audio.stopMusic()
	audio.stopAllSounds()
	audio.preloadMusic(var_0_8)
	audio.playMusic(var_0_8, true)
end

function var_0_1.onExit(arg_5_0)
	var_0_14 = {}
	var_0_15 = {}
	var_0_16 = {}
	var_0_17 = {}
	var_0_18 = {}
	var_0_19 = {}
	var_0_20 = false
	var_0_21 = true
	var_0_22 = 0
	var_0_23 = 0
	var_0_24 = false
	var_0_25 = false
	var_0_26 = {}
	var_0_28 = 0

	audio.stopAllSounds()
	audio.stopMusic()

	local var_5_0 = xyd.tables.sound:getSound("home_bg_music")

	audio.playMusic(var_5_0, true)
end

function var_0_1.init(arg_6_0)
	arg_6_0:setupWindows()
	arg_6_0:nextGroup()
end

function var_0_1.nextGroup(arg_7_0)
	collectgarbage("collect")

	arg_7_0.herosB = arg_7_0.heroGroup[arg_7_0.group_]

	arg_7_0:setupBasicData()

	var_0_22 = 0
	var_0_23 = 0
	var_0_28 = 0
	arg_7_0.lastCount_ = 0
	arg_7_0.stopTimeCount_ = false

	if var_0_10:getGuanQiaLabel() then
		var_0_10:getGuanQiaLabel():setString(arg_7_0.group_ .. " / " .. #arg_7_0.heroGroup)
	end

	var_0_10:hide()

	if arg_7_0.group_ == #arg_7_0.heroGroup and arg_7_0.stories[1] and arg_7_0.stories[1] > 0 then
		local var_7_0 = xyd.WindowManager.get():openWindow("story", {
			story_state = 1,
			is_before_story = true,
			story_id = arg_7_0.stories[1],
			battle_id = arg_7_0.battleID
		})

		cc.EventProxy.new(var_7_0, var_7_0):addEventListener(xyd.event.STORY_COMPLETE, function(arg_8_0)
			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_END then
				arg_7_0:sendStoryOperationLog(arg_8_0.point)
			end

			if arg_8_0.point and arg_8_0.point == 1 then
				arg_7_0:startBattle()
			elseif arg_8_0.point and arg_8_0.point == 2 or arg_8_0.point == 5 or arg_8_0.point == 6 then
				arg_7_0:checkUIEffect()
				var_0_9:show()
			elseif arg_8_0.point and arg_8_0.point == 3 or arg_8_0.point == 4 or arg_8_0.point == 7 then
				arg_7_0:startBattle()
				var_0_9:show()
				arg_7_0:resumeAllFighter()
			else
				if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_END then
					arg_7_0:sendStoryOperationLog(7)
				end

				arg_7_0:performWithDelay(function()
					arg_7_0:pauseBattle()
					arg_7_0:finishBattle_()
				end, 0.5)
			end
		end)
	else
		arg_7_0:startBattle()
	end
end

function var_0_1.auto(arg_10_0)
	if var_0_20 then
		arg_10_0.autoBtn_:setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_10_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
	end

	var_0_20 = not var_0_20
end

function var_0_1.setupWindows(arg_11_0)
	local var_11_0 = {
		heros = arg_11_0.herosA
	}

	var_0_9 = xyd.WindowManager.get():openWindow(xyd.WindowName.battleBottomWnd, var_11_0)
	var_0_10 = xyd.WindowManager.get():openWindow(xyd.WindowName.battleTopWnd, {
		guanqia = 1
	})

	var_0_10:hide()
end

function var_0_1.setupBasicData(arg_12_0)
	arg_12_0:setupBackground_()
	arg_12_0:clearFormation()
	arg_12_0:setFormation()
	arg_12_0:updateZorder()
	arg_12_0:setupButtons()
	arg_12_0:setBuffSkill(var_0_14, var_0_15)
	arg_12_0:setBuffSkill(var_0_15, var_0_14)
	arg_12_0:updateFighters()
	arg_12_0:initHeroStatus()

	arg_12_0.jsonAttacks_ = {}
	arg_12_0.jsonSpecialAttacks_ = {}
	arg_12_0.jsonMoveUnits_ = {}
	arg_12_0.jsonPositionUnits_ = {}
	arg_12_0.jsonApplyUnits_ = {}
	arg_12_0.jsonEnergy_ = {}
end

function var_0_1.initHeroStatus(arg_13_0)
	if arg_13_0.heroStatus and next(arg_13_0.heroStatus) and var_0_14 and next(var_0_14) then
		for iter_13_0, iter_13_1 in pairs(var_0_14) do
			if iter_13_1 and next(iter_13_1) and iter_13_1.hero then
				local var_13_0 = iter_13_1.hero:getHeroID()
				local var_13_1 = arg_13_0.heroStatus[tostring(var_13_0)]

				if var_13_0 > 0 and var_13_1.health == 1 then
					iter_13_1:updateHp(var_13_1.hp, var_0_22)

					iter_13_1.energy = var_13_1.mp

					iter_13_1:updateMpBar()
				end
			end
		end
	end
end

function var_0_1.updateFighters(arg_14_0)
	if arg_14_0.group_ == 1 then
		for iter_14_0, iter_14_1 in ipairs(var_0_14) do
			iter_14_1.hp = iter_14_1:getHpLimit()
		end
	end

	for iter_14_2, iter_14_3 in ipairs(var_0_15) do
		if arg_14_0.campaignType == xyd.CampaignType.MARCH then
			if not iter_14_3.hpPercent or iter_14_3.hpPercent == 1 then
				iter_14_3.hp = iter_14_3:getHpLimit()
			end
		else
			iter_14_3.hp = iter_14_3:getHpLimit()
		end
	end
end

function var_0_1.setupButtons(arg_15_0)
	arg_15_0.skipBtn_ = xyd.AssetLoader.get():loadButton({
		"windows/start_story/btn_skip",
		"windows/start_story/btn_skip",
		"windows/start_story/btn_skip"
	})

	arg_15_0.skipBtn_:addTo(arg_15_0, 100)
	arg_15_0.skipBtn_:align(display.TOP_RIGHT, xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_15_0.skipBtn_:onButtonPressed(function()
		xyd.playButtonSound()
	end)
	arg_15_0.skipBtn_:onButtonRelease(function()
		arg_15_0.player:sendOperationLog(xyd.StatID.ID_CLICK_FIRST_SKIP)

		local var_17_0 = xyd.WindowManager.get():getWindow("story")

		if var_17_0 then
			var_17_0:endBattleStory()
		end

		arg_15_0:pauseBattle()

		if var_17_0 then
			var_17_0:onEnded()
		end

		arg_15_0:finishBattle_()
	end)

	for iter_15_0 = 1, #var_0_14 do
		local var_15_0 = var_0_9:getButtonByIndex(iter_15_0)

		var_15_0:setTouchEnabled(true)
		var_15_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
			arg_15_0:clickAvatar(var_0_14[iter_15_0], arg_18_0)

			return true
		end)
		var_0_14[iter_15_0]:setAvatar(var_15_0)
	end

	arg_15_0.autoBtn_ = var_0_9:getAutoBtn()

	arg_15_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
	arg_15_0.autoBtn_:addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended then
			arg_15_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)

			local var_19_0 = var_0_7:translation("AUTO_BATTLE_TIP2")
		end
	end)

	arg_15_0.speedBtn_ = var_0_9:getSpeedBtn()

	arg_15_0.speedBtn_:setVisible(false)
end

function var_0_1.clearFormation(arg_20_0, arg_20_1)
	if arg_20_1 then
		for iter_20_0 = #var_0_14, 1, -1 do
			if var_0_14[iter_20_0]:getSummonType() ~= xyd.summonMonsterType.None then
				table.remove(var_0_14, iter_20_0)
			end
		end

		for iter_20_1 = #var_0_15, 1, -1 do
			if var_0_15[iter_20_1]:getSummonType() ~= xyd.summonMonsterType.None then
				table.remove(var_0_15, iter_20_1)
			end
		end

		return
	end

	var_0_26 = {}

	for iter_20_2, iter_20_3 in ipairs(var_0_15) do
		iter_20_3:getFighterModel():clearTracks()
		transition.stopTarget(iter_20_3.fighterModel)
		iter_20_3.fighterModel:removeSelf()
	end

	for iter_20_4 = #var_0_14, 1, -1 do
		local var_20_0 = var_0_14[iter_20_4]

		if var_20_0:getSummonType() ~= xyd.summonMonsterType.None then
			table.remove(var_0_14, iter_20_4)
			var_20_0:getFighterModel():clearTracks()
			transition.stopTarget(var_20_0.fighterModel)
			var_20_0.fighterModel:removeSelf()
		end
	end
end

function var_0_1.setFormation(arg_21_0)
	if next(var_0_14) == nil then
		for iter_21_0, iter_21_1 in ipairs(arg_21_0.herosA) do
			local var_21_0 = var_0_2.new({
				is_arena = arg_21_0.campaignType == xyd.CampaignType.ARENA
			})

			var_21_0:populateWithHero(iter_21_1)
			var_21_0:setTeamType(xyd.TeamType.A)
			var_21_0:initModels()
			var_21_0.fighterModel:addTo(arg_21_0, 100)
			var_21_0:getFighterModel():idle()
			var_21_0.fighterModel:initHeaderView(0)
			var_21_0.fighterModel:setHPProgress(1, true)
			table.insert(var_0_14, var_21_0)
		end
	else
		for iter_21_2, iter_21_3 in ipairs(var_0_14) do
			if not iter_21_3:isDeath() then
				iter_21_3.fighterModel.headerView_:setCount(0)
				iter_21_3:getFighterModel():idle()
				iter_21_3:init()
			end
		end
	end

	var_0_15 = {}

	for iter_21_4, iter_21_5 in ipairs(arg_21_0.herosB) do
		local var_21_1 = var_0_2.new({
			is_arena = arg_21_0.campaignType == xyd.CampaignType.ARENA
		})
		local var_21_2 = arg_21_0:isPvPInstance_()
		local var_21_3

		if not arg_21_0:isPvPInstance_() then
			var_21_1:populateWithMonsterID(iter_21_5)
		else
			local var_21_4 = arg_21_0.enemyHeroes[iter_21_5]

			if not var_21_4 then
				print("Failed to get heroData, heroData is nil.")
			else
				var_21_1:populateWithHero(var_21_4)

				if var_21_4 and var_21_4.healthStatus then
					if var_21_4.healthStatus.hp then
						var_21_1:setHp(var_21_4.healthStatus.hp)

						var_21_3 = var_21_4.healthStatus.hp / var_21_1:getHpLimit()
					end

					if var_21_4.healthStatus.mp then
						var_21_1.energy = var_21_4.healthStatus.mp
					end
				end
			end
		end

		var_21_1:setTeamType(xyd.TeamType.B)
		var_21_1:initModels()
		var_21_1.fighterModel:addTo(arg_21_0, 100)
		var_21_1:getFighterModel():idle()
		var_21_1:getFighterModel():flipX(true)
		var_21_1.fighterModel:initHeaderView(1)

		if var_21_3 then
			var_21_1.fighterModel:setHPProgress(var_21_3, true)

			var_21_1.hpPercent = var_21_3
		else
			var_21_1.fighterModel:setHPProgress(1, true)

			var_21_1.hpPercent = 1
		end

		var_21_1.dropIndex = iter_21_4
		var_21_1.dropMana = 0

		if arg_21_0.dropMana then
			var_21_1.dropMana = arg_21_0.dropMana[arg_21_0.group_][iter_21_4]
		end

		table.insert(var_0_15, var_21_1)
	end

	table.sort(var_0_14, function(arg_22_0, arg_22_1)
		return arg_22_0.distance < arg_22_1.distance
	end)
	table.sort(var_0_15, function(arg_23_0, arg_23_1)
		return arg_23_0.distance < arg_23_1.distance
	end)

	local var_21_5 = 1
	local var_21_6 = 9

	for iter_21_6 = 1, #var_0_14 do
		if not var_0_14[iter_21_6]:isDeath() then
			var_0_14[iter_21_6].fighterIndex = "A|" .. iter_21_6

			var_0_14[iter_21_6].fighterModel:pos(-160 * var_21_5, xyd.STAGE_HEIGHT / 2 - 50 + var_21_6 - 90 * ((var_21_5 - 1) % 2))
			table.insert(var_0_26, var_0_14[iter_21_6])
			var_0_14[iter_21_6]:setFormationDelay(xyd.tables.battleConfig.skillDelayQueue[var_21_5])

			var_21_5 = var_21_5 + 1
			var_21_6 = var_21_6 - 2

			var_0_14[iter_21_6]:setHpBar(var_0_9:getHpBarByIndex(iter_21_6))
			var_0_14[iter_21_6]:setEnergyBar(var_0_9:getMpBarByIndex(iter_21_6))

			local var_21_7 = var_0_14[iter_21_6]
			local var_21_8 = var_21_7:enterSkill()

			if var_21_8 > 0 and var_21_7.hero:getSkillLevelByID(var_21_8) and var_21_7.hero:getSkillLevelByID(var_21_8) > 0 then
				var_21_7.fighterModel:x(-100)

				var_21_7.isEnterSkill_ = true
			end
		end
	end

	local var_21_9 = 10

	for iter_21_7 = 1, #var_0_15 do
		var_0_15[iter_21_7].fighterIndex = "B|" .. iter_21_7

		var_0_15[iter_21_7].fighterModel:pos(xyd.STAGE_WIDTH + 160 * iter_21_7, xyd.STAGE_HEIGHT / 2 - 50 + var_21_9 - 90 * ((iter_21_7 - 1) % 2))
		table.insert(var_0_26, var_0_15[iter_21_7])

		var_21_9 = var_21_9 - 2

		var_0_15[iter_21_7]:setFormationDelay(xyd.tables.battleConfig.skillDelayQueue[iter_21_7])

		local var_21_10 = var_0_15[iter_21_7]
		local var_21_11 = var_21_10:enterSkill()

		if var_21_11 > 0 and var_21_10.hero:getSkillLevelByID(var_21_11) and var_21_10.hero:getSkillLevelByID(var_21_11) > 0 then
			var_21_10.fighterModel:x(xyd.STAGE_WIDTH + 100)

			var_21_10.isEnterSkill_ = true
		end
	end
end

function var_0_1.updateZorder(arg_24_0, arg_24_1)
	table.sort(var_0_26, function(arg_25_0, arg_25_1)
		local var_25_0, var_25_1 = arg_25_0.fighterModel:getPosition()
		local var_25_2, var_25_3 = arg_25_1.fighterModel:getPosition()

		return var_25_3 < var_25_1
	end)

	for iter_24_0 = 1, #var_0_26 do
		if arg_24_1 and var_0_26[iter_24_0].fighterModel:getLocalZOrder() >= 1000 then
			var_0_26[iter_24_0].fighterModel:setLocalZOrder(1000 + iter_24_0)
		else
			var_0_26[iter_24_0].fighterModel:setLocalZOrder(100 + iter_24_0)
		end
	end
end

function var_0_1.getFighterByIndex(arg_26_0, arg_26_1)
	local var_26_0 = string.sub(arg_26_1, 1, 1)
	local var_26_1 = tonumber(string.sub(arg_26_1, 3, 3))
	local var_26_2

	if var_26_0 == "A" then
		var_26_2 = var_0_14
	else
		var_26_2 = var_0_15
	end

	return var_26_2[var_26_1]
end

function var_0_1.setBuffSkill(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = import("app.modules.battle.BuffStory")

	local function var_27_1(arg_28_0, arg_28_1)
		for iter_28_0, iter_28_1 in ipairs(arg_28_1) do
			for iter_28_2, iter_28_3 in ipairs(arg_28_0) do
				iter_28_3.target = iter_28_1
			end

			iter_28_1:addBuffs(arg_28_0)
		end
	end

	local function var_27_2(arg_29_0, arg_29_1, arg_29_2)
		local var_29_0 = {}

		for iter_29_0, iter_29_1 in ipairs(arg_29_0) do
			local var_29_1 = var_0_3:father(arg_29_2)
			local var_29_2 = arg_29_1:getSkillLvByID(var_29_1) or arg_29_1:getLevel()
			local var_29_3 = var_27_0.new({
				tableID = iter_29_1,
				start = var_0_22,
				level = var_29_2,
				skillID = arg_29_2,
				fighter = arg_29_1
			})

			var_29_3:setYongJiu()
			table.insert(var_29_0, var_29_3)
		end

		return var_29_0
	end

	for iter_27_0, iter_27_1 in ipairs(arg_27_1) do
		local var_27_3 = iter_27_1.buffSkills

		for iter_27_2, iter_27_3 in pairs(var_27_3) do
			local var_27_4 = var_0_3:father(iter_27_3)

			if iter_27_1:getSkillLvByID(var_27_4) and iter_27_1:getSkillLvByID(var_27_4) > 0 then
				local var_27_5 = var_0_3:skillType(iter_27_3)

				if var_27_5 == xyd.SkillType.BUFF_ALL then
					local var_27_6 = var_27_2(var_0_3:buffs(iter_27_3), iter_27_1, iter_27_3)

					var_27_1(var_27_6, arg_27_1)
					var_27_1(var_27_6, arg_27_2)
				elseif var_27_5 == xyd.SkillType.BUFF_ENEMY then
					local var_27_7 = var_27_2(var_0_3:buffs(iter_27_3), iter_27_1, iter_27_3)

					var_27_1(var_27_7, arg_27_2)
				elseif var_27_5 == xyd.SkillType.BUFF_FRIEND then
					local var_27_8 = var_27_2(var_0_3:buffs(iter_27_3), iter_27_1, iter_27_3)

					var_27_1(var_27_8, arg_27_1)
				elseif var_27_5 == xyd.SkillType.SELF_FUNCTION_BUFF then
					local var_27_9 = var_27_2(var_0_3:buffs(iter_27_3), iter_27_1, iter_27_3)

					for iter_27_4, iter_27_5 in ipairs(var_27_9) do
						iter_27_5.target = iter_27_1
					end

					iter_27_1:addBuffs(var_27_9)
				end
			end
		end
	end
end

function var_0_1.checkEnergySkill(arg_30_0, arg_30_1)
	if arg_30_1.hasUseSkill then
		return false
	end

	if not arg_30_1:canEnergySkill() or arg_30_0.walk2NextBattle or arg_30_1:getDelaySkill() > var_0_22 then
		return false
	end

	if arg_30_1.preUnits_ and next(arg_30_1.preUnits_) and arg_30_1.isEnergySkill then
		return false
	end

	if arg_30_1:isApUnable() and (var_0_3:type(arg_30_1:getSkillID()) == xyd.AttackType.AP or var_0_3:type(arg_30_1:getSkillID()) == xyd.AttackType.CURE) then
		return false
	end

	if arg_30_1:isAdUnable() and var_0_3:type(arg_30_1:getSkillID()) == xyd.AttackType.AD then
		return false
	end

	if arg_30_1:unableEnergySkill(var_0_22) then
		return false
	end

	if arg_30_1:getTeamType() == xyd.TeamType.A then
		local var_30_0

		for iter_30_0, iter_30_1 in ipairs(var_0_15) do
			if not iter_30_1:isDeath() or iter_30_1:isAffected() then
				var_30_0 = iter_30_1

				break
			end
		end

		if not var_30_0 then
			return false
		end
	else
		local var_30_1

		for iter_30_2, iter_30_3 in ipairs(var_0_15) do
			if not iter_30_3:isDeath() or iter_30_3:isAffected() then
				var_30_1 = iter_30_3

				break
			end
		end

		if not var_30_1 then
			return false
		end
	end

	local var_30_2 = arg_30_1:getTeamType() == xyd.TeamType.A and var_0_15 or var_0_14
	local var_30_3 = var_30_2 == var_0_14 and var_0_15 or var_0_14
	local var_30_4 = arg_30_1:isAttackFriend() and var_30_3 or var_30_2

	if var_0_3:distance(arg_30_1:getSkillID()) > 0 then
		local var_30_5 = arg_30_0:minDistanceTarget(arg_30_1, var_30_4)

		if not var_30_5 then
			return false
		end

		if math.abs(var_30_5:getX() - arg_30_1:getX()) > var_0_3:distance(arg_30_1:getSkillID()) then
			return false
		end
	end

	return true
end

function var_0_1.clickAvatar(arg_31_0, arg_31_1, arg_31_2)
	if not arg_31_0:checkEnergySkill(arg_31_1) or not arg_31_1.isPlaySkill then
		return
	end

	local var_31_0 = table.keyof(var_0_14)

	if arg_31_1:manualType() == xyd.ManualType.None then
		if arg_31_2.name == "began" then
			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_END then
				arg_31_0:sendGuideOperationLog(arg_31_1.partnerID)
			end

			if arg_31_1.partnerID == xyd.monsterMaZhong then
				var_0_9:storyManualHand(false, var_31_0)
				var_0_9:storyGuideTalk(false, var_31_0, 1)
				var_0_9:storyGuideManual(var_31_0, false)
			else
				var_0_9:storyGuideHandk(false, var_31_0)
				var_0_9:storyGuideTalk(false, var_31_0, 2)
			end
		elseif arg_31_2.name == "ended" then
			if arg_31_1:initEnergySkill(var_0_22) then
				arg_31_1.hasUseSkill = true

				arg_31_0:jsonInsertEnergy(arg_31_1)

				if next(arg_31_1.preUnits_) then
					arg_31_1:setSkillIndex()

					arg_31_1.isEnergySkill = true
				end

				arg_31_1.preUnits_ = {}
				arg_31_1.unitSkillIDs_ = {}

				var_0_9:energySkillEffect(arg_31_1, var_0_14)
				audio.playSound(xyd.tables.sound:getSound("battle_use_skill"))
			end

			arg_31_0:startInterval()
		end

		return
	end

	if arg_31_2.name == "began" then
		if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_END then
			arg_31_0:sendGuideOperationLog(arg_31_1.partnerID)
		end

		if arg_31_1.partnerID == xyd.monsterMaZhong then
			var_0_9:storyManualHand(false, var_31_0)
			var_0_9:storyGuideTalk(false, var_31_0, 1)
			var_0_9:storyGuideManual(var_31_0, false)
		else
			var_0_9:storyGuideHandk(false, var_31_0)
			var_0_9:storyGuideTalk(false, var_31_0, 2)
		end

		if arg_31_1:initEnergySkill(var_0_22) then
			if next(arg_31_1.preUnits_) then
				arg_31_1:setSkillIndex()

				arg_31_1.isEnergySkill = true
			end

			arg_31_1.preUnits_ = {}
			arg_31_1.unitSkillIDs_ = {}

			arg_31_0:jsonInsertEnergy(arg_31_1)
			arg_31_0:addBlackLayer(arg_31_1, true)

			arg_31_0.startX_ = arg_31_2.x
			arg_31_0.startY_ = arg_31_2.y

			arg_31_0:pauseBattle()
		end
	elseif arg_31_2.name == "moved" then
		local var_31_1 = math.abs(arg_31_2.x - (arg_31_0.startX_ or arg_31_2.x)) > 10 or math.abs(arg_31_2.y - (arg_31_0.startY_ or arg_31_2.y)) > 10

		if arg_31_1.isEnergySkill and var_31_1 then
			arg_31_0:manualTarget(arg_31_1, arg_31_2)
		end
	elseif arg_31_2.name == "ended" then
		if arg_31_1.isEnergySkill then
			if arg_31_0.manualSp1_ then
				arg_31_0.manualSp1_:setVisible(false)
			end

			if arg_31_0.manualSp2_ then
				arg_31_0.manualSp2_:setVisible(false)
			end

			if arg_31_0.manualSp1_1 then
				arg_31_0.manualSp1_3:setVisible(false)
				arg_31_0.manualSp1_2:setVisible(false)
				arg_31_0.manualSp1_1:setVisible(false)
				arg_31_0.manualSp1_1:setScale(1)
			end

			if arg_31_0.manualSp3_1 then
				arg_31_0.manualSp3_1:setVisible(false)
				arg_31_0.manualSp1_2:setVisible(false)
			end

			arg_31_1.hasUseSkill = true
		end

		arg_31_0:startInterval()
		var_0_9:energySkillEffect(arg_31_1, var_0_14)
	end
end

function var_0_1.manualTarget(arg_32_0, arg_32_1, arg_32_2)
	if arg_32_1:manualType() == xyd.ManualType.Single then
		arg_32_0:manualTargetType_1(arg_32_1, arg_32_2)
	elseif arg_32_1:manualType() == xyd.ManualType.Area then
		arg_32_0:manualTargetType_2(arg_32_1, arg_32_2)
	elseif arg_32_1:manualType() == xyd.ManualType.Direction then
		arg_32_0:manualTargetType_3(arg_32_1, arg_32_2)
	end
end

function var_0_1.manualTargetType_1(arg_33_0, arg_33_1, arg_33_2)
	if not arg_33_0.manualSp1_1 then
		arg_33_0.manualSp1_1 = xyd.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_33_0.manualSp1_1:addTo(arg_33_0, 100)

		arg_33_0.manualSp1_2 = xyd.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_33_0.manualSp1_2:addTo(arg_33_0, 100)

		arg_33_0.manualSp1_3 = xyd.AssetLoader.get():loadSprite("images/battle_manual_1_3.png")

		arg_33_0.manualSp1_3:addTo(arg_33_0, 100)
	end

	local var_33_0 = arg_33_2.x
	local var_33_1 = arg_33_2.y
	local var_33_2, var_33_3 = arg_33_1.fighterModel:getPosition()

	if var_33_0 > arg_33_1:getX() then
		arg_33_1:getFighterModel():flipX(false)
	else
		arg_33_1:getFighterModel():flipX(true)
	end

	local var_33_4 = math.atan2(var_33_1 - var_33_3, var_33_0 - var_33_2)
	local var_33_5
	local var_33_6
	local var_33_7 = var_0_3:type(arg_33_1:getSkillID())
	local var_33_8 = {
		arg_33_0:getTaishici()
	}

	for iter_33_0, iter_33_1 in ipairs(var_33_8) do
		if not iter_33_1:isDeath() then
			local var_33_9 = iter_33_1:getY() - var_33_3
			local var_33_10 = iter_33_1:getX() - var_33_2
			local var_33_11 = math.atan2(var_33_9, var_33_10)

			if not var_33_5 or var_33_5 >= math.abs(var_33_4 - var_33_11) then
				var_33_5 = math.abs(var_33_4 - var_33_11)
				var_33_6 = iter_33_1
			end
		end
	end

	if not var_33_6 then
		arg_33_0.manualSp1_3:setVisible(false)
		arg_33_0.manualSp1_2:setVisible(false)
		arg_33_0.manualSp1_1:setVisible(false)

		return
	end

	local var_33_12 = math.atan2(var_33_6:getY() - var_33_3, var_33_6:getX() - var_33_2) / math.pi * -180
	local var_33_13 = math.sqrt((var_33_6:getY() - var_33_3) * (var_33_6:getY() - var_33_3) + (var_33_6:getX() - var_33_2) * (var_33_6:getX() - var_33_2)) - arg_33_0.manualSp1_3:getWidth() / 2 - arg_33_0.manualSp1_2:getWidth() / 2 + 30
	local var_33_14 = math.max(var_33_13, 0)

	arg_33_0.manualSp1_2:setVisible(true)
	arg_33_0.manualSp1_2:pos(arg_33_1:getX(), arg_33_1:getY())
	arg_33_0.manualSp1_3:setVisible(true)
	arg_33_0.manualSp1_3:pos(var_33_6:getX(), var_33_6:getY())
	arg_33_0.manualSp1_1:setVisible(true)
	arg_33_0.manualSp1_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_33_0.manualSp1_1:setScaleX(var_33_14 / arg_33_0.manualSp1_1:getWidth())
	arg_33_0.manualSp1_1:pos(var_33_6:getX() / 2 + var_33_2 / 2, var_33_6:getY() / 2 + var_33_3 / 2)
	arg_33_0.manualSp1_1:setRotation(var_33_12)
	var_33_6:getFighterModel():unsetMaskColor()

	for iter_33_2, iter_33_3 in ipairs(var_0_15) do
		if not iter_33_3:isDeath() and iter_33_3 ~= var_33_6 then
			iter_33_3:getFighterModel():setMaskColor()
		end
	end

	arg_33_0:updateZorder(true)

	arg_33_1.manualTargets = {
		var_33_6
	}
end

function var_0_1.manualTargetType_2(arg_34_0, arg_34_1, arg_34_2)
	if not arg_34_0.manualSp2_ then
		arg_34_0.manualSp2_ = xyd.AssetLoader.get():loadSprite("images/battle_manual_2_1.png")

		arg_34_0.manualSp2_:addTo(arg_34_0, 100)
	end

	arg_34_0.manualSp2_:setVisible(true)
	arg_34_0.manualSp2_:setAnchorPoint(cc.p(0.5, 0.5))

	local var_34_0 = arg_34_2.x

	if var_34_0 > arg_34_1:getX() then
		arg_34_1:getFighterModel():flipX(false)
	else
		arg_34_1:getFighterModel():flipX(true)
	end

	if arg_34_1:getFlipX() then
		var_34_0 = math.max(var_34_0, arg_34_1:getX() - arg_34_1:getDistance())
		var_34_0 = math.max(arg_34_1:getScope() / 2, var_34_0)
	else
		var_34_0 = math.min(var_34_0, arg_34_1:getX() + arg_34_1:getDistance())
		var_34_0 = math.min(xyd.STAGE_WIDTH - arg_34_1:getScope() / 2, var_34_0)
	end

	arg_34_0.manualSp2_:pos(var_34_0, arg_34_2.y)

	local var_34_1 = {}
	local var_34_2 = var_0_3:type(arg_34_1:getSkillID()) == xyd.AttackType.CURE and var_0_14 or var_0_15

	for iter_34_0, iter_34_1 in ipairs(var_34_2) do
		if not iter_34_1:isDeath() and iter_34_1:getX() > var_34_0 - arg_34_1:getScope() / 2 and iter_34_1:getX() < var_34_0 + arg_34_1:getScope() / 2 then
			table.insert(var_34_1, iter_34_1)
			iter_34_1:getFighterModel():unsetMaskColor()
		else
			iter_34_1:getFighterModel():setMaskColor()
		end
	end

	arg_34_0:updateZorder(true)

	arg_34_1.manualTargets = var_34_1
	arg_34_1.manualPosition = {
		var_34_0,
		arg_34_2.y
	}
end

function var_0_1.manualTargetType_3(arg_35_0, arg_35_1, arg_35_2)
	if not arg_35_0.manualSp3_1 then
		arg_35_0.manualSp3_1 = xyd.AssetLoader.get():loadSprite("images/battle_manual_3_1.png")

		arg_35_0.manualSp3_1:addTo(arg_35_0, 100)
	end

	if not arg_35_0.manualSp1_2 then
		arg_35_0.manualSp1_2 = xyd.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_35_0.manualSp1_2:addTo(arg_35_0, 100)
	end

	local var_35_0 = arg_35_2.x
	local var_35_1 = arg_35_2.y
	local var_35_2, var_35_3 = arg_35_1.fighterModel:getPosition()

	if var_35_0 >= arg_35_1:getX() then
		arg_35_1:getFighterModel():flipX(false)
		arg_35_0.manualSp3_1:flipX(false)
		arg_35_0.manualSp3_1:pos(var_35_2 + arg_35_0.manualSp3_1:getWidth() / 2 + arg_35_0.manualSp1_2:getWidth() / 2 - 15, var_35_3)
	else
		arg_35_1:getFighterModel():flipX(true)
		arg_35_0.manualSp3_1:flipX(true)
		arg_35_0.manualSp3_1:pos(var_35_2 - arg_35_0.manualSp3_1:getWidth() / 2 - arg_35_0.manualSp1_2:getWidth() / 2 + 15, var_35_3)
	end

	arg_35_0.manualSp1_2:setVisible(true)
	arg_35_0.manualSp1_2:pos(arg_35_1:getX(), arg_35_1:getY())
	arg_35_0.manualSp3_1:setVisible(true)
	arg_35_0.manualSp3_1:align(display.CENTER)

	arg_35_1.manualDirection = var_35_0 >= arg_35_1:getX() and 1 or 0
end

function var_0_1.adjustYs(arg_36_0)
	arg_36_0.aOrders = {}
	arg_36_0.bOrders = {}

	for iter_36_0, iter_36_1 in ipairs(var_0_14) do
		if not iter_36_1:isDeath() and not iter_36_1:isAffected() then
			table.insert(arg_36_0.aOrders, iter_36_1)
		end
	end

	for iter_36_2, iter_36_3 in ipairs(var_0_15) do
		if not iter_36_3:isDeath() and not iter_36_3:isAffected() then
			table.insert(arg_36_0.aOrders, iter_36_3)
		end
	end

	table.sort(arg_36_0.aOrders, function(arg_37_0, arg_37_1)
		local var_37_0, var_37_1 = arg_37_0.fighterModel:getPosition()
		local var_37_2, var_37_3 = arg_37_1.fighterModel:getPosition()

		return var_37_1 < var_37_3
	end)
	table.sort(arg_36_0.bOrders, function(arg_38_0, arg_38_1)
		local var_38_0, var_38_1 = arg_38_0.fighterModel:getPosition()
		local var_38_2, var_38_3 = arg_38_1.fighterModel:getPosition()

		return var_38_1 < var_38_3
	end)
	arg_36_0:adjustY(arg_36_0.aOrders)
	arg_36_0:adjustY(arg_36_0.bOrders)
end

function var_0_1.adjustY(arg_39_0, arg_39_1)
	local var_39_0 = 160

	for iter_39_0 = 1, #arg_39_1 do
		local var_39_1 = arg_39_1[iter_39_0]
		local var_39_2 = iter_39_0 > 1 and arg_39_1[iter_39_0 - 1]
		local var_39_3 = iter_39_0 < #arg_39_1 and arg_39_1[iter_39_0 + 1]
		local var_39_4 = var_39_1:getX()
		local var_39_5 = var_39_1:getY()
		local var_39_6
		local var_39_7
		local var_39_8
		local var_39_9

		if var_39_2 then
			var_39_6, var_39_7 = var_39_2:getX(), var_39_2:getY()
		end

		if var_39_3 then
			var_39_8, var_39_9 = var_39_3:getX(), var_39_3:getY()
		end

		if not var_39_2 and not var_39_1:isMoveUnable() and not var_39_1.unableMove and not var_39_1.buffMove and not var_39_1:isSkillMove() and var_39_3 then
			if math.abs(var_39_8 - var_39_4) < 80 and var_39_9 - var_39_5 < 70 and var_39_0 < var_39_5 then
				local var_39_10 = math.min(var_39_1:getBasicSpeed(), var_39_5 - var_39_0) * -1

				transition.moveBy(var_39_1.fighterModel, {
					time = arg_39_0:getSecondsPerFrame(),
					y = var_39_10,
					onComplete = function()
						var_39_1.isAdjustY_ = false
						var_39_1.adjustYSpeed_ = 0
					end
				})

				var_39_1.isAdjustY_ = var_0_22 + 1
				var_39_1.adjustYSpeed_ = var_39_10
			end
		elseif var_39_2 and not var_39_1:isMoveUnable() and not var_39_1.unableMove and not var_39_1.buffMove and not var_39_1:isSkillMove() and math.abs(var_39_6 - var_39_4) < 80 and var_39_5 - var_39_7 < 70 then
			if not var_39_2:isAdjustY(var_0_22) or var_39_2:isAdjustY(var_0_22) and var_39_2.adjustYSpeed_ > 0 then
				local var_39_11 = var_39_1:getBasicSpeed()

				transition.moveBy(var_39_1.fighterModel, {
					time = arg_39_0:getSecondsPerFrame(),
					y = var_39_11,
					onComplete = function()
						var_39_1.isAdjustY_ = false
						var_39_1.adjustYSpeed_ = 0
					end
				})

				var_39_1.isAdjustY_ = var_0_22 + 1
				var_39_1.adjustYSpeed_ = var_39_11
			end
		elseif var_39_3 and not var_39_1:isMoveUnable() and not var_39_1.unableMove and not var_39_1.buffMove and not var_39_1:isSkillMove() and math.abs(var_39_8 - var_39_4) < 80 and var_39_9 - var_39_5 < 70 and (not var_39_3:isAdjustY(var_0_22) or var_39_3:isAdjustY(var_0_22) and var_39_3.adjustYSpeed_ < 0) and math.abs(var_39_4 - var_39_6) < 80 and var_39_9 - var_39_5 > 100 + var_39_1:getBasicSpeed() then
			local var_39_12 = var_39_1:getBasicSpeed() * -1

			transition.moveBy(var_39_1.fighterModel, {
				time = arg_39_0:getSecondsPerFrame(),
				y = var_39_12,
				onComplete = function()
					var_39_1.isAdjustY_ = false
					var_39_1.adjustYSpeed_ = 0
				end
			})

			var_39_1.isAdjustY_ = var_0_22 + 1
			var_39_1.adjustYSpeed_ = var_39_12
		end
	end

	arg_39_0:updateZorder()
end

function var_0_1.checkMove(arg_43_0, arg_43_1, arg_43_2, arg_43_3)
	for iter_43_0, iter_43_1 in ipairs(arg_43_1) do
		local var_43_0 = iter_43_1:isMoveUnable() or iter_43_1:isSkillMove()

		if iter_43_1:isDeath() or var_43_0 or iter_43_1.unableMove or iter_43_1.manualDirection or iter_43_1:isAffected() then
			if not iter_43_1:isDeath() and iter_43_1:getCurrentAnimation() == "run" then
				iter_43_1:getFighterModel():idle()
			end

			iter_43_1.isWalking_ = false
		elseif iter_43_1.isEnterSkill_ then
			if var_0_22 < iter_43_1.hero:enterDuration() then
				if not iter_43_1:isWalking(var_0_22) then
					iter_43_1.isWalking_ = var_0_22 + 1
				end

				if iter_43_1:getCurrentAnimation() ~= "run" then
					iter_43_1:walk()
				end

				local var_43_1 = iter_43_1:getFlipX() and -1 or 1

				transition.moveBy(iter_43_1.fighterModel, {
					time = arg_43_0:getSecondsPerFrame(),
					x = iter_43_1.hero:enterSpeed() * var_43_1
				})
			elseif not iter_43_1.playedEnterSkill_ then
				iter_43_1:getFighterModel():idle()

				iter_43_1.isWalking_ = false
				iter_43_1.playedEnterSkill_ = true

				table.insert(iter_43_1.specialSkills, {
					skillID = iter_43_1.hero:enterSkill()
				})
			elseif var_0_22 > iter_43_1.hero:enterDelayDuration() then
				iter_43_1.isEnterSkill_ = nil
				iter_43_1.walk2Position_ = false
				iter_43_1.playedEnterSkill_ = false
			end
		elseif iter_43_1.walk2Position_ then
			if iter_43_1:isWalked2Position() then
				iter_43_1.walk2Position_ = false
			else
				if not iter_43_1:isWalking(var_0_22) then
					iter_43_1.isWalking_ = var_0_22 + 1
				end

				if iter_43_1:getCurrentAnimation() ~= "run" then
					iter_43_1:walk()
				end

				local var_43_2 = iter_43_1:getFlipX() and -1 or 1

				transition.moveBy(iter_43_1.fighterModel, {
					time = arg_43_0:getSecondsPerFrame(),
					x = iter_43_1:getCurrentSpeed() * var_43_2
				})
			end
		else
			local var_43_3, var_43_4 = iter_43_1.fighterModel:getPosition()
			local var_43_5
			local var_43_6
			local var_43_7
			local var_43_8 = 1

			if not iter_43_1:isAttackFriend() then
				var_43_7 = arg_43_0:minDistanceTarget(iter_43_1, arg_43_2)
			else
				var_43_7 = arg_43_0:minDistanceTarget(iter_43_1, arg_43_1)
			end

			if var_43_7 then
				local var_43_9, var_43_10 = var_43_7.fighterModel:getPosition()

				if var_43_9 < var_43_3 then
					var_43_8 = -1
				end

				if not iter_43_1.buffMove and not iter_43_1:isSkillMove() then
					iter_43_1:getFighterModel():flipX(var_43_8 < 0)
				end

				local var_43_11 = math.min(iter_43_1:getCurrentSpeed(), math.abs(var_43_9 - var_43_3))

				if iter_43_1:getDistance() ~= 0 and math.abs(var_43_3 - var_43_9) >= iter_43_1:getDistance() and iter_43_1:isAdjustY(var_0_22) == false then
					transition.moveBy(iter_43_1.fighterModel, {
						time = arg_43_0:getSecondsPerFrame(),
						x = var_43_11 * var_43_8
					})

					if iter_43_1:getCurrentAnimation() ~= "run" then
						iter_43_1:walk()
					end

					iter_43_1.isWalking_ = var_0_22 + 1
				elseif math.abs(var_43_3 - var_43_9) < iter_43_1:getDistance() or iter_43_1:getDistance() then
					if iter_43_1:getCurrentAnimation() == "run" then
						iter_43_1:getFighterModel():idle()
					end

					iter_43_1.isWalking_ = false
				end
			end
		end
	end
end

function var_0_1.checkMoves(arg_44_0)
	if arg_44_0.walk2NextBattle then
		local var_44_0
		local var_44_1

		for iter_44_0, iter_44_1 in ipairs(var_0_14) do
			if not iter_44_1:isDeath() then
				iter_44_1:getFighterModel():flipX(false)

				if not iter_44_1:isWalking(var_0_22) then
					iter_44_1.isWalking_ = var_0_22 + 1
				end

				if iter_44_1:getCurrentAnimation() ~= "run" then
					iter_44_1:walk()
				end

				transition.moveBy(iter_44_1.fighterModel, {
					time = arg_44_0:getSecondsPerFrame(),
					x = iter_44_1:getCurrentSpeed() * xyd.tables.battleConfig.speedAccelerate
				})

				local var_44_2 = iter_44_1:getX()

				if not var_44_1 or var_44_2 < var_44_1 then
					var_44_1 = var_44_2
				end
			end
		end

		if var_44_1 > xyd.STAGE_WIDTH + 100 then
			arg_44_0.walk2NextBattle = false
			arg_44_0.stopTimeCount_ = false
			arg_44_0.group_ = arg_44_0.group_ + 1

			arg_44_0:pauseBattle()
			arg_44_0:nextGroup()
		end

		return
	end

	if var_0_24 then
		return
	end

	arg_44_0:checkMove(var_0_14, var_0_15, 1)
	arg_44_0:checkMove(var_0_15, var_0_14, -1)
end

function var_0_1.updateLeftIntervals(arg_45_0)
	local function var_45_0(arg_46_0)
		if arg_46_0:getLeftInterval() == nil then
			return
		end

		arg_46_0:updateLeftInterval(var_0_22)
	end

	for iter_45_0, iter_45_1 in pairs(var_0_14) do
		var_45_0(iter_45_1)
	end

	for iter_45_2, iter_45_3 in pairs(var_0_15) do
		var_45_0(iter_45_3)
	end
end

function var_0_1.updateBuffEffect(arg_47_0)
	for iter_47_0, iter_47_1 in pairs(var_0_14) do
		iter_47_1:updateBuffEffect(var_0_22)
	end

	for iter_47_2, iter_47_3 in pairs(var_0_15) do
		iter_47_3:updateBuffEffect(var_0_22)
	end
end

function var_0_1.updateBuffState(arg_48_0)
	for iter_48_0, iter_48_1 in pairs(var_0_14) do
		iter_48_1:updateBuffState(var_0_22)

		if iter_48_1:isDeath() and not iter_48_1.playDrop_ then
			arg_48_0:playDie_(iter_48_1)
			arg_48_0:playDrop(iter_48_1)
		end
	end

	for iter_48_2, iter_48_3 in pairs(var_0_15) do
		iter_48_3:updateBuffState(var_0_22)

		if iter_48_3:isDeath() and not iter_48_3.playDrop_ then
			arg_48_0:playDie_(iter_48_3)
			arg_48_0:playDrop(iter_48_3)
		end
	end
end

function var_0_1.updatePosition(arg_49_0)
	for iter_49_0, iter_49_1 in pairs(var_0_14) do
		local var_49_0 = arg_49_0:updateSkillMove(iter_49_1)
		local var_49_1, var_49_2 = iter_49_1:updatePosition(var_0_22)

		if var_49_1 ~= 0 or var_49_2 ~= 0 then
			if action_ then
				transition.removeAction(action_)
			end

			if iter_49_1:getX() + var_49_1 < iter_49_1:getFighterModel():getWidth() / 2 and var_49_1 < 0 then
				var_49_1 = iter_49_1:getFighterModel():getWidth() / 2 - iter_49_1:getX()
			end

			if iter_49_1:getX() + var_49_1 > xyd.STAGE_WIDTH - iter_49_1:getFighterModel():getWidth() / 2 and var_49_1 > 0 then
				var_49_1 = xyd.STAGE_WIDTH - iter_49_1:getFighterModel():getWidth() / 2 - iter_49_1:getX()
			end

			iter_49_1.buffMove = true

			transition.moveBy(iter_49_1.fighterModel, {
				time = arg_49_0:getSecondsPerFrame(),
				x = var_49_1,
				y = var_49_2
			})
			arg_49_0:updateZorder()
		end

		if not iter_49_1:isBuffMove() then
			iter_49_1.buffMove = false
		end
	end

	for iter_49_2, iter_49_3 in pairs(var_0_15) do
		local var_49_3 = arg_49_0:updateSkillMove(iter_49_3)
		local var_49_4, var_49_5 = iter_49_3:updatePosition(var_0_22)

		if var_49_4 ~= 0 or var_49_5 ~= 0 then
			if action_ then
				transition.removeAction(action_)
			end

			if iter_49_3:getX() + var_49_4 < iter_49_3:getFighterModel():getWidth() / 2 and var_49_4 < 0 then
				var_49_4 = iter_49_3:getFighterModel():getWidth() / 2 - iter_49_3:getX()
			end

			if iter_49_3:getX() + var_49_4 > xyd.STAGE_WIDTH - iter_49_3:getFighterModel():getWidth() / 2 and var_49_4 > 0 then
				var_49_4 = xyd.STAGE_WIDTH - iter_49_3:getFighterModel():getWidth() / 2 - iter_49_3:getX()
			end

			iter_49_3.buffMove = true

			transition.moveBy(iter_49_3.fighterModel, {
				time = arg_49_0:getSecondsPerFrame(),
				x = var_49_4,
				y = var_49_5
			})
			arg_49_0:updateZorder()
		end

		if not iter_49_3:isBuffMove() then
			iter_49_3.buffMove = false
		end
	end
end

function var_0_1.updateSkillMove(arg_50_0, arg_50_1)
	if arg_50_1.moveStack_[1] then
		local var_50_0 = clone(arg_50_1.moveStack_[1])

		if arg_50_1:getX() + var_50_0 < arg_50_1:getFighterModel():getWidth() / 2 and var_50_0 < 0 then
			var_50_0 = arg_50_1:getFighterModel():getWidth() / 2 - arg_50_1:getX()
		end

		if arg_50_1:getX() + var_50_0 > xyd.STAGE_WIDTH - arg_50_1:getFighterModel():getWidth() / 2 and var_50_0 > 0 then
			var_50_0 = xyd.STAGE_WIDTH - arg_50_1:getFighterModel():getWidth() / 2 - arg_50_1:getX()
		end

		arg_50_1:popMoveStack()

		return transition.moveBy(arg_50_1.fighterModel, {
			time = arg_50_0:getSecondsPerFrame(),
			x = var_50_0
		})
	end

	return nil
end

function var_0_1.checkSkillCircle(arg_51_0)
	if var_0_24 then
		return
	end

	if var_0_20 then
		for iter_51_0, iter_51_1 in pairs(var_0_14) do
			if arg_51_0:checkEnergySkill(iter_51_1) and iter_51_1:initEnergySkill(var_0_22) then
				arg_51_0:jsonInsertEnergy(iter_51_1)

				if next(iter_51_1.preUnits_) then
					iter_51_1:setSkillIndex()

					iter_51_1.isEnergySkill = true
				end
			end
		end
	end

	if var_0_21 then
		for iter_51_2, iter_51_3 in pairs(var_0_15) do
			if var_0_24 then
				return
			end

			if arg_51_0:checkEnergySkill(iter_51_3) and iter_51_3:initEnergySkill(var_0_22) then
				arg_51_0:jsonInsertEnergy(iter_51_3)

				if next(iter_51_3.preUnits_) then
					iter_51_3:setSkillIndex()

					iter_51_3.isEnergySkill = true
				end
			end
		end
	end
end

function var_0_1.checkBuff(arg_52_0)
	arg_52_0:updateLeftIntervals()
	arg_52_0:updateBuffEffect()
	arg_52_0:updateBuffState()
	arg_52_0:updatePosition()
	arg_52_0:checkSkillCircle()
end

function var_0_1.minDistanceTarget(arg_53_0, arg_53_1, arg_53_2)
	local var_53_0, var_53_1 = arg_53_1.fighterModel:getPosition()
	local var_53_2
	local var_53_3

	if not arg_53_2 then
		return
	end

	for iter_53_0, iter_53_1 in ipairs(arg_53_2) do
		if not iter_53_1:isDeath() and not iter_53_1:isAffected() and iter_53_1 ~= arg_53_1 then
			local var_53_4, var_53_5 = iter_53_1.fighterModel:getPosition()
			local var_53_6 = math.abs(var_53_0 - var_53_4)

			if not var_53_2 or var_53_6 < var_53_2 then
				var_53_2 = var_53_6
				var_53_3 = iter_53_1
			end
		end
	end

	return var_53_3
end

function var_0_1.selectTarget(arg_54_0, arg_54_1, arg_54_2, arg_54_3, arg_54_4)
	local var_54_0 = var_0_3:selectType(arg_54_4)

	if not var_54_0 or type(var_54_0) == "number" or var_54_0 == "0" then
		return {}
	end

	local var_54_1
	local var_54_2

	if arg_54_1:isAttackFriend() then
		var_54_1, var_54_2 = var_0_6[var_54_0](arg_54_1, arg_54_3, arg_54_2, arg_54_4)
	else
		var_54_1, var_54_2 = var_0_6[var_54_0](arg_54_1, arg_54_2, arg_54_3, arg_54_4)
	end

	return var_54_1, var_54_2
end

function var_0_1.unitSelectTarget(arg_55_0, arg_55_1)
	local var_55_0 = arg_55_1.skillID
	local var_55_1 = var_0_3:selectType(var_55_0)

	if not var_55_1 or type(var_55_1) == "number" or var_55_1 == "0" then
		return {}
	end

	local var_55_2

	if arg_55_1.fighter:getTeamType() == var_0_14[1]:getTeamType() then
		var_55_2 = var_0_6[var_55_1](arg_55_1.fighter, var_0_14, var_0_15, arg_55_1)
	else
		var_55_2 = var_0_6[var_55_1](arg_55_1.fighter, var_0_15, var_0_14, arg_55_1)
	end

	return var_55_2
end

function var_0_1.stopAllFighter(arg_56_0, arg_56_1)
	for iter_56_0, iter_56_1 in pairs(var_0_14) do
		if not iter_56_1:isDeath() and arg_56_1 ~= iter_56_1 then
			iter_56_1:getFighterModel():pause()
		end
	end

	for iter_56_2, iter_56_3 in pairs(var_0_15) do
		if not iter_56_3:isDeath() and arg_56_1 ~= iter_56_3 then
			iter_56_3:getFighterModel():pause()
		end
	end

	local var_56_0 = arg_56_0:getUnitLayer():getChildren()

	for iter_56_4, iter_56_5 in ipairs(var_56_0) do
		iter_56_5:pause()
	end
end

function var_0_1.resumeAllFighter(arg_57_0)
	for iter_57_0, iter_57_1 in pairs(var_0_14) do
		if not iter_57_1:isDeath() and not iter_57_1:isPause() then
			iter_57_1:getFighterModel():resume()
		end
	end

	for iter_57_2, iter_57_3 in pairs(var_0_15) do
		if not iter_57_3:isDeath() and not iter_57_3:isPause() then
			iter_57_3:getFighterModel():resume()
		end
	end

	local var_57_0 = arg_57_0:getUnitLayer():getChildren()

	for iter_57_4, iter_57_5 in ipairs(var_57_0) do
		iter_57_5:resume()
	end
end

function var_0_1.removeBlackLayer(arg_58_0, arg_58_1)
	if not arg_58_0.blackLayer then
		return
	end

	arg_58_0.blackLayer:hide()

	for iter_58_0, iter_58_1 in pairs(var_0_14) do
		iter_58_1:getFighterModel():unsetMaskColor()

		if iter_58_1.fighterModel.filterBuff_ then
			iter_58_1:getFighterModel():setMaskColor(iter_58_1.fighterModel.filterBuff_:getFilter().color)
		end
	end

	for iter_58_2, iter_58_3 in pairs(var_0_15) do
		iter_58_3:getFighterModel():unsetMaskColor()

		if iter_58_3.fighterModel.filterBuff_ then
			iter_58_3:getFighterModel():setMaskColor(iter_58_3.fighterModel.filterBuff_:getFilter().color)
		end
	end

	arg_58_0:updateZorder()
	arg_58_0:resumeAllFighter()

	var_0_24 = false
end

function var_0_1.addBlackLayer(arg_59_0, arg_59_1, arg_59_2)
	if var_0_24 then
		var_0_24 = var_0_23 + arg_59_1:getSkillPreTime()

		arg_59_1:getFighterModel():unsetMaskColor()
		transition.scaleTo(arg_59_1.fighterModel, {
			time = 0.2,
			scale = 1.1
		})
		arg_59_1:getFighterModel():resume()

		return
	end

	for iter_59_0, iter_59_1 in pairs(var_0_15) do
		if iter_59_1 ~= arg_59_1 then
			iter_59_1:getFighterModel():setMaskColor()
		end
	end

	for iter_59_2, iter_59_3 in pairs(var_0_14) do
		if iter_59_3 ~= arg_59_1 then
			iter_59_3:getFighterModel():setMaskColor()
		end
	end

	transition.scaleTo(arg_59_1.fighterModel, {
		time = 0.2,
		scale = 1.1
	})

	if not arg_59_0.blackLayer then
		arg_59_0.blackLayer = display.newColorLayer(cc.c4b(0, 0, 0, 125))

		arg_59_0.blackLayer:size(arg_59_0:getContentSize())
		arg_59_0.blackLayer:addTo(arg_59_0, 50)
	end

	arg_59_0.blackLayer:show()
	arg_59_0:stopAllFighter(arg_59_1)
	arg_59_1:getFighterModel():resume()

	var_0_24 = var_0_23 + arg_59_1:getSkillPreTime()
end

function var_0_1.canAttack(arg_60_0, arg_60_1, arg_60_2, arg_60_3)
	if arg_60_1:isDeath() or arg_60_1:isBattleUnable() then
		return false
	end

	if arg_60_1.isEnergySkill and arg_60_1.preUnits_ and next(arg_60_1.preUnits_) then
		return false
	end

	if arg_60_1.isEnergySkill then
		return true
	end

	if arg_60_1.unableMove and var_0_22 < arg_60_1.unableMove then
		return false
	end

	if arg_60_1:isWalking(var_0_22) or arg_60_1:isAdjustY(var_0_22) or var_0_24 then
		return false
	end

	local var_60_0 = false

	for iter_60_0, iter_60_1 in ipairs(arg_60_3) do
		if not iter_60_1:isDeath() and not iter_60_1:isAffected() then
			var_60_0 = true

			break
		end
	end

	if not var_60_0 then
		return false
	end

	if arg_60_1:getDistance() == 0 then
		return true
	end

	local var_60_1, var_60_2 = arg_60_1.fighterModel:getPosition()
	local var_60_3
	local var_60_4

	if arg_60_1:isAttackFriend() then
		var_60_4 = arg_60_2
	else
		var_60_4 = arg_60_3
	end

	for iter_60_2, iter_60_3 in ipairs(var_60_4) do
		if not iter_60_3:isDeath() and arg_60_1 ~= iter_60_3 then
			local var_60_5, var_60_6 = iter_60_3.fighterModel:getPosition()
			local var_60_7 = math.abs(var_60_1 - var_60_5)

			if not var_60_3 or var_60_7 < var_60_3 then
				var_60_3 = var_60_7
			end
		end
	end

	if var_60_3 and var_60_3 <= arg_60_1:getDistance() then
		return true
	else
		return false
	end
end

function var_0_1.beginSpecialAttack(arg_61_0, arg_61_1)
	if not next(arg_61_1.specialSkills) then
		return
	end

	for iter_61_0, iter_61_1 in ipairs(arg_61_1.specialSkills) do
		if not iter_61_1.createCount_ then
			local var_61_0 = iter_61_1.skillID
			local var_61_1 = var_0_3:attackIndex(var_61_0)

			if var_61_1 > 0 then
				arg_61_1:playAttack(var_61_1, var_0_22)
				arg_61_1:delayLeftInterval(arg_61_1:getIndexPlayDuration(var_61_1))
				arg_61_0:jsonInsertSpecialAttack(arg_61_1, var_61_0)
			end

			iter_61_1.createCount_ = var_0_3:pretime(var_61_0) + var_0_22

			if var_61_0 == xyd.AXE_HELIX then
				arg_61_1.specialInterval = xyd.tables.battleConfig.specialSkillInterval
			end
		end
	end
end

function var_0_1.beginAttack(arg_62_0, arg_62_1)
	if arg_62_1.startAttackTime == nil then
		arg_62_1.startAttackTime = var_0_22
		arg_62_1.preUnits_ = {}
		arg_62_1.unitSkillIDs_ = {}
		arg_62_1.childIndex_ = 1
		arg_62_1.isShowEffect = {
			self = true
		}
	end

	arg_62_1:resetLeftInterval()

	local var_62_0 = tonumber(arg_62_1:checkNextSkillID(var_0_22))
	local var_62_1 = var_0_3:type(var_62_0)

	if var_62_1 == xyd.AttackType.AD and arg_62_1:isExcuteAdCircle() or var_62_1 == xyd.AttackType.AP and arg_62_1:isExcuteApCircle() then
		return
	end

	if arg_62_1.isEnergySkill then
		arg_62_1:getFighterModel():playEnergyEffect_()

		arg_62_1.energy = arg_62_1:getDMP() / xyd.DECIMAL_BASE * xyd.ENERGY_DECIMAL_BASE

		arg_62_1:updateMpBar()

		if arg_62_1.teamType == xyd.TeamType.A or arg_62_0.campaignType == xyd.CampaignType.STORY then
			arg_62_0:addBlackLayer(arg_62_1)
		end
	end

	local var_62_2 = var_0_3:attackIndex(var_62_0)

	arg_62_0:jsonInsertAttack(arg_62_1, var_62_0)

	local var_62_3 = var_0_3:sound(var_62_0)

	if var_62_3 ~= "" then
		audio.playSound(var_62_3, false)
	end

	if arg_62_1.manualTargets and next(arg_62_1.manualTargets) then
		arg_62_1:flipX(arg_62_1.manualTargets[1]:getX() < arg_62_1:getX())
	end

	if var_0_3:move(var_62_0) ~= 0 then
		local var_62_4 = arg_62_1:getFlipX() and -1 or 1

		arg_62_1:pushMoveStack(var_0_3:moveTime(var_62_0), var_62_4 * var_0_3:move(var_62_0))
	end

	arg_62_1:playAttack(var_62_2, var_0_22, function()
		if arg_62_1.skillID == var_62_0 then
			arg_62_0:afterEnergySkill(arg_62_1)
		end
	end)
	arg_62_0:selfSkillEffect(arg_62_1)

	local var_62_5 = var_0_3:children(var_62_0)

	if var_62_5 and #var_62_5 > 1 then
		local var_62_6 = var_0_3:pretime(var_62_5[1])

		arg_62_1.unableMove = var_0_24 and arg_62_1.unableMove or arg_62_1.unableMove - var_62_6

		for iter_62_0, iter_62_1 in ipairs(var_62_5) do
			local var_62_7 = var_0_3:pretime(iter_62_1)

			var_62_7 = var_0_24 and var_62_7 - var_62_6 or var_62_7

			table.insert(arg_62_1.preUnits_, var_0_22 + var_62_7)
			table.insert(arg_62_1.unitSkillIDs_, iter_62_1)

			if var_0_3:unitNum(iter_62_1) > 1 then
				for iter_62_2 = 2, var_0_3:unitNum(iter_62_1) do
					table.insert(arg_62_1.preUnits_, var_0_22 + var_62_7 + (iter_62_2 - 1) * var_0_3:interval(iter_62_1))
					table.insert(arg_62_1.unitSkillIDs_, iter_62_1)
				end
			end
		end

		return
	end

	for iter_62_3 = 1, var_0_3:unitNum(var_62_0) do
		local var_62_8 = var_0_3:pretime(var_62_0)

		var_62_8 = var_0_24 and 0 or var_62_8

		table.insert(arg_62_1.preUnits_, var_0_22 + var_62_8 + (iter_62_3 - 1) * var_0_3:interval(var_62_0))
		table.insert(arg_62_1.unitSkillIDs_, var_62_0)
	end

	arg_62_1.unableMove = var_0_24 and arg_62_1.unableMove or arg_62_1.unableMove - var_0_3:pretime(var_62_0)
end

function var_0_1.selfSkillEffect(arg_64_0, arg_64_1)
	local var_64_0 = arg_64_1:getNextSkillID()

	if not var_0_3:selfResource(var_64_0) or var_0_3:selfResource(var_64_0) == "" then
		return
	end

	if arg_64_1.startAttackTime and arg_64_1.startAttackTime + var_0_3:selfDelay(var_64_0) <= var_0_22 and arg_64_1.isShowEffect.self then
		arg_64_1.isShowEffect.self = false

		arg_64_1:getFighterModel():playAttackEffectIfNecessary_()
	end
end

function var_0_1.createSpecialUnits(arg_65_0, arg_65_1, arg_65_2, arg_65_3, arg_65_4)
	local var_65_0 = arg_65_1.specialSkills[arg_65_4]

	if not var_65_0 then
		return
	end

	local var_65_1 = var_65_0.skillID
	local var_65_2 = var_0_3:selectType(var_65_1)
	local var_65_3 = var_0_3:speed(var_65_1)
	local var_65_4 = arg_65_0:selectTarget(arg_65_1, arg_65_2, arg_65_3, var_65_1)

	arg_65_1.unitSkillIDs_ = arg_65_1.unitSkillIDs_ or {}

	table.insert(arg_65_1.unitSkillIDs_, 1, var_65_1)

	local var_65_5 = arg_65_1:createAttacks(var_65_4, var_0_22, arg_65_4) or {}

	for iter_65_0, iter_65_1 in ipairs(var_65_5) do
		table.insert(var_0_16, iter_65_1)
	end

	table.remove(arg_65_1.unitSkillIDs_, 1)
	table.remove(arg_65_1.specialSkills, arg_65_4)

	return var_65_5
end

function var_0_1.createUnits(arg_66_0, arg_66_1, arg_66_2, arg_66_3, arg_66_4)
	local var_66_0 = arg_66_1.unitSkillIDs_[1]
	local var_66_1 = var_0_3:father(var_66_0)
	local var_66_2 = var_0_3:selectType(var_66_0)
	local var_66_3 = string.find(var_66_2, "C")
	local var_66_4 = {}

	if var_66_3 then
		local var_66_5 = arg_66_1:createToPosUnit(var_0_22, arg_66_4)

		table.insert(var_0_17, var_66_5)

		if var_66_5.resource then
			var_66_5.resource:addTo(arg_66_0:getUnitLayer())
			var_66_5.resource:pos(var_66_5:getIniPos())
			var_66_5.resource:playRepeat()
			var_66_5:rotate(var_0_22)
		end

		local var_66_6 = var_0_3:speed(var_66_0)

		if var_66_6 == 0 or var_66_2 ~= "C11" then
			local var_66_7 = arg_66_0:unitSelectTarget(var_66_5)

			if var_66_7[1] and var_66_5.unitEffectType ~= xyd.UnitEffectType.TargetFootPos then
				var_66_5:setDesition(var_66_7[1]:getX(), 250)
			elseif var_66_7[1] then
				var_66_5:setDesition(var_66_7[1]:getX(), var_66_7[1]:getY())
			else
				var_66_5:setDesition(nil, 250)
			end

			if next(var_66_7) and var_66_2 ~= "C3" then
				var_66_5.manualTargets = var_66_7
			end

			if var_66_7[1] and not var_66_7[1]:isDeath() and var_66_0 == xyd.COPY_BUFFS then
				local var_66_8 = var_66_7[1]
				local var_66_9 = {}

				for iter_66_0, iter_66_1 in ipairs(var_66_8.buffs) do
					local var_66_10 = {}

					if iter_66_1:canCopy() then
						var_66_10.id = clone(iter_66_1:getTableID())
						var_66_10.level = clone(iter_66_1:getLevel())
					end

					table.insert(var_66_9, var_66_10)
				end

				var_66_5:addExtraBuffs(var_66_9)
			end
		end

		if arg_66_1.manualPosition then
			var_66_5.manualTargets = arg_66_1.manualTargets

			if var_66_5.unitEffectType ~= xyd.UnitEffectType.TargetFootPos then
				var_66_5:setDesition(arg_66_1.manualPosition[1], 250)
			end
		elseif arg_66_1.manualTargets then
			var_66_5.manualTargets = arg_66_1.manualTargets

			if var_66_5.unitEffectType ~= xyd.UnitEffectType.TargetFootPos then
				var_66_5:setDesition(var_66_5.manualTargets[1]:getX(), 250)
			else
				var_66_5:setDesition(var_66_5.manualTargets[1]:getX(), var_66_5.manualTargets[1]:getY())
			end
		end

		if var_66_6 == 0 then
			var_66_5.arrived = true

			if var_66_5.resource then
				var_66_5.resource:pos(var_66_5.desX_, var_66_5.desY_)
			end
		end

		if arg_66_1.manualTargets or arg_66_1.manualPosition then
			arg_66_1.manualTargets = nil
			arg_66_1.manualPosition = nil
		end

		if var_66_5.resource then
			local var_66_11 = {
				from = {
					var_66_5:getIniPos()
				},
				to = {
					var_66_5.desX_,
					var_66_5.desY_
				}
			}

			arg_66_0:jsonInsertPosition(var_66_0, arg_66_4, var_66_11)
		end

		local var_66_12 = {
			var_66_5.desX_,
			var_66_5.desY_
		}
	else
		local var_66_13 = var_0_3:speed(var_66_0)
		local var_66_14

		if arg_66_1.manualTargets and not arg_66_1.manualPosition then
			var_66_14 = arg_66_1.manualTargets

			if not var_0_3:isFixedTarget(var_66_1) or not (#arg_66_1.unitSkillIDs_ > 1) then
				arg_66_1.manualTargets = nil
			end
		else
			var_66_14 = arg_66_0:selectTarget(arg_66_1, arg_66_2, arg_66_3, var_66_0)

			if var_0_3:isFixedTarget(var_66_1) and #arg_66_1.unitSkillIDs_ > 1 then
				arg_66_1.manualTargets = var_66_14
			end
		end

		arg_66_1.manualDirection = nil

		local var_66_15 = {}

		if var_66_14[1] then
			local var_66_16 = {
				var_66_14[1]:getX(),
				var_66_14[1]:getY()
			}

			if not var_66_14[1]:isDeath() and var_66_0 == xyd.COPY_BUFFS then
				local var_66_17 = var_66_14[1]

				for iter_66_2, iter_66_3 in ipairs(var_66_17.buffs) do
					local var_66_18 = {}

					if iter_66_3:canCopy() then
						var_66_18.id = clone(iter_66_3:getTableID())
						var_66_18.level = clone(iter_66_3:getLevel())
					end

					table.insert(var_66_15, var_66_18)
				end
			end
		end

		local var_66_19 = arg_66_1:createAttacks(var_66_14, var_0_22, arg_66_4) or {}

		if arg_66_1.manualPosition then
			for iter_66_4, iter_66_5 in ipairs(var_66_19) do
				iter_66_5.manualPosition_ = clone(arg_66_1.manualPosition)
			end

			arg_66_1.manualPosition = nil
		end

		if next(var_66_15) then
			for iter_66_6, iter_66_7 in ipairs(var_66_19) do
				iter_66_7:addExtraBuffs(var_66_15)
			end
		end

		if var_66_13 > 0 then
			for iter_66_8, iter_66_9 in ipairs(var_66_19) do
				table.insert(var_0_18, iter_66_9)

				if iter_66_9.resource then
					iter_66_9.resource:pos(iter_66_9:getIniPos())
					iter_66_9:rotate(var_0_22)
					iter_66_9:movePosition(var_0_22)
					iter_66_9.resource:addTo(arg_66_0:getUnitLayer())
					iter_66_9.resource:playRepeat()
					arg_66_0:jsonInsertMove(var_66_0, arg_66_4, arg_66_1.fighterIndex, iter_66_9.target.fighterIndex)
				end
			end
		else
			for iter_66_10, iter_66_11 in ipairs(var_66_19) do
				if iter_66_11.resource then
					local var_66_20 = {
						from = {
							iter_66_11:getIniPos()
						},
						to = {
							iter_66_11.desX_,
							unit,
							iter_66_11.desY_
						}
					}

					arg_66_0:jsonInsertPosition(var_66_0, arg_66_4, var_66_20)
				end

				if iter_66_11.collisionNum > 1 then
					table.insert(var_0_18, iter_66_11)
					table.insert(var_0_16, iter_66_11)

					if iter_66_11.resource and iter_66_11.unitEffectType == xyd.UnitEffectType.ShanDianLian then
						local var_66_21 = iter_66_11.resource:getSizeX() - 10

						if var_66_21 <= 0 then
							var_66_21 = 170
						end

						iter_66_11.resource:setScaleX(math.sqrt(iter_66_11.xDis_ * iter_66_11.xDis_ + iter_66_11.yDis_ * iter_66_11.yDis_) / var_66_21)
						iter_66_11.resource:setRotation(math.atan2(iter_66_11.yDis_, iter_66_11.xDis_) / math.pi * -180)
						iter_66_11.resource:addTo(arg_66_0:getUnitLayer())
						iter_66_11.resource:setAnchorPoint(0.5, 0.5)
						iter_66_11.resource:x((iter_66_11.desX_ + iter_66_11.iniX_) / 2)
						iter_66_11.resource:y((iter_66_11.desY_ + iter_66_11.iniY_) / 2)
						iter_66_11.resource:playOnce()
					end
				else
					table.insert(var_0_16, iter_66_11)

					iter_66_11.target.currentUnit_ = iter_66_11

					if iter_66_11.resource and iter_66_11.unitEffectType == xyd.UnitEffectType.ShenMieZhan then
						local var_66_22 = iter_66_11.resource:getSizeX() - 10

						if var_66_22 <= 0 then
							var_66_22 = 180
						end

						iter_66_11.resource:setScaleX(math.sqrt(iter_66_11.xDis_ * iter_66_11.xDis_ + iter_66_11.yDis_ * iter_66_11.yDis_) / var_66_22)
						iter_66_11.resource:setRotation(math.atan2(iter_66_11.yDis_, iter_66_11.xDis_) / math.pi * -180)
						iter_66_11.resource:addTo(arg_66_0:getUnitLayer())
						iter_66_11.resource:setAnchorPoint(0.5, 0.5)
						iter_66_11.resource:x((iter_66_11.desX_ + iter_66_11.iniX_) / 2)
						iter_66_11.resource:y((iter_66_11.desY_ + iter_66_11.iniY_) / 2)
						iter_66_11.resource:playOnce(function()
							if iter_66_11.target then
								iter_66_11.target.currentUnit_ = nil
							end
						end)
					end
				end
			end
		end
	end

	if arg_66_1.preUnits_ and next(arg_66_1.preUnits_) then
		table.remove(arg_66_1.preUnits_, 1)
		table.remove(arg_66_1.unitSkillIDs_, 1)
	end

	if not arg_66_1.preUnits_ or next(arg_66_1.preUnits_) == nil then
		if arg_66_1:attackReMP() then
			arg_66_0:showGuide(arg_66_1)
		end

		arg_66_1:setSkillIndex()

		arg_66_1.startAttackTime = nil
		arg_66_1.isShowEffect = nil
	end

	return units
end

function var_0_1.setSummonMonsters(arg_68_0, arg_68_1)
	arg_68_1 = arg_68_1 or {}

	local var_68_0 = arg_68_1.summoner
	local var_68_1 = arg_68_1.skill
	local var_68_2 = arg_68_1.monsterID
	local var_68_3 = arg_68_1.level
	local var_68_4 = arg_68_1.pos
	local var_68_5 = var_0_2.new({
		is_arena = arg_68_0.campaignType == xyd.CampaignType.ARENA
	})

	var_68_5:populateWithSummonInfo(var_68_2, var_68_3)
	var_68_5:setTeamType(var_68_0:getTeamType())
	var_68_5:initModels()
	var_68_5.fighterModel:addTo(arg_68_0, 100)
	var_68_5:getFighterModel():idle()
	var_68_5.fighterModel:initHeaderView(0)
	var_68_5.fighterModel:setHPProgress(1, true)
	var_68_5:getFighterModel():flipX(var_68_0:getTeamType() == xyd.TeamType.B)
	var_68_5.fighterModel:pos(var_68_4[1], var_68_4[2])
	var_68_5.fighterModel:setHPProgress(1, true)

	var_68_5.fighterIndex = var_68_0:getTeamType() == xyd.TeamType.A and "A|" .. tostring(#var_0_14 + 1) or "B|" .. tostring(#var_0_15 + 1)

	var_68_5:setFormationDelay(0)

	local var_68_6 = var_68_5:getTeamType() == xyd.TeamType.A and var_0_14 or var_0_15

	table.insert(var_68_6, var_68_5)
	table.insert(var_0_26, var_68_5)
	arg_68_0:updateZorder()
end

function var_0_1.showGuide(arg_69_0, arg_69_1)
	if arg_69_1:getTeamType() == xyd.TeamType.B or arg_69_1.isPlaySkill then
		return
	end

	arg_69_1.playGuide_ = true
end

function var_0_1.checkAttackUnits(arg_70_0)
	for iter_70_0 = #var_0_18, 1, -1 do
		local var_70_0 = var_0_18[iter_70_0]

		if var_70_0.arrived and var_70_0.speed > 0 then
			if var_70_0.collisionNum > 1 then
				if not table.keyof(var_0_16, var_70_0) then
					table.insert(var_0_16, var_70_0)
				end
			else
				if var_70_0.resource then
					var_70_0.resource:stop()
				end

				if not table.keyof(var_0_16, var_70_0) then
					table.insert(var_0_16, var_70_0)
				end

				table.remove(var_0_18, iter_70_0)
			end

			if var_70_0.isApply then
				table.removebyvalue(var_0_16, var_70_0)

				var_70_0.collisionNum = var_70_0.collisionNum - 1

				local var_70_1 = arg_70_0:unitSelectTarget(var_70_0)

				if next(var_70_1) then
					var_70_0:resetTarget(var_70_1[1])

					var_70_0.applyCount = var_0_22
					var_70_0.isApply = nil
					var_70_0.arrived = false
				end
			end
		elseif var_70_0.speed > 0 then
			var_70_0:rotate(var_0_22)
			var_70_0:movePosition(var_0_22)

			if var_70_0.isResetTarget and var_70_0.target:isDeath() then
				local var_70_2 = arg_70_0:unitSelectTarget(var_70_0)

				if var_70_2 and next(var_70_2) then
					var_70_0:resetTarget(var_70_2[1])
				end
			end
		elseif var_70_0.speed == 0 and var_70_0:getCollisionCount() and var_70_0:getCollisionCount() < var_0_22 then
			if var_70_0.collisionNum > 1 then
				var_70_0.collisionNum = var_70_0.collisionNum - 1

				local var_70_3 = arg_70_0:unitSelectTarget(var_70_0)

				if next(var_70_3) then
					var_70_0:resetTarget(var_70_3[1])
				else
					var_70_0.collisionNum = 1

					table.remove(var_0_18, iter_70_0)

					return
				end
			else
				table.remove(var_0_18, iter_70_0)
			end

			var_70_0.applyCount = var_0_22
			var_70_0.isApply = nil

			if var_70_0.resource and var_70_0.unitEffectType == xyd.UnitEffectType.ShanDianLian and #var_70_0.targets_ > 1 then
				local var_70_4 = var_70_0.targets_[#var_70_0.targets_ - 1]
				local var_70_5 = var_70_0.target
				local var_70_6 = var_70_4:getX() + var_70_4:getFighterModel().attackedPoint.x
				local var_70_7 = var_70_5:getX() + var_70_5:getFighterModel().attackedPoint.x
				local var_70_8 = var_70_4:getY() + var_70_4:getFighterModel().attackedPoint.y
				local var_70_9 = var_70_5:getY() + var_70_5:getFighterModel().attackedPoint.y
				local var_70_10 = var_70_0:createResource()
				local var_70_11 = var_70_10:getSizeX() - 10

				if var_70_11 < 0 then
					var_70_11 = 170
				end

				var_70_10:addTo(arg_70_0:getUnitLayer())
				var_70_10:setScaleX(math.sqrt((var_70_7 - var_70_6) * (var_70_7 - var_70_6) + (var_70_9 - var_70_8) * (var_70_9 - var_70_8)) / var_70_11)
				var_70_10:setRotation(math.atan2(var_70_9 - var_70_8, var_70_7 - var_70_6) / math.pi * -180)
				var_70_10:x((var_70_7 + var_70_6) / 2)
				var_70_10:y((var_70_9 + var_70_8) / 2)
				var_70_10:playOnce()
			end
		end
	end
end

function var_0_1.checkMoveUnits(arg_71_0)
	for iter_71_0 = #var_0_17, 1, -1 do
		if next(var_0_17) and var_0_17[iter_71_0].arrived then
			local var_71_0 = var_0_17[iter_71_0]

			table.remove(var_0_17, iter_71_0)

			if var_71_0.resource then
				var_71_0.resource:stop()
			end

			if var_71_0:getAreaResource() then
				local var_71_1 = var_71_0.unitEffectType == xyd.UnitEffectType.TargetFootPos and var_71_0.desY_ or 250

				var_71_0:getAreaResource():addTo(arg_71_0:getUnitLayer())
				var_71_0:getAreaResource():pos(var_71_0.desX_, var_71_1)
				var_71_0:getAreaResource():playOnce()
				var_71_0:getAreaResource():setFlipX(var_71_0.fighter:getX() > var_71_0.desX_)
			end

			local var_71_2 = arg_71_0:unitSelectTarget(var_71_0)

			if next(var_71_2) then
				local var_71_3 = var_71_0:createAttacks(var_71_2, var_0_22)

				for iter_71_1, iter_71_2 in ipairs(var_71_3) do
					table.insert(var_0_16, iter_71_2)
				end
			end
		elseif var_0_17[iter_71_0] ~= nil then
			var_0_17[iter_71_0]:rotate(var_0_22)

			local var_71_4 = var_0_17[iter_71_0]

			var_71_4:movePosition(var_0_22, handler(var_71_4, function(arg_72_0)
				if arg_72_0.selectType == "C11" then
					local var_72_0 = arg_71_0:unitSelectTarget(arg_72_0)

					if next(var_72_0) then
						local var_72_1 = arg_72_0:createAttacks(var_72_0, 0)

						for iter_72_0, iter_72_1 in ipairs(var_72_1) do
							table.insert(var_0_16, iter_72_1)
						end
					end
				end
			end))
		end
	end
end

function var_0_1.checkUnits(arg_73_0)
	arg_73_0:checkMoveUnits()
	arg_73_0:checkAttackUnits()
end

function var_0_1.checkAttack(arg_74_0, arg_74_1, arg_74_2)
	for iter_74_0, iter_74_1 in ipairs(arg_74_1) do
		local var_74_0 = false

		for iter_74_2, iter_74_3 in ipairs(iter_74_1.specialSkills) do
			if xyd.SOUL_SONG_SKILL == iter_74_3.skillID then
				var_74_0 = true

				break
			end
		end

		if iter_74_1:isDeath() ~= true and not iter_74_1:isBattleUnable() or var_74_0 then
			arg_74_0:beginSpecialAttack(iter_74_1)

			if arg_74_0:canAttack(iter_74_1, arg_74_1, arg_74_2) == true and iter_74_1:getLeftInterval() and iter_74_1:getLeftInterval() <= 0 then
				arg_74_0:beginAttack(iter_74_1)
			end

			arg_74_0:selfSkillEffect(iter_74_1)

			local var_74_1 = iter_74_1.specialSkills

			for iter_74_4 = #var_74_1, 1, -1 do
				local var_74_2 = var_74_1[iter_74_4]

				if var_74_2.createCount_ and var_74_2.createCount_ <= var_0_22 then
					arg_74_0:createSpecialUnits(iter_74_1, arg_74_1, arg_74_2, iter_74_4)
				end
			end

			if not iter_74_1:isDeath() then
				while iter_74_1.preUnits_ and next(iter_74_1.preUnits_) ~= nil and iter_74_1.preUnits_[1] < var_0_22 do
					arg_74_0:createUnits(iter_74_1, arg_74_1, arg_74_2, iter_74_1.childIndex_)

					iter_74_1.childIndex_ = iter_74_1.childIndex_ + 1
				end
			end
		end
	end
end

function var_0_1.checkAttacks(arg_75_0)
	arg_75_0:checkAttack(var_0_14, var_0_15)
	arg_75_0:checkAttack(var_0_15, var_0_14)
end

function var_0_1.checkSkillBreak(arg_76_0, arg_76_1, arg_76_2)
	if arg_76_2 == xyd.BreakSkillType.AP then
		if arg_76_1:getCurrentSkillType() == xyd.AttackType.AP or arg_76_1:getCurrentSkillType() == xyd.AttackType.CURE then
			arg_76_1.startAttackTime = nil
			arg_76_1.isShowEffect = nil

			if arg_76_1.preUnits_ and next(arg_76_1.preUnits_) then
				arg_76_1.fighterModel:playFloatText({
					xyd.BattleFloatType.BREAK
				}, arg_76_1:getTeamType())
			end

			arg_76_1:skillIsBreak()

			if arg_76_1.currentUnit_ and arg_76_1.currentUnit_.resource and not tolua.isnull(arg_76_1.currentUnit_.resource) then
				arg_76_1.currentUnit_.resource:removeSelf()

				arg_76_1.currentUnit_ = nil
			end
		end
	elseif arg_76_2 == xyd.BreakSkillType.AD then
		if arg_76_1:isAdBreakImmortal() then
			return
		end

		arg_76_1:setBreakInterval()
		arg_76_1:attacked(var_0_22)

		if arg_76_1:getCurrentSkillType() == xyd.AttackType.AD then
			arg_76_1.startAttackTime = nil
			arg_76_1.isShowEffect = nil

			if arg_76_1.currentUnit_ and arg_76_1.currentUnit_.resource and not tolua.isnull(arg_76_1.currentUnit_.resource) then
				arg_76_1.currentUnit_.resource:removeSelf()

				arg_76_1.currentUnit_ = nil
			end

			if arg_76_1.preUnits_ and next(arg_76_1.preUnits_) then
				arg_76_1.fighterModel:playFloatText({
					xyd.BattleFloatType.BREAK
				}, arg_76_1:getTeamType())
			end

			arg_76_1:skillIsBreak()
		end
	end
end

function var_0_1.hurtSkillEffect(arg_77_0, arg_77_1)
	local var_77_0 = arg_77_1.fighter
	local var_77_1 = arg_77_1.target
	local var_77_2 = arg_77_1.skillID
	local var_77_3, var_77_4 = var_0_3:hurtResource(var_77_2)

	if not var_77_3 or not var_77_4 or var_77_3 == "" or var_77_4 == "" then
		return
	end

	local var_77_5 = var_77_1:getFighterModel().attackedPoint.x
	local var_77_6 = var_77_1:getFighterModel().attackedPoint.y
	local var_77_7 = var_0_4.new(var_77_2, "hurt", var_77_0:getScale())

	if var_0_3:hurtEffectType(var_77_2) == xyd.hurtEffectType.Back then
		var_77_7:addTo(arg_77_0:getUnitLayer())
		var_77_7:x(var_77_5 + var_77_1:getX()):y(var_77_6 + var_77_1:getY())
	else
		var_77_7:addTo(var_77_1.fighterModel:getBuffLayer())
		var_77_7:x(var_77_5):y(var_77_6)
	end

	var_77_7:playOnce()
end

function var_0_1.playDie_(arg_78_0, arg_78_1)
	if arg_78_1:isHasReviveBuff() and arg_78_1.reviveCount or arg_78_1.playDrop_ then
		return
	end

	arg_78_1.energy = 0

	arg_78_1:updateMpBar()

	if arg_78_1:isBuffMove() and arg_78_1.initPosition then
		local var_78_0 = arg_78_1.initPosition[2] - arg_78_1:getY()

		transition.moveBy(arg_78_1.fighterModel, {
			time = 0.3,
			y = var_78_0
		})
	end

	local var_78_1 = arg_78_1:getFighterModel()
	local var_78_2 = xyd.tables.battleConfig.removeHeroModelDuration

	var_78_1:stopAttackEffect_()
	var_78_1:resume()

	if not arg_78_1:isHasReviveBuff() then
		arg_78_1:cleanAllBuffs(var_0_22)
	end

	arg_78_1:removeTargetCircle(nil, true)

	arg_78_1.playDrop_ = not arg_78_1:isHasReviveBuff()
	arg_78_1.reviveCount = arg_78_1:isHasReviveBuff() and var_0_22 + xyd.tables.battleConfig.reviveCount

	arg_78_1.fighterModel:hideHeaderView()
	var_78_1:die(function()
		if not arg_78_1:isHasReviveBuff() then
			arg_78_1.fighterModel:runActionOnce(cc.FadeOut:create(var_78_2), false, function()
				arg_78_1.fighterModel:setVisible(false)
				var_78_1:stop()
			end)
		end
	end)
end

function var_0_1.playDrop(arg_81_0, arg_81_1)
	if not arg_81_0.dropItems or not arg_81_1.dropIndex or arg_81_1:isHasReviveBuff() then
		return
	end

	local var_81_0 = false
	local var_81_1 = 0
	local var_81_2, var_81_3 = arg_81_1.fighterModel:getPosition()
	local var_81_4 = math.min(var_81_2, xyd.STAGE_WIDTH - 100)

	for iter_81_0, iter_81_1 in ipairs(arg_81_0.dropItems) do
		if iter_81_1.drop_[1] == arg_81_0.group_ and iter_81_1.drop_[2] == arg_81_1.dropIndex then
			local var_81_5 = "skeletons/ui_effect/common_effect_shine_box/common_effect_shine_box"
			local var_81_6 = var_0_5.new(var_81_5 .. ".json", var_81_5 .. ".atlas", 1)
			local var_81_7 = display.newNode()

			var_81_7:size(100, 100)
			var_81_7:setAnchorPoint(cc.p(0, 0))
			var_81_7:addTo(arg_81_0, 120)
			var_81_6:align(display.CENTER, var_81_7:getWidth() / 2, var_81_7:getHeight() / 2):addTo(var_81_7)
			var_81_6:play(nil, true)
			var_81_6:setTouchSwallowEnabled(false)
			var_81_7:pos(var_81_4, var_81_3)

			local var_81_8 = xyd.tables.battleConfig.itemDropOffY
			local var_81_9 = xyd.tables.battleConfig.itemDropOffX + var_81_1 * 80
			local var_81_10 = math.min(var_81_9 + var_81_4, xyd.STAGE_WIDTH - 100)
			local var_81_11 = var_81_3 + var_81_8
			local var_81_12 = math.min(2 * var_81_9 + var_81_4, xyd.STAGE_WIDTH - 100)
			local var_81_13 = {
				cc.p(0, 0),
				cc.p(var_81_10 - var_81_4, var_81_8),
				cc.p(var_81_12 - var_81_4, 170 - var_81_3)
			}
			local var_81_14 = cc.CardinalSplineBy:create(0.5, var_81_13, 0)

			iter_81_1.sprite = var_81_7
			var_81_7.item = iter_81_1

			table.insert(arg_81_0.showAward_, iter_81_1)

			arg_81_0.dropAwardCount = arg_81_0.dropAwardCount + 1

			var_81_7:setTouchSwallowEnabled(false)
			var_81_7:runActionOnce(var_81_14, false, function()
				var_81_7:setTouchEnabled(true)
				var_81_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_83_0)
					if arg_83_0.name == "ended" then
						arg_81_0:showAwardAction(iter_81_1)
					end

					return true
				end)
			end)

			var_81_1 = var_81_1 + 1
			var_81_0 = true
		end
	end

	if var_81_0 then
		audio.playSound(xyd.tables.sound:getSound("battle_loot"))
	end

	if arg_81_1.dropMana > 0 then
		arg_81_1.fighterModel:playManaDrop(arg_81_1.dropMana)

		arg_81_0.dropManaCount = arg_81_0.dropManaCount + arg_81_1.dropMana

		var_0_10:getTongqianLabel():setString(arg_81_0.dropManaCount)
	end
end

function var_0_1.showAwardAction(arg_84_0, arg_84_1)
	if arg_84_1.isShow then
		return
	end

	var_0_10:getAwardLabel():setString(arg_84_0.dropAwardCount)

	local var_84_0 = arg_84_1.sprite
	local var_84_1 = display.newNode()

	var_84_1:size(100, 100)
	xyd.setItemBorder(var_84_1, arg_84_1:getTableID())
	var_84_1:setAnchorPoint(cc.p(0, 0))
	var_84_1:addTo(var_0_10, 10)
	var_84_1:setScale(0)

	local var_84_2 = var_0_10:convertToNodeSpace(cc.p(var_84_0:getPosition()))

	var_84_1:setPosition(var_84_2)

	local var_84_3 = cc.Spawn:create(cc.ScaleTo:create(0.2, 1), cc.MoveBy:create(0.2, cc.p(0, 50)))
	local var_84_4 = cc.Spawn:create(cc.ScaleTo:create(0.5, 0.2), cc.MoveTo:create(0.5, cc.p(var_0_10:getAwardLabel():getPosition())))
	local var_84_5 = cc.Sequence:create(var_84_3, cc.DelayTime:create(0.3), var_84_4)

	var_84_1:runActionOnce(var_84_5, true)
	var_84_0:removeSelf()

	arg_84_1.isShow = true
end

function var_0_1.applyHarm(arg_85_0)
	for iter_85_0, iter_85_1 in ipairs(var_0_16) do
		local var_85_0 = iter_85_1.target
		local var_85_1 = iter_85_1.fighter

		if iter_85_1.isApply == nil and var_85_0 and iter_85_1.applyCount and iter_85_1.applyCount < var_0_22 and (var_85_0:isAffected() or var_85_0:isDeath()) then
			iter_85_1.isApply = true
		elseif iter_85_1.isApply == nil and var_85_0 and iter_85_1.applyCount and iter_85_1.applyCount < var_0_22 then
			iter_85_1.isApply = true

			if var_85_0:isDeath() then
				return
			end

			if iter_85_1:getHitSound() ~= "" then
				audio.playSound(iter_85_1:getHitSound())
			end

			if var_0_24 then
				var_85_0:getFighterModel():unsetMaskColor()

				if v.fighterModel.filterBuff_ then
					v:getFighterModel():setMaskColor(v.fighterModel.filterBuff_:getFilter().color)
				end

				if not var_85_0:isPause() then
					var_85_0:getFighterModel():resume()
				end
			end

			local var_85_2, var_85_3, var_85_4, var_85_5, var_85_6, var_85_7 = iter_85_1:calculate()
			local var_85_8 = {
				fighter = iter_85_1.fighter.fighterIndex,
				target = iter_85_1.target.fighterIndex,
				skillID = iter_85_1.skillID,
				isShanBi = var_85_2,
				isBaoJi = var_85_3,
				harm = var_85_4,
				cure = var_85_5,
				xixue = var_85_6,
				mp = var_85_7
			}
			local var_85_9 = false

			if iter_85_1.attackType == xyd.AttackType.CURE then
				arg_85_0:hurtSkillEffect(iter_85_1)

				local var_85_10 = math.min(var_85_0:getHpLimit(), var_85_0:getHp() + var_85_5)

				var_85_0:updateHp(var_85_10, var_0_22)

				if var_85_5 > 0 then
					var_85_0.fighterModel:playHPDeltas({
						{
							var_85_5,
							var_85_3
						}
					}, nil)
				end

				if var_85_7 ~= 0 then
					if var_85_0:addMp(var_85_7) then
						arg_85_0:showGuide(var_85_0)
					end

					var_85_0.fighterModel:playEnergyFloat(var_85_7)
				end
			else
				if iter_85_1.attackType == xyd.AttackType.AD and var_85_0.hero:getSkillLevelByID(xyd.AXE_HELIX) and var_85_0.hero:getSkillLevelByID(xyd.AXE_HELIX) > 0 and var_85_0:getSpecialInterval() == 0 and var_85_0.preUnits_ and next(var_85_0.preUnits_) == nil and xyd.weightedChoise({
					xyd.tables.battleConfig.helixRate,
					1 - xyd.tables.battleConfig.helixRate
				}) == 1 then
					table.insert(var_85_0.specialSkills, {
						skillID = xyd.AXE_HELIX
					})
				end

				if var_85_2 == false then
					if var_85_7 ~= 0 then
						if var_85_0:addMp(var_85_7) then
							arg_85_0:showGuide(var_85_0)
						end

						var_85_0.fighterModel:playEnergyFloat(var_85_7)
					end

					if var_85_0:isImmortal(iter_85_1.attackType) then
						var_85_4 = 0

						local var_85_11 = iter_85_1.attackType == xyd.AttackType.AD and xyd.BattleFloatType.AD_IMMORTAL or xyd.BattleFloatType.AP_IMMORTAL

						var_85_0.fighterModel:playFloatText({
							var_85_11
						}, var_85_0:getTeamType())

						var_85_6 = 0
						var_85_9 = iter_85_1.attackType == xyd.AttackType.AP
					else
						local var_85_12 = clone(var_85_4)

						var_85_4, rehp = var_85_0:getDHarmBuff(var_85_4, iter_85_1.attackType)

						if var_85_4 < var_85_12 and var_85_4 == 0 then
							local var_85_13 = iter_85_1.attackType == xyd.AttackType.AD and xyd.BattleFloatType.AD_IMMORTAL or xyd.BattleFloatType.AP_IMMORTAL

							var_85_0.fighterModel:playFloatText({
								var_85_13
							}, var_85_0:getTeamType())

							var_85_9 = iter_85_1.attackType == xyd.AttackType.AP
						end

						if rehp > 0 then
							local var_85_14 = math.min(var_85_0:getHpLimit(), var_85_0:getHp() + rehp)

							var_85_0:updateHp(var_85_14, var_0_22)
						end
					end

					if (var_85_4 > var_85_0:getHpLimit() * xyd.SHOW_HURT_EFFECT_RATE and not var_85_0.isEnergySkill and not var_0_24 or iter_85_1:isForceBreak()) and not var_85_0:isAdBreakImmortal() then
						var_85_0.startAttackTime = nil
						var_85_0.isShowEffect = nil

						var_85_0:setBreakInterval()
						var_85_0:attacked(var_0_22)

						if var_85_0.preUnits_ and next(var_85_0.preUnits_) then
							var_85_0.fighterModel:playFloatText({
								xyd.BattleFloatType.BREAK
							}, var_85_0:getTeamType())
						end

						var_85_0:skillIsBreak()

						if iter_85_1:hitMove() ~= 0 then
							local var_85_15 = var_85_1:getX() > var_85_0:getX() and -1 or 1

							var_85_0:pushMoveStack(iter_85_1:hitMoveTime(), var_85_15 * iter_85_1:hitMove())
						end
					end

					local var_85_16 = var_85_4 - var_85_0:getHp()
					local var_85_17 = math.max(0, var_85_0:getHp() - var_85_4)
					local var_85_18 = clone(var_85_4)

					if var_85_16 > 0 then
						var_85_17 = var_85_0:getLastDHarmBuff(var_85_16, iter_85_1.attackType) > 0 and 0 or 1
					end

					local var_85_19 = var_85_0:getHp() - var_85_17

					iter_85_1.fighter.harms = iter_85_1.fighter.harms + var_85_19

					var_85_0:updateHp(var_85_17, var_0_22)

					if var_85_0:updateMP(var_85_19) then
						arg_85_0:showGuide(var_85_0)
					end

					arg_85_0:hurtSkillEffect(iter_85_1)

					if iter_85_1.skillID == xyd.REVENGE_SKILL then
						local var_85_20 = var_85_1:getX()
						local var_85_21 = var_85_1:getY()
						local var_85_22 = var_85_0:getX()
						local var_85_23 = var_85_0:getY()

						var_85_1.fighterModel:pos(var_85_22, var_85_23)
						var_85_1:flipX(var_85_20 < var_85_22)
						var_85_0.fighterModel:pos(var_85_20, var_85_21)
						var_85_0:flipX(var_85_22 < var_85_20)

						local var_85_24 = var_85_1.hero:getSkillLevelByID(xyd.REVENGE_SKILL_GREEN)

						if var_85_24 and var_85_24 > 0 then
							table.insert(var_85_1.startCircle, 1, xyd.REVENGE_SKILL_GREEN)

							var_85_1.manualTargets = {
								var_85_0
							}
							var_85_1.leftInterval = 10
						end
					end

					if var_85_19 > 0 then
						local var_85_25 = math.max(1, var_85_18)

						var_85_0.fighterModel:playHPDeltas({
							{
								-var_85_25,
								var_85_3
							}
						}, nil)
					end

					if not var_85_1:isDeath() and var_85_6 > 0 then
						local var_85_26 = math.min(var_85_1:getHpLimit(), var_85_1:getHp() + var_85_6)

						var_85_1:updateHp(var_85_26, var_0_22)
						var_85_1.fighterModel:playHPDeltas({
							{
								var_85_6,
								false
							}
						}, nil)
					end

					if var_85_0:isDeath() then
						arg_85_0:playDie_(var_85_0)
						arg_85_0:playDrop(var_85_0)

						if var_85_0.deathSound ~= "" then
							audio.playSound(var_85_0.deathSound, false)
						end
					end
				else
					var_85_0.fighterModel:playFloatText({
						xyd.BattleFloatType.MISS
					}, var_85_0:getTeamType())
				end
			end

			if iter_85_1:hasBuff() and not var_85_9 and not var_85_0:isDeath() then
				local var_85_27, var_85_28 = iter_85_1:getBuffInfo(var_0_22)

				if not var_85_27.isBuffHit then
					var_85_0.fighterModel:playFloatText({
						xyd.BattleFloatType.BUFF_MISS
					}, var_85_0:getTeamType())
				end

				var_85_8.buffHit = var_85_27.isBuffHit

				local var_85_29
				local var_85_30

				for iter_85_2, iter_85_3 in ipairs(var_85_28) do
					if iter_85_3:isHit() then
						if iter_85_3:getRemoveSkill() > 0 and not iter_85_1.manualPosition_ and iter_85_3:getYx() > 0 then
							local var_85_31 = iter_85_3:getRemoveSkill()
							local var_85_32 = var_0_3:selectType(var_85_31)
							local var_85_33 = var_85_1:getTeamType() == xyd.TeamType.A and var_0_14 or var_0_15
							local var_85_34 = var_85_1:getTeamType() == xyd.TeamType.A and var_0_15 or var_0_14
							local var_85_35 = var_0_6.B17(var_85_1, var_85_33, var_85_34)

							if var_85_35[1] then
								if var_85_35[1] == var_85_0 then
									iter_85_3:resetYXChange(var_85_35[1]:getX() + 1)
								else
									iter_85_3:resetYXChange(var_85_35[1]:getX())
								end
							end
						end

						if iter_85_3:isAttackFriend() then
							var_85_0.startAttackTime = nil
							var_85_0.isShowEffect = nil

							if var_85_0.preUnits_ and next(var_85_0.preUnits_) then
								var_85_0.fighterModel:playFloatText({
									xyd.BattleFloatType.BREAK
								}, var_85_0:getTeamType())
							end

							var_85_0:skillIsBreak()
						end

						var_85_0:addBuffs({
							iter_85_3
						})

						var_85_29 = var_85_29 or iter_85_3:canBreakSkill("ad")
						var_85_30 = var_85_30 or iter_85_3:canBreakSkill("ap")
					end
				end

				if var_85_29 then
					arg_85_0:checkSkillBreak(var_85_0, xyd.BreakSkillType.AD)
				end

				if var_85_30 then
					arg_85_0:checkSkillBreak(var_85_0, xyd.BreakSkillType.AP)
				end

				local var_85_36, var_85_37, var_85_38 = iter_85_1:getExtraBuffs(var_0_22)

				var_85_0:addBuffs(var_85_36)

				if (not var_85_27.breakAdSkill or not var_85_27.isBuffHit) and var_85_38 then
					arg_85_0:checkSkillBreak(var_85_0, xyd.BreakSkillType.AD)
				end

				if (not var_85_27.breakApSkill or not var_85_27.isBuffHit) and var_85_37 then
					arg_85_0:checkSkillBreak(var_85_0, xyd.BreakSkillType.AP)
				end

				if iter_85_1.skillID == xyd.COPY_BUFFS and var_85_1.hero:getSkillLevelByID(xyd.COPY_BUFFS_DHARM) and var_85_1.hero:getSkillLevelByID(xyd.COPY_BUFFS_DHARM) > 0 then
					local var_85_39 = var_0_3:buffs(xyd.COPY_BUFFS)
					local var_85_40 = 0

					for iter_85_4, iter_85_5 in ipairs(var_85_39) do
						if var_85_40 < var_85_1:getBuffNumByID(iter_85_5) then
							var_85_40 = var_85_1:getBuffNumByID(iter_85_5)
						end
					end

					if var_85_40 < xyd.MAX_COPY_DHARMS then
						table.insert(var_85_0.specialSkills, {
							skillID = xyd.COPY_BUFFS_DHARM
						})
					end
				end
			end

			arg_85_0:jsonInsertApply(var_85_8)
		end
	end
end

function var_0_1.applyBuffHarm(arg_86_0)
	local var_86_0 = xyd.tables.battleConfig.buffHarmBaseDuration

	if var_0_22 % var_86_0 > 0 then
		return
	end

	local var_86_1 = false

	for iter_86_0, iter_86_1 in ipairs(var_0_14) do
		if not iter_86_1:isDeath() and not iter_86_1:isAffected() then
			local var_86_2 = iter_86_1:applyBuffHarm(var_0_22)

			if iter_86_1:isDeath() then
				if var_86_2 and not var_86_2:isDeath() then
					var_86_2.energy = math.min(var_86_2.energy + xyd.KILL_RE_MP, xyd.ENERGY_DECIMAL_BASE)

					if var_86_2:updateMpBar() then
						arg_86_0:showGuide(var_86_2)

						var_86_1 = true
					end

					var_86_2.fighterModel:playFloatText({
						xyd.BattleFloatType.KILLING
					}, var_86_2:getTeamType())
				end

				arg_86_0:playDie_(iter_86_1)

				if iter_86_1.deathSound ~= "" then
					audio.playSound(iter_86_1.deathSound, false)
				end
			end
		end
	end

	for iter_86_2, iter_86_3 in ipairs(var_0_15) do
		if not iter_86_3:isDeath() and not iter_86_3:isAffected() then
			local var_86_3 = iter_86_3:applyBuffHarm(var_0_22)

			if iter_86_3:isDeath() then
				if var_86_3 and not var_86_3:isDeath() then
					var_86_3.energy = math.min(var_86_3.energy + xyd.KILL_RE_MP, xyd.ENERGY_DECIMAL_BASE)

					if var_86_3:updateMpBar() then
						arg_86_0:showGuide(var_86_3)

						var_86_1 = true
					end

					var_86_3.fighterModel:playFloatText({
						xyd.BattleFloatType.KILLING
					}, var_86_3:getTeamType())
				end

				arg_86_0:playDie_(iter_86_3)
				arg_86_0:playDrop(iter_86_3)

				if iter_86_3.deathSound ~= "" then
					audio.playSound(iter_86_3.deathSound, false)
				end
			end
		end
	end

	if var_86_1 then
		audio.playSound(xyd.tables.sound:getSound("battle_energy_full"))
	end
end

function var_0_1.checkEnd(arg_87_0, arg_87_1)
	for iter_87_0, iter_87_1 in ipairs(arg_87_1) do
		if iter_87_1:isDeath() ~= true or iter_87_1:isHasReviveBuff() then
			return false
		end
	end

	return true
end

function var_0_1.clickNextBattle(arg_88_0)
	if arg_88_0.walk2NextBattle then
		return
	end

	arg_88_0.walk2NextBattle = true
	arg_88_0.stopTimeCount_ = false

	var_0_9:nextBattleBtn():hide()

	if arg_88_0.battleID <= var_0_27 - 1 and xyd.StoryData.get():getStoryID() <= arg_88_0.battleID then
		var_0_9:showGuideNext(false)
	end

	arg_88_0:reMpHp()
end

function var_0_1.reMpHp(arg_89_0)
	local var_89_0 = false

	for iter_89_0, iter_89_1 in ipairs(var_0_14) do
		if not iter_89_1:isDeath() then
			local var_89_1 = math.min(iter_89_1:getHpLimit(), iter_89_1:getHp() + iter_89_1:getReHP())
			local var_89_2 = math.min(iter_89_1.energy + iter_89_1:getReMP(), xyd.ENERGY_DECIMAL_BASE)

			iter_89_1.fighterModel:playReHPMPFloat(var_89_1 - iter_89_1:getHp(), var_89_2 - iter_89_1.energy)

			local var_89_3 = iter_89_1.energy

			iter_89_1.energy = math.min(iter_89_1.energy + iter_89_1:getReMP(), xyd.ENERGY_DECIMAL_BASE)

			iter_89_1:updateHp(var_89_1, var_0_22)
			iter_89_1:updateMpBar()

			if iter_89_1.energy >= xyd.ENERGY_DECIMAL_BASE and var_89_3 < xyd.ENERGY_DECIMAL_BASE then
				var_89_0 = true
			end
		end
	end

	if var_89_0 then
		audio.playSound(xyd.tables.sound:getSound("battle_energy_full"))
	end
end

function var_0_1.checkEnds(arg_90_0)
	if var_0_13 - var_0_23 <= 0 then
		arg_90_0.timeOut_ = true

		arg_90_0:clear()
		arg_90_0:removeBlackLayer()

		return true
	end

	if arg_90_0:checkEnd(var_0_15) then
		if arg_90_0:hasNextGroup_() then
			local var_90_0 = var_0_9:nextBattleBtn()

			if not arg_90_0.walk2NextBattle and var_0_20 then
				arg_90_0.walk2NextBattle = true
				arg_90_0.stopTimeCount_ = false

				arg_90_0:reMpHp()

				if arg_90_0.battleID <= var_0_27 - 1 and xyd.StoryData.get():getStoryID() <= arg_90_0.battleID then
					var_0_9:showGuideNext(false)
				end

				if var_90_0:isVisible() then
					var_90_0:hide()
				else
					arg_90_0.stopTimeCount_ = true

					arg_90_0:clear()
					arg_90_0:removeBlackLayer()
					var_0_11.performWithDelayGlobal(function()
						for iter_91_0, iter_91_1 in ipairs(arg_90_0.showAward_) do
							arg_90_0:showAwardAction(iter_91_1)
						end
					end, 1)
				end
			elseif not var_0_20 and not var_90_0:isVisible() and not arg_90_0.walk2NextBattle then
				arg_90_0.stopTimeCount_ = true

				if var_0_9 then
					var_0_9:playNextBattle()

					if arg_90_0.battleID <= var_0_27 - 1 and xyd.StoryData.get():getStoryID() <= arg_90_0.battleID then
						var_0_9:showGuideNext(true)
					end
				end

				arg_90_0:clear()
				arg_90_0:removeBlackLayer()
				var_0_11.performWithDelayGlobal(function()
					for iter_92_0, iter_92_1 in ipairs(arg_90_0.showAward_) do
						arg_90_0:showAwardAction(iter_92_1)
					end
				end, 1)
			end

			return false
		end

		arg_90_0:removeBlackLayer()
		arg_90_0:clear()
		var_0_9:showGuideNext(false)

		for iter_90_0, iter_90_1 in pairs(var_0_14) do
			if not iter_90_1:isDeath() then
				iter_90_1:getFighterModel():win(true)
			end
		end

		var_0_11.performWithDelayGlobal(function()
			for iter_93_0, iter_93_1 in ipairs(arg_90_0.showAward_) do
				arg_90_0:showAwardAction(iter_93_1)
			end
		end, 1)

		return true
	elseif arg_90_0:checkEnd(var_0_14) then
		arg_90_0:removeBlackLayer()

		for iter_90_2, iter_90_3 in pairs(var_0_15) do
			if not iter_90_3:isDeath() then
				iter_90_3:getFighterModel():win(true)
			end
		end

		arg_90_0:clear()
		var_0_9:showGuideNext(false)

		return true
	end

	return false
end

function var_0_1.clear(arg_94_0)
	for iter_94_0 = #var_0_18, 1, -1 do
		if var_0_18[iter_94_0].resource then
			var_0_18[iter_94_0].resource:stop()

			var_0_18[iter_94_0].resource = nil
		end

		table.remove(var_0_18, iter_94_0)
	end

	for iter_94_1 = #var_0_16, 1, -1 do
		if var_0_16[iter_94_1].resource then
			var_0_16[iter_94_1].resource = nil
		end

		table.remove(var_0_16, iter_94_1)
	end

	for iter_94_2 = #var_0_17, 1, -1 do
		if var_0_17[iter_94_2].resource then
			var_0_17[iter_94_2].resource:stop()

			var_0_17[iter_94_2].resource = nil
		end

		table.remove(var_0_17, iter_94_2)
	end

	for iter_94_3, iter_94_4 in ipairs(var_0_14) do
		if not iter_94_4:isDeath() then
			iter_94_4:init()
		end
	end

	arg_94_0:getUnitLayer():removeAllChildren()
end

function var_0_1.isWin(arg_95_0)
	if arg_95_0.timeOut_ then
		return false
	end

	for iter_95_0, iter_95_1 in pairs(var_0_14) do
		if not iter_95_1:isDeath() then
			return true
		end
	end

	return false
end

function var_0_1.getBattleStar(arg_96_0)
	if arg_96_0.timeOut_ and arg_96_0.campaignType == xyd.CampaignType.MARCH then
		return 1
	end

	if not arg_96_0.isBattleEnded_ or arg_96_0.timeOut_ then
		return 0
	end

	local var_96_0 = 0

	for iter_96_0, iter_96_1 in pairs(var_0_14) do
		if iter_96_1:isDeath() then
			var_96_0 = var_96_0 + 1
		end
	end

	if var_96_0 == 0 then
		return 3
	elseif var_96_0 == 1 and var_96_0 < #arg_96_0.herosA then
		return 2
	elseif var_96_0 >= 2 and var_96_0 < #arg_96_0.herosA then
		return 1
	else
		return 0
	end
end

function var_0_1.getGuideLayer(arg_97_0)
	if not arg_97_0.guideLayer_ then
		arg_97_0.guideLayer_ = display.newNode()

		arg_97_0.guideLayer_:size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
		arg_97_0.guideLayer_:pos(0, 0)
		arg_97_0.guideLayer_:addTo(arg_97_0, 1)
	end

	return arg_97_0.guideLayer_
end

function var_0_1.afterEnergySkill(arg_98_0, arg_98_1)
	if arg_98_1.partnerID == xyd.monsterMaZhong or arg_98_1.partnerID == xyd.monsterZhangChunHua or arg_98_1.partnerID == xyd.monsterZhengJi then
		arg_98_0:pauseBattle(true)

		arg_98_0.stopInterval = true

		xyd.WindowManager.get():getWindow("story"):resumeBattleStory()
		var_0_9:hide()
	end
end

function var_0_1.resumeStoryWindow(arg_99_0, arg_99_1)
	if arg_99_1.isPlaySkill then
		return true
	end

	arg_99_0:pauseBattle(true)

	arg_99_1.isPlaySkill = true
	arg_99_0.stopInterval = true

	if arg_99_1.partnerID == xyd.monsterDianWei or arg_99_1.partnerID == xyd.monsterLvMeng or arg_99_1.partnerID == xyd.monsterZhangChunHua then
		xyd.WindowManager.get():getWindow("story"):resumeBattleStory()
		var_0_9:hide()
	else
		arg_99_0:checkUIEffect()
	end
end

function var_0_1.endStory(arg_100_0)
	local var_100_0 = xyd.WindowManager.get():getWindow("story")

	if var_100_0 then
		var_100_0:resumeBattleStory()
		var_100_0:endBattleStory()
		var_100_0:onEnded()
	end

	arg_100_0:pauseBattle()
end

function var_0_1.getTaishici(arg_101_0)
	for iter_101_0, iter_101_1 in ipairs(var_0_15) do
		if iter_101_1.partnerID == xyd.monsterTaiShiCi then
			return iter_101_1
		end
	end
end

function var_0_1.checkUIEffect(arg_102_0)
	for iter_102_0, iter_102_1 in ipairs(var_0_14) do
		local var_102_0 = arg_102_0:checkEnergySkill(iter_102_1)

		var_0_9:updateUIEffect(iter_102_1, var_0_14, var_102_0)

		if var_102_0 and iter_102_1.playGuide_ and arg_102_0:resumeStoryWindow(iter_102_1) then
			iter_102_1.playGuide_ = false

			if iter_102_0 <= #arg_102_0.herosA then
				if iter_102_1.partnerID == xyd.monsterMaZhong then
					local var_102_1 = arg_102_0:getTaishici()

					if var_102_1 then
						local var_102_2 = {
							x = var_102_1:getX(),
							y = var_102_1:getY()
						}

						var_0_9:storyManualHand(iter_102_0, true, var_102_2)
						var_0_9:storyGuideTalk(true, iter_102_0, 1)
						var_0_9:storyGuideManual(iter_102_0, true, var_102_1, arg_102_0:getGuideLayer())
					end
				else
					var_0_9:storyGuideHandk(true, iter_102_0)
					var_0_9:storyGuideTalk(true, iter_102_0, 2)
				end
			end
		end
	end

	for iter_102_2, iter_102_3 in ipairs(var_0_15) do
		local var_102_3 = arg_102_0:checkEnergySkill(iter_102_3)

		if var_102_3 and iter_102_3.partnerID == xyd.monsterZhangChunHua and not iter_102_3.isPlaySkill then
			arg_102_0:resumeStoryWindow(iter_102_3)
		elseif var_102_3 and iter_102_3.partnerID == xyd.monsterZhangChunHua and iter_102_3.isPlaySkill then
			arg_102_0:startInterval()
		end
	end

	if var_0_24 and type(var_0_24) == "number" and var_0_23 > var_0_24 then
		arg_102_0:removeBlackLayer()
	end
end

function var_0_1.checkState(arg_103_0)
	for iter_103_0, iter_103_1 in ipairs(var_0_14) do
		if not iter_103_1:isDeath() and iter_103_1.unableMove and var_0_22 > iter_103_1.unableMove then
			iter_103_1:resumeIdleState()
		end

		if not iter_103_1:isDeath() and iter_103_1.unableEnergySkill_ and var_0_22 > iter_103_1.unableEnergySkill_ then
			iter_103_1.unableEnergySkill_ = false
		end
	end

	for iter_103_2, iter_103_3 in ipairs(var_0_15) do
		if not iter_103_3:isDeath() and iter_103_3.unableMove and var_0_22 > iter_103_3.unableMove then
			iter_103_3:resumeIdleState()
		end

		if not iter_103_3:isDeath() and iter_103_3.unableEnergySkill_ and var_0_22 > iter_103_3.unableEnergySkill_ then
			iter_103_3.unableEnergySkill_ = false
		end
	end
end

function var_0_1.onInterval(arg_104_0)
	if arg_104_0:checkEnds() then
		arg_104_0.isBattleEnded_ = true

		arg_104_0:pauseBattle()

		if arg_104_0:isWin() then
			audio.playSound(xyd.tables.sound:getSound("battle_win"), false)
		else
			audio.playSound(xyd.tables.sound:getSound("battle_lose"), false)
		end

		arg_104_0:endStory()

		return
	end

	if arg_104_0.walk2NextBattle then
		arg_104_0:checkUIEffect()
		arg_104_0:checkMoves()

		return
	end

	arg_104_0:checkUIEffect()

	if arg_104_0.stopInterval then
		arg_104_0.stopInterval = false

		return
	end

	if not var_0_24 then
		arg_104_0:checkState()
		arg_104_0:adjustYs()
		arg_104_0:checkMoves()
	end

	arg_104_0:checkAttacks()

	if not var_0_24 then
		arg_104_0:checkUnits()
		arg_104_0:applyHarm()
		arg_104_0:applyBuffHarm()
		arg_104_0:checkBuff()

		var_0_22 = var_0_22 + 1
	end

	arg_104_0:updateTimeLabel()

	if not arg_104_0.stopTimeCount_ then
		var_0_23 = var_0_23 + 1
	end
end

function var_0_1.startBattle(arg_105_0)
	local var_105_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
	local var_105_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleTopWnd)

	if var_105_1 then
		var_105_1:hide()
	end

	if var_105_0 then
		var_105_0:show()
	end

	arg_105_0:startInterval()
end

function var_0_1.startInterval(arg_106_0)
	if not arg_106_0.handler then
		arg_106_0.handler = var_0_11.scheduleUpdateGlobal(handler(arg_106_0, arg_106_0.onInterval))
	end

	return arg_106_0.handler
end

function var_0_1.pauseBattle(arg_107_0, arg_107_1)
	if arg_107_0.handler then
		var_0_11.unscheduleGlobal(arg_107_0.handler)

		arg_107_0.handler = nil
	end

	if arg_107_1 then
		arg_107_0:stopAllFighter()
	end
end

function var_0_1.updateTimeLabel(arg_108_0)
	if var_0_22 % 10 == 0 then
		local var_108_0 = var_0_13 - var_0_23
		local var_108_1 = math.floor(var_108_0 / 1200)
		local var_108_2 = var_108_0 % 1200 / 20
		local var_108_3 = string.format("%02d:%02d", var_108_1, var_108_2)

		var_0_10:getTimeLabel():setString(var_108_3)
	end
end

function var_0_1.jsonInsertSpecialAttack(arg_109_0, arg_109_1, arg_109_2)
	if not arg_109_0.jsonSpecialAttacks_[tostring(var_0_22)] then
		arg_109_0.jsonSpecialAttacks_[tostring(var_0_22)] = {}
	end

	table.insert(arg_109_0.jsonSpecialAttacks_[tostring(var_0_22)], {
		arg_109_1.fighterIndex,
		arg_109_2
	})
end

function var_0_1.jsonInsertAttack(arg_110_0, arg_110_1, arg_110_2)
	if not arg_110_0.jsonAttacks_[tostring(var_0_22)] then
		arg_110_0.jsonAttacks_[tostring(var_0_22)] = {}
	end

	table.insert(arg_110_0.jsonAttacks_[tostring(var_0_22)], {
		arg_110_1.fighterIndex,
		arg_110_2
	})
end

function var_0_1.jsonInsertMove(arg_111_0, arg_111_1, arg_111_2, arg_111_3, arg_111_4)
	if not arg_111_0.jsonMoveUnits_[tostring(var_0_22)] then
		arg_111_0.jsonMoveUnits_[tostring(var_0_22)] = {}
	end

	table.insert(arg_111_0.jsonMoveUnits_[tostring(var_0_22)], {
		arg_111_1,
		arg_111_2,
		arg_111_3,
		arg_111_4
	})
end

function var_0_1.jsonInsertPosition(arg_112_0, arg_112_1, arg_112_2, arg_112_3)
	if not arg_112_0.jsonPositionUnits_[tostring(var_0_22)] then
		arg_112_0.jsonPositionUnits_[tostring(var_0_22)] = {}
	end

	table.insert(arg_112_0.jsonPositionUnits_[tostring(var_0_22)], {
		arg_112_1,
		arg_112_2,
		arg_112_3
	})
end

function var_0_1.jsonInsertApply(arg_113_0, arg_113_1)
	if not arg_113_0.jsonApplyUnits_[tostring(var_0_22)] then
		arg_113_0.jsonApplyUnits_[tostring(var_0_22)] = {}
	end

	table.insert(arg_113_0.jsonApplyUnits_[tostring(var_0_22)], arg_113_1)
end

function var_0_1.jsonInsertEnergy(arg_114_0, arg_114_1)
	if not arg_114_0.jsonEnergy_[tostring(var_0_22)] then
		arg_114_0.jsonEnergy_[tostring(var_0_22)] = {}
	end

	table.insert(arg_114_0.jsonEnergy_[tostring(var_0_22)], arg_114_1.fighterIndex)
end

function var_0_1.point(arg_115_0, arg_115_1, arg_115_2)
	return {
		x = arg_115_1,
		y = arg_115_2
	}
end

function var_0_1.size(arg_116_0, arg_116_1, arg_116_2)
	return {
		width = arg_116_1,
		height = arg_116_2
	}
end

function var_0_1.buttonHandler(arg_117_0, arg_117_1, arg_117_2, arg_117_3)
	if arg_117_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_117_2)
		arg_117_2:setScale(1)
		xyd.playButtonSound()

		if arg_117_1 then
			arg_117_1(arg_117_2, arg_117_3)
		end
	elseif arg_117_3 == ccui.TouchEventType.began then
		local var_117_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_117_1 = cc.RepeatForever:create(var_117_0)

		arg_117_2:runAction(var_117_1)

		return true
	elseif arg_117_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_117_2)
		arg_117_2:setScale(1)
	end
end

function var_0_1.finishBattle_(arg_118_0, arg_118_1)
	xyd.WindowManager.get():closeAllWindows()
	display.replaceScene(xyd.MainScene.new())
end

function var_0_1.closeBattleEndWindow_(arg_119_0, arg_119_1)
	arg_119_0.battleEndWindow_ = nil

	if xyd.WindowManager.get():isWindowOpen(xyd.WindowName.battleLoseWnd) then
		xyd.WindowManager.get():closeWindow(xyd.WindowName.battleLoseWnd, arg_119_1)
	else
		xyd.WindowManager.get():closeWindow(xyd.WindowName.battleWinWnd, arg_119_1)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.UPDATE_STONE_EQUIP_CAMPAIGN,
		params = {
			itemComposeID = arg_119_0.itemComposeID
		}
	})
	audio.stopMusic()
end

function var_0_1.playStoryIfNecessary_(arg_120_0, arg_120_1, arg_120_2)
	local var_120_0 = xyd.StoryData.get():getStoryID()
	local var_120_1 = arg_120_0.stories_[arg_120_1] or 0

	if var_120_1 > 0 and var_120_0 < var_120_1 then
		xyd.WindowManager.get():openWindow(STORY_WINDOW_NAME, {
			story_id = var_120_1,
			callback = arg_120_2
		})
	else
		arg_120_2({})
	end
end

function var_0_1.isBattleWin_(arg_121_0)
	if arg_121_0.isWin_ ~= nil then
		return arg_121_0.isWin_
	end

	if arg_121_0:hasNextGroup_() then
		return false
	end

	local var_121_0 = #arg_121_0.battleSimulator_.selfFormation:getAliveFighters() > 0
	local var_121_1 = #arg_121_0.battleSimulator_.enemyFormation:getAliveFighters() > 0 and arg_121_0:isBossAlive_()

	return var_121_0 and not var_121_1
end

function var_0_1.hasNextGroup_(arg_122_0)
	return arg_122_0.group_ < #arg_122_0.heroGroup
end

function var_0_1.isPvPInstance_(arg_123_0)
	return arg_123_0.instanceType_ == xyd.InstanceType.ARENA_PLAYER or arg_123_0.instanceType_ == xyd.InstanceType.ARENA_NPC or arg_123_0.instanceType_ == xyd.InstanceType.MARCH
end

function var_0_1.isPausable(arg_124_0)
	return arg_124_0.instanceType_ ~= xyd.InstanceType.ARENA_PLAYER and arg_124_0.instanceType_ ~= xyd.InstanceType.ARENA_NPC
end

function var_0_1.selfPlayer_(arg_125_0)
	return xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_1.getBackground_(arg_126_0)
	local var_126_0 = "images/maps/map_images/"

	if arg_126_0.background_ == nil then
		local var_126_1

		if type(arg_126_0.mapID_) == "number" then
			var_126_1 = xyd.tables.map:sceneBackground(arg_126_0.mapID_)
		elseif next(arg_126_0.mapID_) and arg_126_0.group_ <= #arg_126_0.mapID_ then
			var_126_1 = var_126_0 .. tostring(arg_126_0.mapID_[arg_126_0.group_]) .. ".png"
		elseif next(arg_126_0.mapID_) then
			var_126_1 = var_126_0 .. tostring(arg_126_0.mapID_[#arg_126_0.mapID_]) .. ".png"
		end

		arg_126_0.background_ = xyd.ColoredSprite.new(var_126_1):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_126_0, -1)

		arg_126_0.background_:setOpacity(255)
	end

	return arg_126_0.background_
end

function var_0_1.setupBackground_(arg_127_0)
	local var_127_0 = "images/maps/map_images/"

	if arg_127_0.background_ then
		arg_127_0.background_:removeSelf()

		arg_127_0.background_ = nil
	end

	local var_127_1

	if type(arg_127_0.mapID_) == "number" then
		var_127_1 = xyd.tables.map:sceneBackground(arg_127_0.mapID_)
	elseif next(arg_127_0.mapID_) and arg_127_0.group_ <= #arg_127_0.mapID_ then
		var_127_1 = var_127_0 .. tostring(arg_127_0.mapID_[arg_127_0.group_]) .. ".png"
	elseif next(arg_127_0.mapID_) then
		var_127_1 = var_127_0 .. tostring(arg_127_0.mapID_[#arg_127_0.mapID_]) .. ".png"
	end

	arg_127_0.background_ = xyd.ColoredSprite.new(var_127_1):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_127_0, -1)

	arg_127_0.background_:setOpacity(255)
	arg_127_0.background_:setScaleX(arg_127_0:getWidth() / arg_127_0.background_:getWidth())
	arg_127_0.background_:setScaleY(arg_127_0:getHeight() / arg_127_0.background_:getHeight())
end

function var_0_1.getUnitLayer(arg_128_0)
	if not arg_128_0.unitLayer_ then
		arg_128_0.unitLayer_ = display.newNode()

		arg_128_0.unitLayer_:size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
		arg_128_0.unitLayer_:addTo(arg_128_0, 115)
		arg_128_0.unitLayer_:align(display.LEFT_BOTTOM, 0, 0)
	end

	return arg_128_0.unitLayer_
end

function var_0_1.getSecondsPerFrame(arg_129_0)
	return 0.03333333333333333
end

function var_0_1.getexChangeRate(arg_130_0)
	local var_130_0 = cc.Director:getInstance():getDeltaTime()

	var_130_0 = var_130_0 <= 0 and 0.016666666666666666 or var_130_0

	return 60 * var_130_0
end

function var_0_1.sendStoryOperationLog(arg_131_0, arg_131_1)
	if arg_131_1 == 1 then
		arg_131_0.player:sendOperationLog(xyd.StatID.ID_DIALOG1)
	elseif arg_131_1 == 2 then
		arg_131_0.player:sendOperationLog(xyd.StatID.ID_DIALOG2)
	elseif arg_131_1 == 3 then
		arg_131_0.player:sendOperationLog(xyd.StatID.ID_DIALOG3)
	elseif arg_131_1 == 4 then
		arg_131_0.player:sendOperationLog(xyd.StatID.ID_DIALOG4)
	elseif arg_131_1 == 5 then
		arg_131_0.player:sendOperationLog(xyd.StatID.ID_DIALOG5)
	elseif arg_131_1 == 6 then
		arg_131_0.player:sendOperationLog(xyd.StatID.ID_DIALOG6)
	elseif arg_131_1 == 7 then
		arg_131_0.player:sendOperationLog(xyd.StatID.ID_DIALOG7)
	end
end

function var_0_1.sendGuideOperationLog(arg_132_0, arg_132_1)
	if arg_132_1 == 90000002 then
		arg_132_0.player:sendOperationLog(xyd.StatID.ID_CLICK_HERO1)
	elseif arg_132_1 == 90000001 then
		arg_132_0.player:sendOperationLog(xyd.StatID.ID_CLICK_HERO2)
	elseif arg_132_1 == 90000005 then
		arg_132_0.player:sendOperationLog(xyd.StatID.ID_CLICK_HERO3)
	end
end

return var_0_1
