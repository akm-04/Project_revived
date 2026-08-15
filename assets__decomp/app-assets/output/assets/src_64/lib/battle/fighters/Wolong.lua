local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wolong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = var_0_2.tables.dbuff
local var_0_9 = var_0_2.tables.skill
local var_0_10 = var_0_2.tables.hero
local var_0_11 = 0.4
local var_0_12 = 50000
local var_0_13 = 0.8
local var_0_14 = 12
local var_0_15 = 10001807
local var_0_16 = 210
local var_0_17 = 10001808
local var_0_18 = 10001809
local var_0_19 = 10001810
local var_0_20 = 10001811
local var_0_21 = 40011959
local var_0_22 = 50
local var_0_23 = 200
local var_0_24 = 400
local var_0_25 = 0.5
local var_0_26 = 40011960
local var_0_27 = 20090004
local var_0_28 = 20090005
local var_0_29 = 20090006
local var_0_30 = 0.05
local var_0_31 = 15
local var_0_32 = 30

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel1 = 0
	arg_1_0.extraSkillLevel2 = 0
	arg_1_0.extraSkillLevel3 = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % var_0_16 == 0 and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:createAttackUnits(arg_2_0:getTargets(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)), arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true

		local var_2_1 = arg_2_0.hero_:skillBook()

		arg_2_0.extraSkillLevel1 = var_2_1[tostring(var_0_27)] or 0
		arg_2_0.extraSkillLevel2 = var_2_1[tostring(var_0_28)] or 0
		arg_2_0.extraSkillLevel3 = var_2_1[tostring(var_0_29)] or 0

		if arg_2_0.extraSkillLevel2 > 0 then
			var_0_16 = var_0_16 - var_0_31 * arg_2_0.extraSkillLevel2
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_3_0, iter_3_1 in pairs(arg_3_1.target:getBuffs()) do
			if iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and iter_3_1:canRemove() then
				arg_3_1.target:removeBuffs(iter_3_1)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_3_0 = arg_3_0:createAttackUnits({
						arg_3_0
					}, var_0_15)

					for iter_3_2, iter_3_3 in ipairs(var_3_0) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
						table.insert(arg_3_0.records_.special_units, iter_3_3)
					end
				end
			end
		end
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_3_1.target.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI then
			local var_3_1 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_17)

			for iter_3_4, iter_3_5 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
				table.insert(arg_3_0.records_.special_units, iter_3_5)
			end
		elseif arg_3_1.target.hero_:getDistanceType() == var_0_2.DistanceType.ZHONGPAI then
			local var_3_2 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_18)

			for iter_3_6, iter_3_7 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
				table.insert(arg_3_0.records_.special_units, iter_3_7)
			end
		elseif arg_3_1.target.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI then
			local var_3_3 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_19)

			for iter_3_8, iter_3_9 in ipairs(var_3_3) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_9)
				table.insert(arg_3_0.records_.special_units, iter_3_9)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	arg_4_1.resetXchange_ = var_0_8:x(arg_4_1:getTableID())
	arg_4_1.resetYchange_ = var_0_8:y(arg_4_1:getTableID())

	if arg_4_1:getTableID() == var_0_21 then
		local var_4_0 = arg_4_1.target:getX() - arg_4_0:getX()

		if var_4_0 > var_0_24 then
			var_4_0 = var_0_24
		end

		if arg_4_1.target:getTeamType() == arg_4_0:getTeamType() then
			if var_4_0 < var_0_23 then
				var_4_0 = var_0_23
			end
		elseif var_4_0 < var_0_23 then
			var_4_0 = var_0_22
		end

		arg_4_1.resetXchange_ = var_0_22 + var_0_25 * (var_0_24 - var_4_0)
	elseif arg_4_0.extraSkillLevel3 > 0 and arg_4_1:getTableID() == var_0_26 then
		arg_4_1:setExtraTime(var_0_32 * arg_4_0.extraSkillLevel3)
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_4 > 0 and arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_0 = math.abs(arg_5_1.target:getHpLimit() - arg_5_0:getHpLimit())

		if var_5_0 < var_0_12 then
			arg_5_4 = var_0_11 * var_5_0 + var_0_13 * arg_5_0:getAP() + var_0_14 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)
			arg_5_4 = arg_5_4 * arg_5_4 / (arg_5_4 + 12 * math.max(arg_5_1.target:getMoKang() - arg_5_0:getDMoKang(), 0))
		else
			arg_5_4 = var_0_11 * var_0_12 + var_0_13 * arg_5_0:getAP() + var_0_14 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)
		end

		if arg_5_0.extraSkillLevel1 > 0 then
			arg_5_4 = arg_5_4 * (1 + var_0_30 * arg_5_0.extraSkillLevel1)
		end
	elseif arg_5_4 > 0 and arg_5_1.skillID == var_0_20 and arg_5_1.target:getTeamType() == arg_5_0:getTeamType() then
		arg_5_4 = 0
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}
	local var_6_1
	local var_6_2
	local var_6_3 = arg_6_0:getX()

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			local var_6_4 = math.abs(iter_6_1:getX() - var_6_3)

			if not var_6_1 or var_6_4 > math.abs(var_6_1:getX() - var_6_3) then
				var_6_1 = iter_6_1
			end
		end
	end

	if var_6_1 then
		table.insert(var_6_0, var_6_1)

		for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_3:isDeath() and not iter_6_3:isAffected() and iter_6_3 ~= var_6_1 then
				local var_6_5 = math.abs(iter_6_3:getX() - var_6_3)

				if not var_6_2 or var_6_5 > math.abs(var_6_2:getX() - var_6_3) then
					var_6_2 = iter_6_3
				end
			end
		end

		if var_6_2 then
			table.insert(var_6_0, var_6_2)
		end
	end

	return var_6_0
