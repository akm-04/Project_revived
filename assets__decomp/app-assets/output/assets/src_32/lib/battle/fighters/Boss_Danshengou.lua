local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Danshengou", var_0_1.ctx.battle.requireFighter("ProphesyBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = -10
local var_0_7 = 40010042
local var_0_8 = math.min
local var_0_9 = math.max
local var_0_10 = math.abs
local var_0_11 = math.floor
local var_0_12 = math.ceil
local var_0_13 = math.sqrt

function var_0_3.toDoPerFrames(arg_1_0)
	return
end

function var_0_3.updateUnitDataBySpecialHero(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if arg_2_1.target == arg_2_0 then
		if var_2_5 < 0 then
			var_2_2 = var_2_5 * var_0_6
		else
			var_2_2 = 0
		end
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.applyBuffHarm(arg_3_0)
	local var_3_0 = 0
	local var_3_1 = 0
	local var_3_2 = 0
	local var_3_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_3_0, var_3_1, var_3_2 = unpack(arg_3_0.reportBuffHarms_[tostring(var_0_1.ctx.battle.count)] or {
			0,
			0,
			0
		})
	else
		local function var_3_4(arg_4_0)
			for iter_4_0 = #arg_4_0, 1, -1 do
				local var_4_0 = arg_4_0[iter_4_0]

				if var_4_0:getType() == var_0_2.BuffType.ENERGY_CHANGE and var_4_0:getMana() < 0 then
					local var_4_1 = var_4_0:getMana() * var_0_6

					var_3_0 = var_3_0 + var_4_1
					var_3_3 = var_4_0.fighter

					if var_4_0:getMana() < 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						var_3_3:updateHarms(var_4_1)
						var_3_3:buffHarmFeedBack(var_4_1)
					end
				end
			end
		end

		var_3_4(arg_3_0.buffs_)
		var_3_4(arg_3_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB)

		var_3_1 = var_3_1 * arg_3_0:getDCureRate()

		if var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD and arg_3_0:getTeamType() == var_0_2.TeamType.B then
			var_3_1 = 0
		end

		var_3_1 = 0
		var_3_2 = 0
		arg_3_0.records_.buff_harms[tostring(var_0_1.ctx.battle.count)] = {
			var_3_0,
			var_3_1,
			var_3_2
		}
	end

	if var_3_1 == 0 and var_3_0 == 0 and var_3_2 == 0 then
		return
	end

	local var_3_5 = var_0_9(0, arg_3_0:getHp() - var_3_0 + var_3_1)

	if var_3_1 - var_3_0 > 0 then
		var_3_5 = var_0_8(arg_3_0:getHp() - var_3_0 + var_3_1, arg_3_0:getHpLimit())
	end

	if var_3_1 ~= 0 then
		arg_3_0.cureHp = arg_3_0.cureHp + var_3_1
	end

	if var_3_0 - var_3_1 > 0 and next(arg_3_0.shieldBuffs_) then
		local var_3_6 = arg_3_0.shieldBuffs_[1]
		local var_3_7 = arg_3_0.shieldBuffs_[1].fighter
		local var_3_8 = var_3_6:getShieldNum() - 1

		if var_3_0 - var_3_1 > var_3_6:getShieldMaxHarm() then
			var_3_5 = var_0_9(0, arg_3_0:getHp() - var_3_0 + var_3_1 + var_3_6:getShieldMaxHarm())

			arg_3_0:updateHp(var_3_5)
		end

		if var_3_8 <= 0 then
			arg_3_0:removeBuffByID(var_3_6:getTableID())
		else
			var_3_6:setShieldNum(var_3_8)
		end

		var_3_7:shieldFeedBack(arg_3_0, var_3_6)
	else
		arg_3_0:updateHp(var_3_5)
	end

	arg_3_0:updateEnergyTo(arg_3_0:getEnergy() + var_3_2)
	arg_3_0:setOriHurt(var_3_0)

	return var_3_3
end

function var_0_3.checkSkillBreak(arg_5_0, arg_5_1)
	return
end

function var_0_3.selectTargetByTypeD2(arg_6_0, arg_6_1)
	local var_6_0 = {}

	arg_6_0.stormSkill_ = arg_6_0.stormSkill_ or {}
	arg_6_0.stormSkill_[tostring(arg_6_1)] = arg_6_0.stormSkill_[tostring(arg_6_1)] or {}

	local var_6_1
	local var_6_2
	local var_6_3
	local var_6_4 = arg_6_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_6_5 = arg_6_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_6_6 = arg_6_0:isAttackFriend() and var_6_4 or var_6_5
	local var_6_7 = var_0_4:scope(arg_6_1)
	local var_6_8 = arg_6_0:getX()

	for iter_6_0, iter_6_1 in ipairs(var_6_6) do
		local var_6_9 = iter_6_1:getX()

		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_7 >= math.abs(var_6_9 - var_6_8) and not var_0_0.table.keyof(arg_6_0.stormSkill_[tostring(arg_6_1)], iter_6_1) then
			table.insert(var_6_0, iter_6_1)
			table.insert(arg_6_0.stormSkill_[tostring(arg_6_1)], iter_6_1)
		end
	end

	return var_6_0
end

function var_0_3.beginAttack(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if not arg_7_0:canAttack() then
		return
	end

	if arg_7_0:getLeftInterval() > 0 then
		return
	end

	arg_7_0.stormSkill_ = nil

	var_0_3.super.beginAttack(arg_7_0)
end

function var_0_3.applyBuffMoves(arg_8_0)
	if var_0_1.ctx.battle.isEnergySkilling and arg_8_0.acttionInBlack_ ~= true and arg_8_0:isHasBuffByID(var_0_7) then
		return
	end

	var_0_3.super.super.applyBuffMoves(arg_8_0)
end

function var_0_3.addBuffs(arg_9_0, arg_9_1)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		if not iter_9_1:isFear() and not iter_9_1:isApUnable() and not iter_9_1:isAdUnable() and not iter_9_1:isExcuteAdCircle() and not iter_9_1:isAttackFriend() then
			table.insert(var_9_0, iter_9_1)
		end
	end

	var_0_3.super.addBuffs(arg_9_0, var_9_0)
end

return var_0_3
