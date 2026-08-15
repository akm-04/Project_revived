local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Songzhongji", var_0_1.ctx.battle.requireFighter("ProphesyBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = {
	10010169
}
local var_0_7 = 550

function var_0_3.selectTargetByTypeD1(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() and iter_1_1.hero_:getDistance() <= var_0_7 then
			table.insert(var_1_0, iter_1_1)
		end
	end

	return var_1_0
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

	if next(arg_2_1) then
		arg_2_0:addBuffs(arg_2_1)
	end

	if arg_2_3 then
		arg_2_0:checkSkillBreak(var_0_2.BreakSkillType.AD)
	end

	if arg_2_4 then
		arg_2_0:checkSkillBreak(var_0_2.BreakSkillType.AP)
	end
end

function var_0_3.applyBuffHarms(arg_3_0)
	return
end

function var_0_3.checkSkillBreak(arg_4_0, arg_4_1)
	return
end

function var_0_3.addBuffs(arg_5_0, arg_5_1)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		if not iter_5_1:isFear() and not iter_5_1:isApUnable() and not iter_5_1:isAdUnable() and not iter_5_1:isExcuteAdCircle() and not iter_5_1:isAttackFriend() and not iter_5_1:isPossessed() then
			table.insert(var_5_0, iter_5_1)
		end
	end

	var_0_3.super.addBuffs(arg_5_0, var_5_0)
end

return var_0_3
