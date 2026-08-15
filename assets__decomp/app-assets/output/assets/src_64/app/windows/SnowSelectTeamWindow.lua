local var_0_0 = class("SelectTeamWindow", import("app.windows.BaseSelectTeamWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.ActivityHero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = import("framework.scheduler")
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.hero
local var_0_7 = xyd.tables.skill
local var_0_8 = xyd.tables.activityPartnerSkill

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.selectTeamType = arg_1_2.teamType or xyd.SnowSelectTeamType.CHANGE_DEFENSE
	arg_1_0.oldDefense = arg_1_2.defense
	arg_1_0.enemyMainRole_ = arg_1_2.enemyMainRole
	arg_1_0.enemyRankInfo_ = arg_1_2.enemyRankInfo
	arg_1_0.enemyID = arg_1_2.enemy_id
	arg_1_0.mainRole_ = arg_1_0.snowActivity:getHero()
	arg_1_0.mainRoleSkill_ = {}
	arg_1_0.curSelectSkillID_ = 0
	arg_1_0.allHeros_ = nil
end

function var_0_0.layout(arg_2_0)
	var_0_0.super.layout(arg_2_0)
	arg_2_0:initSnowAvatar()
end

function var_0_0.getBattleBtn(arg_3_0)
	if not arg_3_0.battleBtn_ then
		if arg_3_0.selectTeamType == xyd.SnowSelectTeamType.BATTLE then
			arg_3_0.battleBtn_ = arg_3_0:nodeByName("button_battle")

			arg_3_0:nodeByName("button_ok"):setVisible(false)
		else
			arg_3_0.battleBtn_ = arg_3_0:nodeByName("button_ok")

			arg_3_0:nodeByName("button_battle"):setVisible(false)
		end

		arg_3_0.battleBtn_:addTouchEventListener(function(arg_4_0, arg_4_1)
			if not arg_3_0:checkCanStartBattle() then
				return
			end

			if arg_4_1 == ccui.TouchEventType.ended and not arg_3_0.battleBegan then
				xyd.playButtonSound()
				arg_3_0:beforeStartBattle()
			end
		end)
		arg_3_0.battleBtn_:setVisible(true)
	end

	return arg_3_0.battleBtn_
end

function var_0_0.initSnowAvatar(arg_5_0)
	local var_5_0 = cc.p(arg_5_0:nodeByName("avatar_pet1"):getPosition())
	local var_5_1 = display.newNode()

	var_5_1:size(146, 146)
	var_5_1:align(display.CENTER)
	xyd.setPetAvatar(var_5_1, arg_5_0.mainRole_, 100)
	var_5_1:addTo(arg_5_0)
	var_5_1:setPosition(cc.p(var_5_0))
end

function var_0_0.initEnemys(arg_6_0)
	var_0_0.super.initEnemys(arg_6_0)

	if arg_6_0.enemyMainRole_ then
		xyd.setPetAvatar(arg_6_0:nodeByName("pet_back_enemy"), arg_6_0.enemyMainRole_, 100)
		arg_6_0:nodeByName("pet_back_enemy"):setTouchEnabled(true)
		arg_6_0:nodeByName("pet_back_enemy"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				arg_6_0.prevY_ = arg_7_0.y
				arg_6_0.prevX_ = arg_7_0.x
				arg_6_0.isMove_ = false

				arg_6_0:showEnemySkill(true)
			elseif arg_7_0.name == "moved" then
				if math.abs(arg_7_0.x - arg_6_0.prevX_) > 10 or math.abs(arg_7_0.y - arg_6_0.prevY_) > 10 then
					arg_6_0.isMove_ = true

					arg_6_0:showEnemySkill(false)
				end
			elseif arg_7_0.name == "ended" and not arg_6_0.isMove_ then
				arg_6_0:showEnemySkill(false)
			end

			return true
		end)
	end
end

function var_0_0.showEnemySkill(arg_8_0, arg_8_1)
	if not arg_8_1 then
		if arg_8_0.enemySkillContainer and not tolua.isnull(arg_8_0.enemySkillContainer) then
			arg_8_0.enemySkillContainer:setVisible(false)
		end

		return
	end

	if not arg_8_0.enemySkillContainer or tolua.isnull(arg_8_0.enemySkillContainer) then
		local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_battle/snow_skill.csb")

		var_8_0:addTo(arg_8_0)

		local var_8_1 = var_8_0:getChildByName("container")

		var_8_1:getChildByName("text_title"):setString(var_0_5:translation("SNOW_ACTIVITY_ENEMY_SKILL"))

		if not arg_8_0.enemyRankInfo_.rank then
			local var_8_2 = 1001
		end

		local var_8_3 = 1
		local var_8_4 = 40

		for iter_8_0 = 4, 1, -1 do
			local var_8_5 = arg_8_0.enemyMainRole_:getSkillId(iter_8_0)

			if var_8_5 > 0 and arg_8_0.enemyMainRole_:getSkillLevelByID(var_8_5) and arg_8_0.enemyMainRole_:getSkillLevelByID(var_8_5) > 0 then
				local var_8_6 = arg_8_0:createLabel(24, cc.c3b(255, 255, 255), var_0_7:name(var_8_5))

				var_8_6:addTo(var_8_1)
				var_8_6:setAnchorPoint(cc.p(0.5, 0.5))
				var_8_6:setPosition(cc.p(150, var_8_4))

				var_8_4 = var_8_4 + 40
			end
		end

		local var_8_7 = var_8_4 + 10

		var_8_1:getChildByName("text_title"):setPositionY(var_8_7)
		var_8_1:getChildByName("title_bg"):setPositionY(var_8_7)

		local var_8_8 = var_8_7 + 50

		var_8_1:setContentSize(300, var_8_8)
		var_8_0:setPosition(cc.p(240, 570 - var_8_8))

		arg_8_0.enemySkillContainer = var_8_0
	end

	arg_8_0.enemySkillContainer:setVisible(true)
end

function var_0_0.startBattle(arg_9_0)
	local function var_9_0()
		local var_10_0 = {}
		local var_10_1 = false

		for iter_10_0 = 1, #arg_9_0.select_ do
			local var_10_2 = arg_9_0.select_[iter_10_0]:getHeroID()

			table.insert(var_10_0, var_10_2)

			if arg_9_0.oldDefense and (not arg_9_0.oldDefense[iter_10_0] or var_10_2 ~= arg_9_0.oldDefense[iter_10_0]) then
				var_10_1 = true
			end
		end

		if arg_9_0.oldDefense and #arg_9_0.oldDefense ~= #arg_9_0.select_ then
			var_10_1 = true
		end

		return var_10_0, var_10_1
	end

	if arg_9_0.selectTeamType == xyd.SnowSelectTeamType.CHANGE_DEFENSE then
		local var_9_1, var_9_2 = var_9_0()

		if not var_9_2 then
			arg_9_0.battleBegan = false

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_5:translation("SNOW_ACTIVITY_DEFENSE_TIPS")
			})

			return
		end

		local var_9_3 = {
			formation = var_9_1
		}

		arg_9_0.snowActivity:changeDefense(var_9_3, function(arg_11_0, arg_11_1)
			if arg_11_0 == xyd.error.OK then
				local var_11_0 = xyd.WindowManager.get():getWindow("snow_battle")

				if var_11_0 and not tolua.isnull(var_11_0) then
					var_11_0:updateDefense()
				end

				xyd.WindowManager.get():closeWindow(arg_9_0)
			else
				arg_9_0.battleBegan = false
			end
		end)
	elseif arg_9_0.selectTeamType == xyd.SnowSelectTeamType.BATTLE then
		arg_9_0:recordFormation()

		if FRONT_ARENA_BATTLE then
			arg_9_0:setMainRoleSkills()
			arg_9_0:startFrontBattle()

			return
		end

		local var_9_4, var_9_5 = var_9_0()
		local var_9_6 = {
			formation = var_9_4,
			enemy_id = arg_9_0.enemyID
		}

		arg_9_0.snowActivity:fightResult(var_9_6, function(arg_12_0, arg_12_1)
			if arg_12_0 == xyd.error.OK then
				arg_9_0:playReport(arg_12_1)
			else
				arg_9_0.battleBegan = false
			end
		end)
	end
