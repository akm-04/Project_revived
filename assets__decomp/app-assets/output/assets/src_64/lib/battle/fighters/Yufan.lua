local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yufan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 3
local var_0_12 = 10001176
local var_0_13 = 10001172
local var_0_14 = 10001177
local var_0_15 = 10001173
local var_0_16 = 360
local var_0_17 = 40011292
local var_0_18 = 40011293
local var_0_19 = 1.185
local var_0_20 = 40012120
local var_0_21 = 80010198
local var_0_22 = 1.405
local var_0_23 = 180

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleHarmCount = 0
	arg_1_0.energyEffect_ = nil
	arg_1_0.energyTarget = nil
	arg_1_0.blueTarget = nil
	arg_1_0.isZuheji = false
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.isSkinSkillOn_ then
		arg_2_0.PugongID = 10001974
	else
		arg_2_0.PugongID = 10010198
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_3_0.isSkinSkillOn_ then
			if arg_3_0.purpleHarmCount < var_0_23 then
				arg_3_0.purpleHarmCount = arg_3_0.purpleHarmCount + 1
			end
		elseif arg_3_0.purpleHarmCount < var_0_16 then
			arg_3_0.purpleHarmCount = arg_3_0.purpleHarmCount + 1
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if var_4_2 > 0 and arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		var_4_2 = var_4_2 * math.pow(var_0_11, arg_4_1.target:getHp() / arg_4_1.target:getHpLimit())
	end

	if var_4_2 > 0 and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_4_0.isSkinSkillOn_ then
			var_4_2 = var_4_2 * math.pow(var_0_22, arg_4_0.purpleHarmCount / 30)
		else
			var_4_2 = var_4_2 * math.pow(var_0_19, arg_4_0.purpleHarmCount / 30)
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ ~= var_0_13 and arg_5_1.rootID_ ~= var_0_15 and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0
		}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end

	if arg_5_1.rootID_ == arg_5_0:getEnergySkillID() then
		arg_5_0:setImmuneControl(true)

		arg_5_0.isZuheji = true
	elseif arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_5_0:setImmuneControl(true)

		arg_5_0.isZuheji = true
	elseif arg_5_0.isSkinSkillOn_ and arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_1 = arg_5_0:createNewBuffs({
			var_0_20
		}, arg_5_0, var_0_21)

		arg_5_0:addBuffs(var_5_1)
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if (arg_6_1:getTableID() == var_0_17 or arg_6_1:getTableID() == var_0_18) and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_6_0 = arg_6_0:getBuffsByID(arg_6_1:getTableID())

		if next(var_6_0) ~= nil then
			for iter_6_0, iter_6_1 in ipairs(var_6_0) do
				iter_6_1.leftCount_ = iter_6_1:getTime()
			end
		end
	end
end

function var_0_3.checkEnergySkill(arg_7_0)
	if arg_7_0.isZuheji then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_7_0)
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	local var_8_0 = arg_8_1.skillID

	if var_8_0 == var_0_12 then
		arg_8_0:playEnergyEffect(arg_8_1.target)

		arg_8_0.energyTarget = arg_8_1.target
	elseif var_8_0 == var_0_13 then
		arg_8_0:setImmuneControl(false)

		arg_8_0.isZuheji = false
		arg_8_0.purpleHarmCount = 0
	elseif var_8_0 == var_0_14 then
		arg_8_0:playBlueEffect(arg_8_1.target)

		arg_8_0.blueTarget = arg_8_1.target
	elseif var_8_0 == var_0_15 then
		arg_8_0:setImmuneControl(false)

		arg_8_0.isZuheji = false
		arg_8_0.purpleHarmCount = 0
	elseif var_8_0 == arg_8_0.PugongID or var_8_0 == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_8_0.purpleHarmCount = 0
	end
end

function var_0_3.playEnergyEffect(arg_9_0, arg_9_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_9_0.energyEffect_ then
		arg_9_0.energyEffect_:removeSelf()

		arg_9_0.energyEffect_ = nil
	end

	local var_9_0 = var_0_1.ctx.battle.getSpine(var_0_13, "area", 0.5)

	var_9_0:addTo(var_0_1.ctx.battle.unitLayer)
	var_9_0:pos(arg_9_1:getX(), arg_9_1:getY())
	var_9_0:flipX(not arg_9_1:getFlipX())
	var_9_0:playOnce(function()
		arg_9_0.energyEffect_:hide()
	end)

	arg_9_0.energyEffect_ = var_9_0
end

function var_0_3.playBlueEffect(arg_11_0, arg_11_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_11_0.blueEffect_ then
		arg_11_0.blueEffect_:removeSelf()

		arg_11_0.blueEffect_ = nil
	end

	local var_11_0 = var_0_1.ctx.battle.getSpine(var_0_15, "area", 0.5)

	var_11_0:addTo(var_0_1.ctx.battle.unitLayer)
	var_11_0:pos(arg_11_1:getX(), arg_11_1:getY())
	var_11_0:flipX(not arg_11_1:getFlipX())
	var_11_0:playOnce(function()
		arg_11_0.blueEffect_:hide()
	end)

	arg_11_0.blueEffect_ = var_11_0
end

function var_0_3.selectTargetByTypeD1(arg_13_0)
	local function var_13_0(arg_14_0, arg_14_1)
		local var_14_0 = {}

		table.insert(var_14_0, arg_14_0)

		for iter_14_0, iter_14_1 in ipairs(arg_13_0.sideTeam_) do
			if not iter_14_1:isDeath() and not iter_14_1:isAffected() and iter_14_1 ~= arg_14_0 and arg_14_1 >= math.abs(iter_14_1:getX() - arg_14_0:getX()) then
				table.insert(var_14_0, iter_14_1)
			end
		end

		return var_14_0
	end

	local var_13_1
	local var_13_2 = 0
	local var_13_3 = var_0_8:scope(arg_13_0:getEnergySkillID()) * 0.5

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() then
			local var_13_4 = var_13_0(iter_13_1, var_13_3)

			if not var_13_1 or var_13_2 < #var_13_4 then
				var_13_1 = iter_13_1
				var_13_2 = #var_13_4
			end
		end
	end

	return {
		var_13_1
	}
end

function var_0_3.selectTargetByTypeD2(arg_15_0)
	local var_15_0 = {}

	if arg_15_0.energyTarget then
		for iter_15_0, iter_15_1 in ipairs(arg_15_0.sideTeam_) do
			if not iter_15_1:isDeath() and not iter_15_1:isAffected() and math.abs(iter_15_1:getX() - arg_15_0.energyTarget:getX()) <= var_0_8:scope(var_0_13) / 2 then
				table.insert(var_15_0, iter_15_1)
			end
		end
	end

	return var_15_0
end

return var_0_3
