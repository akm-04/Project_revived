local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahouba", var_0_1.ctx.battle.requireFighter("Xiahouba"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40010420
local var_0_7 = 0.05
local var_0_8 = 0.0005
local var_0_9 = 40011012
local var_0_10 = 40011013
local var_0_11 = 10000913
local var_0_12 = 80

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceTargets_ = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and next(arg_2_0.summonMonsters_) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_2_0 = #arg_2_0.summonMonsters_, 1, -1 do
			local var_2_0 = arg_2_0.summonMonsters_[iter_2_0]

			if var_2_0:isDeath() then
				table.remove(arg_2_0.summonMonsters_, iter_2_0)
			else
				arg_2_0:checkAwakeTwcieSkill(var_2_0)
			end
		end
	end
end

function var_0_3.checkAwakeTwcieSkill(arg_3_0, arg_3_1)
	local var_3_0 = var_0_5:scope(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)) / 2
	local var_3_1 = arg_3_1:getX()
	local var_3_2 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and (not arg_3_0.awakeTwiceTargets_[iter_3_1] or var_0_1.ctx.battle.count - arg_3_0.awakeTwiceTargets_[iter_3_1] >= var_0_12) and var_3_0 >= math.abs(iter_3_1:getX() - var_3_1) then
			table.insert(var_3_2, iter_3_1)

			arg_3_0.awakeTwiceTargets_[iter_3_1] = var_0_1.ctx.battle.count
		end
	end

	if next(var_3_2) then
		local var_3_3 = arg_3_0:createAttackUnits(var_3_2, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		for iter_3_2, iter_3_3 in ipairs(var_3_3) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_0
		}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		local var_5_0 = arg_5_1.skillID
		local var_5_1 = var_0_4.new({
			tableID = var_0_6,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(var_5_0),
			skillID = var_5_0,
			fighter = arg_5_0,
			target = arg_5_0
		})

		var_5_1:setIsHit(true)
		var_5_1:setDirection(arg_5_0:getFighterModel():getFlipX())

		local var_5_2 = arg_5_0:getSelfTeamMaxHarm()

		var_5_1.manualDharm = math.min(var_5_2 * (var_0_7 + var_0_8 * arg_5_0:getSkillLevelByID(var_5_0)), arg_5_0:getHpLimit())

		arg_5_0:addBuffs({
			var_5_1
		})
	end
end

function var_0_3.getSelfTeamMaxHarm(arg_6_0)
	local var_6_0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_6_0 or var_6_0 < iter_6_1.harms) then
			var_6_0 = iter_6_1.harms
		end
	end

	return var_6_0
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	var_0_3.super.buffRemoveAction(arg_7_0, arg_7_1)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_7_1:getTableID() == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not arg_7_1.target:isDeath() and #arg_7_1.target:getBuffsByID(var_0_10) == 2 then
		local var_7_0 = {}
		local var_7_1 = var_0_5:scope(var_0_11) / 2
		local var_7_2 = arg_7_1.target:getX()

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and var_7_1 >= math.abs(iter_7_1:getX() - var_7_2) then
				table.insert(var_7_0, iter_7_1)
			end
		end

		if next(var_7_0) then
			local var_7_3 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_11)

			for iter_7_2, iter_7_3 in ipairs(var_7_3) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end

		arg_7_1.target:removeBuffByID(var_0_10)
	end
end

return var_0_3