end

function var_0_0.setMainRoleSkills(arg_13_0)
	if next(arg_13_0.mainRoleSkill_) then
		local var_13_0 = {}

		for iter_13_0 = 1, #arg_13_0.mainRoleSkill_ do
			arg_13_0.mainRole_:setSkillIDByIndex(iter_13_0, arg_13_0.mainRoleSkill_[iter_13_0])
		end
	end
end

function var_0_0.getHeros(arg_14_0)
	if not arg_14_0.allHeros_ or not next(arg_14_0.allHeros_) then
		local var_14_0 = {}
		local var_14_1 = arg_14_0.selfPlayer.heros_

		for iter_14_0, iter_14_1 in ipairs(var_14_1) do
			if arg_14_0:checkHeroCanJoin(iter_14_1) then
				local var_14_2 = var_0_1.new()

				var_14_2:populate(iter_14_1:toParams())
				table.insert(var_14_0, var_14_2)
			end
		end

		arg_14_0.snowActivity:formatNewHeros(var_14_0, arg_14_0.mainRole_:getLevel(), arg_14_0.mainRole_:getColor())
		arg_14_0:sortTables({
			var_14_0
		})

		arg_14_0.allHeros_ = var_14_0
	end

	return arg_14_0.allHeros_
end

function var_0_0.initHeros(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0.tmpTotalHero_[arg_15_2] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ALL] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.QIANPAI] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.HOUPAI] = {}
	arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.FILTER] = {}

	for iter_15_0, iter_15_1 in pairs(arg_15_1) do
		if arg_15_0:canHeroJoinBattle(iter_15_1) then
			if iter_15_1:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.QIANPAI], iter_15_1)
			elseif iter_15_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ZHONGPAI], iter_15_1)
			elseif iter_15_1:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.HOUPAI], iter_15_1)
			end

			table.insert(arg_15_0.tmpTotalHero_[arg_15_2][xyd.DistanceType.ALL], iter_15_1)
		end
	end

	arg_15_0.selectedHeroClass_[arg_15_2] = xyd.DistanceType.ALL
