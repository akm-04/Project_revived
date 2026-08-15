local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Gaoshun", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10000546
local var_0_6 = 10000545
local var_0_7 = 0
local var_0_8 = 0.002
local var_0_9 = 80010123
local var_0_10 = 40011608
local var_0_11 = 10

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCount_ = 0
	arg_1_0.isEnergyRush_ = false
	arg_1_0.rushSpeed_ = 50
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_6 then
		if arg_2_0.skinSkillID_ == var_0_9 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_0 = arg_2_0:createAttackUnits({
					arg_2_0
				}, var_0_9)

				for iter_2_0, iter_2_1 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end
			end
		else
			local var_2_1 = 1 - math.max(0, 0.4 - (var_0_7 + var_0_8 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)))

			arg_2_0:updateHp(arg_2_0:getHp() * var_2_1)
		end
	elseif arg_2_1.skillID == var_0_5 then
		arg_2_0.isEnergyRush_ = true
		arg_2_0.energyCount_ = 5
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_10 then
		arg_3_1.manualHarmRevise = math.max(0, 0.4 - (var_0_7 + var_0_8 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))) / var_0_11 * arg_3_0:getHp()
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.energyCount_ > 0 then
		arg_4_0.energyCount_ = arg_4_0.energyCount_ - 1

		if arg_4_0.energyCount_ == 0 then
			arg_4_0.isEnergyRush_ = false
		end
	end

	if arg_4_0.isEnergyRush_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:getFlipX() == false and 1 or -1
		local var_4_1 = arg_4_0:getX() + var_4_0 * arg_4_0.rushSpeed_
		local var_4_2

		if var_0_1.ctx.battle.isUnlimitBattle then
			var_4_2 = var_0_2.UNLIMIT_STAGE_WIDTH
		else
			var_4_2 = var_0_2.STAGE_WIDTH
		end

		if var_4_1 >= 0 and var_4_1 <= var_4_2 then
			arg_4_0:moveByX(var_4_0 * arg_4_0.rushSpeed_)
		end
	end
end

return var_0_3
