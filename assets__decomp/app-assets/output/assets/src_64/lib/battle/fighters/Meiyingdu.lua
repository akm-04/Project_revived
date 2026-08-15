local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Meiyingdu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40010728
local var_0_8 = 10000691
local var_0_9 = 10000690
local var_0_10 = 0.5
local var_0_11 = 0.4
local var_0_12 = 0.05
local var_0_13 = {
	40010732,
	40010733,
	40010734,
	40010735,
	40010736
}
local var_0_14 = 50
local var_0_15 = 2
local var_0_16 = 50
local var_0_17 = 40010729
local var_0_18 = 0.1
local var_0_19 = 0.15
local var_0_20 = 0.003

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergyType_ = false
	arg_2_0.isBlueType_ = false
	arg_2_0.energyHarmCount_ = 0
	arg_2_0.energyHarm_ = 0
	arg_2_0.greenHarmRecord_ = {}
	arg_2_0.energyHasShowBuff_ = {}
	arg_2_0.records_.show_buff_count = {}
	arg_2_0.records_.tmp_buff_count = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.isEnergyType_ and not arg_3_0:getBuffByID(var_0_7) then
		arg_3_0.isEnergyType_ = false

		arg_3_0:setImmuneControl(false)
	end

	if arg_3_0.isBlueType_ and not arg_3_0:getBuffByID(var_0_17) then
		arg_3_0.isBlueType_ = false

		arg_3_0:setImmuneControl(false)
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
			local var_3_0 = iter_3_1.harm
			local var_3_1 = iter_3_1.fighter

			if iter_3_1.type == var_0_2.AttackType.AP and var_3_1:getTeamType() ~= arg_3_0:getTeamType() then
				if not arg_3_0.greenHarmRecord_[var_3_1] then
					arg_3_0.greenHarmRecord_[var_3_1] = var_3_0
				else
					arg_3_0.greenHarmRecord_[var_3_1] = arg_3_0.greenHarmRecord_[var_3_1] + var_3_0
				end
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_0.isEnergyType_ and var_4_2 > 0 and arg_4_1.target ~= arg_4_0 and arg_4_1.target:getTeamType() == arg_4_0:getTeamType() and arg_4_1.skillID ~= var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_6 = var_4_2 * var_0_10

		var_4_2 = var_4_2 - var_4_6
		arg_4_0.energyHarmCount_ = arg_4_0.energyHarmCount_ + var_4_6

		local var_4_7 = arg_4_0:createAttackUnits({
			arg_4_0
		}, var_0_8)

		for iter_4_0, iter_4_1 in ipairs(var_4_7) do
			iter_4_1.change_harm = var_4_6

			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == var_0_8 and arg_5_1.change_harm and arg_5_1.change_harm > 0 then
		var_5_2 = arg_5_1.change_harm
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_5_2 > 0 and var_5_2 >= arg_5_0:getHpLimit() * var_0_18 then
		var_5_2 = var_5_2 - var_5_2 * (var_0_19 + var_0_20 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	end

	if arg_5_0.isEnergyType_ and var_5_2 > 0 then
		arg_5_0.energyHarmCount_ = arg_5_0.energyHarmCount_ + var_5_2

		if arg_5_0.energyHarmCount_ / arg_5_0:getHpLimit() >= var_0_11 then
			arg_5_0:useEnergyBeatSkill(arg_5_1)
		end
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.useEnergyBeatSkill(arg_6_0, arg_6_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_6_0:isCreatingUnits() then
		return
	end

	if arg_6_1.fighter:getX() - arg_6_0:getX() < 0 then
		arg_6_0:flipX(true)
	else
		arg_6_0:flipX(false)
	end

	local var_6_0 = var_0_9
	local var_6_1 = var_0_6:sound(var_6_0)

	var_0_1.ctx.battle.pushSoundQueue(var_6_1)

	local var_6_2 = var_0_6:attackIndex(var_6_0)

	arg_6_0:playAttack(var_6_2)

	arg_6_0.unitSkills_ = var_0_5.new({
		fighter = arg_6_0,
		skillID = var_6_0
	})

	arg_6_0:beginAttackEnd(arg_6_0.unitSkills_)

	arg_6_0.energyHarm_ = arg_6_0.energyHarmCount_
	arg_6_0.energyHarmCount_ = 0
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.skillID == var_0_9 and arg_7_0.energyHarm_ > 0 then
		var_7_2 = var_7_2 + arg_7_0.energyHarm_ * var_0_12 * arg_7_1.target:getADJianShang()
	elseif arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_7_6 = arg_7_1.target:getEnergy()

		var_7_5 = -((var_0_14 + var_0_15 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)) * var_7_6 / var_0_2.ENERGY_DECIMAL_BASE + var_0_16)
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_1.target == arg_8_0 and arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_8_0:setImmuneControl(true)

		arg_8_0.isBlueType_ = true
	elseif arg_8_1.target == arg_8_0 and arg_8_1.skillID == arg_8_0:getEnergySkillID() then
		arg_8_0:setImmuneControl(true)

		arg_8_0.isEnergyType_ = true
		arg_8_0.energyHarmCount_ = 0
	elseif arg_8_1.skillID == var_0_9 then
		local var_8_0 = arg_8_0:getEnergyShowBuff()

		if var_8_0 then
			local var_8_1 = arg_8_0:newBuffs({
				var_8_0
			}, var_0_9, arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), arg_8_1.target)

			arg_8_1.target:addBuffs(var_8_1)
		end
	end