end

function var_0_0.initRightMenu(arg_16_0)
	var_0_0.super.initRightMenu(arg_16_0)
	arg_16_0:nodeByName("button_filter"):setVisible(false)
	arg_16_0:nodeByName("filter"):setVisible(false)

	local var_16_0 = cc.p(arg_16_0:nodeByName("button_filter"):getPosition())

	arg_16_0:nodeByName("button_preset"):setPosition(cc.p(var_16_0))
	arg_16_0:nodeByName("preset"):setPosition(cc.p(var_16_0))
end

function var_0_0.initLeftMenu(arg_17_0)
	arg_17_0:nodeByName("zhandui"):hide()
	arg_17_0:nodeByName("button_zhandui"):hide()
	arg_17_0:nodeByName("yongbing"):hide()
	arg_17_0:nodeByName("button_yongbing"):hide()
	arg_17_0:nodeByName("pet"):hide()
	arg_17_0:nodeByName("button_pet"):hide()
	arg_17_0:nodeByName("rate_bg"):setVisible(false)

	arg_17_0.leftMenuType_ = xyd.LeftMenuType.SELF_HERO

	arg_17_0:createNewLeftMenu()
end

function var_0_0.createNewLeftMenu(arg_18_0)
	arg_18_0:nodeByName("close"):setGlobalZOrder(10)

	local var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_battle/select_team_item.csb")
	local var_18_1 = var_18_0:getChildByName("container")

	var_18_0:addTo(arg_18_0)
	var_18_0:setPosition(cc.p(0, 215))

	local var_18_2 = var_18_1:getChildByName("list")
	local var_18_3 = var_18_2:getContentSize()

	arg_18_0.leftMenuList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_18_3.width, var_18_3.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_18_2):onScroll(handler(arg_18_0, arg_18_0.scrollListener))
	arg_18_0.curSelectSkillBtn_ = {}
	arg_18_0.skillBtnText_ = {}

	for iter_18_0 = 1, 4 do
		local var_18_4 = var_0_6:getSkillTable(arg_18_0.mainRole_:getTableID(), iter_18_0)

		for iter_18_1 = 1, #var_18_4 do
			local var_18_5 = arg_18_0.leftMenuList_:newItem()
			local var_18_6 = var_18_4[iter_18_1]
			local var_18_7 = arg_18_0:createSkillItem(iter_18_0, var_18_6)
			local var_18_8 = var_18_7:getWidth()
			local var_18_9 = var_18_7:getHeight()

			var_18_5:setItemSize(var_18_8, var_18_9)
			var_18_5:addContent(var_18_7)
			arg_18_0.leftMenuList_:addItem(var_18_5)
		end
	end

	arg_18_0.leftMenuList_:reload()
	arg_18_0:updateSkillBtnText()
