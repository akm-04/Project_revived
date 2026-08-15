local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lvlingqihuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = {
	40010384
}
local var_0_8 = 3
local var_0_9 = 0.002
local var_0_10 = 0.1
local var_0_11 = {
	"Lvlingqi",
	"Lvlingqi_Awaken"
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.awaken_add_buff = {}
	arg_1_0.extraAD_ = 0
	arg_1_0.bloodyTarget_ = nil
end

function var_0_3.getUnitData(arg_2_0, arg_2_1)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.getUnitData(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and not var_2_0 then
		arg_2_1.target:addBuffs(arg_2_0:newBuff(var_0_7, arg_2_1.target, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))

		if var_2_1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			var_2_2 = var_2_2 * arg_2_0:getRandomRate(var_0_8)
		end
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.getRandomRate(arg_3_0, arg_3_1)
	local var_3_0 = math.ceil(arg_3_1) * 10

	if var_3_0 > 10 then
		return math.random(10, var_3_0) * 0.1
	else
		return 1
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_6.new({
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

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_0.summoner and not arg_5_0.summoner:isDeath() and not arg_5_0.summoner:isAffected() and arg_5_0.summoner.hero_:isAwaken() and arg_5_0:checkSummonerIsLvlingqi() then
		local var_5_0 = arg_5_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		if var_5_0 > 0 then
			local var_5_1 = false

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				if arg_5_0.awakenAddBuff[tostring(var_0_1.ctx.battle.count)] then
					var_5_1 = true
				end
			else
				local var_5_2 = var_0_9 * var_5_0 + var_0_10
				local var_5_3 = math.min(1, var_5_2)

				var_5_1 = var_0_2.weightedChoise({
					var_5_3,
					1 - var_5_3
				}) == 1

				if var_5_1 then
					arg_5_0.records_.awaken_add_buff[tostring(var_0_1.ctx.battle.count)] = 1
				end
			end

			if var_5_1 then
				arg_5_0.summoner:addAwakenBuff()
			end
		end
	end
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.awakenAddBuff = arg_6_1.awaken_add_buff
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.awaken_add_buff = arg_7_0.records_.awaken_add_buff

	return var_7_0
end

function var_0_3.setExtraAD(arg_8_0, arg_8_1)
	arg_8_0.extraAD_ = arg_8_0.extraAD_ + arg_8_1
end

function var_0_3.getAD(arg_9_0)
	return var_0_3.super.getAD(arg_9_0) + arg_9_0.extraAD_
end

function var_0_3.getTargets(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_1 == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_10_0.bloodyTarget_ and not arg_10_0.bloodyTarget_:isDeath() and (not arg_10_0.bloodyTarget_:isAffected() or not not arg_10_0.bloodyTarget_:isInvisible()) then
		return {
			arg_10_0.bloodyTarget_
		}
	end

	local var_10_0 = {}
	local var_10_1 = var_0_4:selectType(arg_10_1)

	if not arg_10_0.bloodyTarget_ and arg_10_0:getForceTarget() and not arg_10_0:getForceTarget():isDeath() then
		if var_10_1 == "C11" then
			local var_10_2 = arg_10_0:getForceTarget()

			if (arg_10_2.iniX_ < var_10_2:getX() and var_10_2:getX() <= arg_10_2:getX() or arg_10_2.iniX_ > var_10_2:getX() and var_10_2:getX() >= arg_10_2:getX()) and not arg_10_2.targets[var_10_2.fighterIndex] then
				arg_10_2.targets[var_10_2.fighterIndex] = var_10_2

				return {
					var_10_2
				}
			end

			return {}
		end

		return {
			arg_10_0:getForceTarget()
		}
	end

	if arg_10_0["selectTargetByType" .. var_10_1] then
		var_10_0 = arg_10_0["selectTargetByType" .. var_10_1](arg_10_0, arg_10_1, arg_10_2)
	else
		var_10_0 = var_0_5[var_10_1](arg_10_0, arg_10_1, arg_10_2)
	end

	return var_10_0
end

function var_0_3.getForceTarget(arg_11_0)
	if arg_11_0.bloodyTarget_ and not arg_11_0.bloodyTarget_:isDeath() and (not arg_11_0.bloodyTarget_:isAffected() or not not arg_11_0.bloodyTarget_:isInvisible()) then
		return arg_11_0.bloodyTarget_
	end

	return var_0_3.super.getForceTarget(arg_11_0)
end

function var_0_3.checkSummonerIsLvlingqi(arg_12_0)
	local var_12_0 = arg_12_0.summoner.hero_:className()

	if var_12_0 == var_0_11[1] or var_12_0 == var_0_11[2] then
		return true
	end

	return false
end

return var_0_3
