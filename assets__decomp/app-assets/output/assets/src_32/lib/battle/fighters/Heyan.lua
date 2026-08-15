local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Heyan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 50010205
local var_0_7 = 40011395
local var_0_8 = 40011389
local var_0_9 = 10001309
local var_0_10 = 20010205
local var_0_11 = 40011392
local var_0_12 = 10001310
local var_0_13 = 30010205
local var_0_14 = 10001308
local var_0_15 = 40010205
local var_0_16 = 40011388
local var_0_17 = 40011397
local var_0_18 = 40011398

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.PassiveSkillTarget = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByID(var_0_15) > 0 then
		local var_2_0 = -1
		local var_2_1

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() and var_2_0 <= iter_2_1:getDamage() then
				var_2_0 = iter_2_1:getDamage()
				var_2_1 = iter_2_1
			end
		end

		if arg_2_0.PassiveSkillTarget ~= var_2_1 then
			if var_2_1 ~= nil then
				local var_2_2 = arg_2_0:createNewBuffs({
					var_0_16,
					var_0_17,
					var_0_18
				}, var_2_1, var_0_15, arg_2_0:getSkillLevelByID(var_0_15))

				var_2_1:addBuffs(var_2_2)
			end

			if arg_2_0.PassiveSkillTarget then
				arg_2_0.PassiveSkillTarget:removeBuffByID(var_0_16)
				arg_2_0.PassiveSkillTarget:removeBuffByID(var_0_17)
				arg_2_0.PassiveSkillTarget:removeBuffByID(var_0_18)
			end

			arg_2_0.PassiveSkillTarget = var_2_1
		end
	end

	arg_2_0.EnergyTimeCount = math.max((arg_2_0.EnergyTimeCount or 0) - 1, 0)

	if arg_2_0.bIsEnergy then
		if arg_2_0.EnergyTimeCount >= 1 then
			if arg_2_0.EnergyTimeCount == 95 then
				arg_2_0:getFighterModel():playAnimation_("gongji05", true)
			end
		else
			arg_2_0.bIsEnergy = false

			arg_2_0:playAttack(6)

			if arg_2_0.harmOverload and arg_2_0.harmOverload > 0 then
				arg_2_0.harmOveload = math.min(arg_2_0:getSkillLevelByID(var_0_6) * 500 + 1000, arg_2_0.harmOverload)

				local var_2_3 = {}

				for iter_2_2, iter_2_3 in ipairs(arg_2_0.selfTeam_) do
					if not iter_2_3:isDeath() and not iter_2_3:isAffected() then
						table.insert(var_2_3, iter_2_3)
					end
				end

				local var_2_4 = arg_2_0.harmOverload / #var_2_3

				for iter_2_4, iter_2_5 in ipairs(var_2_3) do
					local var_2_5 = var_0_5.new({
						tableID = var_0_8,
						start = var_0_1.ctx.battle.count,
						level = arg_2_0:getSkillLevelByID(var_0_6),
						skillID = var_0_9,
						fighter = arg_2_0,
						target = iter_2_5
					})

					var_2_5.dHarm_ = var_2_4

					iter_2_5:addBuffs({
						var_2_5
					})
				end

				arg_2_0.harmOverload = 0
			end
		end
	end
end

function var_0_3.canAttack(arg_3_0)
	if arg_3_0.bIsEnergy then
		return false
	else
		return var_0_3.super.canAttack(arg_3_0)
	end
end

function var_0_3.isMoveUnable(arg_4_0)
	if arg_4_0.bIsEnergy then
		return true
	else
		return var_0_3.super.isMoveUnable(arg_4_0)
	end
end

function var_0_3.isBreakImmortal(arg_5_0)
	if arg_5_0.bIsEnergy then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_5_0)
	end
end

function var_0_3.updateUnitInfoBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_0:getTeamType() == arg_6_1.target:getTeamType() and arg_6_1.target:getBuffByID(var_0_7) ~= nil then
		local var_6_0 = arg_6_4 - arg_6_1.target:getHp()

		if var_6_0 > 0 then
			arg_6_0.harmOverload = (arg_6_0.harmOverload or 0) + var_6_0
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_6_0.GreenSkillHarmInfo = arg_6_0.GreenSkillHarmInfo or {}

		if arg_6_0:getTeamType() == arg_6_1.target:getTeamType() and arg_6_1.target:isHasBuffByID(var_0_11) then
			if arg_6_4 > 0 and arg_6_1.target:getTeamType() ~= arg_6_1.fighter:getTeamType() then
				arg_6_0.GreenSkillHarmInfo[arg_6_1.target] = arg_6_0.GreenSkillHarmInfo[arg_6_1.target] or {}
				arg_6_0.GreenSkillHarmInfo[arg_6_1.target][arg_6_1.fighter] = (arg_6_0.GreenSkillHarmInfo[arg_6_1.target][arg_6_1.fighter] or 0) + arg_6_4

				if arg_6_0.GreenSkillHarmInfo[arg_6_1.target][arg_6_1.fighter] > arg_6_1.target:getHpLimit() * 0.5 then
					local var_6_1 = arg_6_0:createAttackUnits({
						arg_6_1.fighter
					}, var_0_12)

					for iter_6_0, iter_6_1 in ipairs(var_6_1) do
						iter_6_1.basicHarm = math.min(arg_6_4 * 0.5, arg_6_0:getSkillLevelByID(var_0_10) * 500 + 1000)

						table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
						table.insert(arg_6_0.records_.special_units, iter_6_1)
					end
				end
			end
		else
			arg_6_0.GreenSkillHarmInfo[arg_6_1.target] = nil
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if var_0_4:father(arg_7_1.skillID) == var_0_6 and not arg_7_0.bIsEnergy then
		arg_7_0:getFighterModel():playAnimation_("gongji05", true)

		arg_7_0.EnergyTimeCount = arg_7_0.EnergyTimeCount ~= 0 and arg_7_0.EnergyTimeCount or 180
		arg_7_0.bIsEnergy = true
	end
end

function var_0_3.skillIsBreakAction(arg_8_0, arg_8_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_8_1.skillID == var_0_13 then
		local var_8_0 = arg_8_0:createAttackUnits({
			arg_8_1.target
		}, var_0_14)

		for iter_8_0, iter_8_1 in ipairs(var_8_0) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end
end

return var_0_3
