local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Litong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10001773
local var_0_6 = 4
local var_0_7 = 10001774
local var_0_8 = 0.3
local var_0_9 = 0.2
local var_0_10 = 0.3
local var_0_11 = 40011912
local var_0_12 = 40011913
local var_0_13 = 40011909

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleBuffNum = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % 30 == 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				if not arg_2_0.purpleBuffNum[iter_2_1] then
					arg_2_0.purpleBuffNum[iter_2_1] = 0
				end

				local var_2_0 = #iter_2_1:getBuffsByID(var_0_13)

				if var_2_0 == 3 and var_2_0 > arg_2_0.purpleBuffNum[iter_2_1] then
					local var_2_1 = arg_2_0:createNewBuffs({
						var_0_11
					}, iter_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					iter_2_1:addBuffs(var_2_1)
				elseif var_2_0 == 4 and var_2_0 > arg_2_0.purpleBuffNum[iter_2_1] then
					local var_2_2 = arg_2_0:createNewBuffs({
						var_0_12
					}, iter_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					iter_2_1:addBuffs(var_2_2)
				end

				arg_2_0.purpleBuffNum[iter_2_1] = var_2_0
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_3_1.target:isHasBuffByID(var_0_13) then
			arg_3_0:greenSkill(arg_3_1)
		end
	elseif var_0_4:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0:blueSkill()
	end

	arg_3_0:purpleSkill(arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)
end

function var_0_3.greenSkill(arg_4_0, arg_4_1)
	local var_4_0 = {}
	local var_4_1 = arg_4_1.target:getX()
	local var_4_2 = {}
	local var_4_3 = arg_4_0.sideTeam_

	for iter_4_0, iter_4_1 in ipairs(var_4_3) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1 ~= arg_4_1.target then
			table.insert(var_4_2, iter_4_1)
		end
	end

	if not next(var_4_2) then
		return {}
	end

	table.sort(var_4_2, function(arg_5_0, arg_5_1)
		return math.abs(arg_5_0:getX() - var_4_1) < math.abs(arg_5_1:getX() - var_4_1)
	end)

	for iter_4_2, iter_4_3 in ipairs(var_4_2) do
		if iter_4_2 <= var_0_6 then
			table.insert(var_4_0, iter_4_3)
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_4 = arg_4_0:createAttackUnits(var_4_0, var_0_5, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))

		for iter_4_4, iter_4_5 in ipairs(var_4_4) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
			table.insert(arg_4_0.records_.special_units, iter_4_5)
		end
	end
end

function var_0_3.blueSkill(arg_6_0)
	if arg_6_0:getHp() / arg_6_0:getHpLimit() < var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_0
		}, var_0_7, arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.purpleSkill(arg_7_0, arg_7_1)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() then
		local var_7_0 = var_0_10

		if var_0_2.weightedChoise({
			var_7_0,
			1 - var_7_0
		}) == 1 then
			local var_7_1 = arg_7_0:createNewBuffs({
				var_0_13
			}, arg_7_1.target, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			arg_7_1.target:addBuffs(var_7_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.skillID == var_0_7 then
		arg_8_5 = (arg_8_0:getHpLimit() - arg_8_0:getHp()) * var_0_9
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

return var_0_3
