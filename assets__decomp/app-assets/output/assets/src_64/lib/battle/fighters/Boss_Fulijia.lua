local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fulijia", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40012109
local var_0_6 = 40012110
local var_0_7 = 8
local var_0_8 = 40012106
local var_0_9 = 40012107
local var_0_10 = 0.003
local var_0_11 = 10002434
local var_0_12 = 10
local var_0_13 = 450
local var_0_14 = 10002448

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				local var_2_0 = arg_2_0:createNewBuffs({
					var_0_5
				}, iter_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				iter_2_1:addBuffs(var_2_0)
			end
		end
	end

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		local var_2_1 = arg_2_0:getTargets(var_0_11)
		local var_2_2 = arg_2_0:createAttackUnits(var_2_1, var_0_11)

		for iter_2_2, iter_2_3 in ipairs(var_2_2) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
			table.insert(arg_2_0.records_.special_units, iter_2_3)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == var_0_11 then
		local var_3_6 = arg_3_1.target:getEnergy()

		arg_3_1.target:updateEnergyTo(0)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_7 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_14)

			for iter_3_0, iter_3_1 in ipairs(var_3_7) do
				iter_3_1.extraCure = var_3_6 * var_0_12

				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	elseif arg_3_1.skillID == var_0_14 and arg_3_1.extraCure then
		var_3_3 = var_3_3 + arg_3_1.extraCure
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_4 > 0 and arg_4_1.target:isHasBuffByID(var_0_5) and arg_4_1.target:getTeamType() == arg_4_0:getTeamType() then
		local var_4_0 = math.log(arg_4_0:getAP() * math.pow(10, 8)) / 100
		local var_4_1 = var_0_4.new({
			level = 1,
			tableID = var_0_6,
			start = var_0_1.ctx.battle.count,
			skillID = arg_4_0:getEnergySkillID(),
			fighter = arg_4_0,
			target = arg_4_1.target,
			manualHarmRevise = arg_4_4 * var_4_0 / var_0_7
		})

		arg_4_1.target:addBuffs({
			var_4_1
		})

		arg_4_4 = 0
	end

	if arg_4_5 > 0 and arg_4_1.target:getTeamType() == arg_4_0:getTeamType() then
		arg_4_5 = arg_4_5 * (1 + var_0_10 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_0 = false

		for iter_5_0, iter_5_1 in ipairs(arg_5_1.target:getBuffs()) do
			if iter_5_1:dBuffType() == var_0_2.DBuffType.SHI_HUA then
				var_5_0 = true

				break
			end
		end

		if not var_5_0 then
			arg_5_1:setCollisionNum()
		end
	end

	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("harm_info")) do
			if iter_6_1.harm > 0 and iter_6_1.target:isHasBuffByID(var_0_8) and iter_6_1.target:getTeamType() == arg_6_0:getTeamType() then
				local var_6_0 = arg_6_0:createNewBuffs({
					var_0_9
				}, iter_6_1.target, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				iter_6_1.target:addBuffs(var_6_0)
			end
		end
	end
end

function var_0_3.addBuffBySpecialHero(arg_7_0, arg_7_1)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_7_0 = var_0_10 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		for iter_7_0 = #arg_7_1, 1, -1 do
			local var_7_1 = arg_7_1[iter_7_0]

			if var_7_1:getType() == var_0_2.BuffType.REVIVIE then
				var_7_1.manualHarmRevise = var_7_1:getHarm() * var_7_0
			elseif var_7_1:isDHarmBuff() then
				var_7_1.manualDharm = var_7_1:totalDHarm() * var_7_0
			end
		end
	end
end

function var_0_3.getHuJia(arg_8_0)
	local var_8_0 = math.floor(var_0_1.ctx.battle.count / var_0_13)
	local var_8_1 = 1

	if var_8_0 > 0 then
		for iter_8_0 = 1, var_8_0 do
			var_8_1 = var_8_1 * 0.7
		end
	end

	return arg_8_0:getAttrByType(var_0_2.AttributeType.HUJIA) * var_8_1
end

function var_0_3.getMoKang(arg_9_0)
	local var_9_0 = math.floor(var_0_1.ctx.battle.count / var_0_13)
	local var_9_1 = 1

	if var_9_0 > 0 then
		for iter_9_0 = 1, var_9_0 do
			var_9_1 = var_9_1 * 0.7
		end
	end

	return arg_9_0:getAttrByType(var_0_2.AttributeType.MOKANG) * var_9_1
end

return var_0_3
