local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Duoduo"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0
local var_0_6 = 2

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("attack_info")) do
		if iter_2_1.rootID_ == iter_2_1.fighter_:getEnergySkillID() and iter_2_1.fighter_:getTeamType() ~= arg_2_0:getTeamType() and iter_2_1.fighter_.hero_:getHeroType() == var_0_2.HeroType.WISE then
			local var_2_0 = var_0_5 + var_0_6 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

			arg_2_0:updateEnergyBy(var_2_0)
		end
	end
end

return var_0_3
