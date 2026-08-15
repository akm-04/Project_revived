local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Tongyuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 5
local var_0_6 = 10000578
local var_0_7 = 10000581
local var_0_8 = 10000580
local var_0_9 = 10000579
local var_0_10 = 0.6
local var_0_11 = 0.02
local var_0_12 = 0.1
local var_0_13 = 0.005
local var_0_14 = 0.25
local var_0_15 = -0.001
local var_0_16 = 30
local var_0_17 = 0.6
local var_0_18 = 80010129
local var_0_19 = 15
local var_0_20 = 15
local var_0_21 = 10001725
local var_0_22 = 10001724
local var_0_23 = 10001723

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.birdNums_ = 0
	arg_1_0.notHpBirdNums_ = 0
	arg_1_0.hpBirdNums_ = 0
	arg_1_0.records_.green_bird = {}

	arg_1_0:updateStateNumber(arg_1_0.birdNums_)
end

function var_0_3.getUnitData(arg_2_0, arg_2_1)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.getUnitData(arg_2_0, arg_2_1)

	if arg_2_0.notHpBirdNums_ > 0 and var_2_1 and arg_2_1.target ~= arg_2_0 then
		arg_2_0:addBirdNum(-1)
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_1.skillID == (arg_3_0.skinSkillID_ == var_0_18 and var_0_22 or var_0_8) and arg_3_0.birdNums_ > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_1.target:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
		local var_3_1 = {}

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_1.target then
				table.insert(var_3_1, iter_3_1)
			end
		end

		if next(var_3_1) then
			local var_3_2 = {}

			if arg_3_0.birdNums_ >= #var_3_1 then
				var_3_2 = var_3_1
			else
				table.sort(var_3_1, function(arg_4_0, arg_4_1)
					return math.abs(arg_4_0:getX() - arg_3_1.target:getX()) < math.abs(arg_4_1:getX() - arg_3_1.target:getX())
				end)

				for iter_3_2 = 1, arg_3_0.birdNums_ do
					table.insert(var_3_2, var_3_1[iter_3_2])
				end
			end

			local var_3_3 = arg_3_0:createAttackUnits(var_3_2, arg_3_0.skinSkillID_ == var_0_18 and var_0_23 or var_0_9)

			for iter_3_3, iter_3_4 in ipairs(var_3_3) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_4)
				table.insert(arg_3_0.records_.special_units, iter_3_4)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_4:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_3_0.isGreenBird_[tostring(var_0_1.ctx.battle.count)] then
				arg_3_0:addBirdNum(1)
			end
		else
			local var_3_4 = var_0_10 + arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) * var_0_11

			if arg_3_0.skinSkillID_ == var_0_18 or var_0_2.weightedChoise({
				var_3_4,
				1 - var_3_4
			}) == 1 then
				arg_3_0.records_.green_bird[tostring(var_0_1.ctx.battle.count)] = 1

				arg_3_0:addBirdNum(1)
			end
		end
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if arg_3_0.skinSkillID_ == var_0_18 or arg_3_0.birdNums_ == 0 then
			arg_3_0:addBirdNum(1)
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_5 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_6)

			for iter_3_5, iter_3_6 in ipairs(var_3_5) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_6)
				table.insert(arg_3_0.records_.special_units, iter_3_6)
			end
		end
	elseif arg_3_1.skillID == (arg_3_0.skinSkillID_ == var_0_18 and var_0_21 or var_0_7) then
		arg_3_0:setImmuneControl(true)
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_5_0.blueHarm_ = arg_5_4
	elseif arg_5_1.skillID == var_0_6 then
		arg_5_5 = arg_5_0.blueHarm_ * (var_0_12 + var_0_13 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
		arg_5_0.blueHarm_ = 0
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.skinSkillID_ == var_0_18 and var_0_1.ctx.battle.count == 30 then
		arg_6_0:addBirdNum(1)
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % 10 < 1 then
		arg_6_0:judeHpBirdNum()
	end
end

function var_0_3.judeHpBirdNum(arg_7_0)
	local var_7_0 = var_0_14 + var_0_15 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	arg_7_0.hpBirdNums_ = math.floor((1 - arg_7_0:getHp() / arg_7_0:getHpLimit()) / var_7_0)

	arg_7_0:addBirdNum(0)
end

function var_0_3.addBirdNum(arg_8_0, arg_8_1)
	arg_8_0.notHpBirdNums_ = arg_8_0.notHpBirdNums_ + arg_8_1
	arg_8_0.birdNums_ = math.min(arg_8_0.notHpBirdNums_ + arg_8_0.hpBirdNums_, var_0_5)

	arg_8_0:updateStateNumber(arg_8_0.birdNums_)
end

function var_0_3.setupReport(arg_9_0, arg_9_1)
	var_0_3.super.setupReport(arg_9_0, arg_9_1)

	arg_9_0.isGreenBird_ = arg_9_1.green_bird
end

function var_0_3.writeReport(arg_10_0)
	local var_10_0 = var_0_3.super.writeReport(arg_10_0)

	var_10_0.green_bird = arg_10_0.records_.green_bird

	return var_10_0
end

function var_0_3.getADBaoJi(arg_11_0)
	return var_0_3.super.getADBaoJi(arg_11_0) + arg_11_0.birdNums_ * (var_0_16 + var_0_17 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
end

function var_0_3.getMingZhong(arg_12_0)
	return var_0_3.super.getMingZhong(arg_12_0) + (arg_12_0.skinSkillID_ == var_0_18 and arg_12_0.birdNums_ * var_0_19 or 0)
end

function var_0_3.getShanBi(arg_13_0)
	return var_0_3.super.getShanBi(arg_13_0) + (arg_13_0.skinSkillID_ == var_0_18 and arg_13_0.birdNums_ * var_0_20 or 0)
end

return var_0_3
