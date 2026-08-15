local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Zhuzi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40010267
local var_0_6 = 40010070
local var_0_7 = 100
local var_0_8 = 60
local var_0_9 = {
	40010072,
	40010267
}

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getEnergySkillID() then
		local var_1_0 = arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
		local var_1_1 = var_0_4.new({
			tableID = var_0_5,
			start = var_0_1.ctx.battle.count,
			level = arg_1_0:getSkillLevelByID(var_1_0),
			skillID = var_1_0,
			fighter = arg_1_0,
			target = arg_1_1.target
		})

		arg_1_1.target:addBuffs({
			var_1_1
		})
	end
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isEnergy_ and var_0_1.ctx.battle.count % 30 < 1 and arg_2_0:getNearestTarget() then
		if not arg_2_0.target_:isDeath() then
			arg_2_0:updateEnergyTo(arg_2_0:getEnergy() - var_0_7)

			if arg_2_0:getEnergy() < 1 then
				for iter_2_0, iter_2_1 in ipairs(var_0_9) do
					arg_2_0.target_:removeBuffByID(iter_2_1)
				end

				arg_2_0.target_:removeBuffByID(var_0_5)
				arg_2_0.target_:setImmuneControl(false)

				arg_2_0.target_ = nil
				arg_2_0.isEnergy_ = false
			end
		else
			arg_2_0.target_:setImmuneControl(false)

			arg_2_0.isEnergy_ = false
			arg_2_0.target_ = nil
		end
	end

	for iter_2_2, iter_2_3 in ipairs(arg_2_0:getInfoByKey("shanbi_info")) do
		if iter_2_3.fighter:getTeamType() == arg_2_0:getTeamType() then
			local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			local var_2_1 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_2_2 = iter_2_3.fighter
			local var_2_3 = var_0_4.new({
				tableID = var_0_6,
				start = var_0_1.ctx.battle.count,
				level = var_2_0,
				skillID = var_2_1,
				fighter = arg_2_0,
				target = var_2_2
			})

			var_2_3:setIsHit(true)
			var_2_3:setDirection(arg_2_0:getFighterModel():getFlipX())
			var_2_2:addBuffs({
				var_2_3
			})
			arg_2_0:updateEnergyTo(arg_2_0:getEnergy() + var_0_8)
		end
	end
end

return var_0_3
