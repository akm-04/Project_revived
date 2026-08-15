local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunyu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 10000136
local var_0_5 = 80010036
local var_0_6 = 0.3
local var_0_7 = 50110036
local var_0_8 = var_0_2.tables.elementEquip
local var_0_9 = 20001460
local var_0_10 = 10002212
local var_0_11 = 40012363
local var_0_12 = 0.3333333333333333

function var_0_3.toDoPerFrames(arg_1_0)
	var_0_3.super.toDoPerFrames(arg_1_0)

	if arg_1_0:isDeath() then
		return
	end

	if arg_1_0:hasElementEquipByID(var_0_9) and not arg_1_0.hadAddElementEnergy and var_0_1.ctx.battle.count % 10 == 1 then
		local var_1_0 = var_0_9
		local var_1_1 = var_0_8:battleAttr(var_1_0, arg_1_0:getElementEquipLevelByID(var_1_0)) * arg_1_0.hero_:getElementEquipActiveRate(var_1_0)

		arg_1_0:updateEnergyBy(var_1_1)

		arg_1_0.addElementEnergy = true
		arg_1_0.hadAddElementEnergy = true
	end
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if var_2_2 > 0 and arg_2_1.skillID == var_0_7 and arg_2_0:getAP() > arg_2_1.target:getAP() and arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_5 then
		var_2_2 = var_2_2 * (1 + var_0_6)
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.updateUnitInfoBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.fighter == arg_3_0 and (arg_3_1.skillID == arg_3_0:getEnergySkillID() or arg_3_1.skillID == var_0_7) then
		arg_3_0.skillRehp_ = (arg_3_0.skillRehp_ or 0) + arg_3_4

		if arg_3_1.collisionNum <= 1 and arg_3_0.skillRehp_ > 0 then
			arg_3_0:updateHp(arg_3_0.skillRehp_ + arg_3_0:getHp())
			arg_3_0.fighterModel:playHPDeltas({
				{
					arg_3_0.skillRehp_,
					false
				}
			}, nil)
			arg_3_0:getFighterModel():stopAttackEffect_()

			arg_3_0.skillRehp_ = 0
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if (arg_4_1.skillID == arg_4_0:getEnergySkillID() or arg_4_1.skillID == var_0_7) and arg_4_0:isDeath() then
		return
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if (arg_4_1.skillID == arg_4_0:getEnergySkillID() or arg_4_1.skillID == var_0_7) and arg_4_0.addElementEnergy and arg_4_0.addElementEnergy == true and arg_4_0:hasElementEquipByID(var_0_9) then
		local var_4_0 = var_0_9
		local var_4_1 = var_0_8:battleAttr(var_4_0, arg_4_0:getElementEquipLevelByID(var_4_0))
		local var_4_2 = arg_4_0.hero_:getElementEquipActiveRate(var_4_0)
		local var_4_3 = arg_4_0:createNewBuffs({
			var_0_11
		}, arg_4_0, var_0_10)

		for iter_4_0, iter_4_1 in ipairs(var_4_3) do
			iter_4_1.manualRevise = var_4_1 * var_4_2 * var_0_12
		end

		arg_4_0:addBuffs(var_4_3)

		arg_4_0.addElementEnergy = false
	end
end

function var_0_3.init(arg_5_0)
	var_0_3.super.init(arg_5_0)

	arg_5_0.skillRehp_ = 0
end

function var_0_3.checkReHpMp(arg_6_0)
	var_0_3.super.checkReHpMp(arg_6_0)

	if arg_6_0.skillRehp_ > 0 and not arg_6_0:isDeath() then
		arg_6_0:getFighterModel():stopAttackEffect_()
		arg_6_0:updateHp(arg_6_0.skillRehp_ + arg_6_0:getHp())
		arg_6_0.fighterModel:playHPDeltas({
			{
				arg_6_0.skillRehp_,
				false
			}
		}, nil)
		arg_6_0:showCureEffect()
	end
end

function var_0_3.showCureEffect(arg_7_0)
	local var_7_0 = var_0_4
	local var_7_1 = {
		arg_7_0
	}
	local var_7_2 = arg_7_0:createAttackUnits(var_7_1, var_7_0)

	arg_7_0:hurtSkillEffect(var_7_2[1])
end

function var_0_3.unitCollisionBreak(arg_8_0, arg_8_1)
	if arg_8_1.skillID == arg_8_0:getEnergySkillID() or arg_8_1.skillID == var_0_7 then
		arg_8_0.skillRehp_ = arg_8_0.skillRehp_ or 0

		if arg_8_0.skillRehp_ > 0 then
			arg_8_0:updateHp(arg_8_0.skillRehp_ + arg_8_0:getHp())
			arg_8_0.fighterModel:playHPDeltas({
				{
					arg_8_0.skillRehp_,
					false
				}
			}, nil)
			arg_8_0:getFighterModel():stopAttackEffect_()

			arg_8_0.skillRehp_ = 0
		end
	end
end

return var_0_3
