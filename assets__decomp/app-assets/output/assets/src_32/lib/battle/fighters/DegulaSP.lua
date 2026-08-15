local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("DegulaSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 0.3
local var_0_9 = 40012445
local var_0_10 = 0.0025
local var_0_11 = 40012434
local var_0_12 = 1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyBuff_ = false
	arg_1_0.purpleEnergyChance = 1
	arg_1_0.purpleCureHp = 0

	arg_1_0:listenInfo("buff_harm")
end

function var_0_3.buffHarmFeedBack(arg_2_0, arg_2_1)
	arg_2_0.super.buffHarmFeedBack(arg_2_0, arg_2_1)

	arg_2_0.purpleCureHp = arg_2_0.purpleCureHp + arg_2_1
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = arg_3_0:getFrontSkill()
	local var_3_1 = var_0_7:buffOrb(var_3_0)

	if var_3_1 > 0 and arg_3_0:getSkillLevelByID(var_3_0) > 0 and arg_3_0.isEnergyBuff_ then
		return var_3_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_3_0)
end

function var_0_3.toDoPerFrames(arg_4_0)
	var_0_3.super.toDoPerFrames(arg_4_0)

	if arg_4_0.purpleEnergyChance > 0 and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0:getHp() / arg_4_0:getHpLimit() < var_0_8 then
		local var_4_0 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)

		arg_4_0:createSkillByID(var_4_0, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), var_0_7:attackIndex(var_4_0))

		local var_4_1 = arg_4_0:createNewBuffs({
			PurpleAddBuffID
		}, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_4_0:addBuffs(var_4_1)

		arg_4_0.purpleEnergyChance = 0
	end

	for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_harm")) do
		local var_4_2 = iter_4_1.buff
		local var_4_3 = var_4_2.target
		local var_4_4 = var_4_2.fighter
		local var_4_5 = iter_4_1.harm

		if var_4_4 == arg_4_0 and var_4_5 > 0 and var_4_2:getTableID() == var_0_11 and var_4_2:getType() == var_0_2.BuffType.CONTINUE_HARM then
			local var_4_6 = var_4_5 * var_0_12
			local var_4_7 = math.min(arg_4_0:getHpLimit(), arg_4_0:getHp() + var_4_6)

			arg_4_0:updateHp(var_4_7)

			local var_4_8 = var_4_6 / arg_4_0:getHpLimit() * var_0_2.ENERGY_DECIMAL_BASE * var_0_10

			arg_4_0:updateEnergyBy(math.ceil(var_4_8 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)))
		elseif var_4_3 == arg_4_0 and var_4_5 > 0 and var_4_2:getType() == var_0_2.BuffType.REVIVIE then
			local var_4_9 = var_4_5 / arg_4_0:getHpLimit() * var_0_2.ENERGY_DECIMAL_BASE * var_0_10

			arg_4_0:updateEnergyBy(math.ceil(var_4_9 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)))
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		arg_5_0.isEnergyBuff_ = true
	end
end

function var_0_3.getDMP(arg_6_0)
	return arg_6_0:getEnergy() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE
end

function var_0_3.updateBaseInfo(arg_7_0)
	var_0_3.super.updateBaseInfo(arg_7_0)

	if arg_7_0.isEnergyBuff_ and var_0_1.ctx.battle.count % 30 < 1 and arg_7_0:getNearestTarget() and not arg_7_0:isHasBuffByID(var_0_9) then
		arg_7_0:updateEnergyTo(arg_7_0:getEnergy() - 100)

		if arg_7_0:getEnergy() < 1 then
			arg_7_0.isEnergyBuff_ = false

			local var_7_0 = var_0_7:buffs(arg_7_0:getEnergySkillID())

			for iter_7_0, iter_7_1 in ipairs(var_7_0) do
				arg_7_0:removeBuffByID(iter_7_1)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.targetTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() then
			table.insert(var_8_0, iter_8_1)
		end
	end

	local var_8_2 = 1

	if arg_8_0.isEnergyBuff_ then
		var_8_2 = 2
	end

	local var_8_3 = math.random(tonumber(os.time()))

	math.randomseed(var_8_3)

	while var_8_2 > #var_8_1 and #var_8_0 > 0 do
		local var_8_4 = math.random(#var_8_0)
		local var_8_5 = var_8_0[var_8_4]

		table.insert(var_8_1, var_8_5)
		table.remove(var_8_0, var_8_4)
	end

	return var_8_1
end

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}
	local var_9_1 = arg_9_0
	local var_9_2, var_9_3 = var_9_1:getPos()
	local var_9_4 = var_0_7:scope(arg_9_1)
	local var_9_5 = unpack(var_0_6.B1(var_9_1, arg_9_1))
	local var_9_6 = var_0_7:distance(arg_9_1)
	local var_9_7 = var_9_1:getFighterModel():getFlipX()
	local var_9_8, var_9_9 = var_0_6.getTeam(var_9_1)

	if not var_9_5 then
		return {}
	elseif not arg_9_0.isEnergyBuff_ then
		return {
			var_9_5
		}
	end

	table.insert(var_9_0, var_9_5)

	local var_9_10

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.targetTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1 ~= var_9_5 then
			if not var_9_10 then
				var_9_10 = iter_9_1
			elseif math.abs(iter_9_1:getX() - var_9_1:getX()) < math.abs(var_9_10:getX() - var_9_1:getX()) then
				var_9_10 = iter_9_1
			end
		end
	end

	if not var_9_10 then
		return var_9_0
	else
		table.insert(var_9_0, var_9_10)
	end

	return var_9_0
end

return var_0_3
