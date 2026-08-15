local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lvbu", var_0_1.ctx.battle.requireFighter("Lvbu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10001035
local var_0_6 = 10001039
local var_0_7 = 10001036
local var_0_8 = 40011144
local var_0_9 = 10
local var_0_10 = 0.3
local var_0_11 = 0.002
local var_0_12 = 0.001
local var_0_13 = 40011376
local var_0_14 = 40011377
local var_0_15 = 80220041
local var_0_16 = 40011552

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.TwiceAwakeBlueSkillTimes = 0
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getOrbOfFrontSkill(arg_2_0)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		var_2_0 = var_0_5
	end

	return var_2_0
end

function var_0_3.purpleSkill(arg_3_0)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_3_0.bloodyTarget_ and var_0_1.ctx.battle.count % 10 == 0 and not arg_3_0:isCreatingUnits() then
		local var_3_0
		local var_3_1

		if arg_3_0.partnerKiller_ and not arg_3_0.partnerKiller_:isDeath() and not arg_3_0.partnerKiller_:isAffected() and arg_3_0.partnerKiller_:getTeamType() ~= arg_3_0:getTeamType() then
			var_3_1 = arg_3_0.partnerKiller_
			arg_3_0.partnerKiller_ = nil
		else
			for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
				if not iter_3_1:isDeath() and (not iter_3_1:isAffected() or not not iter_3_1:isInvisible()) and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
					local var_3_2 = iter_3_1:getHp() / iter_3_1:getHpLimit()

					if var_3_2 <= var_0_10 and (not var_3_0 or var_3_2 < var_3_0) then
						var_3_0 = var_3_2
						var_3_1 = iter_3_1
					end
				end
			end
		end

		if var_3_1 then
			arg_3_0.bloodyTarget_ = var_3_1

			arg_3_0:removeNegativeBuff()

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_3 = arg_3_0:createAttackUnits({
					arg_3_0
				}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_3_2, iter_3_3 in ipairs(var_3_3) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end

				if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
					local var_3_4 = arg_3_0:createAttackUnits({
						arg_3_0
					}, var_0_6)

					for iter_3_4, iter_3_5 in ipairs(var_3_4) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
						table.insert(arg_3_0.records_.special_units, iter_3_5)
					end
				end
			end
		end
	elseif arg_3_0.bloodyTarget_ and (arg_3_0.bloodyTarget_:isAffected() and not arg_3_0.bloodyTarget_:isInvisible() or arg_3_0.bloodyTarget_:isDeath()) and (not arg_3_0.unitSkills_ or arg_3_0.unitSkills_.rootID_ ~= arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) then
		arg_3_0.bloodyTarget_ = nil

		arg_3_0:removePurpleBuff()
	end
end

function var_0_3.deathFeedback(arg_4_0, arg_4_1)
	if arg_4_1.killer_ then
		local var_4_0 = arg_4_1:getBuffByID(var_0_16)

		if var_4_0 and var_4_0.fighter == arg_4_0 then
			arg_4_0.partnerKiller_ = arg_4_1.killer_
		end

		local var_4_1 = 1

		if arg_4_1.killer_ and arg_4_1.killer_ == arg_4_0 then
			var_4_1 = 2
		end

		if arg_4_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_4_1 = var_4_1 * var_0_11 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		else
			var_4_1 = var_4_1 * var_0_12 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		end

		arg_4_0.blueReHp_ = arg_4_0:getDCureRate() * var_4_1 * math.min(arg_4_0:getHpLimit(), arg_4_1:getHpLimit())

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_2 = arg_4_0:createAttackUnits({
				arg_4_0
			}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			for iter_4_0, iter_4_1 in ipairs(var_4_2) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_4_0.TwiceAwakeBlueSkillTimes < var_0_9 then
				arg_4_0.TwiceAwakeBlueSkillTimes = arg_4_0.TwiceAwakeBlueSkillTimes + 1

				local var_4_3 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_7)

				for iter_4_2, iter_4_3 in ipairs(var_4_3) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
					table.insert(arg_4_0.records_.special_units, iter_4_3)
				end
			end
		end
	end

	if arg_4_0.bloodyTarget_ and arg_4_1 == arg_4_0.bloodyTarget_ and (not arg_4_0.unitSkills_ or arg_4_0.unitSkills_.rootID_ ~= arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) then
		arg_4_0.bloodyTarget_ = nil

		arg_4_0:removePurpleBuff()
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_1:getTeamType() == arg_4_0:getTeamType() and arg_4_1:getSummonType() == var_0_2.summonMonsterType.None then
		local var_4_4 = {
			arg_4_0
		}
		local var_4_5 = arg_4_0:createAttackUnits(var_4_4, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_4_4, iter_4_5 in ipairs(var_4_5) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
			table.insert(arg_4_0.records_.special_units, iter_4_5)
		end
	end

	if arg_4_1:getTeamType() == arg_4_0:getTeamType() and arg_4_1:getSummonType() == var_0_2.summonMonsterType.None and arg_4_0.extraSkillLevel3 > 0 then
		local var_4_6 = var_0_4.new({
			tableID = var_0_13,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0.extraSkillLevel3,
			skillID = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_4_0,
			target = arg_4_0,
			manualRevise = arg_4_1:getHuJia() * arg_4_0.extraSkillRate3
		})

		arg_4_0:addBuffs({
			var_4_6
		})

		local var_4_7 = var_0_4.new({
			tableID = var_0_14,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0.extraSkillLevel3,
			skillID = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_4_0,
			target = arg_4_0,
			manualRevise = arg_4_1:getMoKang() * arg_4_0.extraSkillRate3
		})

		arg_4_0:addBuffs({
			var_4_7
		})
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	var_0_3.super.buffRemoveAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_8 then
		arg_5_0.TwiceAwakeBlueSkillTimes = arg_5_0.TwiceAwakeBlueSkillTimes - 1
	end
end

return var_0_3
