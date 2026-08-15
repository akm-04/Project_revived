local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fansaiti", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 40012324
local var_0_12 = 10002176
local var_0_13 = 10002177
local var_0_14 = 10002178
local var_0_15 = 0.15
local var_0_16 = 0.1
local var_0_17 = 40012330
local var_0_18 = 10002181
local var_0_19 = 10
local var_0_20 = 810012
local var_0_21 = 0.3

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.GreenSkill = 10002422
	else
		arg_2_0.GreenSkill = 210012
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.firstTarget = nil
	arg_3_0.secondTarget = nil
	arg_3_0.controlTimes = 0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.skillID
	local var_4_1 = arg_4_1.target

	if arg_4_0:getSkillLevelByID(arg_4_0.GreenSkill) > 0 and var_4_0 == arg_4_0.GreenSkill and arg_4_0:getAP() > var_4_1:getAP() then
		local var_4_2 = arg_4_0:newBuff({
			var_0_11
		}, var_4_1, var_4_0)

		var_4_1:addBuffs(var_4_2)
	elseif arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) > 0 and arg_4_0.firstTarget and arg_4_0.secondTarget and (var_4_0 == var_0_12 or var_4_0 == var_0_13) then
		local var_4_3, var_4_4 = arg_4_0.firstTarget:getPos()
		local var_4_5, var_4_6 = arg_4_0.secondTarget:getPos()

		arg_4_0.firstTarget:pos(var_4_5, var_4_6)
		arg_4_0.secondTarget:pos(var_4_3, var_4_4)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_7 = arg_4_0:createAttackUnits({
				arg_4_0.firstTarget,
				arg_4_0.secondTarget
			}, var_0_14)

			for iter_4_0, iter_4_1 in ipairs(var_4_7) do
				local var_4_8 = var_0_9(var_4_3 - var_4_5) * var_0_15 * arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				iter_4_1:setExtraHarm(var_4_8)
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end

		arg_4_0.firstTarget = nil
		arg_4_0.secondTarget = nil
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
		if iter_5_1 and iter_5_1.fighter == arg_5_0 and iter_5_1.target:getTeamType() ~= arg_5_0:getTeamType() and iter_5_1:getType() == var_0_2.BuffType.MOVE_SKILL_LIMIT then
			local var_5_0 = var_0_16 + 0.001 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			local var_5_1 = var_0_6:time(iter_5_1:getTableID()) + iter_5_1.level_ * iter_5_1:getTimeStep()

			iter_5_1:setExtraTime(arg_5_0.controlTimes * var_5_0 * var_5_1)

			arg_5_0.controlTimes = arg_5_0.controlTimes + 1
			arg_5_0.controlTimes = math.min(var_0_19, arg_5_0.controlTimes)

			if arg_5_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_2 = arg_5_0:createAttackUnits({
					arg_5_0
				}, var_0_20)

				for iter_5_2, iter_5_3 in ipairs(var_5_2) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
					table.insert(arg_5_0.records_.special_units, iter_5_3)
				end
			end
		end
	end

	if var_0_1.ctx.battle.count % 30 == 0 and arg_5_0:isHasBuffByID(var_0_17) then
		local var_5_3 = {}

		for iter_5_4, iter_5_5 in ipairs(arg_5_0.targetTeam_) do
			if not iter_5_5:isDeath() and not iter_5_5:isAffected() then
				table.insert(var_5_3, iter_5_5)
			end
		end

		if #var_5_3 > 0 then
			local var_5_4 = var_5_3[math.random(1, #var_5_3)]

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_5 = arg_5_0:createAttackUnits({
					var_5_4
				}, var_0_18)

				for iter_5_6, iter_5_7 in ipairs(var_5_5) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_7)
					table.insert(arg_5_0.records_.special_units, iter_5_7)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0.skinSkillIndex_ == 1 and arg_6_0:isYunXuan(arg_6_1.target) and arg_6_4 > 0 then
		arg_6_4 = arg_6_4 + arg_6_4 * var_0_21
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.isYunXuan(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1:getBuffs()

	for iter_7_0, iter_7_1 in ipairs(var_7_0) do
		if iter_7_1:dBuffType() == var_0_2.DBuffType.XUAN_YUN then
			return true
		end
	end

	return false
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

function var_0_3.unitAfterCreate(arg_9_0, arg_9_1, arg_9_2)
	for iter_9_0, iter_9_1 in ipairs(arg_9_2) do
		if iter_9_1.skillID == var_0_12 and not arg_9_0.firstTarget then
			arg_9_0.firstTarget = iter_9_1.target
		end

		if iter_9_1.skillID == var_0_13 and not arg_9_0.secondTarget then
			arg_9_0.secondTarget = iter_9_1.target
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.targetTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and (not var_10_0 or iter_10_1:getAP() > var_10_0:getAP()) then
			var_10_0 = iter_10_1
		end
	end

	if var_10_0 then
		return {
			var_10_0
		}
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.targetTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and (not var_11_0 or iter_11_1:getAP() > var_11_0:getAP()) then
			var_11_0 = iter_11_1
		end
	end

	local var_11_1

	if var_11_0 then
		for iter_11_2, iter_11_3 in ipairs(arg_11_0.targetTeam_) do
			if not iter_11_3:isDeath() and not iter_11_3:isAffected() and iter_11_3 ~= var_11_0 and (not var_11_1 or iter_11_3:getAP() < var_11_1:getAP()) then
				var_11_1 = iter_11_3
			end
		end

		if var_11_1 then
			return {
				var_11_1
			}
		else
			return {}
		end
	else
		return {}
	end
end

return var_0_3
