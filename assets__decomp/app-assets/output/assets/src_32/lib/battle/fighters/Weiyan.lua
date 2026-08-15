local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Weiyan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 80010006
local var_0_9 = 81020006
local var_0_10 = 40012025
local var_0_11 = 40011312
local var_0_12 = 2
local var_0_13 = 2
local var_0_14 = 600

function var_0_3.singleLoop(arg_1_0)
	arg_1_0:checkReborn()
	var_0_3.super.singleLoop(arg_1_0)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and #arg_1_0.reportDieCounts_ > 0 and arg_1_0.reportDieCounts_[1] > 0 and var_0_1.ctx.battle.count > arg_1_0.reportDieCounts_[1] then
		table.remove(arg_1_0.reportDieCounts_, 1)

		if not arg_1_0:isDeath() then
			arg_1_0:updateHp(0)
			arg_1_0:die()
		end
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.records_.xixue_info = {}
	arg_2_0.xixueInfo_ = {}
	arg_2_0.rebornDuration = 0
end

function var_0_3.die(arg_3_0)
	arg_3_0.fighterModel:hideHeaderView()

	if arg_3_0.reviveCount_ then
		-- block empty
	elseif arg_3_0:canReborn() then
		if not arg_3_0.dieCounts_ then
			arg_3_0.dieCounts_ = {}
		end

		table.insert(arg_3_0.dieCounts_, var_0_1.ctx.battle.count)

		arg_3_0.reviveCount_ = var_0_1.ctx.battle.count + var_0_2.tables.battleConfig.reviveCount

		arg_3_0:getFighterModel():die()

		if var_0_1.ctx.battle.infoListener.death_info then
			table.insert(var_0_1.ctx.battle.infoListener.death_info, arg_3_0)
		end

		return
	end

	arg_3_0.hasReborn_ = true
	arg_3_0.rebornDuration = var_0_14

	var_0_3.super.die(arg_3_0)
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_8 and arg_4_1.fighter:getTeamType() == arg_4_0:getTeamType() and arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and arg_4_1.attackType == var_0_2.AttackType.AD then
		arg_4_0:addSkinDHarmBuff(arg_4_1.fighter, var_4_4)

		var_4_4 = var_4_4 * var_0_13
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.addSkinDHarmBuff(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1:getBuffByID(var_0_11)

	if not var_5_0 then
		var_5_0 = var_0_4.new({
			tableID = var_0_11,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(var_0_8),
			skillID = var_0_8,
			fighter = arg_5_0,
			target = arg_5_1
		})

		arg_5_1:addBuffs({
			var_5_0
		})
	end

	if var_5_0.manualDharm + arg_5_2 > arg_5_1:getHpLimit() * var_0_12 then
		arg_5_2 = arg_5_1:getHpLimit() * var_0_12 - var_5_0.manualDharm
		var_5_0.manualDharm = arg_5_1:getHpLimit() * var_0_12

		var_5_0:setDHarm(0 - arg_5_2)
	else
		var_5_0.manualDharm = var_5_0.manualDharm + arg_5_2

		var_5_0:setDHarm(0 - arg_5_2)
	end

	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
		arg_5_0.records_.xixue_info[tostring(arg_5_1.fighterIndex) .. tostring(var_0_1.ctx.battle.count)] = arg_5_2
	end

	arg_5_1:updateHpBar(true)
end

function var_0_3.forceDie(arg_6_0)
	arg_6_0.hasReborn_ = true
	arg_6_0.rebornDuration = var_0_14

	var_0_3.super.forceDie(arg_6_0)
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.die_counts = arg_7_0.dieCounts_ or {}
	var_7_0.xixue_info = arg_7_0.records_.xixue_info

	return var_7_0
end

function var_0_3.setupReport(arg_8_0, arg_8_1)
	var_0_3.super.setupReport(arg_8_0, arg_8_1)

	arg_8_0.reportDieCounts_ = arg_8_1.die_counts or {}
	arg_8_0.xixueInfo_ = arg_8_1.xixue_info
end

function var_0_3.checkReborn(arg_9_0)
	if arg_9_0.isDead_ then
		return
	end

	if arg_9_0.reviveFinish_ and arg_9_0.reviveFinish_ == var_0_1.ctx.battle.count then
		arg_9_0.reviveFinish_ = nil
		arg_9_0.reviveCount_ = nil
		arg_9_0.hasReborn_ = true
		arg_9_0.rebornDuration = var_0_14

		local var_9_0 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_9_1 = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_9_2 = var_0_5:init(var_9_0)
		local var_9_3 = var_0_5:step(var_9_0)
		local var_9_4 = math.min(var_9_2 + var_9_3 * var_9_1, arg_9_0:getHpLimit())

		arg_9_0:updateHp(var_9_4)
		arg_9_0.fighterModel:hideHeaderView(true)

		arg_9_0.playReborn_ = false
		arg_9_0.leftInterval_ = 0
		arg_9_0.skillRoll_ = false

		arg_9_0:resumeIdle()
		arg_9_0:addSkinBuff()
	end

	if not arg_9_0.reviveCount_ or arg_9_0.reviveCount_ > var_0_1.ctx.battle.count or arg_9_0.playReborn_ then
		return
	end

	arg_9_0.playReborn_ = true

	local var_9_5 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_9_6 = var_0_5:attackIndex(var_9_5)
	local var_9_7 = var_0_7:duration(arg_9_0:getModelID(), var_9_6)

	arg_9_0.reviveFinish_ = var_0_1.ctx.battle.count + var_9_7

	if var_9_6 then
		arg_9_0:playAttack(var_9_6, function()
			arg_9_0:resumeIdle()
		end)
	end
end

function var_0_3.canReborn(arg_11_0)
	if (arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) or 0) < 1 then
		return false
	end

	if arg_11_0.isSkinSkillOn_ and arg_11_0.skinSkillID_ == var_0_9 then
		if arg_11_0.rebornDuration > 0 then
			return false
		end
	elseif arg_11_0.hasReborn_ then
		return false
	end

	return true
