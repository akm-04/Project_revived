local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Suoer", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = 40012229
local var_0_7 = 300
local var_0_8 = 400
local var_0_9 = 10002072
local var_0_10 = 75
local var_0_11 = 0.2
local var_0_12 = 2
local var_0_13 = 0.4
local var_0_14 = 4
local var_0_15 = 0.002
local var_0_16 = 0.5
local var_0_17 = 450

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueEffect = nil
	arg_1_0.bluePosX = 0
	arg_1_0.blueCount = 0
	arg_1_0.blueAtkCount = 0
	arg_1_0.fadingBlueEffect = false
end

function var_0_3.updateUnitBaseByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	local var_2_0 = arg_2_2 * arg_2_0:getAD() / var_0_2.DECIMAL_BASE + arg_2_3 * arg_2_0:getAP() / var_0_2.DECIMAL_BASE + arg_2_0:elementADExtraHarm(arg_2_1)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() then
		return var_2_0 + #arg_2_1.target:getBuffsByID(var_0_6) * (var_0_13 * arg_2_0:getAP() + var_0_14 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
	elseif arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		return var_2_0 + #arg_2_1.target:getBuffsByID(var_0_6) * (var_0_11 * arg_2_0:getAP() + var_0_12 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	elseif arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_2_1.skillID == arg_2_0:getPugongID() then
		local var_2_1 = #arg_2_1.target:getBuffsByID(var_0_6)
		local var_2_2 = math.min(var_0_15 * var_2_1 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple), 1)

		return arg_2_2 * (1 - var_2_2) * arg_2_0:getAD() / var_0_2.DECIMAL_BASE + (arg_2_3 + arg_2_2 * var_2_2) * arg_2_0:getAP() / var_0_2.DECIMAL_BASE + arg_2_0:elementADExtraHarm(arg_2_1)
	else
		return var_2_0
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_3_1.target:isHasBuffByID(var_0_6) then
			arg_3_1:addCollisionNum()
		else
			for iter_3_0 = 1, #arg_3_0.moveAttackUnits_ do
				if arg_3_0.moveAttackUnits_[iter_3_0] == arg_3_1 then
					table.remove(arg_3_0.moveAttackUnits_, iter_3_0)
				end
			end

			arg_3_1:clearCollisionNum()
		end
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if arg_3_0.blueEffect then
			arg_3_0.blueEffect:stop()

			arg_3_0.blueEffect = nil
		end

		arg_3_0.bluePosX = arg_3_1.target:getX()
		arg_3_0.blueCount = var_0_7

		if not arg_3_0.blueEffect then
			local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
			local var_3_1, var_3_2 = var_0_4:areaResource(var_3_0)

			if var_3_1 and var_3_1 ~= "" and var_3_2 and var_3_2 ~= "" then
				arg_3_0.blueEffect = var_0_1.ctx.battle.getSpine(var_3_0, "area", arg_3_0:getScale())

				arg_3_0.blueEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			end
		end

		if arg_3_0.blueEffect then
			arg_3_0.blueEffect:pos(arg_3_0.bluePosX, arg_3_1.target:getY())
			arg_3_0.blueEffect:playRepeat()
		end
	end
end

function var_0_3.finishBlueEffect(arg_4_0)
	arg_4_0.fadingBlueEffect = true

	if arg_4_0.blueEffect and var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_4_0.blueEffect:runActionOnce(cc.FadeOut:create(0.4 / (arg_4_0.timeScale_ or 1)), false, function()
			arg_4_0.blueEffect:stop()
			arg_4_0.blueEffect:setVisible(false)
			arg_4_0.blueEffect:setOpacity(255)

			arg_4_0.blueEffect = nil
			arg_4_0.fadingBlueEffect = false
		end, 1)
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.blueCount > 0 then
		arg_6_0.blueCount = arg_6_0.blueCount - 1
		arg_6_0.blueAtkCount = arg_6_0.blueAtkCount - 1 * arg_6_0:getCurrentAckSpeed()

		if arg_6_0.blueCount == 0 and not arg_6_0.fadingBlueEffect then
			arg_6_0:finishBlueEffect()
		elseif arg_6_0.blueAtkCount <= 0 then
			arg_6_0:blueAtkSkill()
		end
	end
end

function var_0_3.blueAtkSkill(arg_7_0)
	arg_7_0.blueAtkCount = var_0_10

	local var_7_0 = {}

	for iter_7_0, iter_7_1 in pairs(arg_7_0.sideTeam_) do
		if arg_7_0:checkIsInBlueEffect(iter_7_1) then
			table.insert(var_7_0, iter_7_1)
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_1 = arg_7_0:createAttackUnits(var_7_0, var_0_9)

		for iter_7_2, iter_7_3 in ipairs(var_7_1) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
			table.insert(arg_7_0.records_.special_units, iter_7_3)
		end
	end
end

function var_0_3.checkIsInBlueEffect(arg_8_0, arg_8_1)
	if arg_8_0.blueEffect and arg_8_0.bluePosX ~= 0 and not arg_8_1:isDeath() and not arg_8_1:isAffected() then
		if math.abs(arg_8_1:getX() - arg_8_0.bluePosX) < var_0_8 / 2 then
			return true
		else
			return false
		end
	end

	return false
end

function var_0_3.die(arg_9_0)
	var_0_3.super.die(arg_9_0)
	arg_9_0:finishBlueEffect()
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1, arg_10_2)
	local function var_10_0(arg_11_0, arg_11_1)
		local var_11_0, var_11_1 = var_0_5.getTeam(arg_11_0)
		local var_11_2 = {}

		table.insert(var_11_2, arg_11_0)

		for iter_11_0, iter_11_1 in ipairs(var_11_0) do
			if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1 ~= arg_11_0 and arg_11_1 >= math.abs(iter_11_1:getX() - arg_11_0:getX()) then
				table.insert(var_11_2, iter_11_1)
			end
		end

		return var_11_2
	end

	local var_10_1
	local var_10_2 = 0
	local var_10_3 = var_0_4:scope(arg_10_1) * 0.5
	local var_10_4, var_10_5 = var_0_5.getTeam(arg_10_0)

	for iter_10_0, iter_10_1 in ipairs(var_10_5) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
			local var_10_6 = var_10_0(iter_10_1, var_10_3)

			if var_10_2 < #var_10_6 then
				var_10_1 = iter_10_1
				var_10_2 = #var_10_6
			end
		end
	end

	return {
		var_10_1
	}
end

function var_0_3.getHuJia(arg_12_0)
	local var_12_0 = math.floor(var_0_1.ctx.battle.count / var_0_17)
	local var_12_1 = 1

	if var_12_0 > 0 then
		for iter_12_0 = 1, var_12_0 do
			var_12_1 = var_12_1 * 0.7
		end
	end

	return arg_12_0:getAttrByType(var_0_2.AttributeType.HUJIA) * var_12_1
end

function var_0_3.getMoKang(arg_13_0)
	local var_13_0 = math.floor(var_0_1.ctx.battle.count / var_0_17)
	local var_13_1 = 1

	if var_13_0 > 0 then
		for iter_13_0 = 1, var_13_0 do
			var_13_1 = var_13_1 * 0.7
		end
	end

	return arg_13_0:getAttrByType(var_0_2.AttributeType.MOKANG) * var_13_1
end

function var_0_3.updateUnitDataByTarget(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7 = var_0_3.super.updateUnitDataByTarget(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)

	if not arg_14_3 and arg_14_4 > 0 then
		arg_14_4 = arg_14_4 * (1 - var_0_16)
	end

	return arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7
end

return var_0_3
