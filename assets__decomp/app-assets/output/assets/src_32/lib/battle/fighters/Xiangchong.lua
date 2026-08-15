local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiangchong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 40010414
local var_0_9 = 10000573
local var_0_10 = 10000574
local var_0_11 = 10000575
local var_0_12 = 0.3
local var_0_13 = 150
local var_0_14 = 30
local var_0_15 = 80
local var_0_16 = 80010128

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.hasGreenBackRush_ = false
	arg_1_0.isReadyRush_ = false
	arg_1_0.isRushing_ = false
	arg_1_0.isGreenBackCount_ = 0
	arg_1_0.maxRushCount_ = 0
	arg_1_0.greenBackReadyCount_ = 0
	arg_1_0.energyMoveCount_ = 0
	arg_1_0.greenCount_ = var_0_13
	arg_1_0.rushedTarget_ = {}
	arg_1_0.initCount_ = false
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_9 then
		local var_2_0 = var_0_4.new({
			tableID = var_0_8,
			start = var_0_1.ctx.battle.count,
			level = arg_2_0:getSkillLevelByID(arg_2_1.skillID),
			skillID = arg_2_1.skillID,
			fighter = arg_2_0,
			target = arg_2_1.target
		})
		local var_2_1 = arg_2_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

		var_2_0.resetXchange_ = math.abs(var_2_1 * 100 + var_0_2.STAGE_WIDTH * 0.5 - arg_2_1.target:getX())

		var_2_0:setIsHit(true)
		var_2_0:setDirection(arg_2_0:getFighterModel():getFlipX())
		arg_2_1.target:addBuffs({
			var_2_0
		})

		if arg_2_0.skinSkillID_ == var_0_16 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_2 = arg_2_0:createAttackUnits({
				arg_2_0
			}, var_0_16)

			for iter_2_0, iter_2_1 in ipairs(var_2_2) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	elseif arg_2_1.skillID == var_0_10 then
		arg_2_0:greenBack()
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getEnergySkillID() then
		arg_3_0.energyMoveCount_ = var_0_14
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if not arg_4_0.initCount_ then
		if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and not arg_4_0:isAlone() then
			arg_4_0.isReadyRush_ = true
		end

		arg_4_0.initCount_ = true
	end

	if arg_4_0.isReadyRush_ and arg_4_0.greenCount_ > 0 then
		arg_4_0.greenCount_ = arg_4_0.greenCount_ - 1

		if arg_4_0.greenCount_ <= 0 then
			arg_4_0:greenRushGoon()

			arg_4_0.isReadyRush_ = false
		end
	end

	if arg_4_0.isRushing_ then
		local var_4_0 = var_0_2.STAGE_WIDTH * 0.5
		local var_4_1 = arg_4_0:getY()

		if arg_4_0.skinSkillID_ == var_0_16 then
			local var_4_2

			for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
				if not iter_4_1:isDeath() and not iter_4_1:isAffected() and (not var_4_2 or var_4_2 >= iter_4_1:getHuJia()) then
					var_4_2 = iter_4_1:getHuJia()
					var_4_0 = iter_4_1:getX(), (iter_4_1:getY())
				end
			end
		end

		arg_4_0:checkEnemy()

		if arg_4_0:getTeamType() == var_0_2.TeamType.A then
			arg_4_0:flipX(false)
		else
			arg_4_0:flipX(true)
		end

		if arg_4_0:getFighterModel().currentAnimation_ ~= "gongji02" then
			arg_4_0:playAttack(2)
		end

		local var_4_3 = arg_4_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
		local var_4_4 = 20

		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
			arg_4_0:moveByX(var_4_3 * var_4_4)
		end

		if var_4_3 == 1 and var_4_0 <= arg_4_0:getX() then
			arg_4_0.isRushing_ = false
		elseif var_4_3 == -1 and var_4_0 >= arg_4_0:getX() then
			arg_4_0.isRushing_ = false
		end

		if arg_4_0.maxRushCount_ > 0 then
			arg_4_0.maxRushCount_ = arg_4_0.maxRushCount_ - 1

			if arg_4_0.maxRushCount_ <= 0 then
				arg_4_0.isRushing_ = false
			end
		end
	end

	if arg_4_0.isGreenBackCount_ > 0 then
		arg_4_0.isGreenBackCount_ = arg_4_0.isGreenBackCount_ - 1

		if arg_4_0.isGreenBackCount_ <= 0 then
			arg_4_0:greenRushGoon()
		end
	end

	if arg_4_0.greenBackReadyCount_ > 0 then
		arg_4_0.greenBackReadyCount_ = arg_4_0.greenBackReadyCount_ - 1
	end

	if arg_4_0.energyMoveCount_ > 0 then
		arg_4_0.energyMoveCount_ = arg_4_0.energyMoveCount_ - 1

		if arg_4_0.energyMoveCount_ <= 0 then
			local var_4_5 = unpack(var_0_6.B17(arg_4_0, arg_4_0:getEnergySkillID()))

			if var_4_5 then
				local var_4_6 = arg_4_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
				local var_4_7, var_4_8 = var_4_5:getPos()

				arg_4_0:pos(var_4_7 + var_4_6 * 50, var_4_8)

				if var_4_6 == 1 then
					arg_4_0:flipX(true)
				else
					arg_4_0:flipX(false)
				end
			end
		end
	end

	if var_0_1.ctx.battle.count % 10 < 1 and not arg_4_0:isCreatingUnits() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_4_0:getHp() <= arg_4_0:getHpLimit() * var_0_12 and not arg_4_0.hasGreenBackRush_ then
		arg_4_0.hasGreenBackRush_ = true

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			return
		end

		local var_4_9 = var_0_10
		local var_4_10 = var_0_7:attackIndex(var_4_9)

		arg_4_0:playAttack(var_4_10)

		arg_4_0.unitSkills_ = var_0_5.new({
			fighter = arg_4_0,
			skillID = var_4_9
		})

		arg_4_0:beginAttackEnd(arg_4_0.unitSkills_)
	end
