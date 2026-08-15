local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hanxiandi", var_0_1.ctx.battle.requireFighter("Hanxiandi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 30010031
local var_0_6 = 1
local var_0_7 = 4
local var_0_8 = 8
local var_0_9 = 40010821
local var_0_10 = 40010822
local var_0_11 = 40010843
local var_0_12 = 40010823
local var_0_13 = 40010824
local var_0_14 = 10000766
local var_0_15 = 0.2
local var_0_16 = 10000769

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.oldBloodBuffCount_ = {}
	arg_2_0.totalBloodNum_ = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("attack_info")) do
			local var_3_0 = iter_3_1.fighter_

			if not var_3_0:isDeath() and not var_3_0:isAffected() and var_3_0:getTeamType() ~= arg_3_0:getTeamType() and var_3_0:isHasBuffByID(var_0_11) and var_0_2.weightedChoise({
				var_0_15,
				1 - var_0_15
			}) == 1 then
				local var_3_1 = arg_3_0:createAttackUnits({
					var_3_0
				}, var_0_16)

				for iter_3_2, iter_3_3 in ipairs(var_3_1) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		end
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_5 then
		arg_4_0:checkBloodAction(arg_4_1)

		arg_4_0.totalBloodNum_ = arg_4_0.totalBloodNum_ + 1
	end
end

function var_0_3.checkBloodAction(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.target
	local var_5_1 = #var_5_0:getBuffsByID(var_0_5) + 1
	local var_5_2 = arg_5_0.oldBloodBuffCount_[var_5_0] or 0

	if var_5_1 >= var_0_6 and (not var_5_0:isHasBuffByID(var_0_9) or not arg_5_0:isHasBuffByID(var_0_10) or var_5_2 < var_0_6) then
		local var_5_3 = arg_5_0:createNewBuffs({
			var_0_9
		}, var_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		var_5_0:addBuffs(var_5_3)
		arg_5_0:addBuffs(arg_5_0:createNewBuffs({
			var_0_10
		}, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
	end

	if var_5_1 >= var_0_7 and var_5_2 < var_0_7 then
		local var_5_4 = arg_5_0:createNewBuffs({
			var_0_11,
			var_0_12
		}, var_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		var_5_0:addBuffs(var_5_4)
	end

	if var_5_1 >= var_0_8 and var_5_2 < var_0_8 then
		local var_5_5 = arg_5_0:createNewBuffs({
			var_0_13
		}, var_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		var_5_0:addBuffs(var_5_5)
	end

	if not arg_5_0.oldBloodBuffCount_[var_5_0] then
		arg_5_0.oldBloodBuffCount_[var_5_0] = 1
	else
		arg_5_0.oldBloodBuffCount_[var_5_0] = arg_5_0.oldBloodBuffCount_[var_5_0] + 1
	end
end

function var_0_3.createNewBuffs(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	var_0_3.super.buffRemoveAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_5 then
		arg_7_0:checkBloodRmAction(arg_7_1)
	end
end

function var_0_3.checkBloodRmAction(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.target
	local var_8_1 = var_8_0:getBuffsByID(var_0_5)

	if not arg_8_0.oldBloodBuffCount_[var_8_0] then
		local var_8_2 = 0
	end

	if #var_8_1 < var_0_6 then
		var_8_0:removeBuffByID(var_0_9)
	end

	if #var_8_1 < var_0_7 then
		var_8_0:removeBuffByID(var_0_11)
	end

	arg_8_0.oldBloodBuffCount_[var_8_0] = arg_8_0.oldBloodBuffCount_[var_8_0] - 1
	arg_8_0.totalBloodNum_ = arg_8_0.totalBloodNum_ - 1

	if arg_8_0.totalBloodNum_ == 0 then
		arg_8_0:removeBuffByID(var_0_10)
	end
end

function var_0_3.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	if arg_9_2 > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_0 = 0
		local var_9_1 = {}

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1:isHasBuffByID(var_0_13) then
				var_9_0 = var_9_0 + 1

				table.insert(var_9_1, iter_9_1)
			end
		end

		if var_9_0 > 0 then
			arg_9_2 = arg_9_2 / (1 + var_9_0)

			local var_9_2 = arg_9_0:createAttackUnits(var_9_1, var_0_14)

			for iter_9_2, iter_9_3 in ipairs(var_9_2) do
				iter_9_3.change_harm = arg_9_2

				table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
				table.insert(arg_9_0.records_.special_units, iter_9_3)
			end
		end
	end

	return var_0_3.super.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_1.skillID == var_0_14 and arg_10_1.change_harm and arg_10_1.change_harm > 0 then
		var_10_2 = arg_10_1.change_harm * arg_10_1.target:getAPJianShang()
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

return var_0_3
