local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Masu", var_0_1.ctx.battle.requireFighter("Masu"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 20010052
local var_0_8 = {
	20010268
}
local var_0_9 = {
	20010269
}
local var_0_10 = 0.1
local var_0_11 = 0.002
local var_0_12 = {
	40012078,
	40012079
}
local var_0_13 = 10000109

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	var_0_3:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.iceArmorTarget = {}
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		table.insert(arg_3_0.iceArmorTarget, arg_3_1.target)
		arg_3_1.target:addBuffs(arg_3_0:newBuff(var_0_8, arg_3_1.target, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and (arg_3_1.skillID == arg_3_0:getEnergySkillID() or arg_3_1.skillID == var_0_13) then
		local var_3_0 = arg_3_0:createNewBuffs(var_0_12, arg_3_1.target, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_3_1.target:addBuffs(var_3_0)
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_6.new({
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

function var_0_3.toDoPerFrames(arg_5_0)
	var_0_3.super.toDoPerFrames(arg_5_0)

	if next(arg_5_0.iceArmorTarget) then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("unit_info")) do
			local var_5_0 = iter_5_1.target
			local var_5_1 = iter_5_1.fighter

			if var_5_1:getTeamType() ~= arg_5_0:getTeamType() and not var_5_1:isAffected() then
				for iter_5_2 = #arg_5_0.iceArmorTarget, 1, -1 do
					local var_5_2 = arg_5_0.iceArmorTarget[iter_5_2]

					if not var_5_2:isHasBuffByID(var_0_7) then
						table.remove(arg_5_0.iceArmorTarget, iter_5_2)
					elseif var_5_2 == var_5_0 then
						var_5_1:addBuffs(arg_5_0:newBuff(var_0_9, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
					end
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and (arg_6_1.skillID == arg_6_0:getEnergySkillID() or arg_6_1.skillID == var_0_13 and arg_6_4 > 0) then
		local var_6_0 = var_0_5:collisionNum(arg_6_1.skillID)

		arg_6_4 = arg_6_4 * (1 + (var_0_10 + var_0_11 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)) * (var_6_0 - arg_6_1.collisionNum))
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

return var_0_3
