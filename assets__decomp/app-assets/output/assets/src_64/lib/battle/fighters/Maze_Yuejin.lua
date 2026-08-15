local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("MazeYuejin", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 40010495
local var_0_9 = 40010493
local var_0_10 = 40010494

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skillCount_ = 1
	arg_1_0.skillRush_ = {}
end

function var_0_3.die(arg_2_0)
	var_0_3.super.die(arg_2_0)
end

function var_0_3.getFrontTargetPosX(arg_3_0)
	local var_3_0
	local var_3_1
	local var_3_2
	local var_3_3 = arg_3_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_3_4 = arg_3_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_3_5 = arg_3_0:isAttackFriend() and var_3_3 or var_3_4
	local var_3_6
	local var_3_7

	for iter_3_0, iter_3_1 in ipairs(var_3_5) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and (not var_3_7 or var_3_7 > math.abs(iter_3_1:getX() - arg_3_0:getX())) then
			var_3_6 = iter_3_1
			var_3_7 = math.abs(iter_3_1:getX() - arg_3_0:getX())
		end
	end

	local var_3_8 = 0

	if var_3_6 then
		local var_3_9 = var_3_6:getX() > arg_3_0:getX() and 1 or -1

		if var_3_6:avoidHeroMoveBehind() then
			var_3_8 = var_3_6:getX() - arg_3_0:getX() - 60 * var_3_9
		else
			var_3_8 = var_3_6:getX() - arg_3_0:getX() + 90 * var_3_9
		end
	else
		var_3_8 = 350 * (arg_3_0:getFlipX() and -1 or 1)
	end

	if arg_3_0:getX() + var_3_8 < arg_3_0:getFighterModel():getWidth() / 2 and var_3_8 < 0 then
		var_3_8 = arg_3_0:getFighterModel():getWidth() / 2 - arg_3_0:getX()
	end

	if arg_3_0:getX() + var_3_8 > var_0_2.STAGE_WIDTH - arg_3_0:getFighterModel():getWidth() / 2 and var_3_8 > 0 then
		var_3_8 = var_0_2.STAGE_WIDTH - arg_3_0:getFighterModel():getWidth() / 2 - arg_3_0:getX()
	end

	return var_3_8
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_1.skillID == arg_4_0:getEnergySkillID() then
		arg_4_4 = arg_4_0.skillCount_ * arg_4_4
	end

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_0:isInSpecialBuff(arg_4_1.target) then
		arg_4_4 = arg_4_4 * 2
	end

	arg_4_1:recordData(arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	if arg_5_1.rootID_ ~= arg_5_0:getPugongID() then
		arg_5_0.skillCount_ = 1 + arg_5_0.skillCount_
	end

	if arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_5_0 = arg_5_0:getFrontTargetPosX()
		local var_5_1 = var_0_5:pretime(arg_5_1.rootID_) - 4

		if var_5_1 > 0 then
			local var_5_2 = {}
			local var_5_3 = 4

			arg_5_0.skillRush_ = {}

			for iter_5_0 = 1, var_0_5:pretime(arg_5_1.rootID_) do
				if iter_5_0 <= var_5_3 then
					table.insert(arg_5_0.skillRush_, {
						0,
						0
					})
				else
					table.insert(arg_5_0.skillRush_, {
						var_5_0 / var_5_1,
						0
					})
				end
			end
		end
	end

	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)
end

function var_0_3.applyBuffMoves(arg_6_0)
	var_0_3.super.applyBuffMoves(arg_6_0)

	if next(arg_6_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_6_0.fighterModel) or arg_6_0:isDeath() or not arg_6_0:acttionInBlack() then
		return
	end

	local var_6_0, var_6_1 = unpack(arg_6_0.skillRush_[1])

	table.remove(arg_6_0.skillRush_, 1)

	if var_6_0 ~= 0 or var_6_1 ~= 0 then
		arg_6_0:moveByX(var_6_0, false)
		arg_6_0:moveByY(var_6_1, false)
	end
end

function var_0_3.attacked(arg_7_0)
	var_0_3.super.attacked(arg_7_0)

	if next(arg_7_0.skillRush_) then
		arg_7_0.skillRush_ = {}

		if arg_7_0:getX() > var_0_2.STAGE_WIDTH - arg_7_0:getFighterModel():getWidth() / 2 then
			arg_7_0:x(var_0_2.STAGE_WIDTH - arg_7_0:getFighterModel():getWidth() / 2)
		elseif arg_7_0:getX() < arg_7_0:getFighterModel():getWidth() / 2 then
			arg_7_0:x(arg_7_0:getFighterModel():getWidth() / 2)
		end
	end
end

function var_0_3.getShanBi(arg_8_0)
	return var_0_3.super.getShanBi(arg_8_0)
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if arg_9_1.skillID == arg_9_0:getEnergySkillID() then
		local var_9_0
		local var_9_1 = arg_9_1.target.hero_:getHeroType()

		if var_9_1 == var_0_2.HeroType.STRENGTH then
			var_9_0 = var_0_8
		elseif var_9_1 == var_0_2.HeroType.WISE then
			var_9_0 = var_0_9
		elseif var_9_1 == var_0_2.HeroType.AGILE then
			var_9_0 = var_0_10
		end

		if var_9_0 then
			local var_9_2 = arg_9_0:newBuff({
				var_9_0
			}, arg_9_1.target, arg_9_0:getEnergySkillID())

			arg_9_1.target:addBuffs(var_9_2)
		end
	end
end

function var_0_3.isInSpecialBuff(arg_10_0, arg_10_1)
	if arg_10_1:isApUnable() and not arg_10_1:isAdUnable() then
		return true
	end

	if arg_10_1:isApUnable() and arg_10_1:isAdUnable() and not arg_10_1:isFear() and not arg_10_1:isSleep() and not arg_10_1:isPause() then
		return true
	end

	if var_0_6:speed(arg_10_1:getTableID()) > arg_10_1:getCurrentSpeed() then
		return true
	end

	return false
end

function var_0_3.newBuff(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_1) do
		local var_11_1 = var_0_4.new({
			tableID = iter_11_1,
			start = var_0_1.ctx.battle.count,
			level = arg_11_0:getSkillLevelByID(arg_11_3),
			skillID = arg_11_3,
			fighter = arg_11_0,
			target = arg_11_2
		})

		var_11_1:setIsHit(true)
		var_11_1:setDirection(arg_11_0:getFighterModel():getFlipX())
		table.insert(var_11_0, var_11_1)
	end

	return var_11_0
end

return var_0_3
