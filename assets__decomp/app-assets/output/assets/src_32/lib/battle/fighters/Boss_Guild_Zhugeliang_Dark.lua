local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhugeliang", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = {
	dark = 50020144,
	wind = 50010144
}
local var_0_7 = {
	dark = 20020144,
	wind = 20010144
}
local var_0_8 = {
	dark = 30020144,
	wind = 30010144
}
local var_0_9 = {
	dark = 40020144,
	wind = 40010144
}
local var_0_10 = 10000653
local var_0_11 = 40010623
local var_0_12 = 10000654
local var_0_13 = 10000655
local var_0_14 = 300
local var_0_15 = 40010619
local var_0_16 = 10000656
local var_0_17 = 0
local var_0_18 = 0.003
local var_0_19 = 90
local var_0_20 = 0
local var_0_21 = -0.5
local var_0_22 = 0
local var_0_23 = 6

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isRestartInit_ = false
	arg_1_0.energyDarkTargets_ = {}
	arg_1_0.greenWindTarget_ = {}
	arg_1_0.greenDarkHp_ = 0
	arg_1_0.lessHeros_ = 0
	arg_1_0.blueWindTargets_ = {}
	arg_1_0.purpleWindCD_ = 0
	arg_1_0.isPurpleWindAttack_ = false
	arg_1_0.purpleDarkExtraHpLimit_ = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	arg_2_0.isPurpleWindAttack_ = false

	if arg_2_1.rootID_ == var_0_7.wind then
		arg_2_0.greenWindTarget_ = {}
	elseif arg_2_1.rootID_ == var_0_7.dark then
		arg_2_0.greenDarkHp_ = 0
	end

	if arg_2_1.rootID_ ~= arg_2_0:getPugongID() and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) == var_0_9.wind and arg_2_0.purpleWindCD_ < 1 then
		arg_2_0.lessHeros_ = arg_2_0:isSelfTeamLess()

		if arg_2_0.lessHeros_ ~= 0 then
			arg_2_0.isPurpleWindAttack_ = true
			arg_2_0.purpleWindCD_ = var_0_19
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_7.wind then
		if not arg_3_0.greenWindTarget_[arg_3_1.target] then
			arg_3_0.greenWindTarget_[arg_3_1.target] = true
		else
			arg_3_1.target:checkSkillBreak(var_0_2.BreakSkillType.AP, arg_3_1)
			arg_3_1.target:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_3_1)
		end
	elseif arg_3_1.skillID == var_0_8.wind then
		table.insert(arg_3_0.blueWindTargets_, arg_3_1.target)
	elseif arg_3_1.skillID == var_0_6.dark then
		table.insert(arg_3_0.energyDarkTargets_, arg_3_1.target)
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0 = arg_4_1.skillID

	if var_4_0 == var_0_12 then
		arg_4_0.greenDarkHp_ = arg_4_0.greenDarkHp_ + arg_4_4
	elseif var_4_0 == var_0_13 then
		arg_4_4 = arg_4_4 + arg_4_0.greenDarkHp_
	end

	if arg_4_1.attackType == var_0_2.AttackType.AP and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) == var_0_8.dark then
		arg_4_6 = arg_4_6 + arg_4_4 * (var_0_17 + var_0_18 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	end

	if arg_4_0.isPurpleWindAttack_ then
		arg_4_7 = arg_4_7 + (var_0_20 + var_0_21 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * arg_4_0.lessHeros_
	end

	return var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.toDoPerFrames(arg_5_0)
	arg_5_0:blueWindJudge()
	arg_5_0:energyDarkJudge()

	if arg_5_0:isDeath() then
		return
	end

	if not arg_5_0.isRestartInit_ then
		arg_5_0.isRestartInit_ = true

		local var_5_0 = math.min(arg_5_0:getHp(), arg_5_0:getHpLimit())

		arg_5_0:updateHp(var_5_0)
	end

	if arg_5_0.purpleWindCD_ > 0 then
		arg_5_0.purpleWindCD_ = arg_5_0.purpleWindCD_ - 1
	end

	if var_0_1.ctx.battle.count % 30 < 1 and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) == var_0_9.dark then
		local var_5_1 = var_0_22 + var_0_23 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		arg_5_0.purpleDarkExtraHpLimit_ = arg_5_0.purpleDarkExtraHpLimit_ - var_5_1

		arg_5_0:setTempHpLimit(arg_5_0.purpleDarkExtraHpLimit_)
	end
end

function var_0_3.isSelfTeamLess(arg_6_0)
	local var_6_0 = 0
	local var_6_1 = 0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_6_0 = var_6_0 + 1
		end
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_3:isDeath() and not iter_6_3:isAffected() and iter_6_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_6_1 = var_6_1 + 1
		end
	end

	return math.max(0, var_6_1 - var_6_0)
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
		if not iter_7_1:isDeath() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_7_0, iter_7_1)
		end
	end

	if #var_7_0 >= 1 then
		local var_7_1 = arg_7_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

		local function var_7_2(arg_8_0, arg_8_1)
			return arg_8_0:getX() * var_7_1 < arg_8_1:getX() * var_7_1
		end

		table.sort(var_7_0, var_7_2)

		local var_7_3 = 1

		while true do
			if var_7_0[var_7_3]:isHasBuffByID(var_0_15) then
				var_7_3 = var_7_3 + 1
			else
				return {
					var_7_0[var_7_3]
				}
			end

			if var_7_3 > #var_7_0 then
				return {}
			end
		end

		return
	end

	return {}
