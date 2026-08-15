local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Houcheng", var_0_1.ctx.battle.requireFighter("Houcheng"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 1.5
local var_0_9 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeCDCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	arg_2_0.awakeCDCount = arg_2_0.awakeCDCount - 1

	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("buff_info")) do
		local var_2_0 = iter_2_1.fighter
		local var_2_1 = iter_2_1.target
		local var_2_2 = iter_2_1.level_

		if var_2_1 == arg_2_0 and var_2_0 ~= arg_2_0 and iter_2_1:getBuffForm() == var_0_2.BuffForm.GAIN and arg_2_0.awakeCDCount <= 0 then
			arg_2_0.awakeCDCount = var_0_9

			local var_2_3 = 1

			arg_2_0:addPassionNum(var_2_3)
			arg_2_0:addSelfTeamNewBuff(iter_2_1, var_2_2)

			local var_2_4 = var_0_8 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

			iter_2_1:setExtraTime(var_2_4)
		end
	end
end

function var_0_3.addSelfTeamNewBuff(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = var_0_8 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	local var_3_1 = arg_3_1:getTableID()
	local var_3_2 = arg_3_0:getRandomTargetExceptSelf()

	if var_3_2 then
		arg_3_0:extraNewBuff(var_3_1, var_3_2, arg_3_2, var_3_0)
	end
end

function var_0_3.extraNewBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0 = arg_4_2
	local var_4_1 = var_0_4.new({
		tableID = arg_4_1,
		start = var_0_1.ctx.battle.count,
		level = arg_4_3,
		skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
		fighter = arg_4_0,
		target = var_4_0
	})

	if arg_4_4 then
		var_4_1:setExtraTime(arg_4_4)
	end

	var_4_0:addBuffs({
		var_4_1
	})
end

function var_0_3.getRandomTargetExceptSelf(arg_5_0)
	local var_5_0 = {}
	local var_5_1
	local var_5_2 = arg_5_0.selfTeam_

	for iter_5_0, iter_5_1 in ipairs(var_5_2) do
		if not iter_5_1:isDeath() and iter_5_1 ~= arg_5_0 and not iter_5_1:isAffected() then
			table.insert(var_5_0, iter_5_1)
		end
	end

	if #var_5_0 >= 1 then
		var_5_1 = var_5_0[math.random(#var_5_0)]
	end

	return var_5_1
end

return var_0_3
