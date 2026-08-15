local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jianggan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.model
local var_0_8 = 10010156
local var_0_9 = 10010155
local var_0_10 = 10010154
local var_0_11 = 10000359
local var_0_12 = 10000360
local var_0_13 = 10000358
local var_0_14 = 80010091
local var_0_15 = 40011651
local var_0_16 = 40011652

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyBuff_ = nil
	arg_1_0.isAutoReturn_ = nil
	arg_1_0.skillRush_ = {}
	arg_1_0.skinSkillUsed = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			iter_2_1:removeBuffByID(var_0_16)
		end

		return
	end

	if arg_2_0.skinSkillID_ == var_0_14 then
		if not arg_2_0.skinSkillUsed then
			arg_2_0.skinSkillUsed = true

			for iter_2_2, iter_2_3 in ipairs(arg_2_0.selfTeam_) do
				if not iter_2_3:isDeath() and not iter_2_3:isAffected() then
					iter_2_3:addBuffs({
						var_0_5.new({
							tableID = var_0_15,
							start = var_0_1.ctx.battle.count,
							level = arg_2_0:getLevel(),
							skillID = var_0_14,
							fighter = arg_2_0,
							target = iter_2_3
						})
					})
				end
			end
		end

		local var_2_0 = var_0_6:scope(var_0_14) / 2

		for iter_2_4, iter_2_5 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_5:isDeath() and not iter_2_5:isAffected() then
				if var_2_0 > math.abs(iter_2_5:getX() - arg_2_0:getX()) then
					if not iter_2_5:isHasBuffByID(var_0_16) then
						iter_2_5:addBuffs({
							var_0_5.new({
								tableID = var_0_16,
								start = var_0_1.ctx.battle.count,
								level = arg_2_0:getLevel(),
								skillID = var_0_14,
								fighter = arg_2_0,
								target = iter_2_5
							})
						})
					end
				else
					iter_2_5:removeBuffByID(var_0_16)
				end
			end
		end
	end
end

function var_0_3.checkEnergySkill(arg_3_0)
	if arg_3_0.isEnergyBuff_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_3_0)
end

function var_0_3.getOrbOfFrontSkill(arg_4_0)
	local var_4_0 = arg_4_0:getFrontSkill()
	local var_4_1 = var_0_6:buffOrb(var_4_0)

	if var_4_1 > 0 and arg_4_0:getSkillLevelByID(var_4_1) > 0 and arg_4_0.isEnergyBuff_ then
		return var_4_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_4_0)
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == arg_5_0:getEnergySkillID() and not arg_5_0.isEnergyBuff_ then
		local var_5_0 = arg_5_0:getFrontTargetPosX()

		arg_5_0.lastPosX_ = arg_5_0:getX()

		local var_5_1 = var_0_6:attackIndex(arg_5_1.rootID_)
		local var_5_2 = var_0_7:duration(arg_5_0:getModelID(), var_5_1)
		local var_5_3, var_5_4 = var_0_6:pretime(arg_5_1.rootID_), var_5_2 - 20

		if var_5_4 > 0 then
			arg_5_0.skillRush_ = {}

			for iter_5_0 = 1, var_5_4 do
				if iter_5_0 <= var_5_3 then
					table.insert(arg_5_0.skillRush_, {
						0,
						0
					})
				else
					table.insert(arg_5_0.skillRush_, {
						var_5_0 / var_5_4,
						0
					})
				end
			end
		end
	elseif arg_5_1.rootID_ == var_0_13 and arg_5_0.isEnergyBuff_ then
		local var_5_5 = arg_5_0.lastPosX_ - arg_5_0:getX()
		local var_5_6 = var_0_6:attackIndex(arg_5_1.rootID_)
		local var_5_7 = var_0_7:duration(arg_5_0:getModelID(), var_5_6)
		local var_5_8, var_5_9 = var_0_6:pretime(arg_5_1.rootID_), var_5_7 - 20

		if var_5_9 > 0 then
			arg_5_0.skillRush_ = {}

			for iter_5_1 = 1, var_5_9 do
				if iter_5_1 <= var_5_8 then
					table.insert(arg_5_0.skillRush_, {
						0,
						0
					})
				else
					table.insert(arg_5_0.skillRush_, {
						var_5_5 / var_5_9,
						0
					})
				end
			end
		end

		arg_5_0.isEnergyBuff_ = nil
		arg_5_0.isAutoReturn_ = nil

		arg_5_0:removeBuffByID(var_0_8)
		arg_5_0:removeBuffByID(var_0_9)
	end
