local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caiwenji", var_0_1.ctx.battle.requireFighter("Caiwenji"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.2
local var_0_7 = 40010663
local var_0_8 = 40010662
local var_0_9 = 180
local var_0_10 = 40012059
local var_0_11 = 8000
local var_0_12 = 320
local var_0_13 = 0.01
local var_0_14 = 0.5

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.awakeReflectHarm_ = {}
	arg_2_0.records_.reflect = {}
	arg_2_0.awakeColdCounts = {}
	arg_2_0.awakeTwiceTag = false
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

	if var_3_0 > 0 then
		local var_3_1 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)

		arg_3_0.awakeProb = var_0_5:init(var_3_1) + var_0_5:step(var_3_1) * var_3_0
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.awakeColdCounts) do
		arg_4_0.awakeColdCounts[iter_4_0] = iter_4_1 - 1

		if iter_4_1 <= 1 then
			table.insert(var_4_0, iter_4_0)
		end
	end

	for iter_4_2, iter_4_3 in ipairs(var_4_0) do
		arg_4_0.awakeColdCounts[iter_4_3] = nil
	end

	local var_4_1 = {}
	local var_4_2 = {}

	for iter_4_4, iter_4_5 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
		local var_4_3 = arg_4_0:getTeamType()
		local var_4_4 = iter_4_5.fighter
		local var_4_5 = iter_4_5.target
		local var_4_6 = var_4_4:getSummonType() == var_0_2.summonMonsterType.None and var_4_4:getTeamType() ~= var_4_3
		local var_4_7 = var_4_5:getSummonType() == var_0_2.summonMonsterType.None and var_4_5:getTeamType() == var_4_3

		if var_4_6 and var_4_7 and not arg_4_0.awakeColdCounts[var_4_4] then
			if not var_4_1[var_4_4] then
				var_4_1[var_4_4] = {}
				var_4_2[var_4_4] = {}
			end

			if not var_4_1[var_4_4][var_4_5] then
				var_4_1[var_4_4][var_4_5] = 0
				var_4_2[var_4_4][var_4_5] = {}
			end

			var_4_1[var_4_4][var_4_5] = var_4_1[var_4_4][var_4_5] + iter_4_5.harm

			if iter_4_5.type == var_0_2.AttackType.AD then
				var_4_2[var_4_4][var_4_5].ad = true
			elseif iter_4_5.type == var_0_2.AttackType.AP then
				var_4_2[var_4_4][var_4_5].ap = true
			end
		end
	end

	for iter_4_6, iter_4_7 in pairs(var_4_1) do
		local var_4_8 = 0
		local var_4_9 = false
		local var_4_10 = false

		for iter_4_8, iter_4_9 in pairs(iter_4_7) do
			local var_4_11
			local var_4_12 = var_0_2.split(iter_4_6.fighterIndex, "|")
			local var_4_13 = var_0_2.split(iter_4_8.fighterIndex, "|")
			local var_4_14 = tostring(var_4_12[2])
			local var_4_15 = tostring(var_4_13[2])

			if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
				if arg_4_0.reflectRecord[var_4_14] and arg_4_0.reflectRecord[var_4_14][var_4_15] and arg_4_0.reflectRecord[var_4_14][var_4_15][tostring(var_0_1.ctx.battle.count)] then
					var_4_11 = true
				end
			else
				var_4_11 = var_0_2.weightedChoise({
					arg_4_0.awakeProb,
					1 - arg_4_0.awakeProb
				}) == 1

				if var_4_11 then
					if not arg_4_0.records_.reflect[var_4_14] then
						arg_4_0.records_.reflect[var_4_14] = {}
					end

					if not arg_4_0.records_.reflect[var_4_14][var_4_15] then
						arg_4_0.records_.reflect[var_4_14][var_4_15] = {}
					end

					arg_4_0.records_.reflect[var_4_14][var_4_15][tostring(var_0_1.ctx.battle.count)] = true
				end
			end

			if var_4_11 then
				var_4_8 = var_4_8 + iter_4_9

				local var_4_16 = var_4_2[iter_4_6][iter_4_8]

				if var_4_16.ad then
					var_4_9 = true
				end

				if var_4_16.ap then
					var_4_10 = true
				end
			end
		end

		if var_4_8 > 0 and not iter_4_6:isAffected() then
			arg_4_0.awakeColdCounts[iter_4_6] = var_0_9

			if not arg_4_0.awakeReflectHarm_[iter_4_6] then
				arg_4_0.awakeReflectHarm_[iter_4_6] = var_4_8
			else
				arg_4_0.awakeReflectHarm_[iter_4_6] = arg_4_0.awakeReflectHarm_[iter_4_6] + var_4_8
			end

			if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
				local var_4_17 = arg_4_0:createAttackUnits({
					iter_4_6
				}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				for iter_4_10, iter_4_11 in ipairs(var_4_17) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_11)
					table.insert(arg_4_0.records_.special_units, iter_4_11)
				end
			end

			if var_4_9 then
				local var_4_18 = var_0_4.new({
					tableID = var_0_7,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
					fighter = arg_4_0,
					target = iter_4_6
				})

				iter_4_6:addBuffs({
					var_4_18
				})
			end

			if var_4_10 then
				local var_4_19 = var_0_4.new({
					tableID = var_0_8,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
					fighter = arg_4_0,
					target = iter_4_6
				})

				iter_4_6:addBuffs({
					var_4_19
				})
			end
		end
	end

	for iter_4_12, iter_4_13 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_13:isDeath() and iter_4_13:isHasBuffByID(var_0_10) then
			local var_4_20 = iter_4_13:getBuffByID(var_0_10)
			local var_4_21 = var_4_20:getDHarm()
			local var_4_22 = var_4_20:totalDHarm()
			local var_4_23 = math.min(var_0_13, var_4_21 / var_4_22 - var_0_14)
			local var_4_24 = math.max(var_4_23, 0)

			var_4_20.dHarm_ = var_4_20.dHarm_ - var_4_24 * var_4_22
		end
	end
end

function var_0_3.calculateUnitData(arg_5_0, arg_5_1)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.calculateUnitData(arg_5_0, arg_5_1)

	if var_5_2 > 0 and arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) and arg_5_0.awakeReflectHarm_[arg_5_1.target] then
		var_5_2 = arg_5_0.awakeReflectHarm_[arg_5_1.target] * var_0_6 * arg_5_1.target:getADJianShang()
		arg_5_0.awakeReflectHarm_[arg_5_1.target] = 0
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.reflectRecord = arg_6_1.reflect
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.reflect = arg_7_0.records_.reflect

	return var_7_0
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1:getTableID() == var_0_10 then
		arg_8_1.manualDharm = var_0_11 + var_0_12 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	end

	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)
end

function var_0_3.energyActionBySpecialHero(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and not arg_9_0.awakeTwiceTag and arg_9_1:getTeamType() ~= arg_9_0:getTeamType() then
		arg_9_0.awakeTwiceTag = true

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
			if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
				local var_9_0 = arg_9_0:createNewBuffs({
					var_0_10
				}, iter_9_1, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				iter_9_1:addBuffs(var_9_0)
			end
		end
	end
end

return var_0_3
