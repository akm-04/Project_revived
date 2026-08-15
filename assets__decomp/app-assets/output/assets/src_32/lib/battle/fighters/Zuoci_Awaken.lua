local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zuoci", var_0_1.ctx.battle.requireFighter("Zuoci"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = 0
local var_0_6 = 0.005
local var_0_7 = 0
local var_0_8 = 10

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.reviseGlobal = false
	arg_2_0.awakeTwiceCount_ = 0
	arg_2_0.energyUnitNum = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0.energyUnitNum == 0 then
		arg_3_0.energyUnitNum = var_0_2.tables.skill:unitNum(arg_3_0:getEnergySkillID())
	end

	if not arg_3_0.reviseGlobal then
		arg_3_0.reviseGlobal = true

		local var_3_0 = arg_3_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsB or var_0_1.ctx.battle.globalBuffsA

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			local var_3_1 = iter_3_1:getTableID()

			if iter_3_1.fighter:getTeamType() == arg_3_0:getTeamType() and var_0_4:attr(var_3_1) == var_0_2.AttributeType.MOKANG and (var_0_4:step(var_3_1) < 0 or var_0_4:init(var_3_1) < 0) then
				iter_3_1.manualRevise = iter_3_1:getAttr() * (var_0_5 + var_0_6 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
			end
		end
	end

	if arg_3_0:isDeath() then
		return
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
		local var_3_2 = iter_3_3:getTableID()

		if iter_3_3.fighter:getTeamType() == arg_3_0:getTeamType() and var_0_4:attr(var_3_2) == var_0_2.AttributeType.MOKANG and (var_0_4:step(var_3_2) < 0 or var_0_4:init(var_3_2) < 0) then
			iter_3_3.manualRevise = iter_3_3:getAttr() * (var_0_5 + var_0_6 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_6 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

	if var_4_6 > 0 and arg_4_1.skillID == arg_4_0:getEnergySkillID() then
		local var_4_7 = var_0_7 + var_0_8 * var_4_6

		arg_4_0.awakeTwiceCount_ = arg_4_0.awakeTwiceCount_ + 1
		var_4_2 = var_4_2 + var_4_7 * arg_4_1.target:getAPJianShang() * arg_4_0.awakeTwiceCount_

		if arg_4_0.awakeTwiceCount_ == arg_4_0.energyUnitNum then
			arg_4_0.awakeTwiceCount_ = 0
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

return var_0_3
