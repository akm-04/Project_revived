local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mizhu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.skinSkill
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 10010163
local var_0_8 = 10000396
local var_0_9 = 10010162
local var_0_10 = 10010164
local var_0_11 = 10000401
local var_0_12 = 10000402
local var_0_13 = 60
local var_0_14 = 0.2
local var_0_15 = 0.2
local var_0_16 = 40010679

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyMoveUnit_ = nil
	arg_2_0["is_buff" .. var_0_7] = nil
	arg_2_0.blueCD_ = {}
	arg_2_0.guardFighter_ = nil
	arg_2_0.guardFighterJudge_ = false
	arg_2_0.skinEnergyCount_ = 0
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_7 then
		arg_3_1.target["is_buff" .. var_0_7] = true
	end

	if arg_3_1:getTableID() == var_0_10 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and #arg_3_1.target:getBuffsByID(var_0_10) >= 3 then
		local var_3_0 = {
			arg_3_1.target
		}
		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end

		arg_3_1.target:removeBuffByID(var_0_10)
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_1:getRemoveSkill()
		local var_4_1 = var_0_4:scope(var_4_0)
		local var_4_2 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and var_4_1 > math.abs(arg_4_1.target:getX() - iter_4_1:getX()) then
				table.insert(var_4_2, iter_4_1)
			end
		end

		local var_4_3 = arg_4_0:createAttackUnits(var_4_2, var_4_0)

		for iter_4_2, iter_4_3 in ipairs(var_4_3) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end
	end

	if arg_4_1:getTableID() == var_0_7 and arg_4_1.target["is_buff" .. var_0_7] then
		arg_4_1.target["is_buff" .. var_0_7] = nil
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if not arg_5_0.guardFighterJudge_ and arg_5_0.isSkinSkillOn_ then
		arg_5_0.guardFighterJudge_ = true

		for iter_5_0 = 1, #arg_5_0.selfTeam_ do
			local var_5_0 = arg_5_0.selfTeam_[iter_5_0]

			if not var_5_0:isDeath() and not var_5_0:isAffected() and var_5_0 ~= arg_5_0 and var_5_0:getSummonType() == var_0_2.summonMonsterType.None then
				local var_5_1 = arg_5_0:newBuffs({
					var_0_16
				}, arg_5_0.skinSkillID_, arg_5_0:getLevel(), var_5_0)

				var_5_0:addBuffs(var_5_1)

				arg_5_0.guardFighter_ = var_5_0

				break
			end
		end
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if next(arg_5_0:getInfoByKey("unit_info")) then
		for iter_5_1, iter_5_2 in ipairs(arg_5_0:getInfoByKey("unit_info")) do
			if iter_5_2.target["is_buff" .. var_0_7] and iter_5_2.target:getTeamType() and iter_5_2.fighter:getTeamType() and iter_5_2.target:getTeamType() ~= iter_5_2.fighter:getTeamType() and iter_5_2.fighter:getSummonType() ~= var_0_2.summonMonsterType.Pet and (not arg_5_0.blueCD_[iter_5_2.fighter] or arg_5_0.blueCD_[iter_5_2.fighter] < 1) then
				local var_5_2 = {
					iter_5_2.fighter
				}
				local var_5_3 = arg_5_0:createAttackUnits(var_5_2, var_0_8)

				for iter_5_3, iter_5_4 in ipairs(var_5_3) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_4)
					table.insert(arg_5_0.records_.special_units, iter_5_4)
				end

				arg_5_0.blueCD_[iter_5_2.fighter] = var_0_13
			end
		end
	end

	if arg_5_0.energyMoveUnit_ and not arg_5_0.energyMoveUnit_.arrived and var_0_1.ctx.battle.count % 30 < 1 then
		local var_5_4 = arg_5_0:getEnergyTargets()
		local var_5_5 = arg_5_0:createAttackUnits(var_5_4, var_0_12)

		for iter_5_5, iter_5_6 in ipairs(var_5_5) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_6)
			table.insert(arg_5_0.records_.special_units, iter_5_6)
		end
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_5_7, iter_5_8 in pairs(arg_5_0.blueCD_) do
			arg_5_0.blueCD_[iter_5_7] = arg_5_0.blueCD_[iter_5_7] - 1
		end
	end
end

function var_0_3.newBuffs(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_6.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_3,
			skillID = arg_6_2,
			fighter = arg_6_0,
			target = arg_6_4
		})

		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if var_7_2 > 0 and arg_7_0.guardFighter_ and not arg_7_0.guardFighter_:isDeath() and not arg_7_0.guardFighter_:isAffected() then
		local var_7_6 = var_7_2 * var_0_14

		var_7_2 = var_7_2 - var_7_6

		local var_7_7 = arg_7_0.guardFighter_:getHp()

		arg_7_0.guardFighter_:updateHp(var_7_7 - var_7_6)
		arg_7_0.guardFighter_.fighterModel:playHPDeltas({
			{
				-var_7_6,
				false
			}
		}, nil)

		if arg_7_0.guardFighter_:isDeath() then
			arg_7_0.guardFighter_.killer_ = arg_7_1.fighter

			arg_7_0.guardFighter_:die()
		end
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if var_8_2 > 0 and arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_8_1.skillID ~= arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_6 = {
			arg_8_1.target
		}
		local var_8_7 = arg_8_0:createAttackUnits(var_8_6, var_0_11)

		for iter_8_0, iter_8_1 in ipairs(var_8_7) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.unitAfterCreate(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_1 and arg_9_1.skillID == arg_9_0:getEnergySkillID() then
		arg_9_0.energyMoveUnit_ = arg_9_1
	end
end

function var_0_3.getEnergyTargets(arg_10_0)
	if not arg_10_0.energyMoveUnit_ or arg_10_0.energyMoveUnit_.arrived then
		return {}
	end

	local var_10_0 = var_0_4:scope(arg_10_0.energyMoveUnit_.skillID)
	local var_10_1 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and math.abs(iter_10_1:getX() - arg_10_0.energyMoveUnit_:getX()) < var_10_0 / 2 then
			table.insert(var_10_1, iter_10_1)
		end
	end

	return var_10_1
end

function var_0_3.spGiveValue(arg_11_0, arg_11_1, arg_11_2)
	arg_11_0.skinEnergyCount_ = arg_11_0.skinEnergyCount_ + arg_11_2
end

function var_0_3.applySingleUnit(arg_12_0, arg_12_1)
	var_0_3.super.applySingleUnit(arg_12_0, arg_12_1)

	if arg_12_0.isSkinSkillOn_ and arg_12_1.skillID == arg_12_0:getEnergySkillID() then
		arg_12_0.skinEnergyCount_ = 0
	end
end

function var_0_3.deathFeedback(arg_13_0, arg_13_1)
	if arg_13_0.guardFighter_ == arg_13_1 and arg_13_0.skinEnergyCount_ > 0 then
		arg_13_0:updateEnergyBy(-arg_13_0.skinEnergyCount_)

		arg_13_0.skinEnergyCount_ = 0
	end
end

return var_0_3
