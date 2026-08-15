local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuemonv", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40011600
local var_0_7 = 40011604
local var_0_8 = 300
local var_0_9 = 40011603
local var_0_10 = 500
local var_0_11 = 45

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillCD = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_2_0.purpleSkillCD = arg_2_0.purpleSkillCD + 1

		if arg_2_0.purpleSkillCD > var_0_8 then
			arg_2_0.purpleSkillCD = 0

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_0 = arg_2_0:createAttackUnits(var_0_4.B2(arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)), arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_2_0, iter_2_1 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end
			end
		end
	end

	if arg_2_0.skinSkillIndex_ == 1 and not arg_2_0.SkinAddEnergy and var_0_1.ctx.battle.count % 10 == 1 then
		arg_2_0:updateEnergyBy(var_0_10)

		arg_2_0.SkinAddEnergy = true
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_5:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_3_0 = arg_3_1.target:getBuffByID(var_0_7)

		if var_3_0 then
			if arg_3_0.skinSkillIndex_ == 1 then
				var_3_0:setExtraTime(var_0_11 + 90 + 9 * #arg_3_1.target:getBuffsByID(var_0_6))
			else
				var_3_0:setExtraTime(90 + 9 * #arg_3_1.target:getBuffsByID(var_0_6))
			end
		end
	end

	if var_0_5:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local function var_3_1(arg_4_0)
			if arg_4_0 < 600 then
				return 90 - arg_4_0 / 10
			else
				return 30
			end
		end

		local var_3_2 = arg_3_1.target:getBuffByID(var_0_9)

		if var_3_2 then
			if arg_3_0.skinSkillIndex_ == 1 then
				var_3_2:setExtraTime(var_0_11 + var_3_1(math.abs(arg_3_0:getX() - arg_3_1.target:getX())))
			else
				var_3_2:setExtraTime(var_3_1(math.abs(arg_3_0:getX() - arg_3_1.target:getX())))
			end
		end
	end
end

return var_0_3