end

function var_0_0.scrollListener(arg_19_0, arg_19_1)
	if arg_19_1.name == "began" then
		arg_19_0.scrollViewMoved_ = false
		arg_19_0.prevY_ = arg_19_1.y
	elseif arg_19_1.name == "moved" and 10 <= math.abs(arg_19_1.y - arg_19_0.prevY_) then
		arg_19_0.scrollViewMoved_ = true
	end
end

function var_0_0.createSkillItem(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_battle/skill_item.csb")

	var_20_0:setContentSize(180, 70)

	local var_20_1 = var_0_8:type(arg_20_2)
	local var_20_2 = var_0_8:from(arg_20_2)
	local var_20_3 = var_0_8:distanceType(arg_20_2)
	local var_20_4 = true
	local var_20_5 = var_20_0:getChildByName("btn_select")
	local var_20_6 = var_20_0:getChildByName("btn_select_purple")

	if arg_20_1 == 1 or arg_20_1 > xyd.Color2Quality[arg_20_0.mainRole_:getColor()] then
		var_20_4 = false

		if arg_20_1 == 1 then
			var_20_5:setVisible(false)
			var_20_6:setVisible(true)
			arg_20_0:updateSkillTips(arg_20_2)
			var_20_6:setTouchEnabled(false)
		else
			var_20_5:setBright(false)
			var_20_5:setTouchEnabled(false)
			var_20_6:setVisible(false)
		end
	end

	local var_20_7 = {
		skillID = arg_20_2,
		label = var_20_0:getChildByName("text_desc"),
		isShowSkill = var_20_4,
		btn = var_20_5,
		purpleBtn = var_20_6
	}

	table.insert(arg_20_0.skillBtnText_, var_20_7)

	local function var_20_8(arg_21_0)
		if arg_20_0.curSelectSkillBtn_ and next(arg_20_0.curSelectSkillBtn_) then
			arg_20_0.curSelectSkillBtn_.btn:setBrightStyle(ccui.BrightStyle.normal)
			arg_20_0.curSelectSkillBtn_.btn:setTouchEnabled(true)
			arg_20_0.curSelectSkillBtn_.purpleBtn:setBrightStyle(ccui.BrightStyle.normal)
			arg_20_0.curSelectSkillBtn_.purpleBtn:setTouchEnabled(true)
		end

		arg_20_0.curSelectSkillBtn_ = {
			btn = var_20_5,
			purpleBtn = var_20_6
		}

		var_20_5:setBrightStyle(ccui.BrightStyle.highlight)
		var_20_5:setTouchEnabled(false)
		var_20_6:setBrightStyle(ccui.BrightStyle.highlight)
		var_20_6:setTouchEnabled(false)

		arg_20_0.curSelectSkillID_ = arg_20_2

		arg_20_0:updateAllHeros(var_20_1, var_20_2, var_20_3)
		arg_20_0:updateSkillTips(arg_20_2)
	end

	var_20_5:addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended and not arg_20_0.scrollViewMoved_ and arg_20_0.curSelectSkillID_ ~= arg_20_2 then
			var_20_8(var_20_5)
		end
	end)
	var_20_6:addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended and not arg_20_0.scrollViewMoved_ and arg_20_0.curSelectSkillID_ ~= arg_20_2 then
			var_20_8(var_20_6)
		end
	end)

	return var_20_0
