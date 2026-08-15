local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xujing", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40010913
local var_0_7 = {
	40010909,
	40010910
}
local var_0_8 = {
	40010911
}
local var_0_9 = 10000835

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyShowTarget_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 10 < 1 and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_2_0:checkPurpleSkill()
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and not arg_3_1.target:isDeath() and not arg_3_1.target:isAffected() then
		local var_3_0 = arg_3_1.target:getBuffs()

		for iter_3_0 = #var_3_0, 1, -1 do
			if var_3_0[iter_3_0] and var_3_0[iter_3_0]:getType() == var_0_2.BuffType.D_HARM then
				arg_3_1.target:removeBuffs(var_3_0[iter_3_0])
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		local var_3_1 = arg_3_0:newBuff({
			var_0_6
		}, arg_3_0, arg_3_0:getEnergySkillID())

		arg_3_0:addBuffs(var_3_1)

		if arg_3_0.energyShowTarget_ and arg_3_0.energyShowTarget_ == arg_3_1.target then
			local var_3_2 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_9)

			for iter_3_1, iter_3_2 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_2)
				table.insert(arg_3_0.records_.special_units, iter_3_2)
			end
		end
	end
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

function var_0_3.checkPurpleSkill(arg_5_0)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		local var_5_0 = arg_5_0:checkInCircle(iter_5_1)

		if not iter_5_1:isDeath() and not iter_5_1:isHasBuffByID(var_0_7[1]) and var_5_0 then
			local var_5_1 = arg_5_0:newBuff(var_0_7, iter_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			iter_5_1:addBuffs(var_5_1)
		elseif not iter_5_1:isDeath() and not var_5_0 then
			for iter_5_2 = 1, #var_0_7 do
				iter_5_1:removeBuffByID(var_0_7[iter_5_2])
			end
		end
	end

	for iter_5_3, iter_5_4 in ipairs(arg_5_0.sideTeam_) do
		local var_5_2 = arg_5_0:checkInCircle(iter_5_4)

		if not iter_5_4:isDeath() and not iter_5_4:isHasBuffByID(var_0_8[1]) and var_5_2 then
			local var_5_3 = arg_5_0:newBuff(var_0_8, iter_5_4, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			iter_5_4:addBuffs(var_5_3)
		elseif not iter_5_4:isDeath() and not var_5_2 then
			for iter_5_5 = 1, #var_0_8 do
				iter_5_4:removeBuffByID(var_0_8[iter_5_5])
			end
		end
	end
end

function var_0_3.checkInCircle(arg_6_0, arg_6_1)
	local var_6_0 = var_0_5:scope(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) / 2
	local var_6_1 = arg_6_0:getX()

	if var_6_0 >= math.abs(arg_6_1:getX() - var_6_1) then
		return true
	end

	return false
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local function var_7_0(arg_8_0, arg_8_1)
		local var_8_0 = {}

		table.insert(var_8_0, arg_8_0)

		for iter_8_0, iter_8_1 in ipairs(arg_7_0.sideTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1 ~= arg_8_0 and arg_8_1 >= math.abs(iter_8_1:getX() - arg_8_0:getX()) then
				table.insert(var_8_0, iter_8_1)
			end
		end

		return var_8_0
	end

	local var_7_1 = {}
	local var_7_2
	local var_7_3 = 0
	local var_7_4 = var_0_5:scope(arg_7_0:getEnergySkillID()) * 0.5

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			local var_7_5 = var_7_0(iter_7_1, var_7_4)

			if var_7_3 < #var_7_5 then
				var_7_1 = var_7_5
				var_7_3 = #var_7_5
				var_7_2 = iter_7_1
			end
		end
	end

	arg_7_0.energyShowTarget_ = var_7_2

	return var_7_1
end

return var_0_3
