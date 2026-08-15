local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Madai", var_0_1.ctx.battle.requireFighter("Madai"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 1
local var_0_6 = 0.01
local var_0_7 = 40011789

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraHarm = 0
end

function var_0_3.playShanbi(arg_2_0, arg_2_1)
	var_0_3.super.playShanbi(arg_2_0, arg_2_1)

	arg_2_0.extraHarm = (var_0_5 + arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_6) * arg_2_0:getAttrByType(var_0_2.AttributeType.AGILE)
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_1.basicHarm > 0 then
		arg_3_1:setExtraHarm(arg_3_0.extraHarm)

		arg_3_0.extraHarm = 0

		arg_3_1.target:addBuffs({
			var_0_4.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
				fighter = arg_3_0,
				target = arg_3_1.target
			})
		})
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)
end

return var_0_3
