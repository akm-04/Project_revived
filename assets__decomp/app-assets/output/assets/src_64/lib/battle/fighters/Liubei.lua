local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liubei", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skinSkill
local var_0_6 = 40010703

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isAddSkinBuff = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ and not arg_2_0.isAddSkinBuff then
		arg_2_0.isAddSkinBuff = true

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				local var_2_0 = arg_2_0:newBuff({
					var_0_6
				}, iter_2_1, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

				iter_2_1:addBuffs(var_2_0)
			end
		end
	end
end

function var_0_3.die(arg_3_0)
	if arg_3_0.isSkinSkillOn_ then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1:isHasBuffByID(var_0_6) then
				iter_3_1:removeBuffByID(var_0_6)
			end
		end
	end

	return var_0_3.super.die(arg_3_0)
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

return var_0_3