end

function var_0_3.checkEnemy(arg_5_0)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.targetTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and math.abs(iter_5_1:getX() - arg_5_0:getX()) <= 50 and not arg_5_0.rushedTarget_[iter_5_1] then
			arg_5_0:rushEffect(iter_5_1)
		end
	end
end

function var_0_3.rushEffect(arg_6_0, arg_6_1)
	arg_6_0.rushedTarget_[arg_6_1] = true

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_1
		}, var_0_9)

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.greenRushGoon(arg_7_0)
	arg_7_0.isRushing_ = true
	arg_7_0.maxRushCount_ = var_0_15
end

function var_0_3.greenBack(arg_8_0)
	local var_8_0 = arg_8_0:getTeamType() == var_0_2.TeamType.A and -150 or var_0_2.STAGE_WIDTH + 150
	local var_8_1 = var_0_2.STAGE_HEIGHT * 0.5

	arg_8_0.rushedTarget_ = {}

	arg_8_0:pos(var_8_0, var_8_1)

	arg_8_0.isGreenBackCount_ = var_0_13
end

function var_0_3.isAlone(arg_9_0)
	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if iter_9_1 ~= arg_9_0 and not iter_9_1:isDeath() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None then
			return false
		end
	end

	return true
end

function var_0_3.checkMove(arg_10_0)
	if arg_10_0.isReadyRush_ or arg_10_0.isGreenBackCount_ > 0 then
		return false
	else
		return var_0_3.super.checkMove(arg_10_0)
	end
end

function var_0_3.canAttack(arg_11_0)
	if arg_11_0.isReadyRush_ or arg_11_0.isGreenBackCount_ > 0 or arg_11_0.isRushing_ then
		return false
	else
		return var_0_3.super.canAttack(arg_11_0)
	end
end

function var_0_3.isAffected(arg_12_0)
	if arg_12_0.isReadyRush_ or arg_12_0.isGreenBackCount_ > 0 or arg_12_0.isRushing_ or arg_12_0.unitSkills_ and arg_12_0.unitSkills_.rootID_ == var_0_10 then
		return true
	else
		return var_0_3.super.isAffected(arg_12_0)
	end
end

return var_0_3
