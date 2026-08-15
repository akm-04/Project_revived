local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Change", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 10010055
local var_0_10 = 10010056
local var_0_11 = 10010059
local var_0_12 = 10400001
local var_0_13 = 40010654

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.noEnergy_ = false
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.currentSkillID_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_12)] or 0
	end
end

function var_0_3.addExtraSkillBuff(arg_3_0)
	if arg_3_0.extraSkillLevel > 0 then
		local var_3_0 = var_0_5.new({
			tableID = var_0_13,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0.extraSkillLevel,
			skillID = arg_3_0:getEnergySkillID(),
			fighter = arg_3_0,
			target = arg_3_0
		})

		arg_3_0:addBuffs({
			var_3_0
		})
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}
	local var_4_1
	local var_4_2

	if arg_4_0.manualTargetsMoon_ then
		return arg_4_0.manualTargetsMoon_
	end

	local var_4_3, var_4_4 = var_0_4.getTeam(arg_4_0)

	for iter_4_0, iter_4_1 in ipairs(var_4_4) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:isHasBuffByID(var_0_9) and (not var_4_1 or var_4_1 < math.abs(iter_4_1:getX() - arg_4_0:getX())) then
			var_4_1 = math.abs(iter_4_1:getX() - arg_4_0:getX())
			var_4_2 = iter_4_1
		end
	end

	if var_4_2 then
		return {
			var_4_2
		}
	else
		var_4_0 = var_0_4.B1(arg_4_0, arg_4_1)
	end

	return var_4_0
end

function var_0_3.selectTargetByTypeD2(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}
	local var_5_1, var_5_2 = var_0_4.getTeam(arg_5_0)

	for iter_5_0, iter_5_1 in ipairs(var_5_2) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and not iter_5_1:isHasBuffByID(var_0_9) then
			table.insert(var_5_0, iter_5_1)
		end
	end

	if not var_0_4.timeSeed_ then
		var_0_4.timeSeed_ = 1
	end

	math.randomseed(tonumber(tostring(os.time() + var_0_4.timeSeed_):reverse():sub(1, 6)))

	local var_5_3 = math.random(tonumber(os.time()))

	var_0_4.timeSeed_ = var_5_3

	if next(var_5_0) == nil then
		local var_5_4 = {}

		for iter_5_2, iter_5_3 in pairs(var_5_2) do
			table.insert(var_5_4, iter_5_3)
		end

		var_5_0 = var_5_4
	end

	math.randomseed(var_5_3)

	return {
		var_5_0[math.random(#var_5_0)]
	}
end

function var_0_3.checkEnergySkill(arg_6_0)
	if arg_6_0.noEnergy_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_6_0)
end

function var_0_3.beginAttack(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if not arg_7_0:canAttack() then
		return
	end

	if arg_7_0:getLeftInterval() > 0 then
		return
	end

	var_0_3.super.beginAttack(arg_7_0)

	if arg_7_0:getFrontSkill() == arg_7_0:getEnergySkillID() then
		arg_7_0.noEnergy_ = true
	end
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	local var_8_0 = arg_8_1.target

	if var_8_0:isDeath() then
		return
	end

	if var_0_6:father(arg_8_1.skillID) ~= arg_8_0:getEnergySkillID() or var_8_0 == arg_8_0 then
		return
	end

	local var_8_1 = arg_8_0:getX()
	local var_8_2 = arg_8_0:getY()
	local var_8_3 = var_8_0:getX()
	local var_8_4 = var_8_0:getY()
	local var_8_5 = 0

	if var_8_3 - var_8_1 ~= 0 then
		var_8_5 = (var_8_3 - var_8_1) / math.abs(var_8_3 - var_8_1) * 120
	end

	local var_8_6 = var_0_1.ctx.battle.adjustX(var_8_3 + var_8_5, var_8_0)

	if var_8_0:avoidHeroMoveBehind() then
		var_8_6 = var_0_1.ctx.battle.adjustX(var_8_3 - var_8_5, var_8_0)
		var_8_5 = 0
	end

	arg_8_0:pos(var_8_6, var_8_4)
	arg_8_0:flipX(var_8_5 > 0)

	local var_8_7 = arg_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_8_0, iter_8_1 in ipairs(var_8_7) do
		if not iter_8_1:isDeath() then
			iter_8_1:removeBuffByID(var_0_9)
		end
	end

	arg_8_0:addExtraSkillBuff()
end

function var_0_3.calculateUnitData(arg_9_0, arg_9_1)
	local var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = var_0_3.super.calculateUnitData(arg_9_0, arg_9_1)

	if arg_9_0.noEnergy_ and arg_9_0:getEnergy() > 300 and arg_9_1.target ~= arg_9_0 and arg_9_0:getDmpRate() > 0 and var_0_6:father(arg_9_1.skillID) ~= arg_9_0:getEnergySkillID() then
		var_9_5 = var_9_5 - arg_9_0:getDmpRate() * arg_9_0:getEnergy()

		arg_9_0:updateEnergyTo(0)
	end

	return var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5
end

function var_0_3.getOrbOfFrontSkill(arg_10_0)
	local var_10_0 = arg_10_0:getFrontSkill()
	local var_10_1 = var_0_6:buffOrbSkill(var_10_0)

	if arg_10_0.noEnergy_ and var_10_1 > 0 and arg_10_0:getSkillLevelByID(var_10_1) > 0 then
		return var_10_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_10_0)
end

function var_0_3.checkKilling(arg_11_0, arg_11_1)
	var_0_3.super.checkKilling(arg_11_0, arg_11_1)

	local var_11_0 = arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_11_0 > 0 then
		local var_11_1 = var_0_1.ctx.battle.getRequire("Buff").new({
			tableID = var_0_11,
			start = var_0_1.ctx.battle.count,
			level = var_11_0,
			skillID = arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_11_0,
			target = arg_11_0
		})

		arg_11_0:addBuffs({
			var_11_1
		})
	end
end

function var_0_3.getDMP(arg_12_0)
	return var_0_2.PERCENT_BASE
end

function var_0_3.getDmpRate(arg_13_0)
	if arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) < 1 then
		return 0
	end

	local var_13_0 = arg_13_0:getBuffByID(var_0_10)

	if var_13_0 then
		return var_13_0:getDmpRate()
	else
		return 0
	end
end

return var_0_3
