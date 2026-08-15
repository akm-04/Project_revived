local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Renyu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = 10000956
local var_0_6 = 10000955
local var_0_7 = 40011051
local var_0_8 = 0.2
local var_0_9 = 0.003
local var_0_10 = 0.2
local var_0_11 = 40011045
local var_0_12 = 40011043
local var_0_13 = 0.2
local var_0_14 = 0.004
local var_0_15 = 10000970
local var_0_16 = 10000911
local var_0_17 = 0.2
local var_0_18 = 0.2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyType_ = false
	arg_1_0.energyTempHp_ = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = 0

		if arg_2_1.target:getTeamType() == arg_2_0:getTeamType() then
			var_2_0 = var_0_5
		else
			var_2_0 = var_0_6
		end

		local var_2_1 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_2_0)

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	var_0_3.super.buffAddAction(arg_3_0, arg_3_1)

	if arg_3_1:getTableID() == var_0_12 and arg_3_1.target == arg_3_0 then
		local var_3_0 = arg_3_0:getHpLimit() * var_0_10
		local var_3_1 = arg_3_0:getTempHpLimit()

		arg_3_0.energyTempHp_ = var_3_0

		arg_3_0:setTempHpLimit(var_3_1 - var_3_0)
		arg_3_0:updateHp(arg_3_0:getHp() + var_3_0)

		arg_3_0.isEnergyType_ = true
	end

	if arg_3_1:getTableID() == var_0_12 and arg_3_1.target == arg_3_0 then
		local var_3_2 = arg_3_0:getHpLimit() * var_0_10
		local var_3_3 = arg_3_0:getTempHpLimit()

		arg_3_0.energyTempHp_ = var_3_2

		arg_3_0:setTempHpLimit(var_3_3 - var_3_2)
		arg_3_0:updateHp(arg_3_0:getHp() + var_3_2)

		arg_3_0.isEnergyType_ = true
	end

	if arg_3_0.skinSkillIndex_ == 1 and (arg_3_1:getTableID() == var_0_7 or arg_3_1:getTableID() == var_0_11) then
		local var_3_4 = var_0_4:time(arg_3_1:getTableID()) * var_0_18

		arg_3_1:setExtraTime(var_3_4)
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	var_0_3.super.buffRemoveAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_12 and arg_4_1.target == arg_4_0 then
		local var_4_0 = arg_4_0:getTempHpLimit()

		arg_4_0:setTempHpLimit(var_4_0 + arg_4_0.energyTempHp_)

		arg_4_0.isEnergyType_ = false
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_4 > 0 and arg_5_1.skillID == var_0_15 and arg_5_1.change_harm and arg_5_1.change_harm > 0 then
		arg_5_4 = arg_5_4 + arg_5_1.change_harm * arg_5_0:getADJianShang()
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0.skinSkillIndex_ == 1 and arg_6_1.target:getTeamType() == arg_6_0:getTeamType() and (arg_6_1.target:isHasBuffByID(var_0_7) or arg_6_1.target:isHasBuffByID(var_0_11)) then
		arg_6_4 = arg_6_4 - var_0_17 * arg_6_4
	end

	if arg_6_4 > 0 and arg_6_3 and arg_6_1.target:getTeamType() == arg_6_0:getTeamType() then
		if arg_6_1.target:isHasBuffByID(var_0_7) then
			arg_6_4 = arg_6_4 - (arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_9 + var_0_8) * arg_6_4
		elseif arg_6_1.target:isHasBuffByID(var_0_11) then
			local var_6_0 = var_0_13 + var_0_14 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

			if var_0_2.weightedChoise({
				var_6_0,
				1 - var_6_0
			}) == 1 then
				arg_6_4 = arg_6_4 - arg_6_4 * 0.2

				local var_6_1 = arg_6_4 / 2

				arg_6_4 = arg_6_4 - var_6_1

				local var_6_2 = arg_6_0:createAttackUnits({
					arg_6_0
				}, var_0_15)

				for iter_6_0, iter_6_1 in ipairs(var_6_2) do
					iter_6_1.change_harm = var_6_1

					table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
					table.insert(arg_6_0.records_.special_units, iter_6_1)
				end
			end
		end
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.selectTargetByTypeD2(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1 ~= arg_7_0 and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_7_0, iter_7_1)
		end
	end

	return var_7_0
end

function var_0_3.selectTargetByTypeD4(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1 = arg_8_0:getX()

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1 ~= arg_8_0 then
			table.insert(var_8_0, {
				target = iter_8_1,
				distance = math.abs(iter_8_1:getX() - var_8_1)
			})
		end
	end

	for iter_8_2, iter_8_3 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_3:isDeath() and not iter_8_3:isAffected() and iter_8_3 ~= arg_8_0 then
			table.insert(var_8_0, {
				target = iter_8_3,
				distance = math.abs(iter_8_3:getX() - var_8_1)
			})
		end
	end

	if not next(var_8_0) then
		return {}
	end

	table.sort(var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0.distance ~= arg_9_1.distance then
			return arg_9_0.distance < arg_9_1.distance
		end
	end)

	if not arg_8_2 or not arg_8_2.targets_ or not next(arg_8_2.targets_) then
		return {
			var_8_0[1].target
		}
	else
		local var_8_2

		for iter_8_4, iter_8_5 in ipairs(var_8_0) do
			if not var_0_0.table.keyof(arg_8_2.targets_, iter_8_5.target) then
				var_8_2 = iter_8_5.target

				break
			end
		end

		return {
			var_8_2
		}
	end
end

function var_0_3.checkMove(arg_10_0)
	if arg_10_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_10_0.hero_:enterDuration() then
			arg_10_0.isWalking_ = 1

			if not arg_10_0:isWalking() then
				arg_10_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_10_0:isWalking() == 2 then
				local var_10_0 = arg_10_0:getFlipX() and -1 or 1

				arg_10_0:moveByX(arg_10_0.hero_:enterSpeed() * var_10_0)
			end

			if arg_10_0:getCurrentAnimation() ~= "run" then
				arg_10_0:modelWalk()
			end
		elseif not arg_10_0.playedEnterSkill_ then
			if arg_10_0:isWalking() ~= 3 then
				arg_10_0.preWalk_ = false
				arg_10_0.isWalking_ = false
				arg_10_0.behindWalk_ = false
				arg_10_0.playedEnterSkill_ = true
				arg_10_0.walk2Position_ = false

				if arg_10_0:getCurrentAnimation() == "run" then
					arg_10_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_10_0.hero_:enterDelayDuration() then
			arg_10_0.isEnterSkill_ = nil
			arg_10_0.walk2Position_ = false
			arg_10_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_10_0)
end

function var_0_3.setFormation(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	arg_11_0.isEnterSkill_ = arg_11_0:enterSkill() > 0 and arg_11_0:getSkillLevelByID(arg_11_0:enterSkill()) > 0

	if arg_11_0.isEnterSkill_ then
		arg_11_0.playedEnterSkill_ = false

		local var_11_0 = arg_11_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_11_0:x(var_11_0)
		arg_11_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_11_3 - 90 * (arg_11_2 % 2))

		return arg_11_2 + 1
	end

	return var_0_3.super.setFormation(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
end

function var_0_3.enterSkill(arg_12_0)
	return arg_12_0.hero_:enterSkill()
end

function var_0_3.checkEnergySkill(arg_13_0)
	if arg_13_0.isEnergyType_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_13_0)
end

return var_0_3