end

function var_0_0.updateScore(arg_24_0)
	local var_24_0 = 0

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.team_) do
		var_24_0 = var_24_0 + iter_24_1.data:getZhandouli()
	end

	if arg_24_0.mainRole_ then
		var_24_0 = var_24_0 + arg_24_0.mainRole_:getZhandouli()
	end

	arg_24_0:nodeByName("zhandouli"):setString(var_24_0)
	arg_24_0:updateSkillBtnText()
end

function var_0_0.updateSkillBtnText(arg_25_0)
	arg_25_0.mainRoleSkill_ = {}

	if arg_25_0.skillBtnText_ and next(arg_25_0.skillBtnText_) then
		for iter_25_0 = 1, #arg_25_0.skillBtnText_ do
			local var_25_0 = arg_25_0.skillBtnText_[iter_25_0].skillID
			local var_25_1 = arg_25_0.skillBtnText_[iter_25_0].label
			local var_25_2 = arg_25_0.skillBtnText_[iter_25_0].isShowSkill
			local var_25_3 = arg_25_0.skillBtnText_[iter_25_0].btn
			local var_25_4 = arg_25_0.skillBtnText_[iter_25_0].purpleBtn

			if iter_25_0 == 1 then
				table.insert(arg_25_0.mainRoleSkill_, var_25_0)
			end

			if var_25_2 then
				local var_25_5 = var_0_8:type(var_25_0)
				local var_25_6 = var_0_8:from(var_25_0)
				local var_25_7 = var_0_8:distanceType(var_25_0)
				local var_25_8 = var_0_8:partnerReq(var_25_0)
				local var_25_9 = 0

				for iter_25_1 = 1, #arg_25_0.select_ do
					if arg_25_0:checkHeroIsSelect(arg_25_0.select_[iter_25_1], var_25_5, var_25_6, var_25_7) then
						var_25_9 = var_25_9 + 1
					end
				end

				if var_25_8 <= var_25_9 then
					table.insert(arg_25_0.mainRoleSkill_, var_25_0)
					var_25_3:setVisible(false)
					var_25_4:setVisible(true)
				else
					var_25_3:setVisible(true)
					var_25_4:setVisible(false)
				end

				var_25_1:setString(var_0_7:name(var_25_0) .. "(" .. var_25_9 .. "/" .. var_25_8 .. ")")
			else
				var_25_1:setString(var_0_7:name(var_25_0))
			end
		end
	end
end

function var_0_0.checkHeroIsSelect(arg_26_0, arg_26_1, arg_26_2, arg_26_3, arg_26_4)
	local var_26_0 = true

	if arg_26_2 ~= 0 and arg_26_1:getHeroType() ~= arg_26_2 then
		var_26_0 = false
	elseif arg_26_3 ~= 0 and arg_26_1:getFromType() ~= arg_26_3 then
		var_26_0 = false
	elseif arg_26_4 ~= 0 and arg_26_1:getDistanceType() ~= arg_26_4 then
		var_26_0 = false
	end

	return var_26_0
end

