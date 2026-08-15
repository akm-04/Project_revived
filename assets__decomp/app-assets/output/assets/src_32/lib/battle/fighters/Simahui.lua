local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Simahui", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40011773
local var_0_7 = 40011781
local var_0_8 = 10001670
local var_0_9 = 10001671
local var_0_10 = 40011782
local var_0_11 = 40011785
local var_0_12 = 40011786

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenCure = 0
end

function var_0_3.isBreakImmortal(arg_3_0)
	return arg_3_0:isHasBuffByID(var_0_10) or var_0_3.super.isBreakImmortal(arg_3_0)
end

function var_0_3.updateUnitInfoBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_1.fighter == arg_4_0 then
		arg_4_0.greenCure = arg_4_4 / 2
	elseif arg_4_1.target == arg_4_0 and arg_4_1.fighter:getTeamType() ~= arg_4_0:getTeamType() and arg_4_4 > 0 and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_4_1.fighter:addBuffs({
			var_0_4.new({
				tableID = var_0_11,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_4_0,
				target = arg_4_1.fighter
			})
		})
		arg_4_1.fighter:addBuffs({
			var_0_4.new({
				tableID = var_0_12,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_4_0,
				target = arg_4_1.fighter
			})
		})
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_6 then
		arg_5_1.manualHarmRevise = arg_5_0.greenCure / arg_5_1.leftCount_ * 30
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("attack_info")) do
		local var_6_0 = iter_6_1.fighter_:getBuffByID(var_0_7)

		if var_6_0 and var_6_0.fighter == arg_6_0 then
			if var_0_5:type(iter_6_1.rootID_) == var_0_2.AttackType.AD then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_6_1 = arg_6_0:createAttackUnits({
						var_6_0.target
					}, var_0_9)

					for iter_6_2, iter_6_3 in ipairs(var_6_1) do
						table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
						table.insert(arg_6_0.records_.special_units, iter_6_3)
					end
				end
			elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_2 = arg_6_0:createAttackUnits({
					var_6_0.target
				}, var_0_8)

				for iter_6_4, iter_6_5 in ipairs(var_6_2) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
					table.insert(arg_6_0.records_.special_units, iter_6_5)
				end
			end

			iter_6_1.fighter_:removeBuffs(var_6_0)
		end
	end
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)

	if var_0_5:father(arg_7_1.rootID_) == arg_7_0:getEnergySkillID() then
		arg_7_0.strengthTargets = {}
		arg_7_0.wiseTargets = {}
		arg_7_0.agileTargets = {}

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
				if iter_7_1.hero_:getHeroType() == var_0_2.HeroType.STRENGTH then
					table.insert(arg_7_0.strengthTargets, iter_7_1)
				elseif iter_7_1.hero_:getHeroType() == var_0_2.HeroType.WISE then
					table.insert(arg_7_0.wiseTargets, iter_7_1)
				elseif iter_7_1.hero_:getHeroType() == var_0_2.HeroType.AGILE then
					table.insert(arg_7_0.agileTargets, iter_7_1)
				end
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	return arg_8_0.strengthTargets
end

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	return arg_9_0.wiseTargets
end

function var_0_3.selectTargetByTypeD3(arg_10_0, arg_10_1, arg_10_2)
	return arg_10_0.agileTargets
end

return var_0_3
