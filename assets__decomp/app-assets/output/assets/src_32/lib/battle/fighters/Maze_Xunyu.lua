local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("MazeXunyu", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = 10000136

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	if arg_1_1.skillID == arg_1_0:getEnergySkillID() then
		arg_1_0.skillRehp_ = (arg_1_0.skillRehp_ or 0) + arg_1_4

		if arg_1_1.collisionNum <= 1 and arg_1_0.skillRehp_ > 0 then
			arg_1_0:updateHp(arg_1_0.skillRehp_ + arg_1_0:getHp())
			arg_1_0.fighterModel:playHPDeltas({
				{
					arg_1_0.skillRehp_,
					false
				}
			}, nil)
			arg_1_0:getFighterModel():stopAttackEffect_()

			arg_1_0.skillRehp_ = 0
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_0:isDeath() then
		return
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.skillRehp_ = 0
end

function var_0_3.energyAction(arg_4_0, arg_4_1)
	var_0_3.super.energyAction(arg_4_0, arg_4_1)

	if arg_4_1 == arg_4_0:getEnergySkillID() and arg_4_0.skillRehp_ > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_4_0:updateHp(arg_4_0.skillRehp_ + arg_4_0:getHp())
		arg_4_0.fighterModel:playHPDeltas({
			{
				arg_4_0.skillRehp_,
				false
			}
		}, nil)
		arg_4_0:getFighterModel():stopAttackEffect_()
		arg_4_0:showCureEffect()

		arg_4_0.skillRehp_ = 0

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.applyUnits_) do
			if iter_4_1.skillID == arg_4_0:getEnergySkillID() then
				iter_4_1.collisionNum = 0

				table.remove(arg_4_0.applyUnits_, iter_4_0)
				var_0_0.table.removebyvalue(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.recordUnits_, iter_4_1)
			end
		end
	end
end

function var_0_3.checkReHpMp(arg_5_0)
	var_0_3.super.checkReHpMp(arg_5_0)

	if arg_5_0.skillRehp_ > 0 and not arg_5_0:isDeath() then
		arg_5_0:getFighterModel():stopAttackEffect_()
		arg_5_0:updateHp(arg_5_0.skillRehp_ + arg_5_0:getHp())
		arg_5_0.fighterModel:playHPDeltas({
			{
				arg_5_0.skillRehp_,
				false
			}
		}, nil)
		arg_5_0:showCureEffect()
	end
end

function var_0_3.showCureEffect(arg_6_0)
	local var_6_0 = var_0_4
	local var_6_1 = {
		arg_6_0
	}
	local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

	arg_6_0:hurtSkillEffect(var_6_2[1])
end

function var_0_3.unitCollisionBreak(arg_7_0, arg_7_1)
	if arg_7_1.skillID == arg_7_0:getEnergySkillID() then
		arg_7_0.skillRehp_ = arg_7_0.skillRehp_ or 0

		if arg_7_0.skillRehp_ > 0 then
			arg_7_0:updateHp(arg_7_0.skillRehp_ + arg_7_0:getHp())
			arg_7_0.fighterModel:playHPDeltas({
				{
					arg_7_0.skillRehp_,
					false
				}
			}, nil)
			arg_7_0:getFighterModel():stopAttackEffect_()

			arg_7_0.skillRehp_ = 0
		end
	end
end

return var_0_3