end

function var_0_3.getEnergyShowBuff(arg_9_0)
	if #arg_9_0.energyHasShowBuff_ == #var_0_13 then
		arg_9_0.energyHasShowBuff_ = {}

		local var_9_0 = 1

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_9_0 = arg_9_0.showBuffCount_[tostring(var_0_1.ctx.battle.count)] or 1
		else
			var_9_0 = math.random(1, #var_0_13)
			arg_9_0.records_.show_buff_count[tostring(var_0_1.ctx.battle.count)] = var_9_0
		end

		local var_9_1 = var_0_13[var_9_0]

		table.insert(arg_9_0.energyHasShowBuff_, var_9_1)

		return var_9_1
	end

	local var_9_2 = {}

	for iter_9_0 = 1, #var_0_13 do
		if not var_0_0.table.indexof(arg_9_0.energyHasShowBuff_, var_0_13[iter_9_0]) then
			table.insert(var_9_2, var_0_13[iter_9_0])
		end
	end

	local var_9_3 = 1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_3 = arg_9_0.tmpBuffCount_[tostring(var_0_1.ctx.battle.count)] or 1
	else
		var_9_3 = math.random(1, #var_9_2)
		arg_9_0.records_.tmp_buff_count[tostring(var_0_1.ctx.battle.count)] = var_9_3
	end

	table.insert(arg_9_0.energyHasShowBuff_, var_9_2[var_9_3])

	return var_9_2[var_9_3]
end

function var_0_3.newBuffs(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		local var_10_1 = var_0_4.new({
			tableID = iter_10_1,
			start = var_0_1.ctx.battle.count,
			level = arg_10_3,
			skillID = arg_10_2,
			fighter = arg_10_0,
			target = arg_10_4
		})

		table.insert(var_10_0, var_10_1)
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}
	local var_11_1 = 0

	for iter_11_0, iter_11_1 in pairs(arg_11_0.greenHarmRecord_) do
		if not iter_11_0:isDeath() and not iter_11_0:isAffected() then
			if var_11_1 < iter_11_1 then
				var_11_1 = iter_11_1
				var_11_0 = {}

				table.insert(var_11_0, iter_11_0)
			elseif iter_11_1 == var_11_1 then
				var_11_1 = iter_11_1

				table.insert(var_11_0, iter_11_0)
			end
		end
	end

	arg_11_0.greenHarmRecord_ = {}

	if #var_11_0 == 1 then
		return var_11_0
	end

	if #var_11_0 == 0 or not next(var_11_0) then
		for iter_11_2, iter_11_3 in ipairs(arg_11_0.sideTeam_) do
			if not iter_11_3:isDeath() and not iter_11_3:isAffected() then
				table.insert(var_11_0, iter_11_3)
			end
		end
	end

	table.sort(var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0:getAP() ~= arg_12_1:getAP() then
			return arg_12_0:getAP() > arg_12_1:getAP()
		end
	end)

	return {
		var_11_0[1]
	}
end

function var_0_3.die(arg_13_0)
	if arg_13_0:isBreakImmortal() then
		arg_13_0:setImmuneControl(false)
	end

	return var_0_3.super.die(arg_13_0)
end

function var_0_3.setupReport(arg_14_0, arg_14_1)
	var_0_3.super.setupReport(arg_14_0, arg_14_1)

	arg_14_0.showBuffCount_ = arg_14_1.show_buff_count or {}
	arg_14_0.tmpBuffCount_ = arg_14_1.tmp_buff_count or {}
end

function var_0_3.writeReport(arg_15_0)
	local var_15_0 = var_0_3.super.writeReport(arg_15_0)

	var_15_0.show_buff_count = arg_15_0.records_.show_buff_count
	var_15_0.tmp_buff_count = arg_15_0.records_.tmp_buff_count

	return var_15_0
end

return var_0_3
