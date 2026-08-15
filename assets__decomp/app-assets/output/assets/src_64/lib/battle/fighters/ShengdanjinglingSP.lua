local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ShengdanjinglingSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = {
	40012294,
	40012295
}
local var_0_7 = 0.2
local var_0_8 = 0.003
local var_0_9 = 300
local var_0_10 = 0.7
local var_0_11 = 10002406
local var_0_12 = 10002396

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.GreenBuffs = {
			40012604,
			40012293
		}
		arg_2_0.GreenSkill = 10002395
	else
		arg_2_0.GreenBuffs = {
			40012292,
			40012293
		}
		arg_2_0.GreenSkill = 20020259
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.greenTarget = nil
	arg_3_0.blueTarget = nil
	arg_3_0.skinGreenTarget = nil
	arg_3_0.skinBlueTarget = nil
	arg_3_0.skinSkillCD = 0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0.GreenSkill then
		if arg_4_0.greenTarget then
			local var_4_0 = arg_4_0.greenTarget

			if not var_4_0:isDeath() then
				for iter_4_0, iter_4_1 in ipairs(arg_4_0.GreenBuffs) do
					var_4_0:removeBuffByID(iter_4_1)
				end
			end
		end

		arg_4_0.greenTarget = arg_4_1.target

		if arg_4_0.skinSkillCD <= 0 and arg_4_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_2.weightedChoise({
			var_0_10,
			1 - var_0_10
		}) == 1 then
			local var_4_1 = arg_4_0:getSkinSkillTargets(arg_4_1.target)
			local var_4_2 = arg_4_0:createAttackUnits(var_4_1, var_0_11)

			for iter_4_2, iter_4_3 in ipairs(var_4_2) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end

			arg_4_0.skinSkillCD = var_0_9
		end
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if arg_4_0.blueTarget then
			local var_4_3 = arg_4_0.blueTarget

			if not var_4_3:isDeath() then
				for iter_4_4, iter_4_5 in ipairs(var_0_6) do
					var_4_3:removeBuffByID(iter_4_5)
				end
			end
		end

		arg_4_0.blueTarget = arg_4_1.target

		if arg_4_0.skinSkillCD <= 0 and arg_4_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_2.weightedChoise({
			var_0_10,
			1 - var_0_10
		}) == 1 then
			local var_4_4 = arg_4_0:getSkinSkillTargets(arg_4_1.target)
			local var_4_5 = arg_4_0:createAttackUnits(var_4_4, var_0_12)

			for iter_4_6, iter_4_7 in ipairs(var_4_5) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
				table.insert(arg_4_0.records_.special_units, iter_4_7)
			end

			arg_4_0.skinSkillCD = var_0_9
		end
	elseif arg_4_1.skillID == arg_4_0.SkinGreenSkill then
		if arg_4_0.skinGreenTarget then
			local var_4_6 = arg_4_0.skinGreenTarget

			if not var_4_6:isDeath() then
				for iter_4_8, iter_4_9 in ipairs(arg_4_0.GreenBuffs) do
					var_4_6:removeBuffByID(iter_4_9)
				end
			end
		end

		arg_4_0.skinGreenTarget = arg_4_1.target
	elseif arg_4_1.skillID == arg_4_0.SkinBlueSkill then
		if arg_4_0.skinBlueTarget then
			local var_4_7 = arg_4_0.skinBlueTarget

			if not var_4_7:isDeath() then
				for iter_4_10, iter_4_11 in ipairs(var_0_6) do
					var_4_7:removeBuffByID(iter_4_11)
				end
			end
		end

		arg_4_0.skinBlueTarget = arg_4_1.target
	end
end

function var_0_3.getSkinSkillTargets(arg_5_0, arg_5_1)
	if arg_5_1:getTeamType() == arg_5_0:getTeamType() then
		arg_5_0.selectTeam = arg_5_0.selfTeam_
	else
		arg_5_0.selectTeam = arg_5_0.targetTeam_
	end

	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selectTeam) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1 ~= arg_5_1 then
			table.insert(var_5_0, iter_5_1)
		end
	end

	if not var_5_0 or next(var_5_0) == nil then
		return {}
	end

	local var_5_1 = math.random(tonumber(os.time()))

	math.randomseed(var_5_1)

	return {
		var_5_0[math.random(#var_5_0)]
	}
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	arg_6_0.skinSkillCD = arg_6_0.skinSkillCD - 1

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("attack_info")) do
			if iter_6_1.fighter_ ~= arg_6_0 and iter_6_1.fighter_:getTeamType() == arg_6_0:getTeamType() then
				local var_6_0 = iter_6_1.fighter_
				local var_6_1 = var_0_7 + var_0_8 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

				if var_0_2.weightedChoise({
					var_6_1,
					1 - var_6_1
				}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_6_2 = arg_6_0:createAttackUnits({
						var_6_0
					}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					for iter_6_2, iter_6_3 in ipairs(var_6_2) do
						iter_6_3.purpleRemp = iter_6_1:getRemp() * var_6_0:getEnergyRate()

						table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
						table.insert(arg_6_0.records_.special_units, iter_6_3)
					end
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_7_7 = arg_7_1.purpleRemp
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.forceDie(arg_8_0)
	var_0_3.super.forceDie(arg_8_0)

	if arg_8_0.greenTarget then
		local var_8_0 = arg_8_0.greenTarget

		if not var_8_0:isDeath() then
			for iter_8_0, iter_8_1 in ipairs(arg_8_0.GreenBuffs) do
				var_8_0:removeBuffByID(iter_8_1)
			end
		end
	end

	if arg_8_0.blueTarget then
		local var_8_1 = arg_8_0.blueTarget

		if not var_8_1:isDeath() then
			for iter_8_2, iter_8_3 in ipairs(var_0_6) do
				var_8_1:removeBuffByID(iter_8_3)
			end
		end
	end
end

return var_0_3
