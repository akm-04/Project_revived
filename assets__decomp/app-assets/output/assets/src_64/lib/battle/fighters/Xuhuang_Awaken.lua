local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuhuang", var_0_1.ctx.battle.requireFighter("Xuhuang"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = 40010747
local var_0_7 = 10
local var_0_8 = 0.2
local var_0_9 = 0.002
local var_0_10 = 0.1
local var_0_11 = 90

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.dHarmBuffCount_ = 0
	arg_2_0.awakeTwiceCount = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.dHarmBuffCount_ < var_0_7 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if arg_3_0.dHarmBuffCount_ < var_0_7 and iter_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and var_0_5:dbuffType(iter_3_1:getTableID()) == var_0_2.DBuffType.XUAN_YUN then
				arg_3_0.dHarmBuffCount_ = arg_3_0.dHarmBuffCount_ + 1

				local var_3_0 = arg_3_0:newBuffs({
					var_0_6
				}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake), arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake), arg_3_0)

				arg_3_0:addBuffs(var_3_0)
			end
		end
	end
end

function var_0_3.newBuffs(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_3,
			skillID = arg_4_2,
			fighter = arg_4_0,
			target = arg_4_4
		})

		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

function var_0_3.removeBuffs(arg_5_0, arg_5_1)
	var_0_3.super.removeBuffs(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_6 and arg_5_0.dHarmBuffCount_ > 0 then
		arg_5_0.dHarmBuffCount_ = arg_5_0.dHarmBuffCount_ - 1
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if var_6_2 > 0 and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and (arg_6_0.awakeTwiceCount == 0 or var_0_1.ctx.battle.count - arg_6_0.awakeTwiceCount > var_0_11) then
		var_6_2 = var_6_2 + arg_6_0:getHpLimit() * var_0_10
		arg_6_0.awakeTwiceCount = var_0_1.ctx.battle.count
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.afterDamageHarm(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_7_0:hasXuanYunBuff(arg_7_2.target) then
		local var_7_0 = arg_7_1 * (var_0_8 + var_0_9 * arg_7_0:getLevel())

		arg_7_0:updateHp(var_7_0 + arg_7_0:getHp())
		arg_7_0.fighterModel:playHPDeltas({
			{
				var_7_0,
				false
			}
		}, nil)
	end

	var_0_3.super.afterDamageHarm(arg_7_0, arg_7_1, arg_7_2)
end

function var_0_3.hasXuanYunBuff(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1:getBuffs()

	for iter_8_0, iter_8_1 in ipairs(var_8_0) do
		if var_0_5:dbuffType(iter_8_1:getTableID()) == var_0_2.DBuffType.XUAN_YUN then
			return true
		end
	end

	return false
end

return var_0_3
