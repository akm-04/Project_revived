local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhoutaihuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 10000953
local var_0_5 = 10002342
local var_0_6 = {
	"Zhoutai",
	"Zhoutai_Awaken"
}

function var_0_3.die(arg_1_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_1_0.summoner and not arg_1_0.summoner:isDeath() then
		local var_1_0 = arg_1_0:createAttackUnits({
			arg_1_0.summoner
		}, var_0_4)

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end

	return var_0_3.super.die(arg_1_0)
end

function var_0_3.updateUnitDataBySpecialHero(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_5 > 0 and arg_2_0.summoner and arg_2_0:checkSummonerIsZhoutai() and not arg_2_0.summoner:isDeath() and arg_2_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_2_1.target == arg_2_0 then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_0.summoner
		}, var_0_5)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			iter_2_1.addCure = arg_2_5

			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

function var_0_3.checkSummonerIsZhoutai(arg_3_0)
	local var_3_0 = arg_3_0.summoner.hero_:className()

	if var_3_0 == var_0_6[1] or var_3_0 == var_0_6[2] then
		return true
	end

	return false
end

return var_0_3
