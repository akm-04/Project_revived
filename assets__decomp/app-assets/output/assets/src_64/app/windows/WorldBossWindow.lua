local var_0_0 = class("WorldBossWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.worldBoss
local var_0_4 = 5
local var_0_5 = 2000000
local var_0_6 = 10015
local var_0_7 = {
	0,
	175,
	370,
	640,
	840,
	1015
}
local var_0_8 = {
	1,
	5,
	2,
	4,
	3
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.fromMain = arg_1_2.fromMain
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.WorldBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.WORLD_BOSS)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.bossNum = var_0_3.boss_num
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.bossCur = {}
	arg_2_0.bossUn = {}
	arg_2_0.bossDef = {}

	for iter_2_0 = 1, arg_2_0.bossNum do
		arg_2_0.bossCur[iter_2_0] = arg_2_0:nodeByName("boss" .. iter_2_0)
		arg_2_0.bossUn[iter_2_0] = arg_2_0:nodeByName("boss_un" .. iter_2_0)
		arg_2_0.bossDef[iter_2_0] = arg_2_0:nodeByName("boss_def" .. iter_2_0)
	end

	arg_2_0.addBtn = arg_2_0:nodeByName("add_btn")

	arg_2_0:init()
	arg_2_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_3_0 = {
				title_name = "WORLD_BOSS_TITLE",
				rule = "WORLD_BOSS_RULES"
			}

			xyd.WindowManager.get():openWindow("text_rule", var_3_0)
		end
	end)
	arg_2_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			arg_2_0.arena:loadRankInfo(function(arg_5_0)
				local var_5_0 = {
					rank_type = xyd.RankType.WB,
					sub_type = arg_2_0.boss_id,
					rankData = arg_2_0.arena:getRankData()
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.rankWnd, var_5_0)
			end)
		end
	end)
	arg_2_0.addBtn:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if xyd.tables.refreshCost:buyBossCost(arg_2_0.WorldBoss.buyBossTimes + 1) ~= 0 then
				if arg_2_0.WorldBoss.buyBossTimes < xyd.tables.vip.buyElementTimes_[arg_2_0.selfPlayer.vip] then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("WORLD_BOSS_BUY_TIMES_ALERT"), xyd.tables.refreshCost:buyBossCost(arg_2_0.WorldBoss.buyBossTimes + 1), var_0_4), function()
						if arg_2_0.selfPlayer.crystal < xyd.tables.refreshCost:buyBossCost(arg_2_0.WorldBoss.buyBossTimes + 1) then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
								xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
							end, nil, nil, arg_2_0.colorMode)
						else
							arg_2_0.WorldBoss:buyTimes(function(arg_9_0, arg_9_1)
								if arg_9_0 == xyd.error.OK then
									arg_2_0:updateSence()
								end
							end)
						end
					end, nil, 0, arg_2_0.colorMode)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("ELEMENT_RESET_VIP")
					})
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("DAILY_TIMES_OVER")
				})
			end
		end
	end)
	arg_2_0:nodeByName("ask_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("world_boss_bar_des")
		end
	end)
end

function var_0_0.updateSence(arg_11_0)
	arg_11_0.WorldBoss:loadWorldBoss(function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0:init()
		end
	end, false)
end

function var_0_0.init(arg_13_0)
	arg_13_0.challenge_times = arg_13_0.WorldBoss.challenge_times
	arg_13_0.boss_id = xyd.tables.worldBoss.ids_[arg_13_0.WorldBoss.boss_id]

	arg_13_0:nodeByName("times_text"):setString(string.format(var_0_2:translation("WORLD_BOSS_LEFT_TIMES"), arg_13_0.challenge_times, xyd.tables.misc.dungenChallengeLimit))
	arg_13_0:nodeByName("bar"):setPercent(arg_13_0.WorldBoss.boss_brave / xyd.tables.worldBoss.need_brave[var_0_6] * 100)

	if arg_13_0.challenge_times <= 0 then
		arg_13_0.addBtn:setVisible(true)
	else
		arg_13_0.addBtn:setVisible(false)
	end

	local var_13_0 = {}

	for iter_13_0 = 1, xyd.tables.worldBoss.boss_num do
		if iter_13_0 < arg_13_0.boss_id then
			arg_13_0.bossCur[iter_13_0]:setVisible(false)
			arg_13_0.bossUn[iter_13_0]:setVisible(false)

			var_13_0[iter_13_0] = 1
		elseif iter_13_0 > arg_13_0.boss_id then
			arg_13_0.bossCur[iter_13_0]:setVisible(false)
			arg_13_0.bossDef[iter_13_0]:setVisible(false)

			var_13_0[iter_13_0] = 3
		else
			arg_13_0.bossDef[iter_13_0]:setVisible(false)
			arg_13_0.bossUn[iter_13_0]:setVisible(false)

			var_13_0[iter_13_0] = 2
		end
	end

	arg_13_0:nodeByName("window_bg"):setTouchEnabled(true)
	arg_13_0:nodeByName("window_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		local var_14_0 = arg_13_0:nodeByName("window_bg"):convertToNodeSpace(cc.p(arg_14_0.x, arg_14_0.y))

		if arg_14_0.name == "began" then
			for iter_14_0 = 1, xyd.tables.worldBoss.boss_num do
				if var_14_0.y > arg_13_0:nodeByName("bottom_container"):getHeight() * 1.2 then
					local var_14_1 = var_0_8[iter_14_0]

					if var_14_0.x < var_0_7[var_14_1 + 1] and var_14_0.x > var_0_7[var_14_1] then
						xyd.playButtonSound()
					end
				end
			end

			return true
		elseif arg_14_0.name == "ended" then
			for iter_14_1 = 1, xyd.tables.worldBoss.boss_num do
				if var_14_0.y > arg_13_0:nodeByName("bottom_container"):getHeight() * 1.2 then
					local var_14_2 = var_0_8[iter_14_1]

					if var_14_0.x < var_0_7[var_14_2 + 1] and var_14_0.x > var_0_7[var_14_2] then
						xyd.playButtonSound()

						if var_13_0[iter_14_1] == 1 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("WORLD_BOSS_HAS_BEEN_SEAL")
							})
						elseif var_13_0[iter_14_1] == 2 then
							arg_13_0.WorldBoss:loadWorldBoss(function(arg_15_0, arg_15_1)
								if arg_15_0 == xyd.error.OK then
									xyd.WindowManager.get():openWindow("world_boss_battle_pre")
								end
							end, true)
						elseif var_13_0[iter_14_1] == 3 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("WORLD_BOSS_CANT_DO")
							})
						end
					end
				end
			end
		end
	end)
end

function var_0_0.willClose(arg_16_0, arg_16_1)
	if xyd.WindowManager.get():getWindow("main_scene_bottom") and arg_16_0.fromMain == false then
		local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
		local var_16_1 = xyd.WindowManager.get():openWindow("activities")

		if var_16_1 then
			local var_16_2

			var_16_1.activities = var_16_0:getActivitiesList()

			for iter_16_0, iter_16_1 in pairs(var_16_1.activities) do
				if iter_16_1.table_id == xyd.Activities.WorldBoss then
					var_16_2 = iter_16_0

					break
				end
			end

			var_16_1:leftLayout(var_16_2)
		end
	end
end

function var_0_0.didOpen(arg_17_0, arg_17_1)
	arg_17_0:addBlockLayer()
end

return var_0_0
