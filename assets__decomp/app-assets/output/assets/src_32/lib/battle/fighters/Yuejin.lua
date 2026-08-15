local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuejin", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = var_0_2.tables.elementEquip
local var_0_9 = 20001492
local var_0_10 = 10002391
local var_0_11 = 40012598

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
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == arg_4_0:getEnergySkillID() then
		arg_4_4 = arg_4_0.skillCount_ * arg_4_4
	end

	arg_4_1:recordData(arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_0:hasElementEquipByID(var_0_9) and arg_5_2 then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0
		}, var_0_10)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	if arg_6_1.rootID_ ~= arg_6_0:getPugongID() then
		arg_6_0.skillCount_ = 1 + arg_6_0.skillCount_
	end

	if arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_6_0 = arg_6_0:getFrontTargetPosX()
		local var_6_1 = var_0_5:pretime(arg_6_1.rootID_) - 4

		if var_6_1 > 0 then
			local var_6_2 = {}
			local var_6_3 = 4

			arg_6_0.skillRush_ = {}

			for iter_6_0 = 1, var_0_5:pretime(arg_6_1.rootID_) do
				if iter_6_0 <= var_6_3 then
					table.insert(arg_6_0.skillRush_, {
						0,
						0
					})
				else
					table.insert(arg_6_0.skillRush_, {
						var_6_0 / var_6_1,
						0
					})
				end
			end
		end
	end

	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	var_0_3.super.buffAddAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_11 then
		local var_7_0 = var_0_9

		arg_7_1.manualRevise = var_0_8:battleAttr(var_7_0, arg_7_0:getElementEquipLevelByID(var_7_0)) * arg_7_0.hero_:getElementEquipActiveRate(var_7_0)
	end
end

function var_0_3.applyBuffMoves(arg_8_0)
	var_0_3.super.applyBuffMoves(arg_8_0)

	if next(arg_8_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_8_0.fighterModel) or arg_8_0:isDeath() or not arg_8_0:acttionInBlack() then
		return
	end

	local var_8_0, var_8_1 = unpack(arg_8_0.skillRush_[1])

	table.remove(arg_8_0.skillRush_, 1)

	if var_8_0 ~= 0 or var_8_1 ~= 0 then
		arg_8_0:moveByX(var_8_0, false)
		arg_8_0:moveByY(var_8_1, false)
	end
end

function var_0_3.attacked(arg_9_0)
	var_0_3.super.attacked(arg_9_0)

	if next(arg_9_0.skillRush_) then
		arg_9_0.skillRush_ = {}

		if arg_9_0:getX() > var_0_2.STAGE_WIDTH - arg_9_0:getFighterModel():getWidth() / 2 then
			arg_9_0:x(var_0_2.STAGE_WIDTH - arg_9_0:getFighterModel():getWidth() / 2)
		elseif arg_9_0:getX() < arg_9_0:getFighterModel():getWidth() / 2 then
			arg_9_0:x(arg_9_0:getFighterModel():getWidth() / 2)
		end
	end
end

function var_0_3.getExtraShanbi(arg_10_0)
	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return 0
	end

	if not arg_10_0.extraShanbi_ then
		local var_10_0 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_10_1 = var_0_5:buffs(var_10_0)

		arg_10_0.extraShanbi_ = var_0_4.new({
			tableID = var_10_1[1],
			start = var_0_1.ctx.battle.count,
			level = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			skillID = var_10_0,
			fighter = arg_10_0,
			target = arg_10_0
		}):getAttr()
	end

	return arg_10_0.extraShanbi_ * arg_10_0.skillCount_
end

function var_0_3.getShanBi(arg_11_0)
	return var_0_3.super.getShanBi(arg_11_0) + arg_11_0:getExtraShanbi()
end

return var_0_3
