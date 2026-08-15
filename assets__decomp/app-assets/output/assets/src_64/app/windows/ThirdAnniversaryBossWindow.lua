local var_0_0 = class("ThirdAnniversaryBossWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.boss_id = arg_1_0.thirdAnniversary.boss_id
	arg_1_0.isOpen = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("challenge_times"):setString(string.format(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT1"), arg_4_0.thirdAnniversary.challenge_times))
	arg_4_0:updateTimeCount()

	if arg_4_0.thirdAnniversary.total_rank == nil or arg_4_0.thirdAnniversary.total_rank <= 0 then
		arg_4_0:nodeByName("word_10"):setVisible(false)
		arg_4_0:nodeByName("word_no_rank"):setVisible(true)
	else
		arg_4_0:nodeByName("word_no_rank"):setVisible(false)
		arg_4_0:nodeByName("word_10"):setVisible(true)
		arg_4_0:setRank(arg_4_0.thirdAnniversary.total_rank)
	end

	if arg_4_0.thirdAnniversary.boss_hp <= 0 then
		arg_4_0:nodeByName("btn_fight"):setVisible(false)
		arg_4_0:nodeByName("bg_die"):setVisible(true)
	else
		arg_4_0:nodeByName("btn_fight"):setVisible(true)
		arg_4_0:nodeByName("bg_die"):setVisible(false)
	end

	local var_4_0 = string.formatnumberthousands(arg_4_0.thirdAnniversary.total_damage)

	arg_4_0:nodeByName("harm"):setString(arg_4_0.thirdAnniversary.self_damage)
	arg_4_0:nodeByName("challenge_times"):enableOutline(cc.c4b(92, 16, 16, 255), 0)
	arg_4_0:nodeByName("item_num"):setString(arg_4_0.player:getBackpack():getItemNumByID(xyd.tables.misc.thirdAnniversaryBossTicket))
	arg_4_0:nodeByName("item_num"):enableOutline(cc.c4b(144, 68, 75, 255), 2)
	arg_4_0:nodeByName("skill_des"):enableOutline(cc.c4b(196, 74, 74, 255), 2)
	arg_4_0:nodeByName("word_no_rank"):enableOutline(cc.c4b(145, 98, 209, 255), 2)
	arg_4_0:nodeByName("word_1"):enableOutline(cc.c4b(196, 74, 74, 255), 2)
	arg_4_0:nodeByName("word_no_rank"):enableOutline(cc.c4b(196, 74, 74, 255), 2)
	arg_4_0:nodeByName("word_9"):enableOutline(cc.c4b(196, 74, 74, 255), 2)
	arg_4_0:nodeByName("harm"):enableOutline(cc.c4b(196, 74, 74, 255), 2)
	arg_4_0:nodeByName("word_bossskill"):enableOutline(cc.c4b(196, 74, 74, 255), 2)
	arg_4_0:nodeByName("word_die"):enableOutline(cc.c4b(145, 98, 209, 255), 2)
	arg_4_0:nodeByName("word_10"):enableOutline(cc.c4b(196, 74, 74, 255), 2)
	arg_4_0:nodeByName("stage"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_STAGE" .. arg_4_0.thirdAnniversary.boss_stage))
	arg_4_0:nodeByName("skill_des"):setString(xyd.tables.hero:getDes(arg_4_0.thirdAnniversary.boss_id))
	arg_4_0:nodeByName("boss_hp"):setPercent(arg_4_0.thirdAnniversary.boss_hp / arg_4_0.thirdAnniversary.boss_hp_limit * 100)
	arg_4_0:nodeByName("text_boss_hp"):setString(string.format("%0.2f", arg_4_0.thirdAnniversary.boss_hp / arg_4_0.thirdAnniversary.boss_hp_limit * 100) .. "%")
	arg_4_0:nodeByName("word_bossskill"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT1"))
	arg_4_0:nodeByName("word_no_rank"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT2"))
	arg_4_0:nodeByName("word_1"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT3"))
	arg_4_0:nodeByName("word_9"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT4"))
	arg_4_0:nodeByName("word_10"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT5"))
	arg_4_0:nodeByName("word_die"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT6"))
	arg_4_0:nodeByName("word_fight"):setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TXT7"))
end

function var_0_0.init(arg_5_0)
	arg_5_0.hero = var_0_4.new()

	arg_5_0:layout()
	arg_5_0.hero:populateWithTableID(tonumber(arg_5_0.thirdAnniversary.boss_id))
	arg_5_0:updateHeroModel(arg_5_0.hero)

	arg_5_0.skillContainer = arg_5_0:nodeByName("skills_container")

	local var_5_0 = xyd.tables.hero:getSkill(arg_5_0.thirdAnniversary.boss_id)

	arg_5_0:setSkillContainer(var_5_0)
end

function var_0_0.updateTimeCount(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("time")

	if arg_6_0.handle_ then
		var_0_1.unscheduleGlobal(arg_6_0.handle_)
	end

	if xyd.ServerTime.get():getSecondsOfDay() >= xyd.tables.misc.thirdAnniversaryBossStartTime and xyd.ServerTime.get():getSecondsOfDay() <= xyd.tables.misc.thirdAnniversaryBossEndTime then
		arg_6_0.isOpen = true
	end

	local var_6_1 = xyd.tables.misc.thirdAnniversaryBossEndTime - xyd.ServerTime.get():getSecondsOfDay()

	if not arg_6_0.isOpen then
		var_6_1 = 0

		var_6_0:setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT4"))

		return
	end

	var_6_0:setString(string.format(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT2"), xyd.secondsToString(var_6_1, {
		toText = false
	})))

	arg_6_0.handle_ = var_0_1.scheduleGlobal(function()
		if var_6_0 and not tolua.isnull(var_6_0) then
			var_6_1 = var_6_1 - 1

			var_6_0:setString(string.format(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT2"), xyd.secondsToString(var_6_1, {
				toText = false
			})))

			if var_6_1 == 0 then
				arg_6_0.isOpen = false

				var_6_0:setString(var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT4"))

				if arg_6_0.handle_ then
					var_0_1.unscheduleGlobal(arg_6_0.handle_)

					arg_6_0.handle_ = nil
				end
			end
		elseif arg_6_0.handle_ then
			var_0_1.unscheduleGlobal(arg_6_0.handle_)

			arg_6_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.setRank(arg_8_0, arg_8_1)
	arg_8_0:nodeByName("num_container"):removeAllChildren()

	local var_8_0 = {}

	while arg_8_1 and arg_8_1 ~= 0 do
		local var_8_1 = arg_8_1 % 10

		arg_8_1 = math.floor(arg_8_1 / 10)

		local var_8_2 = xyd.AssetLoader.get():loadSprite("images/num_blue/" .. var_8_1 .. ".png")

		var_8_2:setAnchorPoint(cc.p(0, 0.5))
		var_8_2:scale(0.8)
		table.insert(var_8_0, var_8_2)
	end

	for iter_8_0, iter_8_1 in pairs(var_8_0) do
		iter_8_1:setPosition((#var_8_0 - iter_8_0) * 30, arg_8_0:nodeByName("num_container"):getHeight() / 2)
		arg_8_0:nodeByName("num_container"):addChild(iter_8_1)
	end
end

function var_0_0.setSkillContainer(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1
	local var_9_1 = {}

	arg_9_0.skillItems = {}

	local var_9_2 = arg_9_0.skillContainer:getChildren()
	local var_9_3 = arg_9_0.skillContainer:getHeight()

	for iter_9_0, iter_9_1 in ipairs(var_9_0) do
		if iter_9_1 ~= 0 and iter_9_0 <= 4 then
			local var_9_4 = display.newNode()

			var_9_4:setContentSize(var_9_3, var_9_3)

			local var_9_5 = xyd.tables.skill:icon(iter_9_1)

			if var_9_5 and var_9_5 ~= "" then
				local var_9_6 = xyd.SpriteLoader.new(var_9_5, nil, nil, xyd.DefaultImageType.SKILL_ICON)
				local var_9_7 = xyd.AssetLoader.get():loadSprite("windows/hero/skill_icon.png")

				var_9_7:setPosition(var_9_4:getWidth() / 2, var_9_4:getHeight() / 2)
				var_9_7:setAnchorPoint(cc.p(0.5, 0.5))
				var_9_7:scale(var_9_4:getWidth() / var_9_7:getWidth() / 20 * 19)

				stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

				stencil:setPosition(var_9_4:getWidth() / 2, var_9_4:getHeight() / 2)
				stencil:setAnchorPoint(cc.p(0.5, 0.5))
				stencil:scale(var_9_4:getWidth() / stencil:getWidth())

				local var_9_8 = cc.ClippingNode:create()

				var_9_8:setStencil(stencil)
				var_9_8:setInverted(true)
				var_9_8:setAlphaThreshold(0)
				var_9_4:addChild(var_9_8)
				var_9_8:addChild(var_9_6)
				var_9_6:align(display.LEFT_BOTTOM, 0, 0)
				var_9_6:scale((var_9_4:getWidth() - 3) / var_9_6:getWidth())
				var_9_4:addTo(arg_9_0.skillContainer)
				var_9_7:addTo(var_9_4)
				table.insert(arg_9_0.skillItems, var_9_4)
				var_9_4:x((iter_9_0 - 1) * (var_9_3 + 5) + 10)
				var_9_4:y(0)
				arg_9_0:createSkillTip(iter_9_0, iter_9_1)
			end
		end
	end
end

function var_0_0.createSkillTip(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {
		has_jiantou = false,
		id = arg_10_2
	}
	local var_10_1 = arg_10_0.skillItems[arg_10_1]
	local var_10_2, var_10_3 = var_10_1:getPosition()
	local var_10_4, var_10_5 = arg_10_0.skillContainer:getPosition()
	local var_10_6 = var_10_2 + var_10_4
	local var_10_7 = var_10_3 + var_10_5
	local var_10_8 = display.newNode()

	var_10_8:setPosition(0, 0)
	var_10_8:setAnchorPoint(cc.p(0, 0))
	var_10_8:setContentSize(var_10_1:getContentSize())
	var_10_8:setTouchEnabled(true)
	var_10_8:addTo(var_10_1)
	var_10_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_11_0 = xyd.WindowManager.get():openWindow("skill_tips", var_10_0)

				xyd.adaptToWorldPosition(var_10_8, var_11_0)
			end

			return true
		elseif arg_11_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
end

function var_0_0.updateHeroModel(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_1:getTableID()
	local var_12_1 = arg_12_1:getHeroModel()

	var_12_1:setTouchSwallowEnabled(false)
	var_12_1:setScale(0.8)
	var_12_1:addTo(arg_12_0:nodeByName("hero"))
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	var_0_0.super:didOpen(arg_13_1)
	arg_13_0:nodeByName("close"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_13_0:nodeByName("close"), arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_14_0, false)
			xyd.WindowManager.get():closeWindow("new_item_tips")
			xyd.WindowManager.get():closeWindow(arg_13_0.name)
		end
	end)
	arg_13_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_13_0:nodeByName("btn_rule"), arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_15_0, false)

			local var_15_1 = {
				title_name = "ACTIVITY_BOSS_RULE_TITLE",
				rule = "ACTIVITY_BOSS_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("third_anniversary_boss_rule", var_15_1)
		end
	end)
	arg_13_0:nodeByName("btn_award"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_13_0:nodeByName("btn_award"), arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			local var_16_0 = xyd.tables.sound:getSound("ui_button_click")

			audio.playSound(var_16_0, false)
			xyd.WindowManager.get():openWindow("third_anni_boss_reward")
		end
	end)
	arg_13_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_13_0:nodeByName("btn_rank"), arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			local var_17_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_17_0, false)

			local var_17_1 = {}

			arg_13_0.thirdAnniversary:getBossRankList(var_17_1, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("third_anniversary_boss_rank")
				end
			end)
		end
	end)
	arg_13_0:nodeByName("btn_fight"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_13_0:nodeByName("btn_fight"), arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_13_0:dealWrongTimeChallenge() then
				return
			end

			xyd.WindowManager.get():closeWindow("new_item_tips")

			arg_13_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

			if arg_13_0.player:getBackpack():getItemNumByID(xyd.tables.misc.thirdAnniversaryBossTicket) <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("TRIAL_TIMES_ERROR")
				})
			else
				arg_13_0.guild:loadAllTeamHeros({}, function(arg_20_0)
					local var_20_0 = false
					local var_20_1 = {}
					local var_20_2 = false
					local var_20_3 = false

					if arg_20_0 == xyd.error.OK then
						var_20_0 = true

						for iter_20_0, iter_20_1 in ipairs(arg_13_0.guild:getAllTeamHeros()) do
							local var_20_4 = var_0_4.new()

							var_20_4:populate(iter_20_1)

							var_20_4.player_name = iter_20_1.player_name
							var_20_4.rent_need_mana = iter_20_1.rent_need_mana
							var_20_4.can_rent = iter_20_1.can_rent
							var_20_4.player_id = iter_20_1.player_id

							table.insert(var_20_1, var_20_4)

							if iter_20_1.color >= xyd.EquipQuality.PURPLE then
								var_20_2 = true
							end
						end
					end

					for iter_20_2, iter_20_3 in pairs(arg_13_0.player.heros_) do
						if iter_20_3.color_ >= xyd.EquipQuality.PURPLE then
							var_20_3 = true

							break
						end
					end

					local var_20_5 = {
						hasPet = true,
						type = xyd.SelectTeamType.THIRD_ANNIVERSARY_BOSS,
						isMercenary = var_20_0,
						allTeamHeros = var_20_1,
						campaignType = xyd.CampaignType.THIRD_ANNIVERSARY_BOSS,
						hasPurpleHero = var_20_3,
						hasGuildPurpleHero = var_20_2
					}

					xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_20_5)
				end)
			end
		end
	end)
end

function var_0_0.dealWrongTimeChallenge(arg_21_0)
	local var_21_0 = arg_21_0:checkTimeCanDo()

	if var_21_0 == true then
		return true
	elseif var_21_0 == false then
		local var_21_1 = var_0_2:translation("THIRD_ANNIVERSARY_BOSS_TEXT13")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_21_1
		})

		return false
	end

	return true
end

function var_0_0.checkTimeCanDo(arg_22_0)
	return arg_22_0.isOpen
end

return var_0_0
