local var_0_0 = class("FishBattleCreate", import("app.common.ui.BaseScene"))
local var_0_1 = require("cjson")
local var_0_2 = require("lib.battle.framework.cocos")
local var_0_3 = "lib.fight_fish."
local var_0_4 = "lib.fight_fish."
local var_0_5 = xyd
local var_0_6 = ngx
local var_0_7 = var_0_5.tables.activityFish
local var_0_8 = 5
local var_0_9 = {
	"Ailier",
	"Bimuyu",
	"Buzhi",
	"Denglongyu",
	"Guiyu",
	"Hetun",
	"Huangdaiyu",
	"Hudieyu",
	"Jinqiangyu",
	"Luyu",
	"Shayu",
	"Shiziyu",
	"Xiaochouyu",
	"Xunyu",
	"Youyu"
}
local var_0_10 = {
	15,
	6,
	16,
	8,
	2,
	11,
	13,
	7,
	1,
	3,
	14,
	9,
	10,
	12,
	4
}
local var_0_11 = 1
local var_0_12 = {
	0.2,
	0.2,
	0.2,
	0.2,
	0.2
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	cc.Director:getInstance():purgeCachedData()
	var_0_0.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:initData(arg_1_1)
end

function var_0_0.initData(arg_2_0, arg_2_1)
	arg_2_0.battleType = arg_2_1.battleType

	if arg_2_0.battleType == var_0_5.BattleType.ReplayReport then
		arg_2_0.fighterReportData = arg_2_1.reportData.fighter
		arg_2_0.fighterATableID = arg_2_1.reportData.fighterATableID
		arg_2_0.fighterBTableID = arg_2_1.reportData.fighterBTableID
		arg_2_0.leimingIndex = arg_2_1.reportData.leimingIndex
		arg_2_0.eventIndex = arg_2_1.reportData.eventIndex
	else
		arg_2_0.fighterATableID = arg_2_1.fighterATableID
		arg_2_0.fighterBTableID = arg_2_1.fighterBTableID
	end
end

function var_0_0.onEnter(arg_3_0)
	audio.stopAllSounds()
	audio.stopMusic()

	local var_3_0 = var_0_5.tables.sound:getSound("douyu_bgm")

	audio.playMusic(var_3_0, true)
end

function var_0_0.onExit(arg_4_0)
	audio.stopAllSounds()
	audio.stopMusic()

	local var_4_0 = var_0_5.tables.sound:getSound("home_bg_music")

	audio.playMusic(var_4_0, true)
end

function var_0_0.onEnterTransitionFinish(arg_5_0)
	var_0_0.super.onEnterTransitionFinish(arg_5_0)
	arg_5_0:setupWindows()
	arg_5_0:setupConfig()
	arg_5_0:runEnterAction()
end

function var_0_0.runEnterAction(arg_6_0)
	local var_6_0 = transition.sequence({
		cc.DelayTime:create(0.5),
		cc.CallFunc:create(function()
			arg_6_0.fighterA:enterAction()
			arg_6_0.fighterB:enterAction()
		end),
		cc.DelayTime:create(0.5),
		cc.CallFunc:create(function()
			arg_6_0:startBattle()
		end)
	})

	arg_6_0:runAction(var_6_0)
end

function var_0_0.setupConfig(arg_9_0)
	var_0_6.ctx.battle.count = 0
	var_0_6.ctx.battle.battleType = arg_9_0.battleType
	var_0_6.ctx.battle.specialSkill = {}

	arg_9_0:initFish()
end

function var_0_0.initFish(arg_10_0)
	arg_10_0.fighterA = arg_10_0:newFighter(arg_10_0.fighterATableID, var_0_5.TeamType.A)
	arg_10_0.fighterB = arg_10_0:newFighter(arg_10_0.fighterBTableID, var_0_5.TeamType.B)

	arg_10_0.fighterA:setTarget(arg_10_0.fighterB)
	arg_10_0.fighterB:setTarget(arg_10_0.fighterA)

	if var_0_6.ctx.battle.battleType == var_0_5.BattleType.ReplayReport then
		arg_10_0.fighterA:setupReport(arg_10_0.fighterReportData.A)
		arg_10_0.fighterB:setupReport(arg_10_0.fighterReportData.B)
	end
end

function var_0_0.newFighter(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0
	local var_11_1

	if arg_11_1 ~= var_0_8 then
		var_11_0 = var_0_7:leiming(arg_11_1)
	else
		if var_0_5.BattleType.ReplayReport == var_0_6.ctx.battle.battleType then
			var_11_1 = arg_11_0.leimingIndex
		else
			var_11_1 = math.random(1, #var_0_9)
			arg_11_0.leimingIndex = var_11_1
		end

		var_11_0 = var_0_9[var_11_1]
	end

	local var_11_2

	if var_0_5.BattleType.CreateReport == var_0_6.ctx.battle.battleType then
		var_11_2 = var_0_2.import(var_0_3 .. var_11_0).new()
	else
		var_11_2 = var_0_2.import(var_0_4 .. var_11_0).new()
	end

	var_11_2:populateWithTableID(arg_11_1)
	var_11_2:setTeamType(arg_11_2)

	if arg_11_1 == var_0_8 then
		var_11_2.__cname = "Diaoyu"
		var_11_2.bianshenTableID = var_0_10[var_11_1]

		var_11_2:addGuiyuMessage(var_0_10[var_11_1])
	end

	if var_0_5.BattleType.CreateReport ~= var_0_6.ctx.battle.battleType then
		if arg_11_2 == var_0_5.TeamType.A then
			var_11_2:setEffectNode(arg_11_0.window:nodeByName("node_1"))
			var_11_2:getFighterModel():addTo(arg_11_0.window:nodeByName("node_1"))
			var_11_2:getFighterModel():flipX(true)
			var_11_2:getFighterModel():setScale(0)
		else
			var_11_2:setEffectNode(arg_11_0.window:nodeByName("node_2"))
			var_11_2:getFighterModel():addTo(arg_11_0.window:nodeByName("node_2"))
			var_11_2:getFighterModel():flipX(false)
			var_11_2:getFighterModel():setScale(0)
		end
	end

	return var_11_2
end

function var_0_0.setupWindows(arg_12_0)
	arg_12_0.window = var_0_5.WindowManager.get():openWindow("fight_fish_battle", {
		fighterATableID = arg_12_0.fighterATableID,
		fighterBTableID = arg_12_0.fighterBTableID
	})
end

function var_0_0.startBattle(arg_13_0)
	arg_13_0:mainLoop()
end

function var_0_0.delayStartBattle(arg_14_0, arg_14_1, arg_14_2)
	arg_14_1 = arg_14_1 or 1

	if var_0_5.BattleType.CreateReport ~= var_0_6.ctx.battle.battleType then
		require("framework.scheduler").performWithDelayGlobal(function()
			if arg_14_0 and not tolua.isnull(arg_14_0) then
				if arg_14_2 then
					arg_14_2()
				end

				arg_14_0:startBattle()
			end
		end, arg_14_1)
	end
end

function var_0_0.mainLoop(arg_16_0)
	for iter_16_0 = 1, 9999 do
		if tolua.isnull(arg_16_0) then
			arg_16_0:pauseBattle()

			return
		end

		if arg_16_0:checkEnds() then
			arg_16_0:battleEnd()

			return
		end

		var_0_6.ctx.battle.count = var_0_6.ctx.battle.count + 1

		if var_0_6.ctx.battle.count == 1 then
			arg_16_0:randomEvent()
			arg_16_0:delayStartBattle()

			return
		end

		if var_0_6.ctx.battle.count % 120 == 0 then
			arg_16_0:addHarmMessage()
			arg_16_0:delayStartBattle()

			return
		end

		if var_0_5.BattleType.ReplayReport == var_0_6.ctx.battle.battleType then
			local var_16_0 = arg_16_0.fighterA.reportSpecialSkills_[tostring(var_0_6.ctx.battle.count)]

			if var_16_0 then
				arg_16_0.fighterA:beginSpecialSkill(var_16_0)

				return
			end

			local var_16_1 = arg_16_0.fighterB.reportSpecialSkills_[tostring(var_0_6.ctx.battle.count)]

			if var_16_1 then
				arg_16_0.fighterB:beginSpecialSkill(var_16_1)

				return
			end
		elseif #var_0_6.ctx.battle.specialSkill > 0 then
			local var_16_2 = table.remove(var_0_6.ctx.battle.specialSkill, 1)
			local var_16_3 = var_16_2.fighter
			local var_16_4 = var_16_2.skillID

			var_16_3:beginSpecialSkill(var_16_4)

			return
		end

		if arg_16_0.fighterA:canAttack() and not arg_16_0.fighterB:canAttack() then
			arg_16_0.fighterA:beginAttack()

			return
		elseif not arg_16_0.fighterA:canAttack() and arg_16_0.fighterB:canAttack() then
			arg_16_0.fighterB:beginAttack()

			return
		elseif arg_16_0.fighterA:canAttack() and arg_16_0.fighterB:canAttack() then
			if arg_16_0.fighterA:getLeftInterval() < arg_16_0.fighterB:getLeftInterval() then
				arg_16_0.fighterA:beginAttack()

				return
			elseif arg_16_0.fighterA:getLeftInterval() > arg_16_0.fighterB:getLeftInterval() then
				arg_16_0.fighterB:beginAttack()

				return
			else
				arg_16_0.fighterA:beginAttack()

				return
			end
		else
			arg_16_0.fighterA:updateLeftInterval()
			arg_16_0.fighterB:updateLeftInterval()
		end
	end
end

function var_0_0.pauseBattle(arg_17_0)
	return
end

function var_0_0.checkEnds(arg_18_0)
	if arg_18_0.fighterA:isDeath() then
		return true
	elseif arg_18_0.fighterB:isDeath() then
		return true
	end

	return false
end

function var_0_0.battleEnd(arg_19_0)
	arg_19_0:addEndMessage()
	arg_19_0.window:addEndEffect()
	arg_19_0:pauseBattle()
	arg_19_0:writeReport()
end

function var_0_0.randomEvent(arg_20_0)
	local var_20_0

	if var_0_5.BattleType.ReplayReport == var_0_6.ctx.battle.battleType then
		var_20_0 = arg_20_0.eventIndex
	elseif var_0_5.weightedChoise({
		var_0_11,
		1 - var_0_11
	}) == 1 then
		var_20_0 = var_0_5.weightedChoise({
			var_0_12[1],
			var_0_12[2],
			var_0_12[3],
			var_0_12[4],
			var_0_12[5]
		})
		arg_20_0.eventIndex = var_20_0
	end

	if not var_20_0 then
		return
	end

	local var_20_1 = {
		event = var_20_0
	}

	if var_20_0 == var_0_5.FishEvent.NUAN_LIU then
		local var_20_2 = arg_20_0.fighterA:newSceneBuff(9999, nil, nil, var_0_5.FishEvent.NUAN_LIU)

		arg_20_0.fighterA:addSceneBuff(var_20_2)

		local var_20_3 = arg_20_0.fighterB:newSceneBuff(9999, nil, nil, var_0_5.FishEvent.NUAN_LIU)

		arg_20_0.fighterB:addSceneBuff(var_20_3)
	elseif var_20_0 == var_0_5.FishEvent.BING_HE then
		local var_20_4 = arg_20_0.fighterA:newSceneBuff(9999, nil, nil, var_0_5.FishEvent.BING_HE)

		arg_20_0.fighterA:addSceneBuff(var_20_4)

		local var_20_5 = arg_20_0.fighterB:newSceneBuff(9999, nil, nil, var_0_5.FishEvent.BING_HE)

		arg_20_0.fighterB:addSceneBuff(var_20_5)
	elseif var_20_0 == var_0_5.FishEvent.CHI_CHAO then
		local var_20_6 = math.ceil(arg_20_0.fighterA:getHp() * 0.3)

		arg_20_0.fighterA:updateHp(arg_20_0.fighterA:getHp() - var_20_6)
		arg_20_0.fighterA:playHPDeltas(-var_20_6, false)

		local var_20_7 = math.ceil(arg_20_0.fighterB:getHp() * 0.3)

		arg_20_0.fighterB:updateHp(arg_20_0.fighterB:getHp() - var_20_7)
		arg_20_0.fighterB:playHPDeltas(-var_20_7, false)
	elseif var_20_0 == var_0_5.FishEvent.XIE_LOU then
		local var_20_8 = arg_20_0.fighterA:newSceneBuff(9999, var_0_5.FishAttributeType.BAOJI, 0.1, var_0_5.FishEvent.XIE_LOU)

		arg_20_0.fighterA:addSceneBuff(var_20_8)

		local var_20_9 = arg_20_0.fighterB:newSceneBuff(9999, var_0_5.FishAttributeType.BAOJI, 0.1, var_0_5.FishEvent.XIE_LOU)

		arg_20_0.fighterB:addSceneBuff(var_20_9)
	elseif var_20_0 == var_0_5.FishEvent.BAO_FENG_YU then
		local var_20_10 = arg_20_0.fighterA:newSceneBuff(9999, var_0_5.FishAttributeType.SHANBI, 0.1, var_0_5.FishEvent.BAO_FENG_YU)

		arg_20_0.fighterA:addSceneBuff(var_20_10)

		local var_20_11 = arg_20_0.fighterB:newSceneBuff(9999, var_0_5.FishAttributeType.SHANBI, 0.1, var_0_5.FishEvent.BAO_FENG_YU)

		arg_20_0.fighterB:addSceneBuff(var_20_11)
	end

	arg_20_0:addEventMessage(var_20_1)
end

function var_0_0.addEventMessage(arg_21_0, arg_21_1)
	if var_0_5.BattleType.CreateReport == var_0_6.ctx.battle.battleType then
		return
	end

	local var_21_0 = arg_21_1.event
	local var_21_1
	local var_21_2

	if var_21_0 == var_0_5.FishEvent.NUAN_LIU then
		local var_21_3 = arg_21_0:getRandomMessage("nuanliu")
		local var_21_4 = var_21_3[1]
		local var_21_5 = var_21_3[2]

		var_21_1 = var_21_4 .. "|" .. var_21_5
	elseif var_21_0 == var_0_5.FishEvent.BING_HE then
		local var_21_6 = arg_21_0:getRandomMessage("binghe")
		local var_21_7 = var_21_6[1]
		local var_21_8 = var_21_6[2]

		var_21_1 = var_21_7 .. "|" .. var_21_8
	elseif var_21_0 == var_0_5.FishEvent.CHI_CHAO then
		var_21_1 = arg_21_0:getRandomMessage("chichao")[1]
	elseif var_21_0 == var_0_5.FishEvent.XIE_LOU then
		local var_21_9 = arg_21_0:getRandomMessage("xielou")
		local var_21_10 = var_21_9[1]
		local var_21_11 = var_21_9[2]

		var_21_1 = var_21_10 .. "|" .. var_21_11
	elseif var_21_0 == var_0_5.FishEvent.BAO_FENG_YU then
		local var_21_12 = arg_21_0:getRandomMessage("baofengyu")
		local var_21_13 = var_21_12[1]
		local var_21_14 = var_21_12[2]

		var_21_1 = var_21_13 .. "|" .. var_21_14
	elseif var_21_0 == var_0_5.FishEvent.KOU_XUE then
		local var_21_15 = arg_21_1.fighter

		var_21_2 = var_21_15:getTeamType()

		local var_21_16 = arg_21_0:getRandomMessage("huoshan")

		var_21_1 = string.format(var_21_16[1], var_21_15:getName(), arg_21_1.hp)
	elseif var_21_0 == var_0_5.FishEvent.HUI_XUE then
		local var_21_17 = arg_21_1.fighter

		var_21_2 = var_21_17:getTeamType()

		local var_21_18 = arg_21_0:getRandomMessage("huixue2")

		var_21_1 = string.format(var_21_18[1], var_21_17:getName(), arg_21_1.hp)
	elseif var_21_0 == var_0_5.FishEvent.GONG_JI then
		local var_21_19 = arg_21_1.fighter

		var_21_2 = var_21_19:getTeamType()

		local var_21_20 = arg_21_0:getRandomMessage("gongjibuff")
		local var_21_21 = string.format(var_21_20[1], var_21_19:getName())
		local var_21_22 = var_21_20[2]

		var_21_1 = var_21_21 .. "|" .. var_21_22
	elseif var_21_0 == var_0_5.FishEvent.SU_DU then
		local var_21_23 = arg_21_1.fighter

		var_21_2 = var_21_23:getTeamType()

		local var_21_24 = arg_21_0:getRandomMessage("sudubuff")

		var_21_1 = string.format(var_21_24[1], var_21_23:getName())
	elseif var_21_0 == var_0_5.FishEvent.XING_DONG then
		local var_21_25 = arg_21_1.fighter

		var_21_2 = var_21_25:getTeamType()

		local var_21_26 = arg_21_0:getRandomMessage("wufaxingdong2")

		var_21_1 = string.format(var_21_26[1], var_21_25:getName())
	end

	arg_21_0.window:addMessage(var_21_1, var_21_2)
end

function var_0_0.addEndMessage(arg_22_0)
	if var_0_5.BattleType.CreateReport == var_0_6.ctx.battle.battleType then
		return
	end

	local var_22_0
	local var_22_1

	if arg_22_0.fighterA:isDeath() then
		var_22_0 = arg_22_0.fighterB
		var_22_1 = arg_22_0.fighterA
	else
		var_22_0 = arg_22_0.fighterA
		var_22_1 = arg_22_0.fighterB
	end

	local var_22_2 = arg_22_0:getRandomMessage("jieshu")
	local var_22_3 = string.format(var_22_2[1], var_22_1:getName(), var_22_0:getName())

	arg_22_0.window:addMessage(var_22_3)
end

function var_0_0.addHarmMessage(arg_23_0)
	if var_0_5.BattleType.CreateReport == var_0_6.ctx.battle.battleType then
		return
	end

	local var_23_0 = arg_23_0:getRandomMessage("houqi")
	local var_23_1 = string.format(var_23_0[1])

	arg_23_0.window:addMessage(var_23_1)
end

function var_0_0.getRandomMessage(arg_24_0, arg_24_1)
	local var_24_0 = var_0_5.tables.activityFishBattleText:getDesc(arg_24_1)
	local var_24_1 = var_24_0[math.random(#var_24_0)]

	return (var_0_5.split(var_24_1))
end

function var_0_0.writeReport(arg_25_0)
	if arg_25_0.report_ then
		return var_0_1.encode(arg_25_0.report_)
	end

	arg_25_0.report_ = {}
	arg_25_0.report_.fighterATableID = arg_25_0.fighterATableID
	arg_25_0.report_.fighterBTableID = arg_25_0.fighterBTableID
	arg_25_0.report_.fighter = {}
	arg_25_0.report_.fighter.A = arg_25_0.fighterA:writeReport()
	arg_25_0.report_.fighter.B = arg_25_0.fighterB:writeReport()
	arg_25_0.report_.leimingIndex = arg_25_0.leimingIndex
	arg_25_0.report_.eventIndex = arg_25_0.eventIndex

	return var_0_1.encode(arg_25_0.report_)
end

return var_0_0
