local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangchunhua", var_0_1.ctx.battle.requireFighter("HideBoss"))
local var_0_4 = 80010014
local var_0_5 = {
	40011152,
	40011153,
	40011154,
	40011155,
	40011156
}
local var_0_6 = 0.15
local var_0_7 = 51010014

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("buff_info")) do
			for iter_2_2, iter_2_3 in ipairs(var_0_5) do
				if iter_2_1.target:getTeamType() ~= arg_2_0:getTeamType() and iter_2_1.target:isHasBuffByID(iter_2_3) and iter_2_1:getType() == var_0_2.BuffType.CONTINUE_HARM then
					local var_2_0 = iter_2_1:getHarm()
					local var_2_1 = arg_2_0:skinBuffNum(iter_2_1.target)

					iter_2_1.manualHarmRevise = var_2_0 + var_2_0 * var_0_6 * var_2_1 + iter_2_1.manualHarmRevise
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0.isSkinSkillOn_ and (arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_3_1.skillID == var_0_7) then
		local var_3_0 = arg_3_0:skinBuffNum(arg_3_1.target)

		if var_3_0 < 5 then
			if var_3_0 > 0 then
				arg_3_1.target:removeBuffByID(var_0_5[var_3_0])
			end

			local var_3_1 = arg_3_0:createNewBuffs({
				var_0_5[var_3_0 + 1]
			}, arg_3_1.target, var_0_4)

			arg_3_1.target:addBuffs(var_3_1)
		end
	end
end

function var_0_3.skinBuffNum(arg_4_0, arg_4_1)
	if not arg_4_0.isSkinSkillOn_ then
		return 0
	else
		for iter_4_0, iter_4_1 in ipairs(var_0_5) do
			if arg_4_1:isHasBuffByID(iter_4_1) then
				return iter_4_0
			end
		end

		return 0
	end
end

function var_0_3.die(arg_5_0)
	if arg_5_0.isSkinSkillOn_ then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			for iter_5_2, iter_5_3 in ipairs(var_0_5) do
				if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1:isHasBuffByID(iter_5_3) then
					iter_5_1:removeBuffByID(iter_5_3)
				end
			end
		end
	end

	return var_0_3.super.die(arg_5_0)
end

return var_0_3
