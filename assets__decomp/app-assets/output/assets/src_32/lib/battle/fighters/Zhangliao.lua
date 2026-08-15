local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangliao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 80010017
local var_0_5 = 0.2
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.elementEquip
local var_0_8 = 20001468
local var_0_9 = 10002233

function var_0_3.getFrontSkill(arg_1_0)
	local var_1_0 = var_0_3.super.getFrontSkill(arg_1_0)

	if not arg_1_0.elementEquipsLevel_ then
		arg_1_0:initElementEquip()
	end

	if arg_1_0:hasElementEquipByID(var_0_8) and var_1_0 == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		var_1_0 = var_0_9
	end

	return var_1_0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_1.skillID

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_4 and (var_0_6:father(var_2_0) == arg_2_0:getPugongID() or var_0_6:father(var_2_0) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) and var_2_0 ~= var_0_4 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_2.weightedChoise({
		var_0_5,
		1 - var_0_5
	}) == 1 then
		local var_2_1 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_4)

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_4 > 0 and arg_3_0:hasElementEquipByID(var_0_8) and arg_3_1.skillID == var_0_9 then
		local var_3_0 = arg_3_1.target
		local var_3_1 = var_0_8

		arg_3_4 = arg_3_4 + var_0_7:battleAttr(var_3_1, arg_3_0:getElementEquipLevelByID(var_3_1)) * arg_3_0.hero_:getElementEquipActiveRate(var_3_1)
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
