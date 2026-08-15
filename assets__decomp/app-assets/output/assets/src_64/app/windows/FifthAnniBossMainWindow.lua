local var_0_0 = class("FifthAnniBossMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.fifthAnniBoss
local var_0_5 = xyd.tables.fifthAnniBossServerAward
local var_0_6 = xyd.tables.misc
local var_0_7 = xyd.tables.gift
local var_0_8 = var_0_6:getValue("fifth_anni_boss_total_hp")
local var_0_9 = {
	buy_challenge_times = var_0_1:translation("ACTIVITY_1232_BOSS_1"),
	rest_times = var_0_1:translation("ACTIVITY_1232_BOSS_2"),
	battle = var_0_1:translation("ACTIVITY_1232_BOSS_3"),
	skill = var_0_1:translation("ACTIVITY_1232_BOSS_4"),
	state = var_0_1:translation("ACTIVITY_1232_BOSS_5"),
	kill_award = var_0_1:translation("ACTIVITY_1232_BOSS_6"),
	rank = var_0_1:translation("ACTIVITY_1232_BOSS_7"),
	score = var_0_1:translation("ACTIVITY_1232_BOSS_8"),
	award = var_0_1:translation("ACTIVITY_1232_BOSS_9")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.fifthAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)

	local var_1_0 = arg_1_0.fifthAnniModel.bossInfo

	arg_1_0.bossHp = var_1_0.boss_hp
	arg_1_0.bossKill = var_1_0.boss_kill
	arg_1_0.diffculty = var_1_0.diffculty
	arg_1_0.stage = var_1_0.stage
	arg_1_0.point = arg_1_0.fifthAnniModel.bossPoint
	arg_1_0.challenge = arg_1_0.fifthAnniModel.bossChallengeTime
	arg_1_0.buyTime = arg_1_0.fifthAnniModel.bossBuyTime
	arg_1_0.battleID = var_0_4:battleId(arg_1_0.diffculty)[arg_1_0.stage]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setTexts()
	arg_4_0:updateBossInfo()
	arg_4_0:setBtns()
	arg_4_0:initBossModel()
end

function var_0_0.updateBossInfo(arg_5_0)
	arg_5_0:nodeByName("txt_num"):setString(arg_5_0.challenge)
	arg_5_0:nodeByName("txt_difficulty"):setString(arg_5_0.diffculty)
	arg_5_0:nodeByName("txt_score_num"):setString(arg_5_0.point)

	arg_5_0.bossHp = arg_5_0.bossHp

	local var_5_0 = arg_5_0.bossHp / var_0_8 * 100

	arg_5_0:nodeByName("bar"):setPercent(var_5_0)

	local var_5_1 = math.floor(var_5_0)
	local var_5_2 = math.ceil((var_5_0 - var_5_1) * 100)

	if var_5_2 == 100 then
		var_5_2 = var_5_2 - 1
	end

	arg_5_0:nodeByName("txt_process_1"):setString(var_5_1)
	arg_5_0:nodeByName("txt_process_2"):setString("." .. var_5_2 .. "%")

	local var_5_3 = var_0_4:award(arg_5_0.diffculty)
	local var_5_4 = var_0_7:items(var_5_3)
	local var_5_5 = var_0_7:itemNum(var_5_3)

	for iter_5_0 = 1, #var_5_4 do
		local var_5_6 = display.newNode()

		var_5_6:setContentSize(cc.size(70, 70))
		xyd.setItemAndAddTips(var_5_6, var_5_4[iter_5_0], var_5_5[iter_5_0])
		var_5_6:addTo(arg_5_0:nodeByName("list_person_award"))
		var_5_6:setPosition(90 * iter_5_0 - 80, 0)
	end

	if arg_5_0.bossKill == 4 then
		arg_5_0:nodeByName("bg_person_award"):setVisible(false)
		arg_5_0:nodeByName("list_person_award"):setVisible(false)
		arg_5_0:nodeByName("bg_tips"):setVisible(false)
	end

	local var_5_7 = var_0_5:getIds()
	local var_5_8 = arg_5_0:nodeByName("list_server_award"):getContentSize().width

	for iter_5_1 = 1, #var_5_7 do
		local var_5_9 = var_0_5:giftId(iter_5_1)
		local var_5_10 = var_0_7:items(var_5_9)[1]
		local var_5_11 = var_0_7:itemNum(var_5_9)[1]
		local var_5_12 = display.newNode()

		var_5_12:setContentSize(cc.size(70, 70))
		xyd.setItemAndAddTips(var_5_12, var_5_10, var_5_11)
		var_5_12:addTo(arg_5_0:nodeByName("list_server_award"))

		local var_5_13 = var_0_5:req(iter_5_1) / 100

		var_5_12:setPosition(var_5_13 * var_5_8, 0)
	end
end

function var_0_0.setTexts(arg_6_0)
	arg_6_0:nodeByName("txt_rest"):setString(var_0_9.rest_times)
	arg_6_0:nodeByName("txt_battle"):setString(var_0_9.battle)
	arg_6_0:nodeByName("txt_skill"):setString(var_0_9.skill)
	arg_6_0:nodeByName("txt_state"):setString(var_0_9.state)
	arg_6_0:nodeByName("txt_score"):setString(var_0_9.score)
	arg_6_0:nodeByName("txt_tips"):setString(var_0_9.kill_award)
	arg_6_0:nodeByName("txt_rank"):setString(var_0_9.rank)
	arg_6_0:nodeByName("txt_award"):setString(var_0_9.award)
end

function var_0_0.setBtns(arg_7_0)
	xyd.nodeEventSample(arg_7_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_8_0 = {
			title_name = "FIFTH_ANNI_BOSS_RULE_TITLE",
			rule = "FIFTH_ANNI_BOSS_RULE_TEXT",
			award = xyd.tables.fifthAnniBossRank
		}

		xyd.WindowManager.get():openWindow("fifth_anni_party_rule", var_8_0)
	end)
	arg_7_0:nodeByName("btn_add"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0

			if arg_7_0.buyTime and arg_7_0.buyTime < 5 then
				var_9_0 = var_0_6:getValue("fifth_anni_boss_buy_challenge_prices")[arg_7_0.buyTime + 1]
			else
				var_9_0 = var_0_6:getValue("fifth_anni_boss_buy_challenge_prices")[5]
			end

			local var_9_1 = string.format(var_0_9.buy_challenge_times, var_9_0)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_1, function()
				if arg_7_0.selfPlayer.crystal < var_9_0 then
					local var_10_0 = var_0_1:translation("ZUANSHI_ABSENCE")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
						xyd.WindowManager.get():openWindow("vip_recharge")
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					arg_7_0.fifthAnniModel:buyChallengeTime(nil, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							arg_7_0.buyTime = arg_7_0.buyTime + 1
							arg_7_0.challenge = arg_7_0.challenge + 1
							arg_7_0.fifthAnniModel.bossChallengeTime = arg_7_0.buyTime
							arg_7_0.fifthAnniModel.bossBuyTime = arg_7_0.challenge

							arg_7_0:nodeByName("txt_num"):setString(arg_7_0.challenge)
						end
					end)
				end
			end, nil, 0, xyd.ColorMode.ACTIVITY)
		end
	end)
	arg_7_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			arg_7_0.fifthAnniModel:getRank(function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("fifth_anni_boss_rank", arg_14_1)
				end
			end)
		end
	end)
	arg_7_0:nodeByName("btn_battle"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			if arg_7_0.challenge < 1 then
				local var_15_0 = var_0_1:translation("ACTIVITY_1232_BOSS_10")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_0
				})
			else
				local var_15_1 = xyd.SelectTeamType.FIFTH_ANNIVERSARY_BOSS
				local var_15_2 = {
					type = var_15_1,
					battleID = arg_7_0.battleID,
					campaignType = xyd.CampaignType.FIFTH_ANNIVERSARY_BOSS
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_15_2)
			end
		end
	end)
	arg_7_0:nodeByName("btn_award"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_16_0, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			local var_16_0 = arg_7_0.fifthAnniModel.bossAwardInfo

			xyd.WindowManager.get():openWindow("fifth_anni_boss_award", var_16_0)
		end
	end)
