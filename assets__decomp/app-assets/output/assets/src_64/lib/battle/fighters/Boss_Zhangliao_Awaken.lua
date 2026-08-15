local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangliao", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 90030009
local var_0_9 = 90030008
local var_0_10 = 10010067
local var_0_11 = true
local var_0_12

function var_0_3.buffAddAction(arg_1_0, arg_1_1)
	if var_0_11 and arg_1_1.skillID_ == var_0_8 then
		var_0_12 = var_0_7:time(var_0_5:buffs(var_0_8)[1])

		for iter_1_0, iter_1_1 in pairs(var_0_5:buffs(var_0_9)) do
			local var_1_0 = arg_1_0:getBuffByID(iter_1_1)

			if var_1_0 then
				arg_1_0:removeBuffs(var_1_0)
			end
		end

		var_0_11 = false
	end
end

function var_0_3.singleLoop(arg_2_0)
	arg_2_0:updateBaseInfo()
	arg_2_0:checkMove()

	if not arg_2_0:isDeath() then
		arg_2_0:createAttacks()
	end

	arg_2_0:beginAttack()

	if arg_2_0:acttionInBlack() and (not arg_2_0.unitSkills_ or arg_2_0.unitSkills_.rootID_ ~= var_0_8) then
		arg_2_0:applyUnitMoves()
		arg_2_0:applyUnitHarms()
		arg_2_0:applyBuffHarms()

		if not var_0_11 then
			var_0_12 = var_0_12 - 1

			if var_0_12 == 0 then
				arg_2_0:addShiled()
			end
		end
	end

	arg_2_0:applyBuffMoves()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_2_0.reportDieCount_ > 0 and var_0_1.ctx.battle.count > arg_2_0.reportDieCount_ and arg_2_0.isDead_ ~= true then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

function var_0_3.afterAwaken(arg_3_0)
	var_0_3.super.afterAwaken(arg_3_0)
	arg_3_0:addShiled()
end

function var_0_3.checkSkillBreak(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_0.unitSkills_ or arg_4_0.unitSkills_.rootID_ ~= var_0_8 then
		var_0_3.super.checkSkillBreak(arg_4_0, arg_4_1, arg_4_2)
	end
end

function var_0_3.addShiled(arg_5_0)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(var_0_5:buffs(var_0_9)) do
		local var_5_1 = {
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(var_0_9),
			skillID = var_0_9,
			fighter = arg_5_0,
			target = arg_5_0
		}
		local var_5_2 = var_0_4.new(var_5_1)

		var_5_2:setYongJiu()
		table.insert(var_5_0, var_5_2)
	end

	arg_5_0:addBuffs(var_5_0)

	var_0_11 = true
end

function var_0_3.applyUnitBuffs(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6)
	if arg_6_0:isDeath() then
		for iter_6_0, iter_6_1 in ipairs(arg_6_1 or {}) do
			if iter_6_1:getYx() > 0 then
				arg_6_0.buffMovePath_ = iter_6_1:getPath()
			end
		end

		return
	end

	if next(arg_6_2) then
		arg_6_0.fighterModel:playFloatText({
			var_0_2.BattleFloatType.BUFF_MISS
		}, arg_6_0:getTeamType())
	end

	if next(arg_6_1) and (not arg_6_0.unitSkills_ or arg_6_0.unitSkills_.rootID_ ~= var_0_8) then
		arg_6_0:addBuffs(arg_6_1)

		for iter_6_2, iter_6_3 in ipairs(arg_6_1) do
			if iter_6_3:getTableID() == var_0_10 then
				for iter_6_4, iter_6_5 in ipairs(arg_6_0.buffMovePath_) do
					iter_6_5[1] = 0
				end

				break
			end
		end
	end

	if arg_6_5 and arg_6_0:isCreatingUnits() then
		arg_6_0:skillIsBreak(arg_6_6)

		arg_6_0.leftInterval_ = 0
	end

	if arg_6_3 then
		arg_6_0:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_6_6)
	end

	if arg_6_4 then
		arg_6_0:checkSkillBreak(var_0_2.BreakSkillType.AP, arg_6_6)
	end
end

function var_0_3.canBeStop(arg_7_0)
	if arg_7_0.unitSkills_ and arg_7_0.unitSkills_.rootID_ == var_0_8 then
		return false
	end

	return true
end

return var_0_3
