local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhenji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 50020028
local var_0_6 = 2
local var_0_7 = var_0_2.tables.elementEquip
local var_0_8 = 20001457
local var_0_9 = 10002188
local var_0_10 = 40012346
local var_0_11 = 40012347

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyTargetCounts_ = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_0.isSkinSkillOn_ and arg_2_1.skillID == var_0_5 then
		if not arg_2_0.energyTargetCounts_[arg_2_1.target] then
			arg_2_0.energyTargetCounts_[arg_2_1.target] = 1
		else
			arg_2_0.energyTargetCounts_[arg_2_1.target] = arg_2_0.energyTargetCounts_[arg_2_1.target] + 1
		end

		if arg_2_0.energyTargetCounts_[arg_2_1.target] >= var_0_6 then
			arg_2_0:useSkinSkill(arg_2_1.target)

			arg_2_0.energyTargetCounts_[arg_2_1.target] = 0
		end
	end
end

function var_0_3.useSkinSkill(arg_3_0, arg_3_1)
	if arg_3_1:isDeath() or arg_3_1:isAffected() or var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return
	end

	local var_3_0 = {
		arg_3_1
	}
	local var_3_1 = arg_3_0:createAttackUnits(var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

	for iter_3_0, iter_3_1 in ipairs(var_3_1) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
		table.insert(arg_3_0.records_.special_units, iter_3_1)
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.target

	if arg_4_0:hasElementEquipByID(var_0_8) and arg_4_1:dBuffType() == var_0_2.DBuffType.BING_DONG then
		local var_4_1 = var_0_8
		local var_4_2 = var_0_7:battleAttr(var_4_1, arg_4_0:getElementEquipLevelByID(var_4_1))
		local var_4_3 = arg_4_0.hero_:getElementEquipActiveRate(var_4_1)
		local var_4_4 = arg_4_0:createNewBuffs({
			var_0_10
		}, arg_4_0, var_0_9)

		for iter_4_0, iter_4_1 in ipairs(var_4_4) do
			iter_4_1.manualRevise = var_4_2 * var_4_3
		end

		arg_4_0:addBuffs(var_4_4)

		local var_4_5 = arg_4_0:createNewBuffs({
			var_0_11
		}, var_4_0, var_0_9)

		var_4_0:addBuffs(var_4_5)
	end
end

return var_0_3