function var_0_0.updateAllHeros(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = arg_27_0:getHeros()
	local var_27_1 = {}

	for iter_27_0 = 1, #var_27_0 do
		local var_27_2 = var_27_0[iter_27_0]

		if arg_27_0:checkHeroIsSelect(var_27_2, arg_27_1, arg_27_2, arg_27_3) then
			table.insert(var_27_1, var_27_2)
		end
	end

	arg_27_0:initHeros(var_27_1, xyd.LeftMenuType.SELF_HERO)
	arg_27_0:selectHeros()
	arg_27_0:refreshSelectedHeroClass()
end

function var_0_0.checkHeroCanJoin(arg_28_0, arg_28_1)
	return true
end

function var_0_0.getPets(arg_29_0)
	return {}
end

function var_0_0.checkCanPresetTeam(arg_30_0)
	return true
end

function var_0_0.checkPreHeroCanLoad(arg_31_0)
	return true
end

function var_0_0.checkCanLoadPreFormation(arg_32_0)
	return true
end

function var_0_0.loadPreFormation(arg_33_0)
	local var_33_0 = {}
	local var_33_1 = {}
	local var_33_2 = (xyd.db.formation:getFormationData(arg_33_0.campaignType) or {})[1] or {}

	for iter_33_0, iter_33_1 in ipairs(var_33_2) do
		local var_33_3 = arg_33_0.selfPlayer:getHeroByID(iter_33_1)

		if var_33_3 and #var_33_0 < xyd.MAX_TEAM_MEMBER_NUM then
			local var_33_4 = var_0_1.new()

			var_33_4:populate(var_33_3:toParams())

			var_33_4.type = xyd.LeftMenuType.SELF_HERO

			table.insert(var_33_0, iter_33_1)
			table.insert(var_33_1, var_33_4)
		end
	end

	arg_33_0.snowActivity:formatNewHeros(var_33_1, arg_33_0.mainRole_:getLevel(), arg_33_0.mainRole_:getColor())

	arg_33_0.preSelect_ = var_33_0
	arg_33_0.preHeros_ = var_33_1
end

function var_0_0.checkCanStartBattle(arg_34_0)
	local var_34_0 = true
	local var_34_1 = ""

	if #arg_34_0.select_ < 1 then
		var_34_0 = false
		var_34_1 = var_0_5:translation("BATTLE_NO_HERO")
	end

	if not var_34_0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_34_1
		})
	end

	return var_34_0
end

function var_0_0.updatePresetTeams(arg_35_0, arg_35_1)
	for iter_35_0 = 1, #arg_35_1 do
		local var_35_0 = arg_35_1[iter_35_0].team

		arg_35_0.snowActivity:formatNewHeros(var_35_0, arg_35_0.mainRole_:getLevel(), arg_35_0.mainRole_:getColor())
	end

	return arg_35_1
end

function var_0_0.canHeroJoinBattle(arg_36_0, arg_36_1)
	return true
end

