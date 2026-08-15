local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fengchenxiuji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.dbuff
local var_0_9 = 40010770
local var_0_10 = 10000717
local var_0_11 = 10000715
local var_0_12 = 8
local var_0_13 = 10
local var_0_14 = 68
local var_0_15 = {
	40010773,
	40010774,
	40010775,
	40010776
}
local var_0_16 = 40010783
local var_0_17 = 480
local var_0_18 = 80010156

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyJumpCount_ = 0
	arg_1_0.energyFirstJump_ = 0
	arg_1_0.curEnergyActionSkill = 0
	arg_1_0.records_.energy_pos = {}
	arg_1_0.energyRemoveBuffTime = 0
	arg_1_0.isInEnergyJump = false
	arg_1_0.skinBuffCount = 0

	arg_1_0:listenInfo("buff_info")
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		arg_2_1.idQueue_ = {}
		arg_2_1.pretimeQueue_ = {}

		local var_2_0 = var_0_7:children(arg_2_1.rootID_)

		if var_2_0 and #var_2_0 > 1 then
			local var_2_1 = 0

			for iter_2_0 = 1, var_0_13 / 2 do
				for iter_2_1, iter_2_2 in ipairs(var_2_0) do
					local var_2_2 = var_0_7:pretime(iter_2_2) + var_2_1 * var_0_14

					if iter_2_0 == var_0_13 / 2 then
						var_2_2 = var_2_2 + 4
					end

					table.insert(arg_2_1.pretimeQueue_, var_2_2)
					table.insert(arg_2_1.idQueue_, iter_2_2)

					if iter_2_0 == var_0_13 / 2 then
						break
					end
				end

				var_2_1 = var_2_1 + 1
			end
		end

		arg_2_0.energyFirstJump_ = var_0_7:pretime(arg_2_1.rootID_)
		arg_2_0.energyJumpCount_ = 0
		arg_2_0.isInEnergyJump = true
	end

	return var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0.energyFirstJump_ > 0 then
		arg_3_0.energyFirstJump_ = arg_3_0.energyFirstJump_ - 1

		if arg_3_0.energyFirstJump_ == 0 then
			local var_3_0, var_3_1 = arg_3_0:getEnergyPos()

			arg_3_0:pos(var_3_0, var_3_1)
			arg_3_0:playNextAttack()
		end
	end

	if arg_3_0.energyRemoveBuffTime > 0 then
		arg_3_0.energyRemoveBuffTime = arg_3_0.energyRemoveBuffTime - 1

		if arg_3_0.energyRemoveBuffTime == 0 then
			arg_3_0:removeBuffByID(var_0_16)
		end
	end

	if arg_3_0.isInEnergyJump then
		local var_3_2 = false

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() then
				var_3_2 = true

				break
			end
		end

		if not var_3_2 then
			arg_3_0:skillIsBreak()
		end
	end

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_18 then
		if arg_3_0.skinBuffCount > 0 then
			arg_3_0.skinBuffCount = arg_3_0.skinBuffCount + 1
		end

		if arg_3_0.skinBuffCount > var_0_17 then
			arg_3_0.skinBuffCount = 0
		end

		if arg_3_0.skinBuffCount == 0 then
			local var_3_3 = false

			for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
				if iter_3_3.target == arg_3_0 and iter_3_3.fighter:getTeamType() ~= arg_3_0:getTeamType() and var_0_8:isLimit(iter_3_3:getTableID()) == 1 and arg_3_0:isHasBuffByID(iter_3_3:getTableID()) and not var_3_3 then
					var_3_3 = true

					arg_3_0:removeBuffByID(iter_3_3:getTableID())

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_3_4 = arg_3_0:createAttackUnits({
							arg_3_0
						}, var_0_18)

						for iter_3_4, iter_3_5 in ipairs(var_3_4) do
							table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
							table.insert(arg_3_0.records_.special_units, iter_3_5)
						end
					end

					arg_3_0.skinBuffCount = 1
				end
			end
		end
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0 = {}
	local var_4_1 = arg_4_4 or 1

	for iter_4_0 = 1, var_4_1 do
		for iter_4_1, iter_4_2 in ipairs(arg_4_1) do
			local var_4_2 = var_0_5.new({
				tableID = iter_4_2,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0:getSkillLevelByID(arg_4_3),
				skillID = arg_4_3,
				fighter = arg_4_0,
				target = arg_4_2
			})

			var_4_2:setIsHit(true)
			var_4_2:setDirection(arg_4_0:getFighterModel():getFlipX())
			table.insert(var_4_0, var_4_2)
		end
	end

	return var_4_0
end

function var_0_3.skillIsBreak(arg_5_0, arg_5_1)
	arg_5_0:checkEnergyAward()

	return var_0_3.super.skillIsBreak(arg_5_0, arg_5_1)
end

