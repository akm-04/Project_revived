local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Liru", var_0_1.ctx.battle.requireFighter("Hide_Liru"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.model
local var_0_7 = 0.03
local var_0_8 = 0
local var_0_9 = 300
local var_0_10 = 40010829
local var_0_11 = {
	40010830,
	40010831,
	40010832,
	40010833,
	40010834,
	40010835
}
local var_0_12 = 10
local var_0_13 = 0.1
local var_0_14 = 2

function var_0_4.ctor(arg_1_0, arg_1_1)
	var_0_4.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
	arg_1_0:listenInfo("death_info")
end

function var_0_4.init(arg_2_0)
	var_0_4.super.init(arg_2_0)

	arg_2_0.twiceAwakenCount = 300
	arg_2_0.twiceTargets = {}
	arg_2_0.twiceAwakenBigBuff = 0
	arg_2_0.twiceAwakenDebuffDelay = 0
end

function var_0_4.singleLoop(arg_3_0)
	var_0_4.super.singleLoop(arg_3_0)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) < 1 then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)

	for iter_3_0, iter_3_1 in ipairs(var_0_1.ctx.battle.infoList.attack_info) do
		local var_3_1 = var_0_5:type(iter_3_1.rootID_)

		if var_3_1 == var_0_2.AttackType.AP or var_3_1 == var_0_2.AttackType.CURE then
			arg_3_0:specialAttack({
				iter_3_1.fighter_
			}, var_3_0)
		end
	end
end

function var_0_4.applySingleUnit(arg_4_0, arg_4_1)
	var_0_4.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.target

	if arg_4_1.skillID == arg_4_0:getEnergySkillID() and var_4_0:getBuffByID(var_0_10) then
		var_4_0:removeBuffByID(var_0_10)
	end
end

local function var_0_15(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0) do
		if iter_5_1 == arg_5_1 then
			return true
		end
	end

	return false
end

function var_0_4.toDoPerFrames(arg_6_0)
	var_0_4.super.toDoPerFrames(arg_6_0)

	if arg_6_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_6_0:getFighterModel():scale(1)
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("death_info")) do
		if iter_6_1:getTeamType() ~= arg_6_0:getTeamType() and var_0_15(arg_6_0.twiceTargets, iter_6_1) then
			iter_6_1:removeBuffByID(var_0_10)
		end
	end

	arg_6_0.twiceAwakenCount = arg_6_0.twiceAwakenCount + 1

	if arg_6_0.twiceAwakenCount >= var_0_9 then
		local var_6_0 = arg_6_0:getTwiceAwakenTarget()

		if var_6_0 then
			local var_6_1 = var_0_3.new({
				tableID = var_0_10,
				start = var_0_1.ctx.battle.count,
				level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				fighter = arg_6_0,
				target = var_6_0
			})

			var_6_0:addBuffs({
				var_6_1
			})
			table.insert(arg_6_0.twiceTargets, var_6_0)

			arg_6_0.twiceAwakenDebuffDelay = var_0_12
		end

		arg_6_0.twiceAwakenCount = 0
	end

	local function var_6_2()
		for iter_7_0, iter_7_1 in pairs(arg_6_0.twiceTargets) do
			if not iter_7_1:getBuffByID(var_0_10) then
				for iter_7_2, iter_7_3 in pairs(var_0_11) do
					local var_7_0 = var_0_3.new({
						tableID = iter_7_3,
						start = var_0_1.ctx.battle.count,
						level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
						skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
						fighter = arg_6_0,
						target = arg_6_0
					})

					arg_6_0:addBuffs({
						var_7_0
					})
				end

				arg_6_0.twiceAwakenBigBuff = arg_6_0.twiceAwakenBigBuff + 1

				arg_6_0:getFighterModel():scale(math.min(1 + arg_6_0.twiceAwakenBigBuff * var_0_13, var_0_14))
				table.remove(arg_6_0.twiceTargets, iter_7_0)

				break
			end
		end
	end

	if arg_6_0.twiceAwakenDebuffDelay > 0 then
		arg_6_0.twiceAwakenDebuffDelay = arg_6_0.twiceAwakenDebuffDelay - 1

		if arg_6_0.twiceAwakenDebuffDelay <= 0 then
			var_6_2()
		end
	else
		var_6_2()
	end
end

function var_0_4.modelWalk(arg_8_0)
	arg_8_0:getFighterModel():walk(true)
end

function var_0_4.playAttack(arg_9_0, arg_9_1, arg_9_2)
	if not arg_9_1 then
		return
	end

	arg_9_0.skillRoll_ = var_0_6:duration(arg_9_0:getModelID(), arg_9_1)

	arg_9_0:getFighterModel():attack(arg_9_1, nil, nil, function()
		if arg_9_2 then
			arg_9_2()
		end

		if arg_9_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_9_1) then
			arg_9_0:resumeIdle()
		end
	end)
end

function var_0_4.attacked(arg_11_0)
	if arg_11_0:getFighterModel().currentAnimation_ and arg_11_0:getFighterModel().currentAnimation_ == "hurt" then
		return
	end

	local var_11_0 = var_0_6:hurtDuration(arg_11_0:getModelID())

	arg_11_0.skillRoll_ = var_11_0
	arg_11_0.unableEnergySkill_ = var_0_1.ctx.battle.count + var_11_0

	arg_11_0:getFighterModel():attacked(function()
		if arg_11_0:getFighterModel().currentAnimation_ == "hurt" then
			arg_11_0:resumeIdle()
		end
	end)
end

function var_0_4.getTwiceAwakenTarget(arg_13_0)
	if arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_13_0
		local var_13_1

		for iter_13_0, iter_13_1 in pairs(arg_13_0.sideTeam_) do
			if not var_0_15(arg_13_0.twiceTargets, iter_13_1) and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
				if not var_13_0 then
					var_13_0 = iter_13_1
					var_13_1 = iter_13_1:getHp() / iter_13_1:getHpLimit()
				end

				if not iter_13_1:isDeath() and not iter_13_1:isAffected() and (var_13_1 > iter_13_1:getHp() / iter_13_1:getHpLimit() or var_13_1 == iter_13_1:getHp() / iter_13_1:getHpLimit() and var_13_0:getHp() > iter_13_1:getHp()) then
					var_13_0 = iter_13_1
					var_13_1 = iter_13_1:getHp() / iter_13_1:getHpLimit()
				end
			end
		end

		return var_13_0
	end

	return nil
end

function var_0_4.specialAttack(arg_14_0, arg_14_1, arg_14_2)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_14_1[1]:getTeamType() == arg_14_0:getTeamType() or arg_14_1[1]:isAffected() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_14_0 = arg_14_0:createAttackUnits(arg_14_1, arg_14_2)

		for iter_14_0, iter_14_1 in ipairs(var_14_0) do
			table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
			table.insert(arg_14_0.records_.special_units, iter_14_1)
		end
	end
end

function var_0_4.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)
	local var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = var_0_4.super.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)

	if arg_15_1.skillID == arg_15_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		var_15_2 = var_15_2 + (arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_8 + var_0_7) * arg_15_1.target:getAP()
	end

	return var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5
end

return var_0_4
