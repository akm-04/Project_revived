local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("HanxiandiInvisible", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 30010031
local var_0_6 = 0.08
local var_0_7 = 0.2
local var_0_8 = 2
local var_0_9 = 40011172
local var_0_10 = 80010058

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.bloodBuffInfo = {}
	arg_1_0.records_.unit_harm_change = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_2_0:updateHp(0)
		arg_2_0:die()

		return
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_1:isDeath() then
			local var_2_0 = iter_2_1:getBuffsByID(var_0_5)

			if not arg_2_0.bloodBuffInfo[iter_2_1] or arg_2_0.bloodBuffInfo[iter_2_1] < #var_2_0 then
				arg_2_0.bloodBuffInfo[iter_2_1] = #var_2_0
			end
		end
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_2_0.unitHarmChange[tostring(var_0_1.ctx.battle.count)] and type(arg_2_0.unitHarmChange[tostring(var_0_1.ctx.battle.count)]) == "table" then
		for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
			if arg_2_0.unitHarmChange[tostring(var_0_1.ctx.battle.count)][iter_2_3.fighterIndex] and arg_2_0.unitHarmChange[tostring(var_0_1.ctx.battle.count)][iter_2_3.fighterIndex] > 0 then
				local var_2_1 = arg_2_0.unitHarmChange[tostring(var_0_1.ctx.battle.count)][iter_2_3.fighterIndex]
				local var_2_2 = var_0_4.new({
					level = 1,
					tableID = var_0_9,
					start = var_0_1.ctx.battle.count,
					skillID = var_0_10,
					fighter = arg_2_0.summoner,
					target = iter_2_3,
					manualHarmRevise = var_2_1 * var_0_7 * var_0_8
				})

				iter_2_3:addBuffs({
					var_2_2
				})

				arg_2_0.unitHarmChange[tostring(var_0_1.ctx.battle.count)][iter_2_3.fighterIndex] = 0
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_0.summoner.isSkinSkillOn_ and var_3_2 > 0 and arg_3_1.target:getTeamType() and arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and not arg_3_1.target:isDeath() and not arg_3_1.target:isAffected() and arg_3_0.bloodBuffInfo[arg_3_1.target] and arg_3_0.bloodBuffInfo[arg_3_1.target] > 0 then
		local var_3_6 = var_3_2 * var_0_6 * arg_3_0.bloodBuffInfo[arg_3_1.target]

		var_3_2 = math.max(var_3_2 - var_3_6, 0)

		if not arg_3_0.records_.unit_harm_change[tostring(var_0_1.ctx.battle.count)] then
			arg_3_0.records_.unit_harm_change[tostring(var_0_1.ctx.battle.count)] = {}
		end

		if not arg_3_0.records_.unit_harm_change[tostring(var_0_1.ctx.battle.count)][arg_3_1.target.fighterIndex] then
			arg_3_0.records_.unit_harm_change[tostring(var_0_1.ctx.battle.count)][arg_3_1.target.fighterIndex] = 0
		end

		arg_3_0.records_.unit_harm_change[tostring(var_0_1.ctx.battle.count)][arg_3_1.target.fighterIndex] = var_3_6 + arg_3_0.records_.unit_harm_change[tostring(var_0_1.ctx.battle.count)][arg_3_1.target.fighterIndex]

		local var_3_7 = var_0_4.new({
			level = 100,
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			skillID = var_0_10,
			fighter = arg_3_0.summoner,
			target = arg_3_1.target,
			manualHarmRevise = var_3_6 * var_0_7 * var_0_8
		})

		arg_3_1.target:addBuffs({
			var_3_7
		})
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.unitHarmChange = arg_4_1.unit_harm_change
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.unit_harm_change = arg_5_0.records_.unit_harm_change

	return var_5_0
end

function var_0_3.checkMove(arg_6_0)
	return false
end

function var_0_3.canAttack(arg_7_0)
	return false
end

function var_0_3.isAffected(arg_8_0)
	return true
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None then
			return
		end
	end

	arg_9_0:updateHp(0)
	arg_9_0:die()
end

return var_0_3