end

function var_0_3.applyBuffMoves(arg_6_0)
	var_0_3.super.applyBuffMoves(arg_6_0)

	if next(arg_6_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_6_0.fighterModel) or arg_6_0:isDeath() then
		return
	end

	local var_6_0, var_6_1 = unpack(arg_6_0.skillRush_[1])

	table.remove(arg_6_0.skillRush_, 1)

	if var_6_0 ~= 0 or var_6_1 ~= 0 then
		arg_6_0:moveByX(var_6_0, false)
		arg_6_0:moveByY(var_6_1, false)
	end

	arg_6_0.fighterModel:hideHeaderView(false)

	if not next(arg_6_0.skillRush_) then
		arg_6_0.fighterModel:hideHeaderView(true)

		if arg_6_0.isEnergyBuff_ then
			arg_6_0:initEnergyState()
		end
	end
end

function var_0_3.initEnergyState(arg_7_0)
	arg_7_0.startSkillQueue_ = {}
	arg_7_0.skillQueue_ = arg_7_0.hero_:getCircle()

	arg_7_0:popColorSkill()

	if arg_7_0:getTeamType() == var_0_2.TeamType.A and arg_7_0.bottomWnd and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_7_0.bottomWnd:setXuliSkillEffect(arg_7_0, var_0_1.ctx.battle.teamA, true)
	end
end

function var_0_3.isAffected(arg_8_0)
	return next(arg_8_0.skillRush_) or var_0_3.super.isAffected(arg_8_0)
end