end

function var_0_3.hasReborned(arg_12_0)
	if arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return false
	end

	return arg_12_0.hasReborn_
end

function var_0_3.forceReborn(arg_13_0)
	if arg_13_0.isSkinSkillOn_ and arg_13_0.skinSkillID_ == var_0_9 then
		if arg_13_0.rebornDuration > 0 then
			return
		end
	elseif arg_13_0.hasReborn_ then
		return
	end

	arg_13_0.reviveFinish_ = nil
	arg_13_0.reviveCount_ = nil
	arg_13_0.hasReborn_ = true
	arg_13_0.rebornDuration = var_0_14

	local var_13_0 = arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_13_1 = arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	local var_13_2 = var_0_5:init(var_13_0)
	local var_13_3 = var_0_5:step(var_13_0)
	local var_13_4 = math.min(var_13_2 + var_13_3 * var_13_1, arg_13_0:getHpLimit())

	arg_13_0:updateHp(var_13_4)
	arg_13_0.fighterModel:hideHeaderView(true)

	arg_13_0.playReborn_ = false

	arg_13_0:addSkinBuff()
end

function var_0_3.toDoPerFrames(arg_14_0)
	var_0_3.super.toDoPerFrames(arg_14_0)

	if arg_14_0.isSkinSkillOn_ and arg_14_0.skinSkillID_ == var_0_8 then
		for iter_14_0, iter_14_1 in pairs(arg_14_0.selfTeam_) do
			local var_14_0 = arg_14_0.xixueInfo_[tostring(iter_14_1.fighterIndex) .. tostring(var_0_1.ctx.battle.count)]

			if var_14_0 then
				arg_14_0:addSkinDHarmBuff(iter_14_1, var_14_0)
			end
		end
	end

	if not arg_14_0:isDeath() and arg_14_0.isSkinSkillOn_ and arg_14_0.skinSkillID_ == var_0_9 and arg_14_0.rebornDuration > 0 then
		arg_14_0.rebornDuration = arg_14_0.rebornDuration - 1
	end
end

function var_0_3.addSkinBuff(arg_15_0)
	if arg_15_0.isSkinSkillOn_ and arg_15_0.skinSkillID_ == var_0_9 then
		for iter_15_0, iter_15_1 in ipairs(arg_15_0.selfTeam_) do
			if not iter_15_1:isDeath() and not iter_15_1:isAffected() then
				local var_15_0 = arg_15_0:createNewBuffs({
					var_0_10
				}, iter_15_1, var_0_9)

				iter_15_1:addBuffs(var_15_0)
			end
		end
	end
end

return var_0_3
