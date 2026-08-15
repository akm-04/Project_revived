local var_0_0 = class("NianBossBattlePreWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.NianBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.NIAN_BOSS)
	arg_1_0.boss_id = arg_1_0.NianBoss.boss_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("sweep_word"):enableOutline(cc.c4b(149, 85, 8, 255), 2)
	arg_3_0:nodeByName("sweep_word"):getVirtualRenderer():setAdditionalKerning(2)
	arg_3_0:nodeByName("sweep_word"):setString(var_0_2:translation("MAP_SWEEP"))
	arg_3_0:nodeByName("sweep_word"):setVisible(false)
	arg_3_0:nodeByName("sweep_btn"):setVisible(false)
	arg_3_0:nodeByName("bottom_container"):setVisible(false)
	arg_3_0:nodeByName("first_challenge_words"):setString("")

	if arg_3_0.NianBoss.can_sweep == 0 then
		arg_3_0:nodeByName("sweep_word"):setVisible(false)
		arg_3_0:nodeByName("sweep_btn"):setVisible(false)
	else
		arg_3_0:nodeByName("sweep_word"):setVisible(true)
		arg_3_0:nodeByName("sweep_btn"):setVisible(true)
	end

	if arg_3_0.NianBoss.total_rank == nil or arg_3_0.NianBoss.total_rank == 0 then
		arg_3_0:nodeByName("bottom_container"):setVisible(false)
		arg_3_0:nodeByName("first_challenge_words"):setString(var_0_2:translation("FIRST_CHALLENGE_WORLD_BOSS"))
	else
		arg_3_0:nodeByName("bottom_container"):setVisible(true)
		arg_3_0:nodeByName("first_challenge_words"):setString("")
	end

	arg_3_0:setRank(arg_3_0.NianBoss.total_rank)

	local var_3_0 = string.formatnumberthousands(arg_3_0.NianBoss.total_damage)

	arg_3_0:nodeByName("damage_num_text"):setString(var_3_0)
	arg_3_0:nodeByName("reward_1_num_text"):setString(xyd.tables.nianBossReward:getMana(arg_3_0.NianBoss.total_rank))
	arg_3_0:nodeByName("reward_2_num_text"):setString(xyd.tables.nianBossReward:getDiamond(arg_3_0.NianBoss.total_rank))
	arg_3_0:showAwardItems(arg_3_0.NianBoss.total_rank)
end

function var_0_0.init(arg_4_0)
	arg_4_0.hero = var_0_4.new()

	arg_4_0:layout()
	arg_4_0.hero:populateWithTableID(tonumber(arg_4_0.NianBoss.monster_id))
	arg_4_0:updateHeroModel(arg_4_0.hero)
	arg_4_0:nodeByName("pic_container"):setVisible(true)

	arg_4_0.skillContainer = arg_4_0:nodeByName("skills_container")

	local var_4_0 = {
		xyd.tables.nianBoss.skill1[arg_4_0.boss_id],
		xyd.tables.nianBoss.skill2[arg_4_0.boss_id],
		xyd.tables.nianBoss.skill3[arg_4_0.boss_id],
		xyd.tables.nianBoss.skill4[arg_4_0.boss_id]
	}

	arg_4_0:setSkillContainer(var_4_0)
	arg_4_0:setRank(arg_4_0.NianBoss.total_rank)
	arg_4_0:nodeByName("des_text"):setString(xyd.tables.nianBoss.campaign_des[arg_4_0.boss_id])
	arg_4_0:nodeByName("title_text"):setString(xyd.tables.nianBoss.campaign_name[arg_4_0.boss_id])
	arg_4_0:nodeByName("rank_words"):setString(var_0_2:translation("RANKING") .. var_0_2:translation("COLON"))
	arg_4_0:nodeByName("boss_des_words"):setString(var_0_2:translation("WORLD_BOSS_DES_WORDS"))
	arg_4_0:nodeByName("boss_skill_words"):setString(var_0_2:translation("WORLD_BOSS_SKILL_WORDS"))
	arg_4_0:nodeByName("damage_words"):setString(var_0_2:translation("HISTORY_DAMAGE") .. var_0_2:translation("COLON"))
	arg_4_0:nodeByName("des_words"):setString(string.format(var_0_2:translation("WORLD_BOSS_KEEP_RANK"), xyd.tables.nianBoss.name[arg_4_0.boss_id]))
end

function var_0_0.setRank(arg_5_0, arg_5_1)
	arg_5_0:nodeByName("num_container"):removeAllChildren()

	local var_5_0 = {}

	while arg_5_1 and arg_5_1 ~= 0 do
		local var_5_1 = arg_5_1 % 10

		arg_5_1 = math.floor(arg_5_1 / 10)

		local var_5_2 = xyd.AssetLoader.get():loadSprite("images/num_blue/" .. var_5_1 .. ".png")

		var_5_2:setAnchorPoint(cc.p(0, 0.5))
		var_5_2:scale(0.8)
		table.insert(var_5_0, var_5_2)
	end

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		iter_5_1:setPosition((#var_5_0 - iter_5_0) * 30, arg_5_0:nodeByName("num_container"):getHeight() / 2)
		arg_5_0:nodeByName("num_container"):addChild(iter_5_1)
	end
end

function var_0_0.setSkillContainer(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1
	local var_6_1 = {}

	arg_6_0.skillItems = {}

	local var_6_2 = arg_6_0.skillContainer:getChildren()
	local var_6_3 = arg_6_0.skillContainer:getHeight()

	for iter_6_0, iter_6_1 in pairs(var_6_0) do
		local var_6_4 = display.newNode()

		var_6_4:setContentSize(var_6_3, var_6_3)

		local var_6_5 = xyd.tables.skill:icon(iter_6_1)

		if var_6_5 and var_6_5 ~= "" then
			local var_6_6 = xyd.AssetLoader.get():loadSprite(var_6_5)
			local var_6_7 = xyd.AssetLoader.get():loadSprite("windows/hero/skill_icon.png")

			var_6_7:setPosition(var_6_4:getWidth() / 2, var_6_4:getHeight() / 2)
			var_6_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_7:scale(var_6_4:getWidth() / var_6_7:getWidth() / 20 * 19)

			stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

			stencil:setPosition(var_6_4:getWidth() / 2, var_6_4:getHeight() / 2)
			stencil:setAnchorPoint(cc.p(0.5, 0.5))
			stencil:scale(var_6_4:getWidth() / stencil:getWidth())

			local var_6_8 = cc.ClippingNode:create()

			var_6_8:setStencil(stencil)
			var_6_8:setInverted(true)
			var_6_8:setAlphaThreshold(0)
			var_6_4:addChild(var_6_8)
			var_6_8:addChild(var_6_6)
			var_6_6:align(display.LEFT_BOTTOM, 0, 0)
			var_6_6:scale((var_6_4:getWidth() - 3) / var_6_6:getWidth())
			var_6_4:addTo(arg_6_0.skillContainer)
			var_6_7:addTo(var_6_4)
			table.insert(arg_6_0.skillItems, var_6_4)
			var_6_4:x((iter_6_0 - 1) * (var_6_3 + 10) + 20)
			var_6_4:y(0)
			arg_6_0:createSkillTip(iter_6_0, iter_6_1)
		end
	end
end

function var_0_0.createSkillTip(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {
		has_jiantou = false,
		id = arg_7_2
	}
	local var_7_1 = arg_7_0.skillItems[arg_7_1]
	local var_7_2, var_7_3 = var_7_1:getPosition()
	local var_7_4, var_7_5 = arg_7_0.skillContainer:getPosition()
	local var_7_6 = var_7_2 + var_7_4
	local var_7_7 = var_7_3 + var_7_5
	local var_7_8 = display.newNode()

	var_7_8:setPosition(0, 0)
	var_7_8:setAnchorPoint(cc.p(0, 0))
	var_7_8:setContentSize(var_7_1:getContentSize())
	var_7_8:setTouchEnabled(true)
	var_7_8:addTo(var_7_1)
	var_7_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_8_0 = xyd.WindowManager.get():openWindow("skill_tips", var_7_0)

				xyd.adaptToWorldPosition(var_7_8, var_8_0)
			end

			return true
		elseif arg_8_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
end

function var_0_0.showAwardItems(arg_9_0, arg_9_1)
	local var_9_0 = xyd.tables.nianBossReward:getItems(arg_9_1)
	local var_9_1 = xyd.tables.nianBossReward:getItemNums(arg_9_1)

	if var_9_0 == 0 then
		for iter_9_0 = 1, 2 do
			arg_9_0:nodeByName("reward_item" .. iter_9_0):setVisible(false)
			arg_9_0:nodeByName("reward_item_num" .. iter_9_0):setVisible(false)
		end
	else
		for iter_9_1 = 1, #var_9_0 do
			local var_9_2 = display.newNode()
			local var_9_3 = arg_9_0:nodeByName("reward_item" .. iter_9_1)
			local var_9_4 = var_9_3:getContentSize().height

			var_9_2:setContentSize(var_9_4, var_9_4)
			xyd.setItemBorder(var_9_2, var_9_0[iter_9_1], false, false, 1)
			var_9_2:addTo(var_9_3)
			var_9_2:setAnchorPoint(cc.p(0, 0))
			arg_9_0:nodeByName("reward_item_num" .. iter_9_1):setString(var_9_1[iter_9_1])

			local var_9_5 = {
				id = var_9_0[iter_9_1],
				lev = xyd.tables.item:level(var_9_0[iter_9_1])
			}

			if xyd.tables.item:type(var_9_0[iter_9_1]) == -1 then
				var_9_5.tipsType = 0
				var_9_5.desc1 = xyd.tables.hero:getDes(var_9_0[iter_9_1])
			else
				var_9_5.tipsType = 1
				var_9_5.desc1 = xyd.tables.item:desc1(var_9_0[iter_9_1])
				var_9_5.desc2 = xyd.tables.item:desc2(var_9_0[iter_9_1])
			end

			var_9_5.hasNum = arg_9_0.player:getBackpack():getItemNumByID(var_9_0[iter_9_1])
			var_9_5.name = xyd.tables.item:name(var_9_0[iter_9_1])

			arg_9_0:addTips(var_9_2, var_9_5)
		end

		for iter_9_2 = #var_9_0 + 1, 2 do
			arg_9_0:nodeByName("reward_item" .. iter_9_2):setVisible(false)
			arg_9_0:nodeByName("reward_item_num" .. iter_9_2):setVisible(false)
		end
	end
end

function var_0_0.rewardFormat(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_1:getContentSize().height
	local var_10_1 = var_10_0 / 4
	local var_10_2 = {
		arg_10_2
	}

	if #var_10_2 == 1 and var_10_2[1] == 0 then
		var_10_2 = {}
	end

	local var_10_3 = {
		arg_10_3
	}
	local var_10_4 = #var_10_2

	for iter_10_0 = 1, #var_10_2 do
		if var_10_3[iter_10_0] > 0 then
			local var_10_5 = display.newNode()

			var_10_5:setContentSize(var_10_0, var_10_0)

			if xyd.tables.item:type(var_10_2[iter_10_0]) == -1 then
				xyd.setAvatarBorder(var_10_2[iter_10_0], var_10_5, 1, xyd.tables.hero:initialStar(var_10_2[iter_10_0]))
			else
				xyd.setItemBorder(var_10_5, var_10_2[iter_10_0], false, false, 1)
				arg_10_0:nodeByName("reward_3_num_text"):setString(var_10_3[iter_10_0])
			end

			var_10_5:addTo(arg_10_1)
			var_10_5:setAnchorPoint(cc.p(0, 0))
			var_10_5:setPosition((iter_10_0 - 1) * (var_10_0 + var_10_1), 0)

			local var_10_6 = {
				id = var_10_2[iter_10_0],
				lev = xyd.tables.item:level(var_10_2[iter_10_0])
			}

			if xyd.tables.item:type(var_10_2[iter_10_0]) == -1 then
				var_10_6.tipsType = 0
				var_10_6.desc1 = xyd.tables.hero:getDes(var_10_2[iter_10_0])
			else
				var_10_6.tipsType = 1
				var_10_6.desc1 = xyd.tables.item:desc1(var_10_2[iter_10_0])
				var_10_6.desc2 = xyd.tables.item:desc2(var_10_2[iter_10_0])
			end

			var_10_6.hasNum = arg_10_0.player:getBackpack():getItemNumByID(var_10_2[iter_10_0])
			var_10_6.name = xyd.tables.item:name(var_10_2[iter_10_0])

			arg_10_0:addTips(var_10_5, var_10_6)
		else
			arg_10_0:nodeByName("reward_3_num_text"):setVisible(false)
		end
	end

	return arg_10_1
end

function var_0_0.updateHeroModel(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1:getHeroModel()

	var_11_0:setTouchSwallowEnabled(false)

	local var_11_1 = arg_11_0:nodeByName("pic_container"):getContentSize().width / 2

	var_11_0:setPosition(cc.p(var_11_1, 0))
	arg_11_0:nodeByName("pic_container"):removeAllChildren()
	var_11_0:addTo(arg_11_0:nodeByName("pic_container"))
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	var_0_0.super:didOpen(arg_12_1)
	arg_12_0:nodeByName("close_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			local var_13_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_13_0, false)
			xyd.WindowManager.get():closeWindow("new_item_tips")
			xyd.WindowManager.get():closeWindow(arg_12_0.name)
		end
	end)
	arg_12_0:nodeByName("sweep_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_12_0:dealWrongTimeChallenge() then
				return
			end

			if arg_12_0.NianBoss.challenge_times <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("TRIAL_TIMES_ERROR")
				})
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("WORLD_BOSS_SWEEP"), function()
					arg_12_0.NianBoss:doSweep({
						campaign_id = arg_12_0.NianBoss.boss_id
					}, function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							arg_12_0.NianBoss:loadNianBoss(function(arg_17_0, arg_17_1)
								if arg_17_0 == xyd.error.OK then
									arg_12_0:layout()
									xyd.WindowManager.get():openWindow("nian_boss_sweep")
								end
							end)
						end
					end)
				end, nil, nil, arg_12_0.colorMode)
			end
		end
	end)
	arg_12_0:nodeByName("play_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_12_0:dealWrongTimeChallenge() then
				return
			end

			xyd.WindowManager.get():closeWindow("new_item_tips")

			arg_12_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

			if arg_12_0.NianBoss.challenge_times <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("TRIAL_TIMES_ERROR")
				})
			else
				arg_12_0.guild:loadAllTeamHeros({}, function(arg_19_0)
					local var_19_0 = false
					local var_19_1 = {}
					local var_19_2 = false
					local var_19_3 = false

					if arg_19_0 == xyd.error.OK then
						var_19_0 = true

						for iter_19_0, iter_19_1 in ipairs(arg_12_0.guild:getAllTeamHeros()) do
							local var_19_4 = var_0_4.new()

							var_19_4:populate(iter_19_1)

							var_19_4.player_name = iter_19_1.player_name
							var_19_4.rent_need_mana = iter_19_1.rent_need_mana
							var_19_4.can_rent = iter_19_1.can_rent
							var_19_4.player_id = iter_19_1.player_id

							table.insert(var_19_1, var_19_4)

							if iter_19_1.color >= xyd.EquipQuality.PURPLE then
								var_19_2 = true
							end
						end
					end

					for iter_19_2, iter_19_3 in pairs(arg_12_0.player.heros_) do
						if iter_19_3.color_ >= xyd.EquipQuality.PURPLE then
							var_19_3 = true

							break
						end
					end

					local var_19_5 = {
						type = xyd.SelectTeamType.NIAN_BOSS,
						isMercenary = var_19_0,
						allTeamHeros = var_19_1,
						campaignID = arg_12_0.boss_id,
						campaignType = xyd.CampaignType.NIAN_BOSS,
						hasPurpleHero = var_19_3,
						hasGuildPurpleHero = var_19_2
					}

					xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_19_5)
				end)
			end
		end
	end)
end

function var_0_0.dealWrongTimeChallenge(arg_20_0)
	local var_20_0 = arg_20_0:checkTimeCanDo()

	if var_20_0 == true then
		return true
	elseif var_20_0 == false then
		local var_20_1 = var_0_2:translation("NIAN_OPEN_TIP")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_20_1
		})

		return false
	end

	return true
end

function var_0_0.checkTimeCanDo(arg_21_0)
	local var_21_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_21_0 < xyd.tables.misc.dungenBossStart or var_21_0 > xyd.tables.misc.dungenBossStop then
		return false
	else
		return true
	end
end

return var_0_0