function var_0_3.getFrontTargetPosX(arg_9_0)
	local var_9_0
	local var_9_1

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and (not var_9_1 or var_9_1 < math.abs(iter_9_1:getX() - arg_9_0:getX())) then
			var_9_0 = iter_9_1
			var_9_1 = math.abs(iter_9_1:getX() - arg_9_0:getX())
		end
	end

	local var_9_2 = 0

	if var_9_0 then
		local var_9_3 = var_9_0:getX() > arg_9_0:getX() and 1 or -1

		if var_9_0:avoidHeroMoveBehind() then
			var_9_2 = var_9_0:getX() - arg_9_0:getX() - 90 * var_9_3
		else
			var_9_2 = var_9_0:getX() - arg_9_0:getX() + 90 * var_9_3
		end
	else
		var_9_2 = 350 * (arg_9_0:getFlipX() and -1 or 1)
	end

	if arg_9_0:getX() + var_9_2 < arg_9_0:getFighterModel():getWidth() / 2 and var_9_2 < 0 then
		var_9_2 = arg_9_0:getFighterModel():getWidth() / 2 - arg_9_0:getX()
	end

	if arg_9_0:getX() + var_9_2 > var_0_2.STAGE_WIDTH - arg_9_0:getFighterModel():getWidth() / 2 and var_9_2 > 0 then
		var_9_2 = var_0_2.STAGE_WIDTH - arg_9_0:getFighterModel():getWidth() / 2 - arg_9_0:getX()
	end

	return var_9_2
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
	end

	local var_10_6 = var_0_6:father(arg_10_1.skillID)

	if arg_10_1.target ~= arg_10_0 and var_10_6 ~= arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_10_7 = arg_10_0:createAttackUnits({
			arg_10_1.target
		}, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_10_0, iter_10_1 in ipairs(var_10_7) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end
	end

	if arg_10_1.skillID == var_0_11 then
		local var_10_8 = arg_10_0:createAttackUnits({
			arg_10_0
		}, var_0_12)

		for iter_10_2, iter_10_3 in ipairs(var_10_8) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
			table.insert(arg_10_0.records_.special_units, iter_10_3)
		end

		arg_10_0.purpleCure_ = var_10_2
	end

	if arg_10_1.skillID == var_0_12 then
		var_10_3 = arg_10_0.purpleCure_ or 0
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.buffAddAction(arg_11_0, arg_11_1)
	if arg_11_1:getTableID() == var_0_8 then
		arg_11_0.isEnergyBuff_ = true

		if arg_11_0:getHp() < 0.3 * arg_11_0:getHpLimit() then
			arg_11_0.isAutoReturn_ = nil
		else
			arg_11_0.isAutoReturn_ = true
		end
	elseif arg_11_1:getTableID() == var_0_10 and #arg_11_1.target:getBuffsByID(var_0_10) >= 2 then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
			return
		end

		local var_11_0 = arg_11_0:createAttackUnits({
			arg_11_1.target
		}, var_0_11)

		for iter_11_0, iter_11_1 in ipairs(var_11_0) do
			table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
			table.insert(arg_11_0.records_.special_units, iter_11_1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	if arg_12_1:getTableID() == var_0_8 then
		arg_12_0:moveBack()
	end
end

function var_0_3.moveBack(arg_13_0)
	if not arg_13_0.isEnergyBuff_ or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_13_0 = var_0_13
	local var_13_1 = var_0_6:sound(var_13_0)

	var_0_1.ctx.battle.pushSoundQueue(var_13_1)

	local var_13_2 = var_0_6:attackIndex(var_13_0)

	arg_13_0:playAttack(var_13_2)

	arg_13_0.unitSkills_ = var_0_4.new({
		fighter = arg_13_0,
		skillID = var_13_0
	})

	arg_13_0:beginAttackEnd(arg_13_0.unitSkills_)

	if arg_13_0:getTeamType() == var_0_2.TeamType.A and arg_13_0.bottomWnd then
		arg_13_0.bottomWnd:setXuliSkillEffect(arg_13_0, var_0_1.ctx.battle.teamA, false)
	end
end

function var_0_3.applyBuffHarms(arg_14_0)
	var_0_3.super.applyBuffHarms(arg_14_0)

	if arg_14_0.isEnergyBuff_ and arg_14_0.isAutoReturn_ and arg_14_0:getHp() > 0 and arg_14_0:getHp() < 0.2 * arg_14_0:getHpLimit() then
		arg_14_0:moveBack()
	end
end

function var_0_3.applyHurtFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5)
	local var_15_0, var_15_1, var_15_2, var_15_3 = var_0_3.super.applyHurtFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5)

	if arg_15_0.isEnergyBuff_ and arg_15_0.isAutoReturn_ and arg_15_0:getHp() > 0 and arg_15_0:getHp() < 0.2 * arg_15_0:getHpLimit() then
		arg_15_0:moveBack()
	end

	return var_15_0, var_15_1, var_15_2, var_15_3
end

function var_0_3.clickAvatar(arg_16_0, arg_16_1)
	if arg_16_1.name ~= "ended" or next(arg_16_0.skillRush_) then
		return
	end

	if arg_16_0.isEnergyBuff_ then
		arg_16_0:moveBack()
	end
end

function var_0_3.isImmortal(arg_17_0, arg_17_1)
	return next(arg_17_0.skillRush_) or var_0_3.super.isImmortal(arg_17_0, arg_17_1)
end

function var_0_3.die(arg_18_0)
	arg_18_0.isEnergyBuff_ = nil
	arg_18_0.isAutoReturn_ = nil

	if arg_18_0:getTeamType() == var_0_2.TeamType.A and arg_18_0.bottomWnd and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_18_0.bottomWnd:setXuliSkillEffect(arg_18_0, var_0_1.ctx.battle.teamA, false)
	end

	var_0_3.super.die(arg_18_0)
end

function var_0_3.processAfterBattleEnd(arg_19_0, arg_19_1)
	arg_19_0.isEnergyBuff_ = nil
	arg_19_0.isAutoReturn_ = nil

	if arg_19_0:getTeamType() == var_0_2.TeamType.A and arg_19_0.bottomWnd and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_19_0.bottomWnd:setXuliSkillEffect(arg_19_0, var_0_1.ctx.battle.teamA, false)
	end
end

function var_0_3.applySingleUnit(arg_20_0, arg_20_1)
	var_0_3.super.applySingleUnit(arg_20_0, arg_20_1)

	if var_0_11 == arg_20_1.skillID then
		arg_20_1.target:removeBuffByID(var_0_10)
	end
end

return var_0_3
