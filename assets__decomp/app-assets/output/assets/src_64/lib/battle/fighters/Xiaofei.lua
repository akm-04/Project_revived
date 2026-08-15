local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0.01
local var_0_6 = 0.0002
local var_0_7 = 0.01
local var_0_8 = 40012696
local var_0_9 = 600
local var_0_10 = 10002518
local var_0_11 = 0.2
local var_0_12 = 0.005
local var_0_13 = 0.2
local var_0_14 = 100
local var_0_15 = 40012701
local var_0_16 = 8
local var_0_17 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCount = 0
	arg_1_0.purpleDuration = {}
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		arg_2_0.energyCount = var_0_1.ctx.battle.count
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 30 == 1 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
			if iter_3_1:isHasBuffByID(var_0_8) then
				local var_3_0 = var_0_5 + var_0_6 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

				if arg_3_0.isStarEnergy_ then
					var_3_0 = var_3_0 + var_0_7
				end

				iter_3_1:updateEnergyBy(-iter_3_1:getEnergy() * var_3_0)
			end
		end
	end
end

function var_0_3.checkEnergySkill(arg_4_0)
	local var_4_0 = var_0_9

	if arg_4_0.energyCount == 0 or var_4_0 < var_0_1.ctx.battle.count - arg_4_0.energyCount then
		return var_0_3.super.checkEnergySkill(arg_4_0)
	end

	return false
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_0 = arg_5_1.target
		local var_5_1
		local var_5_2

		for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_1:isDeath() and iter_5_1 ~= arg_5_0 and (not var_5_1 or var_5_1:getEnergy() < iter_5_1:getEnergy()) then
				var_5_1 = iter_5_1
			end

			if not iter_5_1:isDeath() and iter_5_1 ~= arg_5_0 and (not var_5_2 or var_5_2:getEnergy() > iter_5_1:getEnergy()) then
				var_5_2 = iter_5_1
			end
		end

		if var_5_0 and var_5_1 then
			local var_5_3 = var_5_0:getEnergy() - var_5_1:getEnergy()

			if var_5_3 > 0 then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					arg_5_0.greenMp = var_5_0:getEnergy() - var_5_1:getEnergy()

					local var_5_4 = arg_5_0:createAttackUnits({
						var_5_1
					}, var_0_10)

					for iter_5_2, iter_5_3 in ipairs(var_5_4) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
						table.insert(arg_5_0.records_.special_units, iter_5_3)
					end
				end
			elseif var_5_3 < 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_5 = var_0_11 + var_0_12 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

				if arg_5_0.isStarGreen_ then
					arg_5_0.greenMp = -var_5_3 * (var_5_5 + var_0_13)
				else
					arg_5_0.greenMp = -var_5_3 * var_5_5
				end

				local var_5_6 = arg_5_0:createAttackUnits({
					var_5_2
				}, var_0_10)

				for iter_5_4, iter_5_5 in ipairs(var_5_6) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
					table.insert(arg_5_0.records_.special_units, iter_5_5)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_1.skillID == var_0_10 then
		arg_6_7 = arg_6_0.greenMp
		arg_6_0.greenMp = 0
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_6_0.isStarBlue_ and arg_6_7 > 0 then
		arg_6_7 = arg_6_7 + var_0_14
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.energyActionBySpecialHero(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_7_1:getTeamType() == arg_7_0:getTeamType() and arg_7_1 ~= arg_7_0 and (not arg_7_0.purpleDuration[arg_7_1.fighterIndex] or var_0_1.ctx.battle.count - arg_7_0.purpleDuration[arg_7_1.fighterIndex] > var_0_17) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_1
		}, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		arg_7_0.purpleDuration[arg_7_1.fighterIndex] = var_0_1.ctx.battle.count
	end
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_0.isStarPurple_ and arg_8_1:getTableID() == var_0_15 then
		arg_8_1.manualMp = var_0_16
	end
end

return var_0_3
