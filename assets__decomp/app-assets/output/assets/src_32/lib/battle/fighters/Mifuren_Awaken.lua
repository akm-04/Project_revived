local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mifuren", var_0_1.ctx.battle.requireFighter("Mifuren"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.1
local var_0_7 = 0.002
local var_0_8 = 40011539
local var_0_9 = 10002251
local var_0_10 = 10002252

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.AwakenAbsorbedHarm = 0
	arg_1_0.AwakenBuffOn = false
	arg_1_0.AwakenBuffOn2 = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.AwakenBuffOn then
		arg_2_0:addBuffs({
			var_0_4.new({
				tableID = var_0_8,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
				skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
				fighter = arg_2_0,
				target = arg_2_0
			})
		})

		arg_2_0.AwakenBuffOn = true
	end
end

function var_0_3.updateHp(arg_3_0, arg_3_1, arg_3_2)
	var_0_3.super.updateHp(arg_3_0, arg_3_1, arg_3_2)

	if arg_3_0:getHp() < arg_3_0:getHpLimit() * 0.5 and not arg_3_0.AwakenBuffOn2 then
		arg_3_0:addBuffs({
			var_0_4.new({
				tableID = var_0_8,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
				fighter = arg_3_0,
				target = arg_3_0
			})
		})

		arg_3_0.AwakenBuffOn2 = true
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	var_0_3.super.buffRemoveAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_8 and arg_4_1.target == arg_4_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_0.purpleBuffTarget
		}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			iter_4_1:setExtraHarm(arg_4_0.AwakenAbsorbedHarm)
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end

		arg_4_0.AwakenAbsorbedHarm = 0
	end
end

function var_0_3.forceDie(arg_5_0)
	var_0_3.super.forceDie(arg_5_0)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0.purpleBuffTarget
		}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			iter_5_1:setExtraHarm(arg_5_0.AwakenAbsorbedHarm)
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end

		arg_5_0.AwakenAbsorbedHarm = 0
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_1.target == arg_6_0 and arg_6_0:isHasBuffByID(var_0_8) and arg_6_4 > 0 then
		local var_6_0 = math.min(arg_6_4, arg_6_4 * (var_0_6 + var_0_7 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)))

		arg_6_0.AwakenAbsorbedHarm = arg_6_0.AwakenAbsorbedHarm + var_6_0
		arg_6_4 = arg_6_4 - var_6_0
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)

	if arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_1.rootID_ ~= var_0_9 and arg_7_1.rootID_ ~= var_0_10 and arg_7_1.rootID_ ~= arg_7_0:getPugongID() then
		if math.random(2) == 1 then
			local var_7_0 = arg_7_0:createAttackUnits({
				arg_7_0
			}, var_0_9)

			for iter_7_0, iter_7_1 in ipairs(var_7_0) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		else
			local var_7_1 = arg_7_0:createAttackUnits({
				arg_7_0
			}, var_0_10)

			for iter_7_2, iter_7_3 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end
end

return var_0_3
