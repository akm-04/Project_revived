local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SimayiSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.model
local var_0_7 = 5
local var_0_8 = 40012405
local var_0_9 = 40012404
local var_0_10 = 40012408

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.GreenTargetNum = 1
	arg_1_0.PurpleTargetNum = 0
	arg_1_0.ChaofengMarkTarget = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 5 == 1 then
		arg_2_0.PurpleTargetNum = 0

		for iter_2_0, iter_2_1 in pairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and iter_2_1.summonType_ ~= var_0_2.summonMonsterType.Pet then
				arg_2_0.PurpleTargetNum = arg_2_0.PurpleTargetNum + 1
			end
		end

		if arg_2_0.PurpleTargetNum == 1 and not arg_2_0:isHasBuffByID(var_0_8) then
			local var_2_0 = arg_2_0:createNewBuffs({
				var_0_8
			}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			arg_2_0:addBuffs(var_2_0)
		elseif arg_2_0.PurpleTargetNum > 1 and arg_2_0:isHasBuffByID(var_0_8) then
			arg_2_0:removeBuffByID(var_0_8)
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_3_0 = arg_3_1.target

		arg_3_0:removeGoodBuff(arg_3_1.target)
	end
end

function var_0_3.removeGoodBuff(arg_4_0, arg_4_1)
	for iter_4_0 = #arg_4_1.buffs_, 1, -1 do
		local var_4_0 = arg_4_1.buffs_[iter_4_0]

		if var_4_0 and var_4_0:getBuffForm() == var_0_2.BuffForm.GAIN and var_4_0:canRemove() and var_4_0.leftCount_ < 3000 then
			arg_4_1:removeBuffs(var_4_0)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0)
	if arg_5_0.GreenTargetNum == 1 then
		arg_5_0.GreenTargetNum = arg_5_0.GreenTargetNum + 1

		return var_0_4.B3(arg_5_0)
	end

	local var_5_0 = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			table.insert(var_5_0, iter_5_1)
		end
	end

	local var_5_1 = math.random(tonumber(os.time()))

	math.randomseed(var_5_1)

	local var_5_2 = 0

	while #var_5_0 > arg_5_0.GreenTargetNum and var_5_2 < 10 do
		var_5_2 = var_5_2 + 1

		local var_5_3 = math.random(#var_5_0)
		local var_5_4 = var_5_0[var_5_3]

		table.remove(var_5_0, var_5_3)
	end

	arg_5_0.GreenTargetNum = arg_5_0.GreenTargetNum + 1

	return var_5_0
end

function var_0_3.selectTargetByTypeD2(arg_6_0)
	local var_6_0
	local var_6_1 = 0

	for iter_6_0, iter_6_1 in pairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			if not var_6_0 then
				var_6_0 = iter_6_1
				var_6_1 = iter_6_1:getHuJia() + iter_6_1:getMoKang()
			elseif var_6_1 > iter_6_1:getHuJia() + iter_6_1:getMoKang() then
				var_6_0 = iter_6_1
				var_6_1 = iter_6_1:getHuJia() + iter_6_1:getMoKang()
			end
		end
	end

	return {
		var_6_0
	}
end

function var_0_3.selectTargetByTypeD3(arg_7_0)
	local var_7_0
	local var_7_1 = 0

	for iter_7_0, iter_7_1 in pairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			if not var_7_0 then
				var_7_0 = iter_7_1
				var_7_1 = iter_7_1:getEnergy()
			else
				local var_7_2 = iter_7_1:getEnergy()

				if var_7_1 < var_7_2 then
					var_7_0 = iter_7_1
					var_7_1 = var_7_2
				end
			end
		end
	end

	return {
		var_7_0
	}
end

function var_0_3.getAP(arg_8_0)
	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		return arg_8_0.PurpleTargetNum * var_0_7 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) + var_0_3.super.getAP(arg_8_0)
	end

	return var_0_3.super.getAP(arg_8_0)
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	var_0_3.super.buffAddAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == var_0_10 then
		arg_9_0.ChaofengMarkTarget = arg_9_1.target

		for iter_9_0, iter_9_1 in pairs(arg_9_0.selfTeam_) do
			if not iter_9_1:isDeath() then
				local var_9_0 = arg_9_0:createNewBuffs({
					var_0_9
				}, iter_9_1, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				iter_9_1:addBuffs(var_9_0)
			end
		end
	elseif arg_9_1:getTableID() == var_0_9 and arg_9_0.ChaofengMarkTarget then
		arg_9_1:setForceTarget(arg_9_0.ChaofengMarkTarget)
	end
end

function var_0_3.buffRemoveAction(arg_10_0, arg_10_1)
	if arg_10_1:getTableID() == var_0_10 then
		for iter_10_0, iter_10_1 in pairs(arg_10_0.selfTeam_) do
			if not iter_10_1:isDeath() then
				iter_10_1:removeBuffByID(var_0_9)
			end
		end
	end
end

return var_0_3
