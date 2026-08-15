local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chitu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10010143
local var_0_6 = 40010057
local var_0_7 = 1
local var_0_8 = 0.001
local var_0_9 = 0.2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenBuffCount_ = 0
	arg_1_0.blueBuffCount_ = 0
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if var_2_2 > 0 and var_0_4:father(arg_2_1.skillID) == arg_2_0:getEnergySkillID() then
		local var_2_6 = 1
		local var_2_7 = arg_2_1.target:getMingZhong() < arg_2_0:getMingZhong() and 2 - arg_2_1.target:getMingZhong() / arg_2_0:getMingZhong() or 1
		local var_2_8 = math.max(2, 2 - arg_2_1.target:getADHitRate()) * var_2_7
		local var_2_9 = math.max(var_2_8, 1)

		var_2_2 = var_2_2 * math.min(var_2_9, 4)
	end

	if arg_2_1.skillID == arg_2_0:getPugongID() and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_10 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_2_11 = arg_2_0:getBlueTargets(arg_2_1)
		local var_2_12 = arg_2_0:createAttackUnits(var_2_11, var_2_10)

		for iter_2_0, iter_2_1 in ipairs(var_2_12) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.getBlueTargets(arg_3_0, arg_3_1)
	local var_3_0 = {}
	local var_3_1 = var_0_4:scope(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and math.abs(iter_3_1:getX() - arg_3_1.target:getX()) < var_3_1 / 2 then
			table.insert(var_3_0, iter_3_1)
		end
	end

	return var_3_0
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_5 then
		arg_4_0.greenBuffCount_ = arg_4_0.greenBuffCount_ + 1
	elseif arg_4_1:getTableID() == var_0_6 then
		arg_4_0.blueBuffCount_ = arg_4_0.blueBuffCount_ + 1
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == var_0_5 then
		arg_5_0.greenBuffCount_ = arg_5_0.greenBuffCount_ - 1
	elseif arg_5_1:getTableID() == var_0_6 then
		arg_5_0.blueBuffCount_ = arg_5_0.blueBuffCount_ - 1
	end
end

function var_0_3.getMingZhong(arg_6_0)
	local var_6_0 = arg_6_0.greenBuffCount_ * var_0_7

	return var_0_3.super.getMingZhong(arg_6_0) + var_6_0
end

function var_0_3.getADHitRate(arg_7_0)
	local var_7_0 = arg_7_0.greenBuffCount_ * var_0_8

	return var_0_3.super.getADHitRate(arg_7_0)
end

function var_0_3.getADBaoji(arg_8_0)
	local var_8_0 = arg_8_0.blueBuffCount_ * var_0_9

	return var_0_3.super.getADBaoji(arg_8_0) + var_8_0
end

function var_0_3.selectTargetByTypeD1(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = var_0_4:scope(arg_9_1)
	local var_9_1 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
			table.insert(var_9_1, iter_9_1)
		end
	end

	if not next(var_9_1) then
		return {}
	end

	table.sort(var_9_1, function(arg_10_0, arg_10_1)
		return arg_10_0:getX() < arg_10_1:getX()
	end)

	if #var_9_1 == 1 then
		return {
			var_9_1[1]
		}
	end

	local var_9_2 = {}

	for iter_9_2 = 1, #var_9_1 do
		var_9_2[iter_9_2] = 1

		for iter_9_3 = #var_9_1, iter_9_2 + 1, -1 do
			if var_9_0 >= var_9_1[iter_9_3]:getX() - var_9_1[iter_9_2]:getX() then
				var_9_2[iter_9_2] = iter_9_3 + 1 - iter_9_2

				break
			end
		end
	end

	local var_9_3 = 1
	local var_9_4 = var_9_2[1]

	for iter_9_4, iter_9_5 in ipairs(var_9_2) do
		if var_9_4 < iter_9_5 then
			var_9_3 = iter_9_4
			var_9_4 = iter_9_5
		end
	end

	local var_9_5 = {}

	for iter_9_6 = var_9_3, var_9_4 + var_9_3 - 1 do
		table.insert(var_9_5, var_9_1[iter_9_6])
	end

	return var_9_5
end

function var_0_3.beginAttackEnd(arg_11_0, arg_11_1)
	var_0_3.super.beginAttackEnd(arg_11_0, arg_11_1)

	if arg_11_1.rootID_ == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_11_0 = arg_11_0:selectTargetByTypeD1(arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		if var_11_0[1] then
			local var_11_1 = (var_11_0[1]:getX() + var_11_0[#var_11_0]:getX()) / 2

			arg_11_0:flipX(var_11_1 < arg_11_0:getX())
		end
	end
end

return var_0_3