end

function var_0_3.getTargets(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}
	local var_7_1 = var_0_9:selectType(arg_7_1)

	if arg_7_0:getForceTarget() and not arg_7_0:getForceTarget():isDeath() then
		if var_7_1 == "C11" then
			local var_7_2 = arg_7_0:getForceTarget()

			if (arg_7_2.iniX_ < var_7_2:getX() and var_7_2:getX() <= arg_7_2:getX() or arg_7_2.iniX_ > var_7_2:getX() and var_7_2:getX() >= arg_7_2:getX()) and not arg_7_2.targets[var_7_2.fighterIndex] then
				arg_7_2.targets[var_7_2.fighterIndex] = var_7_2

				return {
					var_7_2
				}
			end

			return {}
		end

		return {
			arg_7_0:getForceTarget()
		}
	end

	if arg_7_0:isChaos() then
		arg_7_0:changeTeamCache()
	end

	if arg_7_0["selectTargetByType" .. var_7_1] then
		if var_7_1 == "C11" then
			var_7_0 = arg_7_0:selectTargetByTypeC11(arg_7_0, arg_7_1, arg_7_2)
		else
			var_7_0 = arg_7_0["selectTargetByType" .. var_7_1](arg_7_0, arg_7_1, arg_7_2)
		end
	else
		if not var_7_1 then
			print("invallid select type skillID = " .. arg_7_1)
		end

		var_7_0 = var_0_6[var_7_1](arg_7_0, arg_7_1, arg_7_2)
	end

	return var_7_0
end

function var_0_3.selectTargetByTypeC11(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if not arg_8_3 then
		return {}
	end

	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if (arg_8_3.iniX_ < iter_8_1:getX() and iter_8_1:getX() <= arg_8_3:getX() or arg_8_3.iniX_ > iter_8_1:getX() and iter_8_1:getX() >= arg_8_3:getX()) and not arg_8_3.targets[iter_8_1.fighterIndex] then
			arg_8_3.targets[iter_8_1.fighterIndex] = iter_8_1

			table.insert(var_8_0, iter_8_1)
		end
	end

	for iter_8_2, iter_8_3 in ipairs(arg_8_0.selfTeam_) do
		if (arg_8_3.iniX_ < iter_8_3:getX() and iter_8_3:getX() <= arg_8_3:getX() or arg_8_3.iniX_ > iter_8_3:getX() and iter_8_3:getX() >= arg_8_3:getX()) and not arg_8_3.targets[iter_8_3.fighterIndex] then
			arg_8_3.targets[iter_8_3.fighterIndex] = iter_8_3

			table.insert(var_8_0, iter_8_3)
		end
	end

	return var_8_0
end

return var_0_3
