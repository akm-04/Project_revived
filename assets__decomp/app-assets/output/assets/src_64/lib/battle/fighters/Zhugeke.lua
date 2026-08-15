local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhugeke", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 10001116
local var_0_12 = 10001119
local var_0_13 = 0.2
local var_0_14 = 300
local var_0_15 = 10001127
local var_0_16 = 40011226
local var_0_17 = 40011227
local var_0_18 = 40011235
local var_0_19 = 10001118
local var_0_20 = 10001117
local var_0_21 = 10001129
local var_0_22 = 10001128
local var_0_23 = 40011225
local var_0_24 = 40011224
local var_0_25 = 10001124
local var_0_26 = 10001123
local var_0_27 = 10002235
local var_0_28 = 10002234
local var_0_29 = 12

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenSelfTarget = nil
	arg_2_0.greenTargetHpRate = 0
	arg_2_0.greenTargets = {}
	arg_2_0.isUseGreenTarget = {}
	arg_2_0.blueHramInfo = {}
	arg_2_0.isInitBlue = false
	arg_2_0.harmInfo = {}
	arg_2_0.isInit = false
	arg_2_0.blueSkillCount = var_0_14
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.isInitBlue then
		arg_3_0.isInitBlue = true

		for iter_3_0, iter_3_1 in pairs(arg_3_0.sideTeam_) do
			arg_3_0.blueHramInfo[iter_3_1] = 0
		end
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
		local var_3_0 = iter_3_3.harm
		local var_3_1 = iter_3_3.fighter

		if not arg_3_0.harmInfo[var_3_1] then
			arg_3_0.harmInfo[var_3_1] = var_3_0
		else
			arg_3_0.harmInfo[var_3_1] = arg_3_0.harmInfo[var_3_1] + var_3_0
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		arg_3_0.blueSkillCount = arg_3_0.blueSkillCount - 1

		if arg_3_0.blueSkillCount < 1 and not arg_3_0:isBattleUnable() and not arg_3_0:isCreatingUnits() and not var_0_1.ctx.battle.isEnergySkilling and not var_0_1.ctx.battle.walk2NextBattle_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_2 = -1
			local var_3_3

			for iter_3_4, iter_3_5 in pairs(arg_3_0.sideTeam_) do
				if not iter_3_5:isDeath() and var_3_2 < (arg_3_0.harmInfo[iter_3_5] or 0) - (arg_3_0.blueHramInfo[iter_3_5] or 0) then
					var_3_2 = (arg_3_0.harmInfo[iter_3_5] or 0) - (arg_3_0.blueHramInfo[iter_3_5] or 0)
					var_3_3 = iter_3_5
				end
			end

			local var_3_4 = var_0_8:sound(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			var_0_1.ctx.battle.pushSoundQueue(var_3_4)

			local var_3_5 = var_0_8:attackIndex(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_3_0:playAttack(var_3_5)

			arg_3_0.unitSkills_ = var_0_5.new({
				fighter = arg_3_0,
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
			})

			arg_3_0:beginAttackEnd(arg_3_0.unitSkills_)

			local var_3_6 = arg_3_0:createAttackUnits({
				var_3_3
			}, var_0_15)

			for iter_3_6, iter_3_7 in ipairs(var_3_6) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
				table.insert(arg_3_0.records_.special_units, iter_3_7)
			end

			for iter_3_8, iter_3_9 in pairs(arg_3_0.sideTeam_) do
				if not iter_3_9:isDeath() then
					arg_3_0.blueHramInfo[iter_3_9] = arg_3_0.harmInfo[iter_3_9] or 0
				end
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_4_0.blueSkillCount = var_0_14
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.skillID

	if var_5_0 == var_0_15 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_1 = var_0_7.new({
			tableID = var_0_16,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)),
			skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
			fighter = arg_5_0,
			target = arg_5_1.target,
			manualRevise = arg_5_1.target:getAP() - arg_5_1.target:getAD()
		})
		local var_5_2 = var_0_7.new({
			tableID = var_0_17,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)),
			skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
			fighter = arg_5_0,
			target = arg_5_1.target,
			manualRevise = arg_5_1.target:getAD() - arg_5_1.target:getAP()
		})

		arg_5_1.target:addBuffs({
			var_5_1
		})
		arg_5_1.target:addBuffs({
			var_5_2
		})

		if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			local var_5_3 = arg_5_0:createAttackUnits({
				arg_5_1.target
			}, var_0_25)

			for iter_5_0, iter_5_1 in ipairs(var_5_3) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end

		if arg_5_0.skinSkillIndex_ == 1 then
			local var_5_4 = arg_5_0:createAttackUnits({
				arg_5_1.target
			}, var_0_27)

			for iter_5_2, iter_5_3 in ipairs(var_5_4) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
				table.insert(arg_5_0.records_.special_units, iter_5_3)
			end
		end
	elseif var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_5_4, iter_5_5 in pairs(arg_5_0.sideTeam_) do
			if not iter_5_5:isDeath() and not iter_5_5:isAffected() then
				if math.random(2) == 1 then
					local var_5_5 = arg_5_0:createAttackUnits({
						iter_5_5
					}, var_0_19)

					for iter_5_6, iter_5_7 in ipairs(var_5_5) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_7)
						table.insert(arg_5_0.records_.special_units, iter_5_7)
					end
				else
					local var_5_6 = arg_5_0:createAttackUnits({
						iter_5_5
					}, var_0_20)

					for iter_5_8, iter_5_9 in ipairs(var_5_6) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_9)
						table.insert(arg_5_0.records_.special_units, iter_5_9)
					end
				end
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_18 then
		local var_6_0 = {}

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			local var_6_1 = {}

			for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
				if not iter_6_1:isDeath() and (iter_6_1:isHasBuffByID(var_0_23) or iter_6_1:isHasBuffByID(var_0_24)) then
					table.insert(var_6_0, iter_6_1)
				end
			end

			for iter_6_2, iter_6_3 in ipairs(var_6_0) do
				table.insert(var_6_1, cc.p(iter_6_3:getPos()))
			end

			for iter_6_4, iter_6_5 in ipairs(var_6_0) do
				local var_6_2 = math.random(#var_6_1)

				iter_6_5:pos(var_6_1[var_6_2].x, var_6_1[var_6_2].y)
				table.remove(var_6_1, var_6_2)
			end
		end

		if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_3 = arg_6_0:createAttackUnits(var_6_0, var_0_25)

			for iter_6_6, iter_6_7 in ipairs(var_6_3) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_7)
				table.insert(arg_6_0.records_.special_units, iter_6_7)
			end
		end

		if arg_6_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_4 = arg_6_0:createAttackUnits(var_6_0, var_0_27)

			for iter_6_8, iter_6_9 in ipairs(var_6_4) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_9)
				table.insert(arg_6_0.records_.special_units, iter_6_9)
			end
		end
	elseif arg_6_1:getTableID() == var_0_23 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_5 = arg_6_0:createAttackUnits({
			arg_6_1.target
		}, var_0_21)

		for iter_6_10, iter_6_11 in ipairs(var_6_5) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_11)
			table.insert(arg_6_0.records_.special_units, iter_6_11)
		end
	elseif arg_6_1:getTableID() == var_0_24 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_6 = arg_6_0:createAttackUnits({
			arg_6_1.target
		}, var_0_22)

		for iter_6_12, iter_6_13 in ipairs(var_6_6) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_13)
			table.insert(arg_6_0.records_.special_units, iter_6_13)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_4 > 0 and arg_7_1.skillID == var_0_11 and arg_7_0.greenSelfTarget and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_7_4 = math.abs(arg_7_1.target:getHp() / arg_7_1.target:getHpLimit() - arg_7_0.greenTargetHpRate) * arg_7_0.greenSelfTarget:getHpLimit() * var_0_13

		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_0.greenSelfTarget
		}, var_0_12)

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			iter_7_1.cureHp = arg_7_4

			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			local var_7_1 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_25)

			for iter_7_2, iter_7_3 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end

		if arg_7_0.skinSkillIndex_ == 1 then
			local var_7_2 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_27)

			for iter_7_4, iter_7_5 in ipairs(var_7_2) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
				table.insert(arg_7_0.records_.special_units, iter_7_5)
			end
		end
	elseif arg_7_1.skillID == var_0_12 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_7_5 = arg_7_1.cureHp

		if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			local var_7_3 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_26)

			for iter_7_6, iter_7_7 in ipairs(var_7_3) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_7)
				table.insert(arg_7_0.records_.special_units, iter_7_7)
			end
		end

		if arg_7_0.skinSkillIndex_ == 1 then
			local var_7_4 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_28)

			for iter_7_8, iter_7_9 in ipairs(var_7_4) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_9)
				table.insert(arg_7_0.records_.special_units, iter_7_9)
			end
		end
	elseif arg_7_1.skillID == var_0_28 then
		arg_7_5 = arg_7_5 + var_0_29 * arg_7_0.hero_:getLevel()
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.selectTargetByTypeD1(arg_8_0)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getHp() / iter_8_1:getHpLimit() < 0.5 then
			table.insert(var_8_0, iter_8_1)
		end
	end

	if not next(var_8_0) then
		local var_8_1
		local var_8_2

		for iter_8_2, iter_8_3 in pairs(arg_8_0.selfTeam_) do
			if not iter_8_3:isDeath() and not iter_8_3:isAffected() and (not var_8_1 or var_8_2 > iter_8_3:getHp() / iter_8_3:getHpLimit()) then
				var_8_1 = iter_8_3
				var_8_2 = var_8_1:getHp() / var_8_1:getHpLimit()
			end
		end

		table.insert(var_8_0, var_8_1)
	end

	local var_8_3 = var_8_0[math.random(#var_8_0)]

	if var_8_3 then
		arg_8_0.greenSelfTarget = var_8_3
		arg_8_0.greenTargetHpRate = var_8_3:getHp() / var_8_3:getHpLimit()

		for iter_8_4, iter_8_5 in pairs(arg_8_0.sideTeam_) do
			if not iter_8_5:isDeath() and not iter_8_5:isAffected() and arg_8_0.greenTargetHpRate < iter_8_5:getHp() / iter_8_5:getHpLimit() then
				table.insert(arg_8_0.greenTargets, iter_8_5)

				arg_8_0.isUseGreenTarget[iter_8_5] = 0
			end
		end
	end

	return {
		var_8_3
	}
end

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	if not arg_9_2 and next(arg_9_0.greenTargets) and arg_9_0.isUseGreenTarget[arg_9_0.greenTargets[1]] and arg_9_0.isUseGreenTarget[arg_9_0.greenTargets[1]] == 0 then
		arg_9_0.isUseGreenTarget[arg_9_0.greenTargets[1]] = 1

		return {
			arg_9_0.greenTargets[1]
		}
	end

	if not arg_9_2 or not arg_9_2.targets_ or not next(arg_9_2.targets_) then
		return {}
	end

	for iter_9_0, iter_9_1 in pairs(arg_9_0.greenTargets) do
		if arg_9_0.isUseGreenTarget[iter_9_1] == 0 then
			arg_9_0.isUseGreenTarget[iter_9_1] = 1

			return {
				iter_9_1
			}
		end
	end

	arg_9_2:clearCollisionNum()

	arg_9_0.greenTargets = {}
	arg_9_0.isUseGreenTarget = {}
	arg_9_0.greenSelfTarget = nil
	arg_9_0.greenTargetHpRate = 0

	return {}
end

return var_0_3
