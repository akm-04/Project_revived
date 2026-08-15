local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huodeer", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = 3
local var_0_10 = 0.5
local var_0_11 = 60
local var_0_12 = 1
local var_0_13 = 1.5
local var_0_14 = 40011667
local var_0_15 = 150
local var_0_16 = 40011665
local var_0_17 = {
	10002096,
	10002097,
	10002098
}
local var_0_18 = 810001
local var_0_19 = 10002096
local var_0_20 = 0.15
local var_0_21 = var_0_2.tables.elementEquip
local var_0_22 = 20001444

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueEffectCount = 0
	arg_1_0.purpleEffectCount = 0
	arg_1_0.purpleEffectX = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.GreenSkillID = 10002107
		arg_2_0.BlueSkillID = 10002108
		arg_2_0.PurpleSkillID = 10002109
		arg_2_0.EnergySkillID = 10002110
	else
		arg_2_0.GreenSkillID = 210001
		arg_2_0.BlueSkillID = 310001
		arg_2_0.PurpleSkillID = 410001
		arg_2_0.EnergySkillID = 510001
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0.GreenSkillID then
		local var_3_0 = arg_3_0:selectTargetByTypeD2(arg_3_0.GreenSkillID)

		if next(var_3_0) then
			local var_3_1 = 0
			local var_3_2 = 0

			for iter_3_0, iter_3_1 in ipairs(var_3_0) do
				var_3_1 = var_3_1 + iter_3_1:getX()
				var_3_2 = var_3_2 + iter_3_1:getY()
			end

			local var_3_3 = var_3_1 / #var_3_0
			local var_3_4 = var_3_2 / #var_3_0

			arg_3_0.greenEffect = var_0_1.ctx.battle.getSpine(arg_3_0.GreenSkillID, "area", 1)

			arg_3_0.greenEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_3_0.greenEffect:pos(var_3_3, var_3_4)
			arg_3_0.greenEffect:setScale(0.5)
			arg_3_0.greenEffect:playOnce()
		end
	end

	if arg_3_1.rootID_ == arg_3_0.BlueSkillID then
		local var_3_5 = var_0_6.B30(arg_3_0, arg_3_0.BlueSkillID)

		if next(var_3_5) then
			local var_3_6 = 0
			local var_3_7 = 0

			for iter_3_2, iter_3_3 in ipairs(var_3_5) do
				var_3_6 = var_3_6 + iter_3_3:getX()
				var_3_7 = var_3_7 + iter_3_3:getY()
			end

			local var_3_8 = var_3_6 / #var_3_5
			local var_3_9 = var_3_7 / #var_3_5

			arg_3_0.blueEffect = var_0_1.ctx.battle.getSpine(arg_3_0.BlueSkillID, "area", 1)

			arg_3_0.blueEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_3_0.blueEffect:pos(var_3_8, var_3_9)
			arg_3_0.blueEffect:setScale(0.5)
			arg_3_0.blueEffect:playRepeat()

			arg_3_0.blueEffectCount = var_0_15
		end
	end

	if arg_3_1.rootID_ == arg_3_0.PurpleSkillID then
		local var_3_10 = var_0_6.B30(arg_3_0, arg_3_0.PurpleSkillID)

		if next(var_3_10) then
			local var_3_11 = 0
			local var_3_12 = 0

			for iter_3_4, iter_3_5 in ipairs(var_3_10) do
				var_3_11 = var_3_11 + iter_3_5:getX()
				var_3_12 = var_3_12 + iter_3_5:getY()
			end

			local var_3_13 = var_3_11 / #var_3_10
			local var_3_14 = var_3_12 / #var_3_10

			arg_3_0.purpleEffect = var_0_1.ctx.battle.getSpine(arg_3_0.PurpleSkillID, "area", 1)

			arg_3_0.purpleEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_3_0.purpleEffect:pos(var_3_13, var_3_14)
			arg_3_0.purpleEffect:setScale(0.5)
			arg_3_0.purpleEffect:playRepeat()

			arg_3_0.purpleEffectCount = var_0_11
			arg_3_0.purpleEffectX = var_3_13
		end
	end

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_18 and (arg_3_1.rootID_ == arg_3_0.GreenSkillID or arg_3_1.rootID_ == arg_3_0.BlueSkillID or arg_3_1.rootID_ == arg_3_0.PurpleSkillID or arg_3_1.rootID_ == arg_3_0.EnergySkillID) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_15 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_0_17[math.random(1, #var_0_17)])

		for iter_3_6, iter_3_7 in ipairs(var_3_15) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
			table.insert(arg_3_0.records_.special_units, iter_3_7)
		end
	end
end

function var_0_3.selectTargetByTypeD2(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = var_0_7:scope(arg_4_1) / 2
	local var_4_1 = 0

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			local var_4_2 = var_0_8:distanceType(iter_4_1.hero_:getTableID())

			if var_4_1 < var_4_2 then
				var_4_1 = var_4_2

				if var_4_1 == var_0_2.DistanceType.HOUPAI then
					break
				end
			end
		end
	end

	local var_4_3 = {}

	for iter_4_2, iter_4_3 in ipairs(arg_4_0.targetTeam_) do
		if not iter_4_3:isDeath() and not iter_4_3:isAffected() and var_4_1 == var_0_8:distanceType(iter_4_3.hero_:getTableID()) then
			table.insert(var_4_3, iter_4_3)
		end
	end

	local function var_4_4(arg_5_0, arg_5_1)
		local var_5_0 = {}

		table.insert(var_5_0, arg_5_0)

		for iter_5_0, iter_5_1 in ipairs(var_4_3) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1 ~= arg_5_0 and arg_5_1 >= math.abs(iter_5_1:getX() - arg_5_0:getX()) then
				table.insert(var_5_0, iter_5_1)
			end
		end

		return var_5_0
	end

	local var_4_5 = 0
	local var_4_6

	for iter_4_4, iter_4_5 in ipairs(var_4_3) do
		if not iter_4_5:isDeath() and not iter_4_5:isAffected() then
			local var_4_7 = var_4_4(iter_4_5, var_4_0)

			if var_4_5 < #var_4_7 then
				var_4_6 = iter_4_5
				var_4_3 = var_4_7
				var_4_5 = #var_4_7
			end
		end
	end

	local var_4_8 = {}

	if var_4_6 then
		for iter_4_6, iter_4_7 in ipairs(arg_4_0.targetTeam_) do
			if not iter_4_7:isDeath() and not iter_4_7:isAffected() and var_4_0 > math.abs(var_4_6:getX() - iter_4_7:getX()) then
				table.insert(var_4_8, iter_4_7)
			end
		end
	end

	return var_4_8
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0.purpleEffectCount > 0 then
		arg_6_0.purpleEffectCount = arg_6_0.purpleEffectCount - 1

		local var_6_0 = var_0_7:scope(arg_6_0.PurpleSkillID)

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_0 > math.abs(arg_6_0.purpleEffectX - iter_6_1:getX()) then
				local var_6_1 = var_0_9

				if iter_6_1:getX() < arg_6_0.purpleEffectX then
					iter_6_1:moveByX(var_6_1)
				else
					iter_6_1:moveByX(-var_6_1)
				end
			end
		end
	elseif arg_6_0.purpleEffect then
		arg_6_0.purpleEffect:stop()

		arg_6_0.purpleEffect = nil
	end

	if arg_6_0.blueEffectCount > 0 then
		arg_6_0.blueEffectCount = arg_6_0.blueEffectCount - 1
	elseif arg_6_0.blueEffect then
		arg_6_0.blueEffect:stop()

		arg_6_0.blueEffect = nil
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0.EnergySkillID then
		for iter_7_0, iter_7_1 in ipairs(arg_7_1.target:getBuffs()) do
			if iter_7_1.fighter:getTeamType() == arg_7_0:getTeamType() and iter_7_1:Ychange() > 0 then
				if iter_7_1:getTableID() == var_0_14 then
					local var_7_0 = var_0_5.new({
						tableID = var_0_16,
						start = var_0_1.ctx.battle.count,
						level = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
						skillID = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
						fighter = arg_7_0,
						target = arg_7_1.target
					})

					arg_7_1.target:addBuffs({
						var_7_0
					})
				end

				break
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if arg_8_1.skillID == arg_8_0.EnergySkillID then
		for iter_8_0, iter_8_1 in ipairs(arg_8_1.target:getBuffs()) do
			if iter_8_1.fighter:getTeamType() == arg_8_0:getTeamType() and iter_8_1:Ychange() > 0 then
				if iter_8_1:getTableID() == var_0_14 then
					arg_8_4 = arg_8_4 + arg_8_4 * var_0_13

					break
				end

				arg_8_4 = arg_8_4 + arg_8_4 * var_0_12

				break
			end
		end
	end

	if arg_8_1.skillID == var_0_19 then
		arg_8_5 = arg_8_0:getHpLimit() * var_0_20
	end

	return var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
end

function var_0_3.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	local var_9_0 = var_0_7:scope(arg_9_0.PurpleSkillID)

	if arg_9_0.purpleEffectCount > 0 and arg_9_1.target:getTeamType() ~= arg_9_0:getTeamType() and var_9_0 > math.abs(arg_9_0.purpleEffectX - arg_9_1.target:getX()) then
		arg_9_4 = arg_9_4 + arg_9_4 * 0.5
	end

	return var_0_3.super.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

function var_0_3.distributeBuff(arg_10_0, arg_10_1)
	if arg_10_0:hasElementEquipByID(var_0_22) and arg_10_1:getType() == var_0_2.BuffType.MOVE_SKILL_LIMIT then
		local var_10_0 = var_0_22
		local var_10_1 = var_0_21:battleAttr(var_10_0, arg_10_0:getElementEquipLevelByID(var_10_0))
		local var_10_2 = arg_10_0.hero_:getElementEquipActiveRate(var_10_0)

		arg_10_1.leftCount_ = math.max(math.floor(arg_10_1.leftCount_ * (1 - var_10_1 * var_10_2)), 1)
	end

	var_0_3.super.distributeBuff(arg_10_0, arg_10_1)
end

return var_0_3
