local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Xuenv"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40010886
local var_0_6 = 10000803
local var_0_7 = 0.1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTargets_ = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if next(arg_2_0.awakeTargets_) then
		local var_2_0 = {}

		for iter_2_0, iter_2_1 in pairs(arg_2_0.awakeTargets_) do
			if not iter_2_0:isDeath() and not iter_2_0:isAffected() and iter_2_0:isHasBuffByID(var_0_5) and iter_2_1 and (iter_2_0:getHp() - iter_2_1) / iter_2_0:getHpLimit() >= var_0_7 then
				arg_2_0.awakeTargets_[iter_2_0] = nil

				table.insert(var_2_0, iter_2_0)
			end
		end

		if next(var_2_0) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_1 = arg_2_0:createAttackUnits(var_2_0, var_0_6)

			for iter_2_2, iter_2_3 in ipairs(var_2_1) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
				table.insert(arg_2_0.records_.special_units, iter_2_3)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and not arg_3_1.target:isHasBuffByID(var_0_5) then
		local var_3_0 = arg_3_0:newBuff({
			var_0_5
		}, arg_3_1.target, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_3_1.target:addBuffs(var_3_0)
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_5 and not arg_5_0.awakeTargets_[arg_5_1.target] then
		arg_5_0.awakeTargets_[arg_5_1.target] = arg_5_1.target:getHp()
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	var_0_3.super.buffRemoveAction(arg_6_0, arg_6_1)

	if arg_6_1:getTableID() == var_0_5 and arg_6_0.awakeTargets_[arg_6_1.target] then
		arg_6_0.awakeTargets_[arg_6_1.target] = nil
	end
end

return var_0_3
