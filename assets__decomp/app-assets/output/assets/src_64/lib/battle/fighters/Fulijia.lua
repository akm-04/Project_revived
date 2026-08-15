local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fulijia", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40012109
local var_0_6 = 40012110
local var_0_7 = 8
local var_0_8 = 40012106
local var_0_9 = 40012107
local var_0_10 = 0.003
local var_0_11 = 810010
local var_0_12 = 40012746
local var_0_13 = 0.2

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
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_4 > 0 and arg_3_1.target:isHasBuffByID(var_0_5) and arg_3_1.target:getTeamType() == arg_3_0:getTeamType() then
		local var_3_0 = math.log(arg_3_0:getAP() * math.pow(10, 8)) / 100
		local var_3_1 = var_0_4.new({
			level = 1,
			tableID = var_0_6,
			start = var_0_1.ctx.battle.count,
			skillID = arg_3_0:getEnergySkillID(),
			fighter = arg_3_0,
			target = arg_3_1.target,
			manualHarmRevise = arg_3_4 * var_3_0 / var_0_7
		})

		arg_3_1.target:addBuffs({
			var_3_1
		})

		arg_3_4 = 0
	end

	if arg_3_5 > 0 and arg_3_1.target:getTeamType() == arg_3_0:getTeamType() then
		arg_3_5 = arg_3_5 * (1 + var_0_10 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_4_0 = false

		for iter_4_0, iter_4_1 in ipairs(arg_4_1.target:getBuffs()) do
			if iter_4_1:dBuffType() == var_0_2.DBuffType.SHI_HUA then
				var_4_0 = true

				break
			end
		end

		if not var_4_0 then
			arg_4_1:setCollisionNum()
		end
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("harm_info")) do
			if iter_5_1.harm > 0 and iter_5_1.target:isHasBuffByID(var_0_8) and iter_5_1.target:getTeamType() == arg_5_0:getTeamType() then
				local var_5_0 = arg_5_0:createNewBuffs({
					var_0_9
				}, iter_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				iter_5_1.target:addBuffs(var_5_0)
			end
		end
	end
end

function var_0_3.addBuffBySpecialHero(arg_6_0, arg_6_1)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_6_0 = var_0_10 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		for iter_6_0 = #arg_6_1, 1, -1 do
			local var_6_1 = arg_6_1[iter_6_0]

			if var_6_1:getType() == var_0_2.BuffType.REVIVIE then
				var_6_1.manualHarmRevise = var_6_1:getHarm() * var_6_0
			elseif var_6_1:isDHarmBuff() then
				var_6_1.manualDharm = var_6_1:totalDHarm() * var_6_0
			end
		end
	end

	for iter_6_1, iter_6_2 in ipairs(arg_6_1) do
		local var_6_2 = iter_6_2.target

		if arg_6_0.skinSkillIndex_ == 1 and var_6_2:isHasBuffByID(var_0_12) and var_6_2:getTeamType() == arg_6_0:getTeamType() and iter_6_2:getHarm() > 0 then
			local var_6_3 = iter_6_2:getHarm()

			iter_6_2.manualHarmRevise = -var_0_13 * var_6_3
		end
	end
end

function var_0_3.afterDamageHarm(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0.skinSkillIndex_ == 1 and arg_7_1 > 0 and arg_7_0:getTeamType() ~= arg_7_2.target:getTeamType() then
		local var_7_0 = {}

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and not iter_7_1:isHasBuffByID(var_0_12) then
				table.insert(var_7_0, iter_7_1)
			end
		end

		if next(var_7_0) then
			local var_7_1 = var_7_0[math.random(#var_7_0)]

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_2 = arg_7_0:createAttackUnits({
					var_7_1
				}, var_0_11)

				for iter_7_2, iter_7_3 in ipairs(var_7_2) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
					table.insert(arg_7_0.records_.special_units, iter_7_3)
				end
			end
		end
	end
end

return var_0_3
