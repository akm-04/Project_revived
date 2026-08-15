local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lusu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 150
local var_0_8 = 80010080
local var_0_9 = 40011241
local var_0_10 = 20001506
local var_0_11 = 90
local var_0_12 = 10002565

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.elementCount = 0
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)
end

function var_0_3.removeTargetBuff(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2:canRemove() then
		arg_4_1:removeBuffs(arg_4_2)
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	var_0_3.super.toDoPerFrames(arg_5_0)

	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_8 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
			if iter_5_1.target:isHasBuffByID(var_0_9) and arg_5_0:getTeamType() == iter_5_1.target:getTeamType() and (iter_5_1:getType() == var_0_2.BuffType.CONTINUE_HARM or iter_5_1:getType() == var_0_2.BuffType.MOVE_SKILL_LIMIT) then
				arg_5_0:removeTargetBuff(iter_5_1.target, iter_5_1)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1
	local var_6_2
	local var_6_3

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and (not var_6_0 or var_6_2 > iter_6_1:getHp() / iter_6_1:getHpLimit()) and (not arg_6_2 or arg_6_2.greenTargets[iter_6_1] == nil) then
			var_6_0 = iter_6_1
			var_6_2 = var_6_0:getHp() / var_6_0:getHpLimit()
		end

		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and (not var_6_1 or var_6_3 > iter_6_1:getHp() / iter_6_1:getHpLimit()) then
			var_6_1 = iter_6_1
			var_6_3 = iter_6_1:getHp() / iter_6_1:getHpLimit()
		end
	end

	if not var_6_0 then
		return var_6_1 == nil and {} or {
			var_6_1
		}
	end

	return {
		var_6_0
	}
end

function var_0_3.selectTargetByTypeD2(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.targetTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and (not var_7_0 or var_7_1 < iter_7_1:getGainBuffNum()) then
			var_7_0 = iter_7_1
			var_7_1 = iter_7_1:getGainBuffNum()
		end
	end

	if not var_7_0 then
		return var_0_4.B1(arg_7_0, arg_7_1)
	end

	return {
		var_7_0
	}
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if var_0_5:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_8_0:removeGainBuff(arg_8_1.target)
	elseif var_0_5:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_8_1.greenTargets = arg_8_1.greenTargets or {}
		arg_8_1.greenTargets[arg_8_1.target] = true

		if arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_0 = arg_8_0:createAttackUnits({
				arg_8_1.target
			}, var_0_8)

			for iter_8_0, iter_8_1 in ipairs(var_8_0) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
				table.insert(arg_8_0.records_.special_units, iter_8_1)
			end
		end

		local var_8_1

		for iter_8_2, iter_8_3 in ipairs(arg_8_1.target:getBuffs()) do
			if (iter_8_3:dBuffType() > 0 or iter_8_3:getBuffForm() == var_0_2.BuffForm.DEBUFF) and (not var_8_1 or iter_8_3:getTime() - iter_8_3.leftCount_ < var_8_1:getTime() - var_8_1.leftCount_) then
				var_8_1 = iter_8_3
			end
		end

		if var_8_1 then
			arg_8_0:removeTargetBuff(arg_8_1.target, var_8_1)
		end
	elseif (var_0_5:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) or var_0_5:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) and arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_2 = arg_8_0:createAttackUnits({
			arg_8_1.target
		}, var_0_8)

		for iter_8_4, iter_8_5 in ipairs(var_8_2) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_5)
			table.insert(arg_8_0.records_.special_units, iter_8_5)
		end
	end

	if arg_8_0:hasElementEquipByID(var_0_10) and arg_8_1.skillID == var_0_12 then
		local var_8_3 = arg_8_1.target
		local var_8_4 = var_8_3:getBuffs()

		if arg_8_0.elementCount == 0 or var_0_1.ctx.battle.count - arg_8_0.elementCount >= var_0_11 then
			for iter_8_6, iter_8_7 in ipairs(var_8_4) do
				if iter_8_7:dBuffType() > 0 and iter_8_7:canRemove() then
					var_8_3:removeBuffs(iter_8_7)

					arg_8_0.elementCount = var_0_1.ctx.battle.count

					break
				end
			end
		end
	end
end

function var_0_3.removeGainBuff(arg_9_0, arg_9_1)
	local var_9_0 = 0

	for iter_9_0 = #arg_9_1.buffs_, 1, -1 do
		if var_9_0 >= 3 then
			break
		end

		local var_9_1 = arg_9_1.buffs_[iter_9_0]

		if var_9_1 and var_9_1:getBuffForm() == var_0_2.BuffForm.GAIN and var_9_1:canRemove() then
			var_9_0 = var_9_0 + 1

			arg_9_0:removeTargetBuff(arg_9_1, var_9_1)
		end
	end
end

function var_0_3.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	local var_10_0, var_10_1, var_10_2, var_10_3 = var_0_3.super.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)

	if var_10_0 > 0 and arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_10_4 = arg_10_0:createAttackUnits({
			arg_10_0
		}, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_10_0, iter_10_1 in ipairs(var_10_4) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end
	end

	return var_10_0, var_10_1, var_10_2, var_10_3
end

function var_0_3.updatePurpleSkill(arg_11_0)
	if not arg_11_0.purpleCount_ or arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return
	end

	if arg_11_0.purpleCount_ and arg_11_0.purpleCount_ > 0 then
		arg_11_0.purpleCount_ = arg_11_0.purpleCount_ - 1
	end

	if arg_11_0.purpleCount_ > 0 or arg_11_0:getHp() == arg_11_0:getHpLimit() then
		return
	end

	if arg_11_0:isDeath() or arg_11_0:isAffected() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if var_0_1.ctx.battle.count % 30 > 0 then
		return
	end

	local var_11_0 = arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_11_1 = arg_11_0:createAttackUnits({
		arg_11_0
	}, var_11_0)

	for iter_11_0, iter_11_1 in ipairs(var_11_1) do
		table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
		table.insert(arg_11_0.records_.special_units, iter_11_1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7 = var_0_3.super.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)

	if arg_12_5 > 0 and arg_12_0:hasElementEquipByID(var_0_10) then
		local var_12_0 = var_0_10

		arg_12_5 = arg_12_5 * (1 + var_0_6:battleAttr(var_12_0, arg_12_0:getElementEquipLevelByID(var_12_0)) * arg_12_0.hero_:getElementEquipActiveRate(var_12_0))

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_12_1 = arg_12_0:createAttackUnits({
				arg_12_1.target
			}, var_0_12)

			for iter_12_0, iter_12_1 in ipairs(var_12_1) do
				table.insert(arg_12_0.moveAttackUnits_, iter_12_1)
				table.insert(arg_12_0.records_.special_units, iter_12_1)
			end
		end
	end

	return arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7
end

return var_0_3
