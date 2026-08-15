local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhangfeiSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 40012206
local var_0_5 = 40012200
local var_0_6 = 0.2
local var_0_7 = 0.003

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleHarm = {}

	arg_1_0:listenInfo("harm_info")
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_2_0 = arg_2_0:createNewBuffs({
			var_0_5
		}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_2_0:addBuffs(var_2_0)
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() and arg_3_1.target.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI then
		local var_3_0 = arg_3_0:createNewBuffs({
			var_0_4
		}, arg_3_1.target, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		arg_3_1.target:addBuffs(var_3_0)
	end
end

function var_0_3.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_0:isHasBuffByID(var_0_5) and arg_4_4 > 0 then
		local var_4_0 = arg_4_1:getIniPos("x")
		local var_4_1 = arg_4_0:getFlipX() and -1 or 1

		if (var_4_0 - arg_4_0:getX()) * var_4_1 > 0 then
			arg_4_4 = 0
		end
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.toDoPerFrames(arg_5_0)
	if not arg_5_0:isDeath() and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("harm_info")) do
			local var_5_0 = iter_5_1.harm
			local var_5_1 = iter_5_1.fighter
			local var_5_2 = iter_5_1.target

			if var_5_1:getSummonType() == var_0_2.summonMonsterType.None and var_5_1:getTeamType() ~= arg_5_0:getTeamType() and var_5_2 == arg_5_0 then
				if not arg_5_0.purpleHarm[var_5_1] then
					arg_5_0.purpleHarm[var_5_1] = 0
				end

				arg_5_0.purpleHarm[var_5_1] = arg_5_0.purpleHarm[var_5_1] + var_5_0
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0.purpleHarm[arg_6_1.target] then
		local var_6_0 = 1
		local var_6_1 = arg_6_0.purpleHarm[arg_6_1.target]

		for iter_6_0, iter_6_1 in pairs(arg_6_0.purpleHarm) do
			if iter_6_0 ~= arg_6_1.target and not iter_6_0:isDeath() and var_6_1 < iter_6_1 then
				var_6_0 = var_6_0 + 1
			end
		end

		arg_6_4 = arg_6_4 * (1 + math.max(1 - (var_6_0 - 1) * 0.2, 0) * (var_0_6 + var_0_7 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)))
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

return var_0_3
