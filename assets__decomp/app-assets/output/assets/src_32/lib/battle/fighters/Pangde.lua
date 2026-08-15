local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pangde", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 30010010
local var_0_8 = 80010010
local var_0_9 = 40011427
local var_0_10 = 40011428

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.SkinSkillExtraBaojiCounts = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.basicHarm > 1 and arg_2_0.SkinSkillExtraBaojiCounts > 0 then
		arg_2_1.mustBaoji = true
		arg_2_0.SkinSkillExtraBaojiCounts = arg_2_0.SkinSkillExtraBaojiCounts - 1
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_8 and arg_2_1.skillID == var_0_7 then
		local var_2_0 = arg_2_1.target:getHuJia()
		local var_2_1 = arg_2_0:getHuJia()

		if var_2_1 < var_2_0 then
			local var_2_2 = math.max(var_2_0 - var_2_1, var_2_1) / 2
			local var_2_3 = var_0_4.new({
				tableID = var_0_9,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getLevel(),
				skillID = var_0_8,
				fighter = arg_2_0,
				target = arg_2_0,
				manualRevise = var_2_2
			})

			arg_2_0:addBuffs({
				var_2_3
			})

			local var_2_4 = var_0_4.new({
				tableID = var_0_10,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getLevel(),
				skillID = var_0_8,
				fighter = arg_2_0,
				target = arg_2_1.target,
				manualRevise = -var_2_2
			})

			arg_2_1.target:addBuffs({
				var_2_4
			})
		else
			arg_2_0.SkinSkillExtraBaojiCounts = 3
		end
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
end

return var_0_3
