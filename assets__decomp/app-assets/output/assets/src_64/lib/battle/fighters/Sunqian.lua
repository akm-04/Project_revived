local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunqian", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skinSkill
local var_0_6 = 40010527
local var_0_7 = 40010528
local var_0_8 = 0.5
local var_0_9 = {
	40010527,
	40010528
}
local var_0_10 = 210
local var_0_11 = 40010032
local var_0_12 = 40010031
local var_0_13 = 20010124

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isInitBuff_ = false
	arg_1_0.isSkinBuffAddReady_ = false
	arg_1_0.skinSpeedAttr_ = 0
	arg_1_0.skinBuffCount_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.isInitBuff_ then
		arg_2_0:addInitialBuff()

		arg_2_0.isInitBuff_ = true
	end

	if arg_2_0.skinBuffCount_ > 0 then
		arg_2_0.skinBuffCount_ = arg_2_0.skinBuffCount_ - 1

		if arg_2_0.skinBuffCount_ <= 0 then
			if not arg_2_0:isDeath() then
				arg_2_0:addInitialBuff()
			end

			for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
				if not iter_2_1:isDeath() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None then
					for iter_2_2, iter_2_3 in ipairs(var_0_9) do
						iter_2_1:removeBuffByID(iter_2_3)
					end
				end
			end
		end
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	var_0_3.super.buffAddAction(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.target

	if arg_3_1:getTableID() == var_0_11 and #var_3_0:getBuffsByID(var_0_11) + 1 > 1 then
		local var_3_1 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
		local var_3_2 = arg_3_0:newBuff({
			var_0_12
		}, var_3_0, var_3_1)

		var_3_0:addBuffs(var_3_2)
	end

	if arg_3_1:getTableID() == var_0_6 then
		arg_3_1.manualRevise = arg_3_1.target:getAD() * var_0_8
	elseif arg_3_1:getTableID() == var_0_7 then
		arg_3_1.manualRevise = arg_3_0.skinSpeedAttr_
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == arg_5_0:getEnergySkillID() then
		arg_5_0.isSkinBuffAddReady_ = true
	end
end

function var_0_3.addSkinBuff(arg_6_0)
	arg_6_0.skinBuffCount_ = var_0_10

	local var_6_0 = #arg_6_0:getBuffsByID(var_0_13)
	local var_6_1 = 0
	local var_6_2 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if iter_6_1 ~= arg_6_0 and not iter_6_1:isDeath() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_6_1 = var_6_1 + 1

			table.insert(var_6_2, iter_6_1)
		end
	end

	if var_6_0 > 0 then
		local var_6_3, var_6_4 = arg_6_0:getBuffsByID(var_0_13)[1]:getAttr()

		arg_6_0.skinSpeedAttr_ = var_6_0 * var_6_3 / var_6_1

		arg_6_0:removeBuffByID(var_0_13)
	else
		arg_6_0.skinSpeedAttr_ = 0
	end

	for iter_6_2, iter_6_3 in ipairs(var_6_2) do
		local var_6_5 = arg_6_0:newBuff(var_0_9, iter_6_3, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		iter_6_3:addBuffs(var_6_5)
	end

	local var_6_6 = arg_6_0:newBuff({
		var_0_6
	}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

	arg_6_0:addBuffs(var_6_6)
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0:getEnergySkillID() then
		if arg_7_0.isSkinBuffAddReady_ then
			arg_7_0.isSkinBuffAddReady_ = false

			if arg_7_0.isSkinSkillOn_ then
				arg_7_0:addSkinBuff()
			end
		end

		local var_7_0 = arg_7_1.target

		if var_7_0:getSummonType() == var_0_2.summonMonsterType.Copy then
			var_7_0:updateHp(0)
			var_7_0:die()
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0
	local var_8_1 = {}
	local var_8_2 = arg_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_8_3 = {}

	for iter_8_0, iter_8_1 in ipairs(var_8_2) do
		if not iter_8_1:isDeath() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_8_3, iter_8_1)
		end
	end

	for iter_8_2, iter_8_3 in ipairs(var_8_3) do
		if not var_8_0 then
			var_8_0 = iter_8_3:getEnergy()
			var_8_1 = {
				iter_8_3
			}
		elseif var_8_0 > iter_8_3:getEnergy() then
			var_8_1 = {
				iter_8_3
			}
			var_8_0 = iter_8_3:getEnergy()
		elseif iter_8_3:getEnergy() == var_8_0 then
			table.insert(var_8_1, iter_8_3)
		end
	end

	local var_8_4

	if #var_8_1 > 1 then
		var_8_4 = var_8_1[math.random(1, #var_8_1)]
	else
		var_8_4 = var_8_1[1]
	end

	return {
		var_8_4
	}
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	var_0_3.super.deathFeedback(arg_9_0, arg_9_1)

	if arg_9_1:getTeamType() == arg_9_0:getTeamType() and arg_9_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_9_0:removeSpeedBuff()
	end
end

function var_0_3.addSpeedBuff(arg_10_0)
	local var_10_0
	local var_10_1 = arg_10_0:newBuff({
		var_0_13
	}, arg_10_0, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	arg_10_0:addBuffs(var_10_1)
end

function var_0_3.removeSpeedBuff(arg_11_0)
	local var_11_0 = arg_11_0:getBuffsByID(var_0_13)

	if next(var_11_0) ~= nil then
		arg_11_0:removeBuffs(var_11_0[1])
	end
end

function var_0_3.addInitialBuff(arg_12_0)
	if arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 then
		return
	end

	local var_12_0 = 0
	local var_12_1 = arg_12_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	for iter_12_0, iter_12_1 in ipairs(var_12_1) do
		if not iter_12_1:isDeath() and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_12_0 = var_12_0 + 1
		end
	end

	local var_12_2 = var_12_0 - 1

	if var_12_2 >= 1 then
		for iter_12_2 = 1, var_12_2 do
			arg_12_0:addSpeedBuff()
		end
	end
end

return var_0_3
