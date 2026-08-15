local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guanning", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 10001568
local var_0_8 = 0.2
local var_0_9 = 40011642
local var_0_10 = 40011640
local var_0_11 = 40011639
local var_0_12 = 0.5
local var_0_13 = 180
local var_0_14 = 40011638
local var_0_15 = 0.15
local var_0_16 = 10001567
local var_0_17 = 80010222
local var_0_18 = 0
local var_0_19 = 0.001

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.accHarms = {}

	arg_1_0:listenInfo("harm_info")
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_0.skinSkillID_ == var_0_17 and arg_2_1:getTableID() == var_0_9 then
		local var_2_0 = arg_2_1.getMana

		function arg_2_1.getMana(arg_3_0)
			return var_2_0(arg_3_0) * (1 - (var_0_18 + var_0_19 * arg_3_0:getLevel()))
		end
	end
end

function var_0_3.energyAction(arg_4_0, arg_4_1)
	if var_0_5:father(arg_4_1) == arg_4_0:getEnergySkillID() then
		arg_4_0:getFighterModel():playEnergyEffect_()

		if arg_4_0:getTeamType() == var_0_2.TeamType.A or arg_4_0.isInArena_ or arg_4_0:isMainRole() then
			arg_4_0:addBlackLayer()
		end

		if arg_4_0.skinSkillID_ == var_0_17 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_0 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_17)

				for iter_4_0, iter_4_1 in ipairs(var_4_0) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end
			end

			for iter_4_2, iter_4_3 in ipairs(arg_4_0:getBuffs()) do
				if iter_4_3:canRemove() and (iter_4_3:getBuffForm() == var_0_2.BuffForm.DEBUFF or iter_4_3:dBuffType() > 0) then
					arg_4_0:removeBuffs(iter_4_3)
				end
			end
		end
	end
end

function var_0_3.selectTargetByTypeD2(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}
	local var_5_1 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.targetTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			if #var_5_1 < 2 then
				if iter_5_1.hero_:getHeroType() == var_0_2.HeroType.WISE then
					table.insert(var_5_1, iter_5_1)
				else
					table.insert(var_5_0, iter_5_1)
				end
			else
				return var_5_1
			end
		end
	end

	local var_5_2 = math.random(tonumber(os.time()))

	math.randomseed(var_5_2)

	while #var_5_1 < 2 and #var_5_0 > 0 do
		local var_5_3 = math.random(#var_5_0)
		local var_5_4 = var_5_0[var_5_3]

		table.insert(var_5_1, var_5_4)
		table.remove(var_5_0, var_5_3)
	end

	return var_5_1
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0:getEnergy() == 0 then
		arg_6_0:removeBuffByID(var_0_9)
	end

	if arg_6_0:isHasBuffByID(var_0_9) then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
			if not iter_6_1:isDeath() then
				for iter_6_2 = #iter_6_1:getBuffsByID(var_0_14) + 1, #arg_6_0:getBuffsByID(var_0_14) do
					iter_6_1:addBuffs({
						var_0_4.new({
							tableID = var_0_14,
							start = var_0_1.ctx.battle.count,
							level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
							skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
							fighter = arg_6_0,
							target = iter_6_1
						})
					})
				end
			end
		end
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_6_0 = math.fmod(var_0_1.ctx.battle.count, var_0_13)
		local var_6_1 = math.fmod(var_6_0 + var_0_13 - 1, var_0_13)
		local var_6_2 = math.fmod(var_6_0 + 1, var_0_13)

		arg_6_0.accHarms[var_6_0] = arg_6_0.accHarms[var_6_0] or 0
		arg_6_0.accHarms[var_6_1] = arg_6_0.accHarms[var_6_1] or 0
		arg_6_0.accHarms[var_6_2] = arg_6_0.accHarms[var_6_2] or 0

		for iter_6_3, iter_6_4 in ipairs(arg_6_0:getInfoByKey("harm_info")) do
			if iter_6_4.type == var_0_2.AttackType.AP and iter_6_4.target:getTeamType() == arg_6_0:getTeamType() then
				arg_6_0.accHarms[var_6_0] = arg_6_0.accHarms[var_6_1] + iter_6_4.harm
			end
		end

		local var_6_3 = 0

		for iter_6_5, iter_6_6 in ipairs(arg_6_0.selfTeam_) do
			if not iter_6_6:isDeath() then
				var_6_3 = var_6_3 + iter_6_6:getHpLimit()
			end
		end

		if arg_6_0.accHarms[var_6_0] - arg_6_0.accHarms[var_6_2] > var_6_3 * var_0_12 then
			arg_6_0.accHarms = {}

			arg_6_0:createSkillByID(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_5:attackIndex(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_0:isHasBuffByID(var_0_9) and arg_7_1.skillID == arg_7_0:getPugongID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_1.target
		}, var_0_7)

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			local var_7_1 = 0

			for iter_7_2, iter_7_3 in ipairs(arg_7_0.sideTeam_) do
				if not iter_7_3:isDeath() then
					var_7_1 = var_7_1 + iter_7_3:getAP()
				end
			end

			iter_7_1:setExtraHarm(var_7_1 * var_0_8)
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end

	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_7_0:isHasBuffByID(var_0_11) then
		arg_7_1.target:addBuffs({
			var_0_4.new({
				tableID = var_0_10,
				start = var_0_1.ctx.battle.count,
				level = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
				skillID = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
				fighter = arg_7_0,
				target = arg_7_1.target
			})
		})
	end
end

function var_0_3.checkEnergySkill(arg_8_0)
	if arg_8_0:isHasBuffByID(var_0_9) then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_8_0)
	end
end

function var_0_3.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if arg_9_4 > arg_9_0:getHpLimit() * var_0_15 then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_16)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

return var_0_3
