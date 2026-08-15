local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hetun", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.06
local var_0_5 = 99999

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6)
	if arg_1_1 == var_0_2.FishSkill.SKILL then
		arg_1_4 = var_0_5
		arg_1_2 = false
		arg_1_3 = true
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6
end

function var_0_3.skillAction(arg_2_0, arg_2_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		arg_2_0:applySingleUnit(arg_2_1)
	else
		arg_2_0:xuliAction(arg_2_0.applySingleUnit, arg_2_1)
	end
end

function var_0_3.addSkillMessage(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_0:getRandomMessage("hetun")
	local var_3_1 = string.format(var_3_0[1], arg_3_0:getName(), arg_3_0:getSkillName())
	local var_3_2 = string.format(var_3_0[2], arg_3_0.target:getName(), arg_3_3)
	local var_3_3 = var_3_1 .. "|" .. var_3_2

	arg_3_0:addMessage(var_3_3)
end

function var_0_3.getCurrentSkill(arg_4_0)
	if var_0_2.weightedChoise({
		var_0_4,
		1 - var_0_4
	}) == 1 then
		return var_0_2.FishSkill.SKILL
	else
		return var_0_2.FishSkill.PUGONG
	end
end

function var_0_3.specialAttackEffect(arg_5_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_5_0 = "skeletons/ui_effect/activity_fish_fight/hetunshouji.png"
	local var_5_1 = var_0_2.AssetLoader.get():loadSprite(var_5_0)

	var_5_1:align(display.CENTER, 0, arg_5_0:getFighterModel():getHeight() * arg_5_0:getFighterModel():getScale() / 2 - 80)
	arg_5_0.target:playFloatAnimations_(var_5_1)
end

return var_0_3
