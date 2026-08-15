local var_0_0 = require("cjson")
local var_0_1 = require("lib.battle.framework.cocos")
local var_0_2 = "lib.fight_fish."
local var_0_3 = "lib.fight_fish."
local var_0_4 = var_0_1.getXinyoudi(ngx)
local var_0_5 = ngx
local var_0_6 = var_0_4.tables.activityFish
local var_0_7 = 5
local var_0_8 = {
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
local var_0_9 = 1
local var_0_10 = {
	0.2,
	0.2,
	0.2,
	0.2,
	0.2
}
local var_0_11 = var_0_1.class("FishBattleCreateReport", var_0_5.ctx.battle.getRequire("BattleBaseNode"))

function var_0_11.ctor(arg_1_0, arg_1_1)
	arg_1_0:initData(arg_1_1)
end

function var_0_11.initData(arg_2_0, arg_2_1)
	arg_2_0.battleType = var_0_4.BattleType.CreateReport

	if arg_2_0.battleType == var_0_4.BattleType.ReplayReport then
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

function var_0_11.run(arg_3_0)
	arg_3_0:setupConfig()
	arg_3_0:startBattle()
end

function var_0_11.setupConfig(arg_4_0)
	var_0_5.ctx.battle.count = 0
	var_0_5.ctx.battle.battleType = arg_4_0.battleType
	var_0_5.ctx.battle.specialSkill = {}

	arg_4_0:initFish()
end

function var_0_11.initFish(arg_5_0)
	arg_5_0.fighterA = arg_5_0:newFighter(arg_5_0.fighterATableID, var_0_4.TeamType.A)
	arg_5_0.fighterB = arg_5_0:newFighter(arg_5_0.fighterBTableID, var_0_4.TeamType.B)

	arg_5_0.fighterA:setTarget(arg_5_0.fighterB)
	arg_5_0.fighterB:setTarget(arg_5_0.fighterA)

	if var_0_5.ctx.battle.battleType == var_0_4.BattleType.ReplayReport then
		arg_5_0.fighterA:setupReport(arg_5_0.fighterReportData.A)
		arg_5_0.fighterB:setupReport(arg_5_0.fighterReportData.B)
	end
end

function var_0_11.newFighter(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0

	if arg_6_1 ~= var_0_7 then
		var_6_0 = var_0_6:leiming(arg_6_1)
	else
		local var_6_1

		if var_0_4.BattleType.ReplayReport == var_0_5.ctx.battle.battleType then
			var_6_1 = arg_6_0.leimingIndex
		else
			var_6_1 = math.random(1, #var_0_8)
			arg_6_0.leimingIndex = var_6_1
		end

		var_6_0 = var_0_8[var_6_1]
	end

	local var_6_2

	if var_0_4.BattleType.CreateReport == var_0_5.ctx.battle.battleType then
		var_6_2 = var_0_1.import(var_0_2 .. var_6_0).new()
	else
		var_6_2 = var_0_1.import(var_0_3 .. var_6_0).new()
	end

	if arg_6_1 == var_0_7 then
		var_6_2.__cname = "Diaoyu"
	end

	var_6_2:populateWithTableID(arg_6_1)
	var_6_2:setTeamType(arg_6_2)

	if var_0_4.BattleType.CreateReport ~= var_0_5.ctx.battle.battleType then
		if arg_6_2 == var_0_4.TeamType.A then
			var_6_2:getFighterModel():addTo(arg_6_0.window:nodeByName("node_1"))
			var_6_2:getFighterModel():flipX(true)
		else
			var_6_2:getFighterModel():addTo(arg_6_0.window:nodeByName("node_2"))
			var_6_2:getFighterModel():flipX(false)
		end
	end

	return var_6_2
end

function var_0_11.setupWindows(arg_7_0)
	arg_7_0.window = var_0_4.WindowManager.get():openWindow("fight_fish_battle", {
		fighterATableID = arg_7_0.fighterATableID,
		fighterBTableID = arg_7_0.fighterBTableID
	})
end

function var_0_11.startBattle(arg_8_0)
	arg_8_0:mainLoop()
end

function var_0_11.mainLoop(arg_9_0)
	for iter_9_0 = 1, 9999 do
		if arg_9_0:checkEnds() then
			arg_9_0:battleEnd()

			return
		end

		var_0_5.ctx.battle.count = var_0_5.ctx.battle.count + 1

		if var_0_5.ctx.battle.count == 1 then
			arg_9_0:randomEvent()
		elseif var_0_5.ctx.battle.count % 120 == 0 then
			-- block empty
		else
			local var_9_0 = false

			if var_0_4.BattleType.ReplayReport == var_0_5.ctx.battle.battleType then
				local var_9_1 = arg_9_0.fighterA.reportSpecialSkills_[tostring(var_0_5.ctx.battle.count)]

				if var_9_1 then
					arg_9_0.fighterA:beginSpecialSkill(var_9_1)
				end

				local var_9_2 = arg_9_0.fighterB.reportSpecialSkills_[tostring(var_0_5.ctx.battle.count)]

				if var_9_2 then
					arg_9_0.fighterB:beginSpecialSkill(var_9_2)
				end
			elseif #var_0_5.ctx.battle.specialSkill > 0 then
				local var_9_3 = table.remove(var_0_5.ctx.battle.specialSkill, 1)
				local var_9_4 = var_9_3.fighter
				local var_9_5 = var_9_3.skillID

				var_9_4:beginSpecialSkill(var_9_5)

				var_9_0 = true
			end

			if not var_9_0 then
				if arg_9_0.fighterA:canAttack() and not arg_9_0.fighterB:canAttack() then
					arg_9_0.fighterA:beginAttack()
				elseif not arg_9_0.fighterA:canAttack() and arg_9_0.fighterB:canAttack() then
					arg_9_0.fighterB:beginAttack()
				elseif arg_9_0.fighterA:canAttack() and arg_9_0.fighterB:canAttack() then
					if arg_9_0.fighterA:getLeftInterval() < arg_9_0.fighterB:getLeftInterval() then
						arg_9_0.fighterA:beginAttack()
					elseif arg_9_0.fighterA:getLeftInterval() > arg_9_0.fighterB:getLeftInterval() then
						arg_9_0.fighterB:beginAttack()
					else
						arg_9_0.fighterA:beginAttack()
					end
				else
					arg_9_0.fighterA:updateLeftInterval()
					arg_9_0.fighterB:updateLeftInterval()
				end
			end
		end
	end
end

function var_0_11.pauseBattle(arg_10_0)
	return
end

function var_0_11.checkEnds(arg_11_0)
	if arg_11_0.fighterA:isDeath() then
		return true
	elseif arg_11_0.fighterB:isDeath() then
		return true
	end

	return false
end

function var_0_11.battleEnd(arg_12_0)
	arg_12_0:pauseBattle()
	arg_12_0:writeReport()
end

function var_0_11.randomEvent(arg_13_0)
	local var_13_0

	if var_0_4.BattleType.ReplayReport == var_0_5.ctx.battle.battleType then
		var_13_0 = arg_13_0.eventIndex
	elseif var_0_4.weightedChoise({
		var_0_9,
		1 - var_0_9
	}) == 1 then
		var_13_0 = var_0_4.weightedChoise({
			var_0_10[1],
			var_0_10[2],
			var_0_10[3],
			var_0_10[4],
			var_0_10[5]
		})
		arg_13_0.eventIndex = var_13_0
	end

	if not var_13_0 then
		return
	end

	if var_13_0 == var_0_4.FishEvent.NUAN_LIU then
		local var_13_1 = arg_13_0.fighterA:newSceneBuff(9999, nil, nil, var_0_4.FishEvent.NUAN_LIU)

		arg_13_0.fighterA:addSceneBuff(var_13_1)

		local var_13_2 = arg_13_0.fighterB:newSceneBuff(9999, nil, nil, var_0_4.FishEvent.NUAN_LIU)

		arg_13_0.fighterB:addSceneBuff(var_13_2)
	elseif var_13_0 == var_0_4.FishEvent.BING_HE then
		local var_13_3 = arg_13_0.fighterA:newSceneBuff(9999, nil, nil, var_0_4.FishEvent.BING_HE)

		arg_13_0.fighterA:addSceneBuff(var_13_3)

		local var_13_4 = arg_13_0.fighterB:newSceneBuff(9999, nil, nil, var_0_4.FishEvent.BING_HE)

		arg_13_0.fighterB:addSceneBuff(var_13_4)
	elseif var_13_0 == var_0_4.FishEvent.CHI_CHAO then
		local var_13_5 = math.ceil(arg_13_0.fighterA:getHp() * 0.3)

		arg_13_0.fighterA:updateHp(arg_13_0.fighterA:getHp() - var_13_5)
		arg_13_0.fighterA:playHPDeltas(-var_13_5, false)

		local var_13_6 = math.ceil(arg_13_0.fighterB:getHp() * 0.3)

		arg_13_0.fighterB:updateHp(arg_13_0.fighterB:getHp() - var_13_6)
		arg_13_0.fighterA:playHPDeltas(-var_13_6, false)
	elseif var_13_0 == var_0_4.FishEvent.XIE_LOU then
		local var_13_7 = arg_13_0.fighterA:newSceneBuff(9999, var_0_4.FishAttributeType.BAOJI, 0.1, var_0_4.FishEvent.XIE_LOU)

		arg_13_0.fighterA:addSceneBuff(var_13_7)

		local var_13_8 = arg_13_0.fighterB:newSceneBuff(9999, var_0_4.FishAttributeType.BAOJI, 0.1, var_0_4.FishEvent.XIE_LOU)

		arg_13_0.fighterB:addSceneBuff(var_13_8)
	elseif var_13_0 == var_0_4.FishEvent.BAO_FENG_YU then
		local var_13_9 = arg_13_0.fighterA:newSceneBuff(9999, var_0_4.FishAttributeType.SHANBI, 0.1, var_0_4.FishEvent.BAO_FENG_YU)

		arg_13_0.fighterA:addSceneBuff(var_13_9)

		local var_13_10 = arg_13_0.fighterB:newSceneBuff(9999, var_0_4.FishAttributeType.SHANBI, 0.1, var_0_4.FishEvent.BAO_FENG_YU)

		arg_13_0.fighterB:addSceneBuff(var_13_10)
	end
end

function var_0_11.writeReport(arg_14_0, arg_14_1)
	if arg_14_0.report_ and not arg_14_1 then
		return var_0_0.encode(arg_14_0.report_)
	end

	arg_14_0.report_ = {}
	arg_14_0.report_.fighterATableID = arg_14_0.fighterATableID
	arg_14_0.report_.fighterBTableID = arg_14_0.fighterBTableID
	arg_14_0.report_.isWin = arg_14_0.fighterB:isDeath() and 1 or 0
	arg_14_0.report_.fighter = {}
	arg_14_0.report_.fighter.A = arg_14_0.fighterA:writeReport()
	arg_14_0.report_.fighter.B = arg_14_0.fighterB:writeReport()
	arg_14_0.report_.leimingIndex = arg_14_0.leimingIndex
	arg_14_0.report_.eventIndex = arg_14_0.eventIndex

	return var_0_0.encode(arg_14_0.report_)
end

return var_0_11
