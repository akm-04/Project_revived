local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhugeliang", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = 10000653
local var_0_7 = 40010623
local var_0_8 = 10000654
local var_0_9 = 10000655
local var_0_10 = 300
local var_0_11 = 40010619
local var_0_12 = 10000656
local var_0_13 = 0
local var_0_14 = 6
local var_0_15 = 4
local var_0_16 = 18
local var_0_17 = 4

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueWindTargets_ = {}
	arg_1_0.energyDarkTargets_ = {}
	arg_1_0.greenDarkHp_ = 0
	arg_1_0.awakeDarkDieHero_ = 0
	arg_1_0.awakeDarkDieMonster_ = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_2_0.greenDarkHp_ = 0
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		table.insert(arg_3_0.energyDarkTargets_, arg_3_1.target)
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0 = arg_4_1.skillID

	if var_4_0 == var_0_8 then
		arg_4_0.greenDarkHp_ = arg_4_0.greenDarkHp_ + arg_4_4
	elseif var_4_0 == var_0_9 then
		arg_4_4 = arg_4_4 + arg_4_0.greenDarkHp_
	end

	return var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.toDoPerFrames(arg_5_0)
	arg_5_0:blueWindJudge()
	arg_5_0:energyDarkJudge()
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_6_0, iter_6_1)
		end
	end

	if #var_6_0 >= 1 then
		local var_6_1 = arg_6_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

		function sortFunc(arg_7_0, arg_7_1)
			return arg_7_0:getX() * var_6_1 < arg_7_1:getX() * var_6_1
		end

		table.sort(var_6_0, sortFunc)

		local var_6_2 = 1

		while true do
			if var_6_0[var_6_2]:isHasBuffByID(var_0_11) then
				var_6_2 = var_6_2 + 1
			else
				return {
					var_6_0[var_6_2]
				}
			end

			if var_6_2 > #var_6_0 then
				return {}
			end
		end

		return
	end

	return {}
end

function var_0_3.blueWindJudge(arg_8_0)
	if not next(arg_8_0.blueWindTargets_) or var_0_1.ctx.battle.count % 10 >= 1 then
		return
	end

	for iter_8_0 = #arg_8_0.blueWindTargets_, 1, -1 do
		if arg_8_0.blueWindTargets_[iter_8_0]:isDeath() then
			table.remove(arg_8_0.blueWindTargets_, iter_8_0)
		end
	end

	if next(arg_8_0.blueWindTargets_) then
		for iter_8_1, iter_8_2 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_2:isDeath() and not iter_8_2:isAffected() then
				for iter_8_3, iter_8_4 in ipairs(arg_8_0.blueWindTargets_) do
					if math.abs(iter_8_4:getX() - iter_8_2:getX()) <= var_0_10 * 0.5 then
						if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
							local var_8_0 = arg_8_0:createAttackUnits({
								iter_8_2
							}, var_0_12)

							for iter_8_5, iter_8_6 in ipairs(var_8_0) do
								table.insert(arg_8_0.moveAttackUnits_, iter_8_6)
								table.insert(arg_8_0.records_.special_units, iter_8_6)
							end
						end

						iter_8_4:removeBuffByID(var_0_11)
						table.remove(arg_8_0.blueWindTargets_, iter_8_3)

						break
					end
				end
			end

			if not next(arg_8_0.blueWindTargets_) then
				break
			end
		end
	end
end

function var_0_3.energyDarkJudge(arg_9_0)
	if not next(arg_9_0.energyDarkTargets_) or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or var_0_1.ctx.battle.count % 30 >= 1 then
		return
	end

	for iter_9_0 = #arg_9_0.energyDarkTargets_, 1, -1 do
		local var_9_0 = arg_9_0.energyDarkTargets_[iter_9_0]

		if var_9_0:isDeath() or not var_9_0:isHasBuffByID(var_0_7) then
			table.remove(arg_9_0.energyDarkTargets_, iter_9_0)
		else
			local var_9_1 = arg_9_0:createAttackUnits({
				var_9_0
			}, var_0_6)

			for iter_9_1, iter_9_2 in ipairs(var_9_1) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_2)
				table.insert(arg_9_0.records_.special_units, iter_9_2)
			end
		end
	end
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	if arg_10_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_10_0.awakeDarkDieHero_ = arg_10_0.awakeDarkDieHero_ + 1
	else
		arg_10_0.awakeDarkDieMonster_ = arg_10_0.awakeDarkDieMonster_ + 1
	end
end

function var_0_3.getAD(arg_11_0)
	return arg_11_0:getAttrByType(var_0_2.AttributeType.AD)
end

function var_0_3.getAP(arg_12_0)
	local var_12_0 = arg_12_0:getAttrByType(var_0_2.AttributeType.AP)
	local var_12_1 = 0
	local var_12_2 = arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * (arg_12_0.awakeDarkDieMonster_ * var_0_15 + arg_12_0.awakeDarkDieHero_ * var_0_16)

	return var_12_0 + math.min(var_12_0 * var_0_17, var_12_2)
end

return var_0_3