function var_0_0.playReport(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = arg_37_1.battle_result

	if var_37_0 == nil then
		return
	end

	local var_37_1 = var_37_0.battle_report

	if var_37_1 == nil then
		return
	end

	if not arg_37_0 or tolua.isnull(arg_37_0) then
		return
	end

	local var_37_2 = {}
	local var_37_3 = json.decode(var_37_1)

	var_37_2.herosA = {}
	var_37_2.herosB = {}
	var_37_2.summonMonsters = {}
	var_37_2.campaignType = xyd.CampaignType.SNOW
	var_37_2.battleID = xyd.MapBattleID.SNOW_ACTIVITY
	var_37_2.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_37_3

	local var_37_4 = {}
	local var_37_5 = {}

	for iter_37_0, iter_37_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_37_6 = string.sub(iter_37_0, 1, 1)
		local var_37_7 = tonumber(string.sub(iter_37_0, 3, 3))

		if var_37_6 == "A" and tonumber(iter_37_1.is_main_role) == 1 then
			local var_37_8 = var_0_2.new()

			var_37_8:populate(iter_37_1.hero)
			var_37_8:setReportData(iter_37_1)
			var_37_8:setEffectBuffID(arg_37_0.mainRole_:getEffectBuffID())

			if arg_37_2 then
				var_37_8.harms = iter_37_1.harms
				var_37_8.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_2.herosA[var_37_7] = var_37_8
			end

			var_37_2.main_role_a = var_37_8
		elseif var_37_6 == "A" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.None then
			local var_37_9 = var_0_1.new()

			var_37_9:populate(iter_37_1.hero)
			var_37_9:setReportData(iter_37_1)

			if arg_37_2 then
				var_37_9.harms = iter_37_1.harms
				var_37_9.willDie = (iter_37_1.die_count or 0) ~= -1
			end

			table.insert(var_37_2.herosA, var_37_9)
		elseif var_37_6 == "A" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_37_10 = var_0_3.new()

			var_37_10:populate(iter_37_1.hero)
			var_37_10:setReportData(iter_37_1)

			if arg_37_2 then
				var_37_10.harms = iter_37_1.harms
				var_37_10.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_2.petA = {
					var_37_10
				}
			else
				var_37_2.petsA = {
					var_37_10
				}
			end
		elseif var_37_6 == "B" and tonumber(iter_37_1.is_main_role) == 1 then
			local var_37_11 = var_0_2.new()

			var_37_11:populate(iter_37_1.hero)
			var_37_11:setReportData(iter_37_1)
			var_37_11:setEffectBuffID(arg_37_0.enemyMainRole_:getEffectBuffID())

			if arg_37_2 then
				var_37_11.harms = iter_37_1.harms
				var_37_11.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_2.herosB[var_37_7] = var_37_11
			else
				var_37_2.main_role_b = var_37_11
			end
		elseif var_37_6 == "B" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.None then
			local var_37_12 = var_0_1.new()

			var_37_12:populate(iter_37_1.hero)
			var_37_12:setReportData(iter_37_1)

			if arg_37_2 then
				var_37_12.harms = iter_37_1.harms
				var_37_12.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_2.herosB[var_37_7] = var_37_12
			else
				table.insert(var_37_4, var_37_12)
			end
		elseif var_37_6 == "B" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_37_13 = var_0_3.new()

			var_37_13:populate(iter_37_1.hero)
			var_37_13:setReportData(iter_37_1)

			if arg_37_2 then
				var_37_13.harms = iter_37_1.harms
				var_37_13.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_2.petB = {
					var_37_13
				}
			else
				var_37_2.petsB = {
					var_37_13
				}
			end
		elseif var_37_6 == "C" then
			local var_37_14 = var_0_1.new()

			var_37_14:populate(iter_37_1.hero)
			var_37_14:setReportData(iter_37_1)

			if not arg_37_2 then
				sceneFighter = var_37_14
			end
		elseif tonumber(iter_37_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_37_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_37_15 = var_0_1.new()

			var_37_15:populate(iter_37_1.hero)
			var_37_15:setReportData(iter_37_1)

			var_37_5[iter_37_0] = var_37_15
		end
	end

	var_37_2.herosB = {
		var_37_4
	}
	var_37_2.sceneFighter = sceneFighter
	var_37_2.summonMonsters = var_37_5
	var_37_2.reportStar = tonumber(var_37_3.star)
	var_37_2.isShowResult = true

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "snow_battle"
		}
	})
	xyd.WindowManager.get():retainHistory()
	cc.Director:getInstance():pushScene(import("app.scenes.ActivityBattleCreate").new(var_37_2))
end

function var_0_0.startFrontBattle(arg_38_0)
	local var_38_0 = {
		herosA = {},
		herosB = {}
	}

	for iter_38_0, iter_38_1 in ipairs(arg_38_0.team_) do
		table.insert(var_38_0.herosA, iter_38_1.data)
	end

	var_38_0.campaignType = xyd.CampaignType.SNOW
	var_38_0.battleID = xyd.MapBattleID.SNOW_ACTIVITY
	var_38_0.herosB = {
		arg_38_0.enemyHeroes_
	}
	var_38_0.formation = arg_38_0:getFormationStr(var_38_0.herosA)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "snow_battle"
		}
	})

	var_38_0.main_role_a = arg_38_0.mainRole_
	var_38_0.main_role_b = arg_38_0.enemyMainRole_

	xyd.WindowManager.get():retainHistory()
	cc.Director:getInstance():pushScene(import("app.scenes.ActivityBattleCreate").new(var_38_0))
