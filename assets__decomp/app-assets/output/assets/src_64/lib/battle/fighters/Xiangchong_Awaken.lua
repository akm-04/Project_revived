local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiangchong", var_0_1.ctx.battle.requireFighter("Xiangchong"))
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
local var_0_17 = 10001813

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.initCount_ then
		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and not arg_2_0:isAlone() then
			arg_2_0.isReadyRush_ = true
		end

		arg_2_0.initCount_ = true
	end

	if arg_2_0.isReadyRush_ and arg_2_0.greenCount_ > 0 then
		arg_2_0.greenCount_ = arg_2_0.greenCount_ - 1

		if arg_2_0.greenCount_ <= 0 then
			arg_2_0:greenRushGoon()

			arg_2_0.isReadyRush_ = false
		end
	end

	if arg_2_0.isRushing_ then
		local var_2_0 = var_0_2.STAGE_WIDTH * 0.5
		local var_2_1 = arg_2_0:getY()

		if arg_2_0.skinSkillID_ == var_0_16 then
			local var_2_2

			for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
				if not iter_2_1:isDeath() and not iter_2_1:isAffected() and (not var_2_2 or var_2_2 >= iter_2_1:getHuJia()) then
					var_2_2 = iter_2_1:getHuJia()
					var_2_0 = iter_2_1:getX(), (iter_2_1:getY())
				end
			end
		end

		arg_2_0:checkEnemy()

		if arg_2_0:getTeamType() == var_0_2.TeamType.A then
			arg_2_0:flipX(false)
		else
			arg_2_0:flipX(true)
		end

		if arg_2_0:getFighterModel().currentAnimation_ ~= "gongji02" then
			arg_2_0:playAttack(2)
		end

		local var_2_3 = arg_2_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
		local var_2_4 = 20

		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
			arg_2_0:moveByX(var_2_3 * var_2_4)
		end

		if var_2_3 == 1 and var_2_0 <= arg_2_0:getX() then
			arg_2_0.isRushing_ = false
		elseif var_2_3 == -1 and var_2_0 >= arg_2_0:getX() then
			arg_2_0.isRushing_ = false
		end

		if arg_2_0.maxRushCount_ > 0 then
			arg_2_0.maxRushCount_ = arg_2_0.maxRushCount_ - 1

			if arg_2_0.maxRushCount_ <= 0 then
				arg_2_0.isRushing_ = false
			end
		end
	end

	if arg_2_0.isGreenBackCount_ > 0 then
		arg_2_0.isGreenBackCount_ = arg_2_0.isGreenBackCount_ - 1

		if arg_2_0.isGreenBackCount_ <= 0 then
			arg_2_0:greenRushGoon()
		end
	end

	if arg_2_0.greenBackReadyCount_ > 0 then
		arg_2_0.greenBackReadyCount_ = arg_2_0.greenBackReadyCount_ - 1
	end

	if arg_2_0.energyMoveCount_ > 0 then
		arg_2_0.energyMoveCount_ = arg_2_0.energyMoveCount_ - 1

		if arg_2_0.energyMoveCount_ <= 0 then
			local var_2_5 = unpack(var_0_6.B17(arg_2_0, arg_2_0:getEnergySkillID()))

			if var_2_5 then
				local var_2_6 = arg_2_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
				local var_2_7, var_2_8 = var_2_5:getPos()

				arg_2_0:pos(var_2_7 + var_2_6 * 50, var_2_8)

				if var_2_6 == 1 then
					arg_2_0:flipX(true)
				else
					arg_2_0:flipX(false)
				end
			end
		end
	end

	if var_0_1.ctx.battle.count % 10 < 1 and not arg_2_0:isCreatingUnits() and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_2_0:getHp() <= arg_2_0:getHpLimit() * var_0_12 and not arg_2_0.hasGreenBackRush_ then
		arg_2_0.hasGreenBackRush_ = true

		arg_2_0:addAwakeBuffs()

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			return
		end

		local var_2_9 = var_0_10
		local var_2_10 = var_0_7:attackIndex(var_2_9)

		arg_2_0:playAttack(var_2_10)

		arg_2_0.unitSkills_ = var_0_5.new({
			fighter = arg_2_0,
			skillID = var_2_9
		})

		arg_2_0:beginAttackEnd(arg_2_0.unitSkills_)
	end
end

function var_0_3.addAwakeBuffs(arg_3_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:createAttackUnits(arg_3_0:getTargets(var_0_17), var_0_17)

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

function var_0_3.die(arg_4_0)
	arg_4_0:addAwakeBuffs()
	var_0_3.super.die(arg_4_0)
end

return var_0_3
