local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chunyuqiong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_9 = var_0_2.tables.skill
local var_0_10 = math.abs
local var_0_11 = math.min
local var_0_12 = 0.3
local var_0_13 = 40011254
local var_0_14 = 40011255
local var_0_15 = 150
local var_0_16 = 40011256
local var_0_17 = 40011258
local var_0_18 = 40011259
local var_0_19 = 40011260
local var_0_20 = 10001148
local var_0_21 = 10001147
local var_0_22 = 10001149
local var_0_23 = 0.5
local var_0_24 = 10001151
local var_0_25 = 10001152
local var_0_26 = 150
local var_0_27 = 1
local var_0_28 = 40011261
local var_0_29 = 1000
local var_0_30 = 300
local var_0_31 = 10001996

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.pugongTarget = nil
	arg_1_0.attackState = false
	arg_1_0.purpleSkillCount = 0
	arg_1_0.energyHarm = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	arg_2_0:purpleSkill()
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	if var_0_3.super.getFrontSkill(arg_3_0) == arg_3_0:getPugongID() and arg_3_0.attackState then
		return var_0_20
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_3_0)
end

function var_0_3.purpleSkill(arg_4_0)
	if not (arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0) then
		return
	end

	arg_4_0.purpleSkillCount = arg_4_0.purpleSkillCount - 1

	if arg_4_0.purpleSkillCount > 0 then
		return
	end

	if arg_4_0.attackState then
		if arg_4_0:getHp() / arg_4_0:getHpLimit() < 0.5 then
			arg_4_0.attackState = false
			arg_4_0.purpleSkillCount = var_0_15

			arg_4_0:removeBuffByID(var_0_16)
			arg_4_0:removeBuffByID(PurpleAttackStateBuff2)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_0 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_22)

				for iter_4_0, iter_4_1 in ipairs(var_4_0) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end

				if arg_4_0.isSkinSkillOn_ then
					local var_4_1 = arg_4_0:createAttackUnits({
						arg_4_0
					}, var_0_31)

					for iter_4_2, iter_4_3 in ipairs(var_4_1) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
						table.insert(arg_4_0.records_.special_units, iter_4_3)
					end
				end
			end
		end
	elseif arg_4_0:getHp() / arg_4_0:getHpLimit() >= 0.5 then
		arg_4_0.attackState = true
		arg_4_0.purpleSkillCount = var_0_15

		arg_4_0:removeBuffByID(var_0_17)
		arg_4_0:removeBuffByID(var_0_18)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_2 = arg_4_0:createAttackUnits({
				arg_4_0
			}, var_0_21)

			for iter_4_4, iter_4_5 in ipairs(var_4_2) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
				table.insert(arg_4_0.records_.special_units, iter_4_5)
			end

			if arg_4_0.isSkinSkillOn_ then
				local var_4_3 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_31)

				for iter_4_6, iter_4_7 in ipairs(var_4_3) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
					table.insert(arg_4_0.records_.special_units, iter_4_7)
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.skillID

	if (var_5_0 == arg_5_0:getPugongID() or var_5_0 == var_0_20) and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_5_0.pugongTarget and arg_5_1.target ~= arg_5_0.pugongTarget then
			arg_5_0:removeBuffByID(var_0_13)
			arg_5_0:removeBuffByID(var_0_14)
		end

		local var_5_1 = arg_5_0:createAttackUnits({
			arg_5_0
		}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		for iter_5_0, iter_5_1 in ipairs(var_5_1) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end

		arg_5_0.pugongTarget = arg_5_1.target
	elseif var_5_0 == arg_5_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local function var_5_2(arg_6_0)
			local var_6_0 = {
				skillID = var_0_24,
				fighter = arg_5_0,
				target = arg_6_0,
				count = var_0_1.ctx.battle.count + arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_27 + var_0_26
			}

			return var_0_8.new(var_6_0)
		end

		local var_5_3 = {}
		local var_5_4 = var_5_2(arg_5_0)

		table.insert(arg_5_0.records_.attackunit, var_5_4)
		table.insert(var_5_3, var_5_4)

		var_5_4.recordIndex_ = #arg_5_0.records_.attackunit

		for iter_5_2, iter_5_3 in ipairs(var_5_3) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	elseif var_5_0 == var_0_24 then
		arg_5_0:removeBuffByID(var_0_28)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_5 = var_0_9:sound(var_0_25)

			var_0_1.ctx.battle.pushSoundQueue(var_5_5)

			local var_5_6 = var_0_9:attackIndex(var_0_25)

			arg_5_0:playAttack(var_5_6)

			arg_5_0.unitSkills_ = var_0_5.new({
				fighter = arg_5_0,
				skillID = var_0_25
			})

			arg_5_0:beginAttackEnd(arg_5_0.unitSkills_)
		end
	elseif var_5_0 == var_0_25 then
		arg_5_0:setImmuneControl(false)
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	if arg_7_1.attackType == var_0_2.AttackType.AD and arg_7_0:isHasBuffByID(var_0_28) then
		arg_7_0.energyHarm = arg_7_0.energyHarm + arg_7_2
		arg_7_2 = 0
		arg_7_3 = 0
	end

	return var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if var_8_2 > 0 and arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_8_6 = var_0_9:scope(arg_8_1.skillID)

		var_8_2 = var_8_2 * ((var_0_12 - 1) * math.max(math.abs(arg_8_1.target:getX() - arg_8_0:getX()) - 100, 0) / var_8_6 + 1)
	elseif arg_8_1.skillID == var_0_25 then
		var_8_2 = var_8_2 + arg_8_0.energyHarm
		var_8_2 = math.min(var_8_2, var_0_29 + var_0_30 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
		arg_8_0.energyHarm = 0
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == arg_9_0:getEnergySkillID() then
		arg_9_0:setImmuneControl(true)
	end
end

return var_0_3
