local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yanyue", var_0_1.ctx.battle.requireFighter("Yanyue"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40011272
local var_0_8 = 16
local var_0_9 = 0.15
local var_0_10 = 10000403
local var_0_11 = 0
local var_0_12 = 25
local var_0_13 = 0.8

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isAddKillBuff = false
	arg_1_0.killTarget = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and not arg_2_0.isAddKillBuff then
		arg_2_0.isAddKillBuff = true

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and (not arg_2_0.killTarget or iter_2_1:getAttrByType(var_0_2.AttributeType.STRENGTH) < arg_2_0.killTarget:getAttrByType(var_0_2.AttributeType.STRENGTH)) then
				arg_2_0.killTarget = iter_2_1
			end
		end

		if arg_2_0.killTarget then
			local var_2_0 = var_0_5.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getSkillLevelByID(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)),
				skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				fighter = arg_2_0,
				target = arg_2_0.killTarget
			})

			arg_2_0.killTarget:addBuffs({
				var_2_0
			})
		end
	end
end

function var_0_3.deathFeedback(arg_3_0, arg_3_1)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_1:isHasBuffByID(var_0_7) then
		arg_3_0.killTarget = nil

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_1 and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None and (not arg_3_0.killTarget or iter_3_1:getAttrByType(var_0_2.AttributeType.STRENGTH) < arg_3_0.killTarget:getAttrByType(var_0_2.AttributeType.STRENGTH)) then
				arg_3_0.killTarget = iter_3_1
			end
		end

		if arg_3_0.killTarget then
			local var_3_0 = var_0_5.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByID(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				fighter = arg_3_0,
				target = arg_3_0.killTarget
			})

			arg_3_0.killTarget:addBuffs({
				var_3_0
			})
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_0.killTarget and not arg_4_0.killTarget:isDeath() and not arg_4_0.killTarget:isAffected() then
		return {
			arg_4_0.killTarget
		}
	end

	local var_4_0
	local var_4_1 = 0
	local var_4_2 = var_0_6:distance(arg_4_1)

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_4_3 = math.abs(arg_4_0:getX() - iter_4_1:getX())

			if var_4_3 <= var_4_2 and var_4_1 < var_4_3 then
				var_4_0 = iter_4_1
				var_4_1 = var_4_3
			end
		end
	end

	return {
		var_4_0
	}
end

function var_0_3.selectTargetByTypeB4(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_0.killTarget and not arg_5_0.killTarget:isDeath() and not arg_5_0.killTarget:isAffected() then
		return {
			arg_5_0.killTarget
		}
	end

	return var_0_4.B4(arg_5_0, arg_5_1, arg_5_2)
end

function var_0_3.calculateUnitData(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.target

	if var_6_0:getTeamType() ~= arg_6_0:getTeamType() and arg_6_0.awakeSkillNum_ >= 2 then
		arg_6_0.awakeSkillNum_ = 0

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_1 = arg_6_0:createAttackUnits({
				var_6_0
			}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_6_0, iter_6_1 in ipairs(var_6_1) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	end

	local var_6_2, var_6_3, var_6_4, var_6_5, var_6_6, var_6_7 = var_0_3.super.calculateUnitData(arg_6_0, arg_6_1)
	local var_6_8 = arg_6_1.target

	if not var_6_2 and var_6_4 > 0 and arg_6_1.skillID ~= var_0_10 and arg_6_0.killTarget and var_6_8 == arg_6_0.killTarget then
		if var_6_8:getTeamType() ~= arg_6_0:getTeamType() and arg_6_0:getFlipX() ~= var_6_8:getFlipX() and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
			var_6_4 = var_6_4 + (var_0_11 + var_0_12 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
			arg_6_0.blueSkillNum_ = arg_6_0.blueSkillNum_ + 1

			if arg_6_0.blueSkillNum_ >= 2 then
				arg_6_0.blueSkillNum_ = 0
				arg_6_0.awakeSkillNum_ = arg_6_0.awakeSkillNum_ + 1

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_6_9 = arg_6_0:createAttackUnits({
						var_6_8
					}, var_0_10)

					for iter_6_2, iter_6_3 in ipairs(var_6_9) do
						table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
						table.insert(arg_6_0.records_.special_units, iter_6_3)
					end
				end
			end
		end

		var_6_4 = var_6_4 + var_0_8 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) + var_0_9 * arg_6_0:getAD()
	end

	return var_6_2, var_6_3, var_6_4, var_6_5, var_6_6, var_6_7
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	if arg_7_2 > 0 and arg_7_0.killTarget and not arg_7_0.killTarget:isDeath() and arg_7_1.fighter ~= arg_7_0.killTarget then
		arg_7_2 = var_0_13 * arg_7_2
	end

	return var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
end

return var_0_3
