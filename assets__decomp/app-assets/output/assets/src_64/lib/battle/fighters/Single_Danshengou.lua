local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Danshengou", var_0_1.ctx.battle.requireFighter("SingleBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = -100
local var_0_7 = 40010042
local var_0_8 = math.min
local var_0_9 = math.max
local var_0_10 = math.abs
local var_0_11 = math.floor
local var_0_12 = math.ceil
local var_0_13 = math.sqrt

function var_0_3.updateUnitDataBySpecialHero(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	local var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_1.target == arg_1_0 and var_1_5 < 0 then
		var_1_2 = var_1_2 + var_1_5 * var_0_6
	end

	return var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5
end

function var_0_3.applyBuffHarm(arg_2_0)
	local var_2_0 = 0
	local var_2_1 = 0
	local var_2_2 = 0
	local var_2_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_2_0, var_2_1, var_2_2 = unpack(arg_2_0.reportBuffHarms_[tostring(var_0_1.ctx.battle.count)] or {
			0,
			0,
			0
		})
	else
		local function var_2_4(arg_3_0)
			for iter_3_0 = #arg_3_0, 1, -1 do
				local var_3_0 = arg_3_0[iter_3_0]

				if var_3_0:getType() == var_0_2.BuffType.ENERGY_CHANGE and var_3_0:getMana() < 0 then
					local var_3_1 = var_3_0:getMana() * var_0_6

					var_2_0 = var_2_0 + var_3_1
					var_2_3 = var_3_0.fighter

					if var_3_0:getMana() < 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						var_2_3:updateHarms(var_3_1)
						var_2_3:buffHarmFeedBack(var_3_1)
					end
				end
			end
		end

		var_2_4(arg_2_0.buffs_)
		var_2_4(arg_2_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB)

		var_2_1 = var_2_1 * arg_2_0:getDCureRate()

		if var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD and arg_2_0:getTeamType() == var_0_2.TeamType.B then
			var_2_1 = 0
		end

		var_2_1 = 0
		var_2_2 = 0
		arg_2_0.records_.buff_harms[tostring(var_0_1.ctx.battle.count)] = {
			var_2_0,
			var_2_1,
			var_2_2
		}
	end

	if var_2_1 == 0 and var_2_0 == 0 and var_2_2 == 0 then
		return
	end

	local var_2_5 = var_0_9(0, arg_2_0:getHp() - var_2_0 + var_2_1)

	if var_2_1 - var_2_0 > 0 then
		var_2_5 = var_0_8(arg_2_0:getHp() - var_2_0 + var_2_1, arg_2_0:getHpLimit())
	end

	if var_2_1 ~= 0 then
		arg_2_0.cureHp = arg_2_0.cureHp + var_2_1
	end

	if var_2_0 - var_2_1 > 0 and next(arg_2_0.shieldBuffs_) then
		local var_2_6 = arg_2_0.shieldBuffs_[1]
		local var_2_7 = arg_2_0.shieldBuffs_[1].fighter
		local var_2_8 = var_2_6:getShieldNum() - 1

		if var_2_0 - var_2_1 > var_2_6:getShieldMaxHarm() then
			var_2_5 = var_0_9(0, arg_2_0:getHp() - var_2_0 + var_2_1 + var_2_6:getShieldMaxHarm())

			arg_2_0:updateHp(var_2_5)
		end

		if var_2_8 <= 0 then
			arg_2_0:removeBuffByID(var_2_6:getTableID())
		else
			var_2_6:setShieldNum(var_2_8)
		end

		var_2_7:shieldFeedBack(arg_2_0, var_2_6)
	else
		arg_2_0:updateHp(var_2_5)
	end

	arg_2_0:updateEnergyTo(arg_2_0:getEnergy() + var_2_2)
	arg_2_0:setOriHurt(var_2_0)

	return var_2_3
end

function var_0_3.checkSkillBreak(arg_4_0, arg_4_1)
	return
end

function var_0_3.selectTargetByTypeD2(arg_5_0, arg_5_1)
	local var_5_0 = {}

	arg_5_0.stormSkill_ = arg_5_0.stormSkill_ or {}
	arg_5_0.stormSkill_[tostring(arg_5_1)] = arg_5_0.stormSkill_[tostring(arg_5_1)] or {}

	local var_5_1
	local var_5_2
	local var_5_3
	local var_5_4 = arg_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_5_5 = arg_5_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_5_6 = arg_5_0:isAttackFriend() and var_5_4 or var_5_5
	local var_5_7 = var_0_4:scope(arg_5_1)
	local var_5_8 = arg_5_0:getX()

	for iter_5_0, iter_5_1 in ipairs(var_5_6) do
		local var_5_9 = iter_5_1:getX()

		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and var_5_7 >= math.abs(var_5_9 - var_5_8) and not var_0_0.table.keyof(arg_5_0.stormSkill_[tostring(arg_5_1)], iter_5_1) then
			table.insert(var_5_0, iter_5_1)
			table.insert(arg_5_0.stormSkill_[tostring(arg_5_1)], iter_5_1)
		end
	end

	return var_5_0
end

function var_0_3.beginAttack(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if not arg_6_0:canAttack() then
		return
	end

	if arg_6_0:getLeftInterval() > 0 then
		return
	end

	arg_6_0.stormSkill_ = nil

	var_0_3.super.beginAttack(arg_6_0)
end

function var_0_3.applyBuffMoves(arg_7_0)
	if var_0_1.ctx.battle.isEnergySkilling and arg_7_0.acttionInBlack_ ~= true and arg_7_0:isHasBuffByID(var_0_7) then
		return
	end

	var_0_3.super.super.applyBuffMoves(arg_7_0)
end

function var_0_3.addBuffs(arg_8_0, arg_8_1)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		if not iter_8_1:isFear() and not iter_8_1:isApUnable() and not iter_8_1:isAdUnable() and not iter_8_1:isExcuteAdCircle() and not iter_8_1:isAttackFriend() then
			table.insert(var_8_0, iter_8_1)
		end
	end

	var_0_3.super.addBuffs(arg_8_0, var_8_0)
end

return var_0_3
