local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangliao", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = 90030009
local var_0_5 = 10010067

function var_0_3.checkSkillBreak(arg_1_0, arg_1_1, arg_1_2)
	if not arg_1_0.unitSkills_ or arg_1_0.unitSkills_.rootID_ ~= var_0_4 then
		var_0_3.super.checkSkillBreak(arg_1_0, arg_1_1, arg_1_2)
	end
end

function var_0_3.applyUnitBuffs(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6)
	if arg_2_0:isDeath() then
		for iter_2_0, iter_2_1 in ipairs(arg_2_1 or {}) do
			if iter_2_1:getYx() > 0 then
				arg_2_0.buffMovePath_ = iter_2_1:getPath()
			end
		end

		return
	end

	if next(arg_2_2) then
		arg_2_0.fighterModel:playFloatText({
			var_0_2.BattleFloatType.BUFF_MISS
		}, arg_2_0:getTeamType())
	end

	if next(arg_2_1) and (not arg_2_0.unitSkills_ or arg_2_0.unitSkills_.rootID_ ~= var_0_4) then
		arg_2_0:addBuffs(arg_2_1)

		for iter_2_2, iter_2_3 in ipairs(arg_2_1) do
			if iter_2_3:getTableID() == var_0_5 then
				for iter_2_4, iter_2_5 in ipairs(arg_2_0.buffMovePath_) do
					iter_2_5[1] = 0
				end

				break
			end
		end
	end

	if arg_2_5 and arg_2_0:isCreatingUnits() then
		arg_2_0:skillIsBreak(arg_2_6)

		arg_2_0.leftInterval_ = 0
	end

	if arg_2_3 then
		arg_2_0:checkSkillBreak(var_0_2.BreakSkillType.AD)
	end

	if arg_2_4 then
		arg_2_0:checkSkillBreak(var_0_2.BreakSkillType.AP)
	end
end

function var_0_3.canBeStop(arg_3_0)
	if arg_3_0.unitSkills_ and arg_3_0.unitSkills_.rootID_ == var_0_4 then
		return false
	end

	return true
end

return var_0_3