function var_0_3.getEnergyPos(arg_6_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_6_0.energyPos_[tostring(var_0_1.ctx.battle.count)] then
		local var_6_0 = arg_6_0.energyPos_[tostring(var_0_1.ctx.battle.count)]

		return var_6_0.x, var_6_0.y
	end

	local var_6_1 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_6_1, iter_6_1)
		end
	end

	if #var_6_1 == 0 then
		local var_6_2, var_6_3 = arg_6_0:getPos()

		arg_6_0.records_.energy_pos[tostring(var_0_1.ctx.battle.count)] = {
			x = var_6_2,
			y = var_6_3
		}

		return var_6_2, var_6_3
	end

	local var_6_4, var_6_5 = var_6_1[math.random(1, #var_6_1)]:getPos()

	arg_6_0.records_.energy_pos[tostring(var_0_1.ctx.battle.count)] = {
		x = var_6_4,
		y = var_6_5
	}

	return var_6_4, var_6_5
end

function var_0_3.setupReport(arg_7_0, arg_7_1)
	var_0_3.super.setupReport(arg_7_0, arg_7_1)

	arg_7_0.energyPos_ = arg_7_1.energy_pos
end

function var_0_3.writeReport(arg_8_0)
	local var_8_0 = var_0_3.super.writeReport(arg_8_0)

	var_8_0.energy_pos = arg_8_0.records_.energy_pos

	return var_8_0
end

function var_0_3.createAttacks(arg_9_0)
	local var_9_0 = arg_9_0.unitSkills_

	if not var_9_0 then
		return
	end

	if var_9_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_9_0.reportSkills_, 1)
		end

		arg_9_0.unitSkills_ = nil

		return
	end

	local var_9_1, var_9_2 = var_9_0:getFront()

	while var_9_1 and var_9_1 < 1 do
		if var_0_1.ctx.battle.infoListener.createAttack_info then
			table.insert(var_0_1.ctx.battle.infoListener.createAttack_info, arg_9_0)
		end

		arg_9_0:createUnits(var_9_0)
		var_9_0:popQueue()

		local var_9_3

		var_9_1, var_9_3 = var_9_0:getFront()

		if var_0_7:father(var_9_3) == arg_9_0:getEnergySkillID() then
			arg_9_0:playNextAttack(var_9_3)
		end

		if not arg_9_0:isCreatingUnits() then
			arg_9_0:checkEnergyAward()

			arg_9_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_9_0.reportSkills_, 1)
			end

			arg_9_0:updateEnergyBy(var_9_0:getRemp() * arg_9_0:getAttrByType(var_0_2.AttributeType.ENERGY_RATE))
			arg_9_0:popFrontSkill()
		end
	end
end

function var_0_3.checkEnergyAward(arg_10_0)
	if arg_10_0.unitSkills_ and arg_10_0.unitSkills_.rootID_ == arg_10_0:getEnergySkillID() then
		arg_10_0.isInEnergyJump = false

		arg_10_0:removeBuffByID(var_0_16)

		local var_10_0 = arg_10_0.energyJumpCount_ + 1

		if var_10_0 > 0 then
			local var_10_1 = arg_10_0:newBuff(var_0_15, arg_10_0, arg_10_0:getEnergySkillID(), var_10_0)

			arg_10_0:addBuffs(var_10_1)
		end
	end
end

function var_0_3.playNextAttack(arg_11_0, arg_11_1)
	if arg_11_1 and arg_11_0.curEnergyActionSkill == arg_11_1 then
		return
	end

	local var_11_0 = arg_11_0.unitSkills_

	if not var_11_0 then
		return
	end

	local var_11_1 = arg_11_1
	local var_11_2

	if not var_11_1 then
		local var_11_3

		var_11_3, var_11_1 = var_11_0:getFront()
	end

	arg_11_0.curEnergyActionSkill = var_11_1
	arg_11_0.energyJumpCount_ = arg_11_0.energyJumpCount_ + 1

	local var_11_4 = var_0_7:sound(var_11_1)

	var_0_1.ctx.battle.pushSoundQueue(var_11_4)

	local var_11_5 = var_0_7:attackIndex(var_11_1)

	if arg_11_0.energyJumpCount_ == var_0_13 - 1 then
		var_11_5 = var_0_12
	end

	arg_11_0.energyRemoveBuffTime = 2

	arg_11_0:playAttack(var_11_5)

	local var_11_6, var_11_7 = arg_11_0:getEnergyPos()

	arg_11_0:pos(var_11_6, var_11_7)
end

function var_0_3.playAttack(arg_12_0, arg_12_1, arg_12_2)
	if not arg_12_1 then
		return
	end

	arg_12_0.skillRoll_ = var_0_6:duration(arg_12_0:getModelID(), arg_12_1)

	arg_12_0:getFighterModel():attack(arg_12_1, nil, nil, function()
		if arg_12_2 then
			arg_12_2()
		end

		if arg_12_0.fighterModel:getScale() ~= 1 then
			arg_12_0.fighterModel:scale(1)
		end

		if arg_12_1 >= 5 and arg_12_1 < 8 and arg_12_0.isInEnergyJump then
			local var_13_0 = arg_12_0:newBuff({
				var_0_16
			}, arg_12_0, arg_12_0:getEnergySkillID())

			arg_12_0:addBuffs(var_13_0)
		end

		if arg_12_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_12_1) then
			arg_12_0:resumeIdle()
		end
	end)
end

function var_0_3.buffRemoveAction(arg_14_0, arg_14_1)
	var_0_3.super.buffRemoveAction(arg_14_0, arg_14_1)

	if arg_14_0:isDeath() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) <= 0 then
		return
	end

	if arg_14_1:getTableID() == var_0_9 then
		local var_14_0 = arg_14_0:getTargets(var_0_10)
		local var_14_1 = arg_14_0:createAttackUnits(var_14_0, var_0_10)

		for iter_14_0, iter_14_1 in ipairs(var_14_1) do
			table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
			table.insert(arg_14_0.records_.special_units, iter_14_1)
		end
	end
end

return var_0_3
