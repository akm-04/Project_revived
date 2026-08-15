local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiandao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = 30010027
local var_0_7 = 10000179

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isdefend = false
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if arg_2_0:acttionInBlack() then
		if arg_2_0:isHasBuffByID(var_0_6) then
			arg_2_0.isdefend = true

			arg_2_0:getFighterModel():pause()
		end

		if arg_2_0.isdefend and not arg_2_0:isHasBuffByID(var_0_6) then
			arg_2_0:getFighterModel():resume()
			arg_2_0:attackBack()

			arg_2_0.isdefend = false
		end
	end
end

function var_0_3.attackBack(arg_3_0)
	local var_3_0 = var_0_7
	local var_3_1 = var_0_4:sound(var_3_0)

	var_0_1.ctx.battle.pushSoundQueue(var_3_1)

	local var_3_2 = var_0_4:attackIndex(var_3_0)

	arg_3_0:playAttack(var_3_2)

	arg_3_0.unitSkills_ = var_0_5.new({
		fighter = arg_3_0,
		skillID = var_3_0
	})

	arg_3_0:beginAttackEnd(arg_3_0.unitSkills_)
end

function var_0_3.die(arg_4_0)
	var_0_3.super.die(arg_4_0)

	if arg_4_0.isdefend then
		arg_4_0:getFighterModel():resume()

		arg_4_0.isdefend = false
	end
end

return var_0_3
