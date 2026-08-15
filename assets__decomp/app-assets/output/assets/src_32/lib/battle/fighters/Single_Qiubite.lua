local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Qiubite", var_0_1.ctx.battle.requireFighter("SingleBoss"))
local var_0_4 = 5

function var_0_3.applyBuffHarm(arg_1_0)
	local var_1_0 = 0
	local var_1_1 = 0
	local var_1_2 = 0
	local var_1_3

	for iter_1_0 = #arg_1_0.buffs_, 1, -1 do
		local var_1_4 = arg_1_0.buffs_[iter_1_0]

		if var_1_4:getType() == var_0_2.BuffType.CONTINUE_HARM then
			var_1_0 = var_1_0 + var_1_4:getHarm()
			var_1_3 = var_1_4.fighter

			if var_1_4:getHarm() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				var_1_3:updateHarms(var_1_4:getHarm())
			end

			var_1_2 = var_1_2 + var_1_4:getMana()
		elseif var_1_4:getType() == var_0_2.BuffType.GAIN then
			var_1_1 = var_1_1 + var_1_4:getHarm()
		end
	end

	if var_1_0 > 0 then
		var_1_0 = var_1_0 * var_0_4
	end

	local var_1_5 = var_1_1 * arg_1_0:getDCureRate()

	if var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD and arg_1_0:getTeamType() == var_0_2.TeamType.B then
		var_1_5 = 0
	end

	if var_1_5 == 0 and var_1_0 == 0 and var_1_2 == 0 then
		return
	end

	local var_1_6 = math.max(0, arg_1_0:getHp() - var_1_0 + var_1_5)

	if var_1_5 - var_1_0 > 0 then
		var_1_6 = math.min(arg_1_0:getHp() - var_1_0 + var_1_5, arg_1_0:getHpLimit())
	end

	if var_1_5 ~= 0 then
		arg_1_0.cureHp = arg_1_0.cureHp + var_1_5
	end

	if var_1_0 > 0 then
		arg_1_0:updateEnergyByHarm(var_1_0)
	end

	local var_1_7 = var_1_2

	if var_1_0 - var_1_5 > 0 and next(arg_1_0.shieldBuffs_) then
		local var_1_8 = arg_1_0.shieldBuffs_[1]
		local var_1_9 = arg_1_0.shieldBuffs_[1].fighter
		local var_1_10 = var_1_8:getShieldNum() - 1

		if var_1_0 - var_1_5 > var_1_8:getShieldMaxHarm() then
			var_1_6 = math.max(0, arg_1_0:getHp() - var_1_0 + var_1_5 + var_1_8:getShieldMaxHarm())

			arg_1_0:updateHp(var_1_6)
		end

		if var_1_10 <= 0 then
			arg_1_0:removeBuffByID(var_1_8:getTableID())
		else
			var_1_8:setShieldNum(var_1_10)
		end

		var_1_9:shieldFeedBack(arg_1_0, var_1_8)
	else
		arg_1_0:updateHp(var_1_6)
	end

	arg_1_0:updateEnergyTo(arg_1_0:getEnergy() + var_1_7)
	arg_1_0:setOriHurt(var_1_0)

	return var_1_3
end

return var_0_3
