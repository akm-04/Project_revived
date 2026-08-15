local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Paradise_Mizhu", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10000670
local var_0_6 = 10010162
local var_0_7 = 40010677
local var_0_8 = 10000669
local var_0_9 = 60

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.blueCD_ = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_3_0.energyMoveUnit_ and not arg_3_0.energyMoveUnit_.arrived and var_0_1.ctx.battle.count % 30 < 1 then
			local var_3_0 = arg_3_0:getEnergyTargets()
			local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_5)

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end

		for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("unit_info")) do
			local var_3_2 = iter_3_3.fighter

			if iter_3_3.target == arg_3_0 and var_3_2:getTeamType() ~= arg_3_0:getTeamType() and not var_3_2:isDeath() and not var_3_2:isAffected() and arg_3_0:isHasBuffByID(var_0_7) and not arg_3_0.blueCD_[var_3_2] then
				local var_3_3 = arg_3_0:createAttackUnits({
					var_3_2
				}, var_0_8)

				for iter_3_4, iter_3_5 in ipairs(var_3_3) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
					table.insert(arg_3_0.records_.special_units, iter_3_5)
				end

				arg_3_0.blueCD_[var_3_2] = var_0_9
			end
		end

		local var_3_4 = {}

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
			for iter_3_6, iter_3_7 in pairs(arg_3_0.blueCD_) do
				arg_3_0.blueCD_[iter_3_6] = iter_3_7 - 1

				if iter_3_7 <= 1 then
					table.insert(var_3_4, iter_3_6)
				end
			end
		end

		for iter_3_8, iter_3_9 in ipairs(var_3_4) do
			arg_3_0.blueCD_[iter_3_9] = nil
		end
	end
end

function var_0_3.unitAfterCreate(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_1 and arg_4_1.skillID == arg_4_0:getEnergySkillID() then
		arg_4_0.energyMoveUnit_ = arg_4_1
	end
end

function var_0_3.getEnergyTargets(arg_5_0)
	if not arg_5_0.energyMoveUnit_ or arg_5_0.energyMoveUnit_.arrived then
		return {}
	end

	local var_5_0 = var_0_4:scope(arg_5_0.energyMoveUnit_.skillID)
	local var_5_1 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and math.abs(iter_5_1:getX() - arg_5_0.energyMoveUnit_:getX()) < var_5_0 / 2 then
			table.insert(var_5_1, iter_5_1)
		end
	end

	return var_5_1
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_6 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_1:getRemoveSkill()
		local var_6_1 = var_0_4:scope(var_6_0)
		local var_6_2 = {}

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_1 > math.abs(arg_6_1.target:getX() - iter_6_1:getX()) then
				table.insert(var_6_2, iter_6_1)
			end
		end

		local var_6_3 = arg_6_0:createAttackUnits(var_6_2, var_6_0)

		for iter_6_2, iter_6_3 in ipairs(var_6_3) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
			table.insert(arg_6_0.records_.special_units, iter_6_3)
		end
	end
end

return var_0_3