end

function var_0_0.initBossModel(arg_17_0)
	local var_17_0 = xyd.tables.battle:fight1(arg_17_0.battleID)[1]
	local var_17_1 = var_0_3:modelID(var_17_0)
	local var_17_2 = xyd.HeroAnimation.new(var_17_0, var_17_1, xyd.tables.model:uiScale(var_17_1), {})

	if var_17_2 then
		var_17_2:idle()
	end

	var_17_2:addTo(arg_17_0:nodeByName("pos_hero"))

	local var_17_3 = arg_17_0:nodeByName("list_skill"):getHeight()

	for iter_17_0 = 1, 4 do
		local var_17_4 = display.newNode()

		var_17_4:setContentSize(var_17_3, var_17_3)

		local var_17_5 = var_0_3:getSkill(var_17_0, iter_17_0)

		xyd.setSkillBorder(var_17_4, var_17_5, true)
		var_17_4:setTouchEnabled(true)
		var_17_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
			if arg_18_0.name == "began" then
				local var_18_0 = {
					has_jiantou = false,
					id = var_17_5
				}

				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_18_1 = xyd.WindowManager.get():openWindow("skill_tips", var_18_0)

					xyd.adaptToWorldPosition(var_17_4, var_18_1)
				end

				return true
			elseif arg_18_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
		var_17_4:addTo(arg_17_0:nodeByName("list_skill"))
		var_17_4:setPositionX((var_17_3 + 18) * (iter_17_0 - 1))
	end

	local var_17_6 = display.newNode()

	var_17_6:setContentSize(var_17_3, var_17_3)

	local var_17_7 = var_0_3:getSkill(var_17_0, 5)

	xyd.setSkillBorder(var_17_6, var_17_7, true)
	var_17_6:setTouchEnabled(true)
	var_17_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			local var_19_0 = {
				has_jiantou = false,
				id = var_17_7
			}

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_19_1 = xyd.WindowManager.get():openWindow("skill_tips", var_19_0)

				xyd.adaptToWorldPosition(var_17_6, var_19_1)
			end

			return true
		elseif arg_19_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
	var_17_6:addTo(arg_17_0:nodeByName("list_state"))
end

return var_0_0
