local var_0_0 = class("ZhugeEnemyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = 4
local var_0_4 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.enemyType = arg_1_2.enemyType
	arg_1_0.battleID = arg_1_2.battleID
	arg_1_0.noteID = arg_1_2.noteID
	arg_1_0.bossID = nil
	arg_1_0.team = {}
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initTeam()
	arg_2_0:layout()
end

function var_0_0.initTeam(arg_3_0)
	local var_3_0 = xyd.tables.battle:fight1(arg_3_0.battleID)

	if arg_3_0.enemyType and arg_3_0.enemyType == xyd.ZhugeHouseEnemy.ZHUGE_BOSS then
		arg_3_0.bossID = var_3_0[1]
	elseif #var_3_0 == 1 then
		arg_3_0.bossID = var_3_0[1]
		arg_3_0.enemyType = xyd.ZhugeHouseEnemy.NORMAL_BOSS
	else
		arg_3_0.team = var_3_0
		arg_3_0.enemyType = xyd.ZhugeHouseEnemy.NORMAL_TEAM
	end
end

function var_0_0.layout(arg_4_0, arg_4_1)
	arg_4_0:updateBg()

	if arg_4_0.enemyType == xyd.ZhugeHouseEnemy.ZHUGE_BOSS then
		arg_4_0:createZhugeBoss()
	elseif arg_4_0.enemyType == xyd.ZhugeHouseEnemy.NORMAL_BOSS then
		arg_4_0:createNormalBoss()
	elseif arg_4_0.enemyType == xyd.ZhugeHouseEnemy.NORMAL_TEAM then
		arg_4_0:createNormalTeam()
	end
end

function var_0_0.updateBg(arg_5_0)
	for iter_5_0 = 1, 3 do
		local var_5_0 = false

		if arg_5_0.enemyType == iter_5_0 then
			var_5_0 = true
		end

		arg_5_0:nodeByName("bg_" .. iter_5_0):setVisible(var_5_0)
	end
end

function var_0_0.createZhugeBoss(arg_6_0)
	arg_6_0:nodeByName("team_panel"):setVisible(false)
	arg_6_0:nodeByName("normal_bottom"):setVisible(false)
	arg_6_0:nodeByName("text_name"):setVisible(false)
	arg_6_0:nodeByName("text_skill_desc"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_16"))
	arg_6_0:updateBossModel(arg_6_0.bossID)
	arg_6_0:updateBossSkill(arg_6_0.bossID)
	arg_6_0:initSpecialBottom()
	arg_6_0:nodeByName("text_boss_desc"):setString(xyd.tables.hero:name(arg_6_0.bossID))
end

function var_0_0.createNormalBoss(arg_7_0)
	arg_7_0:nodeByName("team_panel"):setVisible(false)
	arg_7_0:nodeByName("special_bottom"):setVisible(false)
	arg_7_0:nodeByName("close"):setVisible(false)
	arg_7_0:nodeByName("boss_panel"):setPositionY(563)
	arg_7_0:nodeByName("text_boss_desc"):setPosition(625, 245)
	arg_7_0:nodeByName("text_boss_desc"):setString(xyd.tables.zhugeNote:desc(arg_7_0.noteID))
	arg_7_0:nodeByName("text_name"):setString(xyd.tables.hero:name(arg_7_0.bossID))
	arg_7_0:nodeByName("text_skill_desc"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_16"))
	arg_7_0:nodeByName("boss"):setPositionY(-25)
	arg_7_0:initNormalBottom()
	arg_7_0:updateBossModel(arg_7_0.bossID)
	arg_7_0:updateNormalBossSkill(arg_7_0.bossID)
end

function var_0_0.createNormalTeam(arg_8_0)
	arg_8_0:nodeByName("boss_panel"):setVisible(false)
	arg_8_0:nodeByName("special_bottom"):setVisible(false)
	arg_8_0:nodeByName("close"):setVisible(false)
	arg_8_0:nodeByName("text_team_desc"):setString(xyd.tables.zhugeNote:desc(arg_8_0.noteID))
	arg_8_0:initNormalBottom()
	arg_8_0:initTeamList()
end

function var_0_0.initNormalBottom(arg_9_0)
	local var_9_0 = arg_9_0:nodeByName("normal_bottom")

	var_9_0:getChildByName("btn_cancel"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			arg_9_0.zhugeModel:completeTask(false, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					local var_11_0 = xyd.WindowManager.get():getWindow("zhuge_small_house")

					if var_11_0 and not tolua.isnull(var_11_0) then
						var_11_0:initNotebookWnd()
					end

					xyd.WindowManager.get():closeWindow(arg_9_0)
				end
			end)
		end
	end)
	var_9_0:getChildByName("btn_fight"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			arg_9_0:startFight(xyd.SelectTeamType.ZHUGE_NOTE, xyd.CampaignType.ZHUGE_NOTE)
		end
	end)
end

function var_0_0.updateBossModel(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0:nodeByName("boss")
	local var_13_1 = var_0_2.new()

	var_13_1:populateWithTableID(arg_13_1)

	local var_13_2 = var_13_1:getHeroModel()

	var_13_2:addTo(var_13_0)
	var_13_2:setScale(0.75)
	var_13_2:setPosition(var_13_0:getContentSize().width / 2, 0)
end

function var_0_0.updateBossSkill(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_0:nodeByName("skill_panel")
	local var_14_1 = var_14_0:getContentSize()
	local var_14_2 = xyd.tables.hero:getSkill(arg_14_1)
	local var_14_3 = var_14_1.height / 2

	for iter_14_0 = 1, #var_14_2 do
		local var_14_4 = var_14_2[iter_14_0]

		if var_14_4 ~= 0 then
			local var_14_5 = display.newNode()

			var_14_5:setContentSize(var_14_1.height, var_14_1.height)
			xyd.setSkillBorder(var_14_5, var_14_4, var_0_4)
			var_14_5:addTo(var_14_0)
			var_14_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_14_5:setPosition(cc.p(var_14_3, var_14_1.height / 2))

			var_14_3 = var_14_3 + var_14_1.height + 10

			arg_14_0:createSkillTip(var_14_5, var_14_4)
		end
	end
end

function var_0_0.createSkillTip(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = {
		has_jiantou = false,
		id = arg_15_2
	}
	local var_15_1, var_15_2 = arg_15_1:getPosition()

	arg_15_1:setTouchEnabled(true)
	arg_15_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_16_0 = xyd.WindowManager.get():openWindow("skill_tips", var_15_0)

				xyd.adaptToWorldPosition(arg_15_1, var_16_0)
			end

			return true
		elseif arg_16_0.name == "ended" and xyd.WindowManager.get():getWindow("skill_tips") then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
end

function var_0_0.initTeamList(arg_17_0)
	local var_17_0 = xyd.tables.battle:fight1(arg_17_0.battleID)
	local var_17_1 = arg_17_0:nodeByName("team")
	local var_17_2 = 120

	for iter_17_0 = 1, #var_17_0 do
		local var_17_3 = var_17_0[iter_17_0]
		local var_17_4 = xyd.tables.hero:modelID(var_17_3)
		local var_17_5 = xyd.HeroAnimation.new(var_17_3, var_17_4, xyd.tables.model:uiScale(var_17_4), {})

		if var_17_5 then
			var_17_5:idle()
			var_17_5:addTo(var_17_1)
			var_17_5:setScale(0.75)
			var_17_5:setPosition(cc.p(var_17_2, 0))

			var_17_2 = var_17_2 + 140
		end
	end
end

function var_0_0.startFight(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = {
		type = arg_18_1,
		campaignType = arg_18_2,
		battleID = arg_18_0.battleID
	}

	xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_18_0)
end

function var_0_0.initSpecialBottom(arg_19_0)
	arg_19_0.bossInfo = arg_19_0.zhugeModel:getLocalBossInfo()

	local var_19_0 = arg_19_0:nodeByName("special_bottom")
	local var_19_1 = arg_19_0.bossInfo.cur_damage
	local var_19_2 = arg_19_0.bossInfo.free_times
	local var_19_3 = arg_19_0.bossInfo.is_passed
	local var_19_4 = arg_19_0.bossInfo.total_hp
	local var_19_5 = math.floor(var_19_1 / var_19_4 * 100)

	var_19_0:getChildByName("text_damage"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_17"))
	var_19_0:getChildByName("text_damage"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_19_0:getChildByName("text_progress"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_18"))
	var_19_0:getChildByName("text_progress"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_19_0:getChildByName("text_damage_num"):setString(var_19_1)
	var_19_0:getChildByName("text_damage_num"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_19_0:getChildByName("text_progress_num"):setString(var_19_5 .. "%")
	var_19_0:getChildByName("text_progress_num"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_19_0:getChildByName("bar"):setPercent(var_19_5)
	var_19_0:getChildByName("btn_fight"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			arg_19_0:startFight(xyd.SelectTeamType.ZHUGE_BOSS, xyd.CampaignType.ZHUGE_BOSS)
		end
	end)
end

function var_0_0.updateNormalBossSkill(arg_21_0)
	arg_21_0.skills = xyd.tables.zhugeNote:getSkill(arg_21_0.noteID)

	arg_21_0:initListview()
end

function var_0_0.initListview(arg_22_0)
	local var_22_0 = arg_22_0:nodeByName("skill_panel")
	local var_22_1 = var_22_0:getContentSize().width
	local var_22_2 = var_22_0:getContentSize().height

	arg_22_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_22_1, var_22_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_22_0)

	arg_22_0:updateList()
end

function var_0_0.updateList(arg_23_0)
	for iter_23_0 = 1, #arg_23_0.skills do
		local var_23_0
		local var_23_1 = arg_23_0.list:dequeueItem()

		if not var_23_1 then
			var_23_1 = arg_23_0.list:newItem()
		else
			var_23_1:removeAllChildren()
		end

		content = display.newNode()

		content:setTouchSwallowEnabled(false)

		cell = display.newNode()

		arg_23_0:initSkillItem(cell, iter_23_0)

		local var_23_2 = cell:getContentSize().width
		local var_23_3 = cell:getContentSize().height

		content:addChild(cell)
		content:setContentSize(cc.size(arg_23_0.list.viewRect_.width, cell:getContentSize().height + 5))
		var_23_1:setItemSize(arg_23_0.list.viewRect_.width, cell:getContentSize().height + 5)
		var_23_1:addContent(content)
		arg_23_0.list:addItem(var_23_1)
	end

	arg_23_0.list:reload()
end

function var_0_0.initSkillItem(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_0:nodeByName("skill_panel"):getContentSize()
	local var_24_1 = arg_24_0.skills[arg_24_2]
	local var_24_2 = arg_24_0:createTextLabel(var_24_1.title, var_24_0.width - 50, cc.ui.TEXT_ALIGN_LEFT, 22, cc.c3b(246, 116, 9))
	local var_24_3 = arg_24_0:createTextLabel(var_24_1.desc, var_24_0.width - 50, cc.ui.TEXT_ALIGN_LEFT, 22, cc.c3b(180, 62, 10))

	var_24_3:addTo(arg_24_1)

	local var_24_4 = var_24_3:getContentSize().height + 10

	var_24_3:setPosition(cc.p(16, var_24_4))
	var_24_3:setAnchorPoint(cc.p(0, 1))
	var_24_2:addTo(arg_24_1)

	local var_24_5 = var_24_4 + var_24_2:getContentSize().height + 5

	var_24_2:setPosition(cc.p(16, var_24_5))
	var_24_2:setAnchorPoint(cc.p(0, 1))
	arg_24_1:setContentSize(var_24_0.width, var_24_5)
end

function var_0_0.createTextLabel(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4, arg_25_5)
	local var_25_0 = {
		text = arg_25_1,
		align = arg_25_3,
		color = arg_25_5,
		size = arg_25_4,
		dimensions = cc.size(arg_25_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_25_0))
end

return var_0_0
