local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dianwei", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 20010004
local var_0_7 = {
	40010748,
	40010749
}
local var_0_8 = 10000875
local var_0_9 = 10000876
local var_0_10 = 40010962
local var_0_11 = 0.3
local var_0_12 = 0.5
local var_0_13 = 0.04
local var_0_14 = var_0_2.tables.elementEquip
local var_0_15 = 20001475
local var_0_16 = 10002267
local var_0_17 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.isUseSkinSkill_ = false
	arg_1_0.skinCureCount_ = 0
	arg_1_0.isInSkinSkill_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_6)] or 0
	end

	if arg_2_0.isSkinSkillOn_ and not arg_2_0:isDeath() then
		arg_2_0:checkSkinSkill()
	end

	if var_0_1.ctx.battle.count % var_0_17 == 1 and arg_2_0:hasElementEquipByID(var_0_15) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:getTargets(var_0_16)
		local var_2_1 = arg_2_0:createAttackUnits(var_2_0, var_0_16)

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.checkSkinSkill(arg_3_0)
	if arg_3_0.isInSkinSkill_ and var_0_1.ctx.battle.count % 30 < 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:getTargets(var_0_8)

		if next(var_3_0) then
			local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_8)

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	elseif not arg_3_0.isUseSkinSkill_ and arg_3_0:getHp() / arg_3_0:getHpLimit() <= var_0_11 then
		local var_3_2 = arg_3_0:newBuff({
			var_0_10
		}, arg_3_0, arg_3_0:getEnergySkillID())

		arg_3_0:addBuffs(var_3_2)
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_10 then
		arg_4_0.isUseSkinSkill_ = true
		arg_4_0.isInSkinSkill_ = true
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	var_0_3.super.buffRemoveAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_10 then
		arg_5_0.isInSkinSkill_ = false
	end
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_0.extraSkillLevel > 0 and var_0_5:father(arg_7_1.skillID) == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_7_1.target ~= arg_7_0 and not arg_7_1.target:isDeath() and not arg_7_1.target:isAffected() then
		arg_7_0:addExtraSkillBuff(arg_7_1.target)
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.skillID == var_0_8 then
		if arg_8_1.target:getEnergy() > 0 then
			var_8_5 = var_8_5 - math.ceil(arg_8_1.target:getEnergy() * var_0_13)

			if arg_8_0.skinCureCount_ < var_0_12 * arg_8_0:getHpLimit() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_8_6 = arg_8_0:createAttackUnits({
					arg_8_0
				}, var_0_9)

				for iter_8_0, iter_8_1 in ipairs(var_8_6) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
					table.insert(arg_8_0.records_.special_units, iter_8_1)
				end
			end
		else
			var_8_5 = 0
		end
	elseif arg_8_1.skillID == var_0_9 then
		arg_8_0.skinCureCount_ = arg_8_0.skinCureCount_ + var_8_3
	elseif arg_8_1.skillID == var_0_16 then
		local var_8_7 = var_0_15
		local var_8_8 = var_0_14:battleAttr(var_8_7, arg_8_0:getElementEquipLevelByID(var_8_7))
		local var_8_9 = arg_8_0.hero_:getElementEquipActiveRate(var_8_7)

		if arg_8_1.target:getEnergy() > 0 then
			var_8_5 = var_8_5 - var_8_8

			arg_8_0:updateEnergyBy(var_8_8)
		else
			var_8_5 = 0
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.addExtraSkillBuff(arg_9_0, arg_9_1)
	if arg_9_0.extraSkillLevel > 0 then
		local var_9_0 = {}

		for iter_9_0 = 1, #var_0_7 do
			local var_9_1 = var_0_4.new({
				tableID = var_0_7[iter_9_0],
				start = var_0_1.ctx.battle.count,
				level = arg_9_0.extraSkillLevel,
				skillID = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
				fighter = arg_9_0,
				target = arg_9_1
			})

			table.insert(var_9_0, var_9_1)
		end

		arg_9_1:addBuffs(var_9_0)
	end
end

return var_0_3
