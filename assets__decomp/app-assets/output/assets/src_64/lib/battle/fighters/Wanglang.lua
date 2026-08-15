local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wanglang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 40011130
local var_0_5 = 40011131
local var_0_6 = 80010086
local var_0_7 = 40011132
local var_0_8 = 450
local var_0_9 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	if arg_1_0.isSkinSkillOn_ then
		arg_1_0.isAddSkinBuff = false
		arg_1_0.isHasSkinBuff = false
	end
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:skinSkill()
end

function var_0_3.skinSkill(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.isSkinSkillOn_ or not arg_3_0.isAddSkinBuff or not arg_3_0.isHasSkinBuff then
		return
	end

	if var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % var_0_8 == 0 then
		local var_3_0 = arg_3_0:createNewBuffs({
			var_0_5,
			var_0_7
		}, arg_3_0, var_0_6, 1)

		arg_3_0:addBuffs(var_3_0)
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.isSkinSkillOn_ and not arg_4_0.isAddSkinBuff then
		arg_4_0.isAddSkinBuff = true
		arg_4_0.isHasSkinBuff = true

		local var_4_0 = arg_4_0:createNewBuffs({
			var_0_4
		}, arg_4_0, var_0_6, 1)

		arg_4_0:addBuffs(var_4_0)
	end
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	local var_5_0, var_5_1, var_5_2, var_5_3 = var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)

	if arg_5_0.isSkinSkillOn_ and arg_5_0.isAddSkinBuff and arg_5_0.isHasSkinBuff and var_5_0 > arg_5_0:getLevel() * var_0_9 then
		arg_5_0.isHasSkinBuff = false

		arg_5_0:removeBuffByID(var_0_4)
		arg_5_0:removeBuffByID(var_0_5)
		arg_5_0:removeBuffByID(var_0_7)
	end

	return var_5_0, var_5_1, var_5_2, var_5_3
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local function var_6_0(arg_7_0)
		local var_7_0
		local var_7_1

		for iter_7_0, iter_7_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_7_1:isAffected() and not iter_7_1:isDeath() and iter_7_1 ~= arg_6_1.target and (not var_7_0 or var_7_1 > math.abs(iter_7_1:getX() - arg_6_1.target:getX())) then
				var_7_0 = iter_7_1
				var_7_1 = math.abs(iter_7_1:getX() - arg_6_1.target:getX())
			end
		end

		return var_7_0 and {
			var_7_0
		} or {}
	end

	if arg_6_1:isSleep() and arg_6_1.leftCount_ < 1 and arg_6_1.transformTargets_ and #arg_6_1.transformTargets_ < 3 then
		local var_6_1 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_2 = var_6_0(arg_6_1.transformTargets_)
		local var_6_3 = arg_6_0:createAttackUnits(var_6_2, var_6_1)

		for iter_6_0, iter_6_1 in ipairs(var_6_3) do
			iter_6_1.transformTargets_ = arg_6_1.transformTargets_

			table.insert(iter_6_1.transformTargets_, iter_6_1.target)
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.checkUnitBuffs(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4 = var_0_3.super.checkUnitBuffs(arg_8_0, arg_8_1, arg_8_2)

	if arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_8_1.transformTargets_ = arg_8_1.transformTargets_ or {
			arg_8_1.target
		}
	end

	if arg_8_1.transformTargets_ then
		for iter_8_0, iter_8_1 in ipairs(var_8_0) do
			var_8_0[iter_8_0].transformTargets_ = arg_8_1.transformTargets_
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4
end

return var_0_3
