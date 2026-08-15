local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Qiaoxuan", var_0_1.ctx.battle.requireFighter("Qiaoxuan"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = 0.1
local var_0_6 = 0.001
local var_0_7 = 0.2

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.EnergyAttackSkill = 10002529
		arg_1_0.EnergyDefenceSkill = 10002530
	else
		arg_1_0.EnergyAttackSkill = 50020238
		arg_1_0.EnergyDefenceSkill = 50030238
	end

	arg_1_0.AwakeAttackMap = {
		[arg_1_0.EnergyAttackSkill] = arg_1_0.EnergyDefenceSkill,
		[arg_1_0.GreenAttackSkill] = arg_1_0.GreenDefenceSkill,
		[arg_1_0.BlueAttackSkill] = arg_1_0.BlueDefenceSkill
	}
	arg_1_0.AwakeDefenceMap = {
		[arg_1_0.EnergyDefenceSkill] = arg_1_0.EnergyAttackSkill,
		[arg_1_0.GreenDefenceSkill] = arg_1_0.GreenAttackSkill,
		[arg_1_0.BlueDefenceSkill] = arg_1_0.BlueAttackSkill
	}
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1, arg_2_2)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_2 then
		return
	end

	if arg_2_1.rootID_ == arg_2_0.EnergyAttackSkill or arg_2_1.rootID_ == arg_2_0.GreenAttackSkill or arg_2_1.rootID_ == arg_2_0.BlueAttackSkill then
		arg_2_0:AwakeSkill(arg_2_1, true)
	elseif arg_2_1.rootID_ == arg_2_0.EnergyDefenceSkill or arg_2_1.rootID_ == arg_2_0.GreenDefenceSkill or arg_2_1.rootID_ == arg_2_0.BlueDefenceSkill then
		arg_2_0:AwakeSkill(arg_2_1, false)
	end
end

function var_0_3.AwakeSkill(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_1.isAwakenUnit then
		return
	end

	local var_3_0 = var_0_5 + var_0_6 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

	if arg_3_0.skinSkillIndex_ == 1 then
		var_3_0 = var_3_0 + var_0_7
	end

	if var_0_2.weightedChoise({
		var_3_0,
		1 - var_3_0
	}) == 1 then
		local var_3_1 = (arg_3_2 and arg_3_0.AwakeAttackMap or arg_3_0.AwakeDefenceMap)[arg_3_1.rootID_]

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_3_0.specialSkills_ = var_0_4.new({
				fighter = arg_3_0,
				skillID = var_3_1
			})

			arg_3_0:beginAttackEnd(arg_3_0.specialSkills_, true)
		end
	end
end

return var_0_3