end

function var_0_0.updateSkillTips(arg_39_0, arg_39_1)
	if not arg_39_0.skillTipsList_ then
		local var_39_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_battle/skill_tips.csb")

		var_39_0:addTo(arg_39_0)
		var_39_0:setPosition(cc.p(1030, 150))

		local var_39_1 = var_39_0:getChildByName("container"):getChildByName("list")
		local var_39_2 = var_39_1:getContentSize()

		arg_39_0.skillTipsList_ = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, var_39_2.width, var_39_2.height),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_39_1)
	end

	arg_39_0.skillTipsList_:removeAllItems()

	local var_39_3 = arg_39_0.skillTipsList_:newItem()
	local var_39_4 = arg_39_0:createLabel(20, cc.c3b(255, 255, 255), xyd.tables.skill:desc(arg_39_1))

	var_39_3:addContent(var_39_4)
	var_39_3:setItemSize(var_39_4:getContentSize().width, var_39_4:getContentSize().height + 10)
	arg_39_0.skillTipsList_:addItem(var_39_3)

	local var_39_5 = arg_39_0.skillTipsList_:newItem()
	local var_39_6 = arg_39_0:createLabel(18, cc.c3b(241, 255, 15), nil)
	local var_39_7 = arg_39_0:getSkillUnlockDesc(arg_39_1)

	var_39_6:setString(var_39_7)
	var_39_5:addContent(var_39_6)
	var_39_5:setItemSize(var_39_6:getContentSize().width, var_39_6:getContentSize().height + 10)
	arg_39_0.skillTipsList_:addItem(var_39_5)
	arg_39_0.skillTipsList_:reload()
end

function var_0_0.getSkillUnlockDesc(arg_40_0, arg_40_1)
	local var_40_0 = var_0_5:translation("SNOW_ACTIVITY_UNlOCK_DESC")
	local var_40_1 = var_0_8:type(arg_40_1)
	local var_40_2 = var_0_8:from(arg_40_1)
	local var_40_3 = var_0_8:distanceType(arg_40_1)
	local var_40_4 = var_0_8:partnerReq(arg_40_1)

	if var_40_4 <= 0 then
		return ""
	end

	local var_40_5 = ""

	if var_40_1 > 0 then
		var_40_5 = var_0_5:translation("HERO_FILTER_DES_2") .. var_0_5:translation("HERO_FILTER_TYPE_" .. var_40_1)
	elseif var_40_2 > 0 then
		var_40_5 = var_0_5:translation("HERO_FILTER_DES_3") .. var_0_5:translation("HERO_FILTER_POWER_" .. var_40_2)
	elseif var_40_3 > 0 then
		var_40_5 = var_0_5:translation("HERO_FILTER_DES_1") .. var_0_5:translation("HERO_FILTER_POS_" .. var_40_3 - 1)
	end

	return (string.format(var_40_0, var_40_5, var_40_4))
end

function var_0_0.createLabel(arg_41_0, arg_41_1, arg_41_2, arg_41_3, arg_41_4)
	local var_41_0 = {
		color = arg_41_2,
		size = arg_41_1
	}
	local var_41_1 = xyd.AssetLoader.get():loadLabel(var_41_0)

	var_41_1:setLineBreakWithoutSpace(true)

	if arg_41_4 then
		var_41_1:setDimensions(arg_41_4, 0)
	else
		var_41_1:setDimensions(200, 0)
	end

	if arg_41_3 then
		var_41_1:setString(arg_41_3)
	end

	return var_41_1
end

function var_0_0.isBanned(arg_42_0, arg_42_1)
	if arg_42_1.isSuper and arg_42_1:isSuper() then
		return true
	else
		return false
	end
end

return var_0_0
