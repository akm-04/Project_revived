local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Fulan"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = {
	40010491
}

function var_0_3.toDoPerFrames(arg_1_0)
	var_0_3.super.toDoPerFrames(arg_1_0)

	if arg_1_0:isDeath() then
		return
	end

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() then
			if not iter_1_1:isHasBuffByID(unpack(var_0_5)) then
				if arg_1_0:isInSilence(iter_1_1) then
					local var_1_0 = arg_1_0:newBuff(var_0_5, iter_1_1, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

					iter_1_1:addBuffs(var_1_0)
				end
			elseif not arg_1_0:isInSilence(iter_1_1) then
				for iter_1_2, iter_1_3 in ipairs(var_0_5) do
					iter_1_1:removeBuffByID(iter_1_3)
				end
			end
		end
	end
end

function var_0_3.isInSilence(arg_2_0, arg_2_1)
	if arg_2_1:isApUnable() and not arg_2_1:isAdUnable() then
		return true
	else
		return false
	end
end

function var_0_3.newBuff(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		local var_3_1 = var_0_4.new({
			tableID = iter_3_1,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_3),
			skillID = arg_3_3,
			fighter = arg_3_0,
			target = arg_3_2
		})

		var_3_1:setIsHit(true)
		var_3_1:setDirection(arg_3_0:getFighterModel():getFlipX())
		table.insert(var_3_0, var_3_1)
	end

	return var_3_0
end

return var_0_3
