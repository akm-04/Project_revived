local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 70050011
local var_0_7 = 500
local var_0_8 = 220
local var_0_9 = 40010424

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.selfTarget_ = nil
	arg_1_0.sideTarget_ = nil
	arg_1_0.energyHp_ = nil
	arg_1_0.greenMainTarget_ = nil
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() then
		arg_2_0:choseTarget()

		local var_2_0 = var_0_7 + var_0_8 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

		if not arg_2_0.energyHp_ and arg_2_0.isStarEnergy_ then
			arg_2_0:updateEnergyBy(var_0_2.ENERGY_DECIMAL_BASE * 0.2)
		end

		if arg_2_0.selfTarget_ then
			if arg_2_0.energyHp_ then
				local var_2_1 = arg_2_0.energyHp_ * arg_2_0.selfTarget_:getHpLimit()

				if var_2_1 > arg_2_0.selfTarget_:getHp() then
					arg_2_0.selfTarget_:updateHp(math.min(var_2_1, arg_2_0.selfTarget_:getHp() + var_2_0))
				end
			end

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_2 = {
					arg_2_0.selfTarget_
				}
				local var_2_3 = arg_2_0:createAttackUnits(var_2_2, var_0_6)

				for iter_2_0, iter_2_1 in ipairs(var_2_3) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end
			end
		end

		if arg_2_0.sideTarget_ and arg_2_0.energyHp_ then
			local var_2_4 = arg_2_0.energyHp_ * arg_2_0.sideTarget_:getHpLimit()

			if var_2_4 < arg_2_0.sideTarget_:getHp() then
				local var_2_5 = math.max(var_2_4, arg_2_0.sideTarget_:getHp() - var_2_0)

				arg_2_0.harms = arg_2_0.harms + arg_2_0.sideTarget_:getHp() - var_2_5

				arg_2_0.sideTarget_:updateHp(var_2_5)
			end
		end
	elseif arg_2_0.isStarBlue_ and arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) == arg_2_1.skillID then
		local var_2_6 = var_0_4.new({
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			level = arg_2_0:getSkillLevelByID(arg_2_1.skillID),
			skillID = arg_2_1.skillID,
			fighter = arg_2_0,
			target = arg_2_1.target
		})

		var_2_6:setIsHit(true)
		var_2_6:setDirection(arg_2_0:getFighterModel():getFlipX())
		arg_2_1.target:addBuffs({
			var_2_6
		})
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_3_1.target ~= arg_3_0.greenMainTarget_ then
		local var_3_0 = math.abs(arg_3_1.target:getX() - arg_3_0.greenMainTarget_:getX())
		local var_3_1 = 0

		if arg_3_0.isStarGreen_ then
			var_3_1 = 0.2
		end

		if var_3_0 <= 50 then
			arg_3_5 = arg_3_5 * (var_3_1 + 0.8)
		elseif var_3_0 <= 100 then
			arg_3_5 = arg_3_5 * (var_3_1 + 0.5)
		else
			arg_3_5 = arg_3_5 * (var_3_1 + 0.3)
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = var_0_5:distance(arg_4_1)
	local var_4_1 = var_0_5:scope(arg_4_1)
	local var_4_2 = {}
	local var_4_3
	local var_4_4

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_4_5 = iter_4_1:getHp() / iter_4_1:getHpLimit()

			if not var_4_3 or var_4_5 < var_4_3 then
				var_4_4 = iter_4_1
				var_4_3 = var_4_5
			end
		end
	end

	if var_4_4 then
		table.insert(var_4_2, var_4_4)

		for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_3:isDeath() and not iter_4_3:isAffected() and iter_4_3 ~= var_4_4 and math.abs(iter_4_3:getX() - var_4_4:getX()) <= var_4_1 * 0.5 then
				table.insert(var_4_2, iter_4_3)
			end
		end

		arg_4_0.greenMainTarget_ = var_4_4
	end

	return var_4_2
end

function var_0_3.choseTarget(arg_5_0)
	arg_5_0.selfTarget_ = nil
	arg_5_0.sideTarget_ = nil
	arg_5_0.energyHp_ = nil

	local var_5_0
	local var_5_1

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_5_2 = iter_5_1:getHp() / iter_5_1:getHpLimit()

			if not var_5_0 or var_5_2 < var_5_0 then
				arg_5_0.selfTarget_ = iter_5_1
				var_5_0 = var_5_2
			end
		end
	end

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_3:isDeath() and not iter_5_3:isAffected() and iter_5_3:getSummonType() == var_0_2.summonMonsterType.None and not iter_5_3:isBoss() then
			local var_5_3 = iter_5_3:getHp() / iter_5_3:getHpLimit()

			if not var_5_1 or var_5_1 < var_5_3 then
				arg_5_0.sideTarget_ = iter_5_3
				var_5_1 = var_5_3
			end
		end
	end

	if var_5_0 and var_5_1 and var_5_0 < var_5_1 then
		arg_5_0.energyHp_ = (var_5_0 + var_5_1) * 0.5
	end
end

return var_0_3