end

function var_0_3.blueWindJudge(arg_9_0)
	if not next(arg_9_0.blueWindTargets_) or var_0_1.ctx.battle.count % 10 >= 1 then
		return
	end

	for iter_9_0 = #arg_9_0.blueWindTargets_, 1, -1 do
		if arg_9_0.blueWindTargets_[iter_9_0]:isDeath() then
			table.remove(arg_9_0.blueWindTargets_, iter_9_0)
		end
	end

	if next(arg_9_0.blueWindTargets_) then
		for iter_9_1, iter_9_2 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_2:isDeath() and not iter_9_2:isAffected() then
				for iter_9_3, iter_9_4 in ipairs(arg_9_0.blueWindTargets_) do
					if math.abs(iter_9_4:getX() - iter_9_2:getX()) <= var_0_14 * 0.5 then
						if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
							local var_9_0 = arg_9_0:createAttackUnits({
								iter_9_2
							}, var_0_16)

							for iter_9_5, iter_9_6 in ipairs(var_9_0) do
								table.insert(arg_9_0.moveAttackUnits_, iter_9_6)
								table.insert(arg_9_0.records_.special_units, iter_9_6)
							end
						end

						iter_9_4:removeBuffByID(var_0_15)
						table.remove(arg_9_0.blueWindTargets_, iter_9_3)

						break
					end
				end
			end

			if not next(arg_9_0.blueWindTargets_) then
				break
			end
		end
	end
end

function var_0_3.energyDarkJudge(arg_10_0)
	if not next(arg_10_0.energyDarkTargets_) or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or var_0_1.ctx.battle.count % 30 >= 1 then
		return
	end

	for iter_10_0 = #arg_10_0.energyDarkTargets_, 1, -1 do
		local var_10_0 = arg_10_0.energyDarkTargets_[iter_10_0]

		if var_10_0:isDeath() or not var_10_0:isHasBuffByID(var_0_11) then
			table.remove(arg_10_0.energyDarkTargets_, iter_10_0)
		else
			local var_10_1 = arg_10_0:createAttackUnits({
				var_10_0
			}, var_0_10)

			for iter_10_1, iter_10_2 in ipairs(var_10_1) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_2)
				table.insert(arg_10_0.records_.special_units, iter_10_2)
			end
		end
	end
end

return var_0_3
