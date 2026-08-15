local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhitianxinnai", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = {
	10000935,
	10000936,
	10000937,
	10000938
}
local var_0_9 = 40011032
local var_0_10 = 80
local var_0_11 = 5
local var_0_12 = 0.3
local var_0_13 = 40011035
local var_0_14 = 225
local var_0_15 = -1.5
local var_0_16 = 600
local var_0_17 = {
	10000938,
	10000939
}
local var_0_18 = 40011850
local var_0_19 = 40011851
local var_0_20 = 80010175

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillCD_ = nil
	arg_1_0.purpleSkillReBuffTime_ = 0
	arg_1_0.needUseGreenSkill = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() or var_0_1.ctx.battle.walk2NextBattle_ then
		arg_2_0:updateStateNumber()

		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and (not arg_2_0.purpleSkillCD_ or var_0_1.ctx.battle.count - arg_2_0.purpleSkillCD_ >= var_0_16) and not arg_2_0:isHasBuffByID(var_0_13) and arg_2_0:getHp() / arg_2_0:getHpLimit() <= var_0_12 then
		local var_2_0 = arg_2_0:newBuff({
			var_0_13
		}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_2_0:addBuffs(var_2_0)
	end

	if arg_2_0.isPurpleSkill_ then
		if not arg_2_0:checkHasAlive() then
			arg_2_0:removeBuffByID(var_0_13)
		else
			arg_2_0.purpleSkillReBuffTime_ = arg_2_0.purpleSkillReBuffTime_ - 1

			if arg_2_0.purpleSkillReBuffTime_ <= 0 then
				arg_2_0:addGreenShieldNum(1)

				arg_2_0.purpleSkillReBuffTime_ = var_0_14 + arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_15
			end
		end
	end

	if arg_2_0.needUseGreenSkill and not arg_2_0:isCreatingUnits() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_2_0:useSkill(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_2_0.needUseGreenSkill = false
	end
end

function var_0_3.checkHasAlive(arg_3_0)
	local var_3_0 = false

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() then
			var_3_0 = true

			break
		end
	end

	if var_3_0 then
		var_3_0 = false

		for iter_3_2, iter_3_3 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_3:isDeath() and not iter_3_3:isAffected() then
				var_3_0 = true

				break
			end
		end
	end

	return var_3_0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_8[1] then
		local var_4_0, var_4_1 = arg_4_1.target:getPos()

		arg_4_0.startPos_ = {
			x = arg_4_0:getX(),
			y = arg_4_0:getY(),
			flipX_ = arg_4_0:getFlipX()
		}

		local var_4_2 = arg_4_1.target:getFlipX() and 1 or -1

		if arg_4_1.target:isBoss() then
			var_4_2 = -1
		end

		arg_4_0:pos(var_4_0 + var_4_2 * 50, var_4_1)
		arg_4_0:flipX(arg_4_1.target:getFlipX())
	elseif arg_4_1.skillID == var_0_8[2] and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_4_0:energyChildSkill(arg_4_1.target)
	elseif arg_4_1.skillID == var_0_8[3] and arg_4_0.startPos_ and next(arg_4_0.startPos_) then
		arg_4_0:pos(arg_4_0.startPos_.x, arg_4_0.startPos_.y)
		arg_4_0:flipX(arg_4_0.startPos_.flipX_)
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0:addGreenShieldNum(var_0_11)
	end

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_20 then
		local var_4_3 = false

		for iter_4_0, iter_4_1 in ipairs(var_0_17) do
			if iter_4_1 == arg_4_1.skillID and arg_4_1.target ~= var_0_7.B1(arg_4_0)[1] then
				var_4_3 = true

				break
			end
		end

		if var_4_3 then
			local var_4_4 = arg_4_0:createNewBuffs({
				var_0_18,
				var_0_19
			}, arg_4_1.target, var_0_20, arg_4_0:getLevel())

			arg_4_1.target:addBuffs(var_4_4)
		end
	end
end

function var_0_3.energyChildSkill(arg_5_0, arg_5_1)
	if not arg_5_1 then
		return {}
	end

	local var_5_0 = var_0_5:scope(var_0_8[4]) / 2
	local var_5_1 = arg_5_1:getX()
	local var_5_2 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if iter_5_1 ~= arg_5_1 and not iter_5_1:isDeath() and not iter_5_1:isAffected() and var_5_0 >= math.abs(iter_5_1:getX() - var_5_1) then
			table.insert(var_5_2, iter_5_1)
		end
	end

	if next(var_5_2) then
		local var_5_3 = arg_5_0:createAttackUnits(var_5_2, var_0_8[4])

		for iter_5_2, iter_5_3 in ipairs(var_5_3) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	end
end

function var_0_3.deathFeedback(arg_6_0, arg_6_1)
	var_0_3.super.deathFeedback(arg_6_0, arg_6_1)

	if arg_6_1.killer_ and arg_6_1.killer_ == arg_6_0 and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		if arg_6_0:isCreatingUnits() then
			arg_6_0.needUseGreenSkill = true
		else
			local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)

			arg_6_0:useSkill(var_6_0)
		end
	end
end

function var_0_3.useSkill(arg_7_0, arg_7_1)
	if arg_7_0:isCreatingUnits() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_7_0 = var_0_5:sound(arg_7_1)

	var_0_1.ctx.battle.pushSoundQueue(var_7_0)

	local var_7_1 = var_0_5:attackIndex(arg_7_1)

	arg_7_0:playAttack(var_7_1)

	arg_7_0.unitSkills_ = var_0_6.new({
		fighter = arg_7_0,
		skillID = arg_7_1
	})

	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == var_0_9 and arg_8_1:getSkillID() == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_8_1.target:removeBuffByID(var_0_9)
	elseif arg_8_1:getTableID() == var_0_13 then
		arg_8_0.purpleSkillCD_ = var_0_1.ctx.battle.count
		arg_8_0.isPurpleSkill_ = true
		arg_8_0.purpleSkillReBuffTime_ = var_0_14 + arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_15

		arg_8_0:addGreenShieldNum(2)
	end
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	var_0_3.super.buffRemoveAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == var_0_13 then
		arg_9_0.isPurpleSkill_ = false
		arg_9_0.purpleSkillReBuffTime_ = 0
	elseif arg_9_1:getTableID() == var_0_9 then
		arg_9_0:updateStateNumber()
	end
end

function var_0_3.shieldFeedBack(arg_10_0, arg_10_1, arg_10_2)
	var_0_3.super.shieldFeedBack(arg_10_0, arg_10_1, arg_10_2)

	if arg_10_2 and arg_10_2:getTableID() == var_0_9 then
		arg_10_0:updateEnergyBy(var_0_10)

		if arg_10_2:getShieldNum() > 1 then
			arg_10_0:updateStateNumber(arg_10_2:getShieldNum())
		end
	end
end

function var_0_3.playShanbi(arg_11_0, arg_11_1)
	var_0_3.super.playShanbi(arg_11_0, arg_11_1)

	if arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_11_0:addGreenShieldNum(1)
	end
end

function var_0_3.addGreenShieldNum(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0:getBuffByID(var_0_9)
	local var_12_1 = 0

	if not var_12_0 then
		local var_12_2 = arg_12_0:newBuff({
			var_0_9
		}, arg_12_0, arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		var_12_0 = var_12_2[1]

		arg_12_0:addBuffs(var_12_2)
	else
		var_12_1 = var_12_0:getShieldNum()
	end

	local var_12_3 = var_12_1 + arg_12_1

	var_12_3 = var_12_3 > var_0_11 and var_0_11 or var_12_3

	var_12_0:setShieldNum(var_12_3)
	arg_12_0:updateStateNumber(var_12_3)

	if arg_12_0.isPurpleSkill_ and var_12_3 >= var_0_11 then
		arg_12_0:removeBuffByID(var_0_13)
		arg_12_0:useSkill(arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))
	end
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_1 = var_0_4.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(arg_13_3),
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_1:setIsHit(true)
		var_13_1:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

return var_0_3
