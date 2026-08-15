local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 240
local var_0_6 = 10000476
local var_0_7 = 10000471
local var_0_8 = 10000479

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount_ = 0
	arg_1_0.energyTarget = {}
	arg_1_0.energyCount_ = nil
	arg_1_0.energyBackCount_ = nil
	arg_1_0.energyBeforePosX_ = nil
	arg_1_0.energyBeforePosY_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0.purpleCount_ > 0 then
		arg_2_0.purpleCount_ = arg_2_0.purpleCount_ - 1
	end

	if arg_2_0.energyCount_ then
		arg_2_0.energyCount_ = arg_2_0.energyCount_ - 1

		if arg_2_0.energyCount_ <= 0 then
			arg_2_0.energyBeforePosX_ = arg_2_0:getX()
			arg_2_0.energyBeforePosY_ = arg_2_0:getY()

			arg_2_0:x(arg_2_0.energyPosX_)
			arg_2_0:y(arg_2_0.energyPosY_)

			arg_2_0.energyPosX_ = nil
			arg_2_0.energyPosY_ = nil
			arg_2_0.energyCount_ = nil
		end
	end

	if arg_2_0.energyBackCount_ then
		arg_2_0.energyBackCount_ = arg_2_0.energyBackCount_ - 1

		if arg_2_0.energyBackCount_ <= 0 then
			arg_2_0.energyBackCount_ = nil
			arg_2_0.energyTarget = {}

			arg_2_0:x(arg_2_0.energyBeforePosX_)
			arg_2_0:y(arg_2_0.energyBeforePosY_)
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_3_0.hero_:getStar() > 1 then
		var_3_0 = var_0_8
	end

	return var_3_0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0.purpleCount_ == 0 then
		local var_4_0 = {
			arg_4_1.target
		}
		local var_4_1 = arg_4_0:createAttackUnits(var_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end

		arg_4_0.purpleCount_ = var_0_5
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	if arg_5_1.rootID_ == arg_5_0:getEnergySkillID() then
		local var_5_0 = unpack(arg_5_0:selectTargetByTypeD1())

		if var_5_0 then
			local var_5_1

			if arg_5_0:getTeamType() == var_0_2.TeamType.A then
				var_5_1 = -1

				arg_5_0:flipX(false)
			else
				var_5_1 = 1

				arg_5_0:flipX(true)
			end

			arg_5_0.energyPosX_ = var_5_0:getX() + 100 * var_5_1
			arg_5_0.energyPosY_ = var_5_0:getY()
			arg_5_0.energyCount_ = var_0_4:pretime(var_0_7)
			arg_5_0.energyBackCount_ = var_0_4:pretime(var_0_6)
		end
	end

	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	if not next(arg_6_0.energyTarget) then
		local var_6_0 = -1
		local var_6_1

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
				local var_6_2 = iter_6_1.hero_:getMainAttr(var_0_2.AttributeType.WISE)

				if var_6_0 < var_6_2 then
					var_6_1 = iter_6_1
					var_6_0 = var_6_2
				end
			end
		end

		arg_6_0.energyTarget = {
			var_6_1
		}
	end

	return arg_6_0.energyTarget
end

function var_0_3.selectTargetByTypeD2(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			local var_7_2 = iter_7_1.hero_:getMainAttr(var_0_2.AttributeType.STRENGTH)

			if not var_7_0 or var_7_2 < var_7_0 then
				var_7_1 = iter_7_1
				var_7_0 = var_7_2
			end
		end
	end

	return {
		var_7_1
	}
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0 = var_0_4:desc4NumStep(arg_8_1.skillID)[2]
	local var_8_1 = arg_8_0:getSkillLevelByID(arg_8_1.skillID)

	if arg_8_0.isStarEnergy_ and arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_8_4 = var_8_1 * var_8_0 * arg_8_1.target:getADJianShang() + arg_8_4
	elseif arg_8_0.isStarPurple_ and arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_8_7 = arg_8_7 + var_8_1 * var_8_0 * -1
	end

	return var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1:getLevel()
	local var_9_1 = var_0_4:desc4NumStep(arg_9_1:getSkillID())[2]

	if arg_9_1:getSkillID() == var_0_8 and arg_9_0.isStarBlue_ then
		arg_9_1.manualRevise = 0.05
	end
end

return var_0_3
