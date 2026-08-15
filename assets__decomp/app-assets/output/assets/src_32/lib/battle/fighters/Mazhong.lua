local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mazhong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.battleConfig
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.4
local var_0_7 = 800
local var_0_8 = 200
local var_0_9 = 51010019
local var_0_10 = 80010019
local var_0_11 = 2
local var_0_12 = 0.1
local var_0_13 = 51010019
local var_0_14 = 80010019
local var_0_15 = 0.2
local var_0_16 = 0.004
local var_0_17 = 2
local var_0_18 = 0.2
local var_0_19 = var_0_2.tables.elementEquip
local var_0_20 = 20001490

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.elementNotBaojiTimes = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.skillID
	local var_2_1 = arg_2_1.target

	if arg_2_0:hasElementEquipByID(var_0_20) and arg_2_0.elementNotBaojiTimes >= 3 then
		arg_2_1.mustBaoji = true
		arg_2_0.elementNotBaojiTimes = 0
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	local var_2_2 = arg_2_1.target

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_14 and arg_2_1.skillID == var_0_13 then
		if not arg_2_0:isDeath() and var_2_2:isDeath() and var_2_2:canReborn() ~= true then
			arg_2_0:updateEnergyBy(var_0_8)
		elseif not arg_2_0:isDeath() and not var_2_2:isDeath() then
			arg_2_0:updateEnergyBy(var_0_7)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if var_3_2 > 0 and arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_14 and arg_3_1.skillID == var_0_13 then
		var_3_2 = var_3_2 * (1 + var_0_6)
	end

	if var_3_2 > 0 and arg_3_1.basicHarm > 0 and arg_3_1.attackType == var_0_2.AttackType.AD and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if not var_3_1 then
			local var_3_6 = arg_3_0:getADBaoJi() / (var_0_4.hujiaBaojiParam1 * math.max(arg_3_1.target:getHuJia() - arg_3_0:getDHuJia(), 0) + var_0_4.hujiaBaojiParam2) + arg_3_0:getBothBaoji()

			if arg_3_0:hasDbuff(arg_3_1.target) then
				var_3_6 = var_3_6 * var_0_17
			end

			local var_3_7 = math.min(1, var_3_6)

			if arg_3_1.mustBaoji or var_0_2.weightedChoise({
				var_3_7,
				1 - var_3_7
			}) == 1 then
				isBaoJi = true
			end
		end

		var_3_2 = arg_3_1.basicHarm * arg_3_1.basicHarm / (arg_3_1.basicHarm + 8 * math.max(arg_3_1.target:getHuJia() - arg_3_1.target:getHuJia() * (arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * var_0_16 + var_0_15) - arg_3_0:getDHuJia(), 0)) * arg_3_1.target:getADJianShang()

		if var_3_1 then
			var_3_2 = var_3_2 * (arg_3_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_3_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
			var_3_2 = var_3_2 * math.max(0.01, arg_3_1.target:getADBaoJiJianShang())
		end
	end

	if var_3_2 > 0 and var_3_1 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		var_3_2 = var_3_2 * (1 + arg_3_1.target:getHp() / arg_3_1.target:getHpLimit() * var_0_11) * (1 + var_0_12)

		if arg_3_0:hasDbuff(arg_3_1.target) and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			var_3_4 = var_3_4 + var_3_2 * var_0_18
		end
	end

	if arg_3_0:hasElementEquipByID(var_0_20) and var_3_2 > 0 and not var_3_1 and not arg_3_1.mustBaoji then
		arg_3_0.elementNotBaojiTimes = arg_3_0.elementNotBaojiTimes + 1
	end

	if arg_3_0:hasElementEquipByID(var_0_20) and var_3_2 > 0 and arg_3_1.target:getHp() / arg_3_1.target:getHpLimit() < arg_3_0:getHp() / arg_3_0:getHpLimit() then
		local var_3_8 = var_0_20
		local var_3_9 = var_0_19:battleAttr(var_3_8, arg_3_0:getElementEquipLevelByID(var_3_8))
		local var_3_10 = arg_3_0.hero_:getElementEquipActiveRate(var_3_8)

		var_3_2 = var_3_2 + var_3_2 * var_3_9 * var_3_10
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.hasDbuff(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in pairs(arg_4_1:getBuffs()) do
		if iter_4_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
			return true
		end
	end

	return false
end

return var_0_3
