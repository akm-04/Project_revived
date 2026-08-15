local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuelingyun", var_0_1.ctx.battle.getRequire("BaseFighter"))
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
local var_0_16 = var_0_2.tables.cabinetSkillTable
local var_0_17 = 20040006
local var_0_18 = 80010187
local var_0_19 = 0.05
local var_0_20 = 10000

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleBuffCount = {}
	arg_1_0.purpleKillCD_ = 0
	arg_1_0.greenSkillTarget_ = nil
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel1 = 0
	arg_1_0.addMoKangRate = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel1 = arg_2_0.hero_:skillBook()[tostring(var_0_17)] or 0
		arg_2_0.addMoKangRate = arg_2_0.extraSkillLevel1 * var_0_16:attrValues(var_0_17) * 0.01
	end

	if arg_2_0.purpleKillCD_ >= 0 then
		arg_2_0.purpleKillCD_ = arg_2_0.purpleKillCD_ - 1
	end
end

function var_0_3.getMoKang(arg_3_0)
	local var_3_0 = var_0_3.super.getMoKang(arg_3_0)

	if arg_3_0.extraSkillLevel1 > 0 then
		var_3_0 = var_3_0 + arg_3_0:getHuJia() * arg_3_0.addMoKangRate
	end

	return var_3_0
end

function var_0_3.beginAttack(arg_4_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0.reportSkills_[1]

		if not var_4_0 or var_0_1.ctx.battle.count ~= var_4_0.startCount_ then
			if arg_4_0.reportSkills_[2] and arg_4_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_4_0.reportSkills_, 1)
			else
				return
			end
		end
	elseif not arg_4_0:canAttack() then
		return
	end

	if arg_4_0:popSkillByType() == var_0_12 then
		arg_4_0.greenSkillTarget_ = nil
	end

	var_0_3.super.beginAttack(arg_4_0)
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and not arg_5_1.target:isBoss() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_5_1.target:getHp() / arg_5_1.target:getHpLimit() < var_0_8 and arg_5_0.purpleKillCD_ <= 0 then
			local var_5_0 = arg_5_0:createAttackUnits({
				arg_5_1.target
			}, var_0_9)

			for iter_5_0, iter_5_1 in ipairs(var_5_0) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end

			arg_5_0.purpleKillCD_ = var_0_15
		end
	elseif arg_5_1.skillID == var_0_12 then
		local var_5_1 = arg_5_1.target:getX()
		local var_5_2 = arg_5_1.target:getY()
		local var_5_3
		local var_5_4 = arg_5_1.target:getFlipX() and 1 or -1

		arg_5_0:flipX(arg_5_1.target:getFlipX())
		arg_5_0:x(var_5_1 + 100 * var_5_4)
		arg_5_0:y(var_5_2)
	elseif arg_5_1.skillID == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_5 = arg_5_0:selectTargetByTypeD1(arg_5_1.target)

		for iter_5_2, iter_5_3 in pairs(var_5_5) do
			if not arg_5_0.purpleBuffCount[iter_5_3] or arg_5_0.purpleBuffCount[iter_5_3] < var_0_11 then
				local var_5_6 = arg_5_0:createAttackUnits({
					iter_5_3
				}, var_0_10)

				for iter_5_4, iter_5_5 in ipairs(var_5_6) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
					table.insert(arg_5_0.records_.special_units, iter_5_5)
				end

				if not arg_5_0.purpleBuffCount[iter_5_3] then
					arg_5_0.purpleBuffCount[iter_5_3] = 0
				end

				arg_5_0.purpleBuffCount[iter_5_3] = arg_5_0.purpleBuffCount[iter_5_3] + 1
			end
		end

		if not arg_5_1.target:isDeath() then
			arg_5_1.target:forceDie()
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1 ~= arg_6_1 then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

function var_0_3.selectTargetByTypeD2(arg_7_0)
	if arg_7_0.greenSkillTarget_ and not arg_7_0.greenSkillTarget_:isDeath() and not arg_7_0.greenSkillTarget_:isAffected() then
		return {
			arg_7_0.greenSkillTarget_
		}
	end

	local var_7_0 = arg_7_0:getX()
	local var_7_1
	local var_7_2

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:getX() >= 100 and iter_7_1:getX() <= var_0_2.STAGE_WIDTH - 100 and (not var_7_1 or var_7_1 < math.abs(iter_7_1:getX() - var_7_0)) then
			var_7_2 = iter_7_1
			var_7_1 = math.abs(iter_7_1:getX() - var_7_0)
		end
	end

	if var_7_2 then
		arg_7_0.greenSkillTarget_ = var_7_2

		return {
			var_7_2
		}
	else
		return {}
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if arg_8_4 > 0 and arg_8_0.skinSkillID_ == var_0_18 then
		arg_8_4 = arg_8_4 + math.min(var_0_20, arg_8_1.target:getHp() * var_0_19)
	end

	return var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
end

return var_0_3
