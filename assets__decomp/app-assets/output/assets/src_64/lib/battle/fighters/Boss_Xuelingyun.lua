local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuelingyun", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.battleConfig
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 0.1
local var_0_9 = 10001071
local var_0_10 = 10001070
local var_0_11 = 4
local var_0_12 = 10001068
local var_0_13 = 10001069
local var_0_14 = 10001076
local var_0_15 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleBuffCount = {}
	arg_1_0.purpleKillCD_ = 0
	arg_1_0.greenSkillTarget_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.purpleKillCD_ >= 0 then
		arg_2_0.purpleKillCD_ = arg_2_0.purpleKillCD_ - 1
	end
end

function var_0_3.beginAttack(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0.reportSkills_[1]

		if not var_3_0 or var_0_1.ctx.battle.count ~= var_3_0.startCount_ then
			if arg_3_0.reportSkills_[2] and arg_3_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_3_0.reportSkills_, 1)
			else
				return
			end
		end
	elseif not arg_3_0:canAttack() then
		return
	end

	if arg_3_0:popSkillByType() == var_0_12 then
		arg_3_0.greenSkillTarget_ = nil
	end

	var_0_3.super.beginAttack(arg_3_0)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and not arg_4_1.target:isBoss() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_4_1.target:getHp() / arg_4_1.target:getHpLimit() < var_0_8 and arg_4_0.purpleKillCD_ <= 0 then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_9)

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end

			arg_4_0.purpleKillCD_ = var_0_15
		end
	elseif arg_4_1.skillID == var_0_12 then
		local var_4_1 = arg_4_1.target:getX()
		local var_4_2 = arg_4_1.target:getY()
		local var_4_3
		local var_4_4 = arg_4_1.target:getFlipX() and 1 or -1

		arg_4_0:flipX(arg_4_1.target:getFlipX())
		arg_4_0:x(var_4_1 + 100 * var_4_4)
		arg_4_0:y(var_4_2)
	elseif arg_4_1.skillID == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_5 = arg_4_0:selectTargetByTypeD1(arg_4_1.target)

		for iter_4_2, iter_4_3 in pairs(var_4_5) do
			if not arg_4_0.purpleBuffCount[iter_4_3] or arg_4_0.purpleBuffCount[iter_4_3] < var_0_11 then
				local var_4_6 = arg_4_0:createAttackUnits({
					iter_4_3
				}, var_0_10)

				for iter_4_4, iter_4_5 in ipairs(var_4_6) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end

				if not arg_4_0.purpleBuffCount[iter_4_3] then
					arg_4_0.purpleBuffCount[iter_4_3] = 0
				end

				arg_4_0.purpleBuffCount[iter_4_3] = arg_4_0.purpleBuffCount[iter_4_3] + 1
			end
		end

		if not arg_4_1.target:isDeath() then
			arg_4_1.target:forceDie()
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1 ~= arg_5_1 then
			table.insert(var_5_0, iter_5_1)
		end
	end

	return var_5_0
end

function var_0_3.selectTargetByTypeD2(arg_6_0)
	if arg_6_0.greenSkillTarget_ and not arg_6_0.greenSkillTarget_:isDeath() and not arg_6_0.greenSkillTarget_:isAffected() then
		return {
			arg_6_0.greenSkillTarget_
		}
	end

	local var_6_0 = arg_6_0:getX()
	local var_6_1
	local var_6_2

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getX() >= 100 and iter_6_1:getX() <= var_0_2.STAGE_WIDTH - 100 and (not var_6_1 or var_6_1 < math.abs(iter_6_1:getX() - var_6_0)) then
			var_6_2 = iter_6_1
			var_6_1 = math.abs(iter_6_1:getX() - var_6_0)
		end
	end

	if var_6_2 then
		arg_6_0.greenSkillTarget_ = var_6_2

		return {
			var_6_2
		}
	else
		return {}
	end
end

return var_0_3
