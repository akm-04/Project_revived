local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shayu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.2

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6)
	if arg_1_1 == var_0_2.FishSkill.SKILL then
		arg_1_4 = arg_1_0:getAttrByType(var_0_2.FishAttributeType.AD)

		if arg_1_3 then
			arg_1_4 = arg_1_4 * 2
		end
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

	local var_3_0 = arg_3_0:getRandomMessage("shayu")
	local var_3_1 = string.format(var_3_0[1], arg_3_0:getName())
	local var_3_2

	if arg_3_1 then
		local var_3_3 = arg_3_0:getRandomMessage("shanbi")

		var_3_2 = string.format(var_3_3[1], arg_3_0.target:getName())
	elseif arg_3_2 then
		local var_3_4 = arg_3_0:getRandomMessage("baoji")

		var_3_2 = string.format(var_3_4[1], arg_3_0.target:getName(), arg_3_3)
	else
		local var_3_5 = arg_3_0:getRandomMessage("mingzhong")

		var_3_2 = string.format(var_3_5[1], arg_3_0.target:getName(), arg_3_3)
	end

	local var_3_6 = var_3_1 .. "|" .. var_3_2

	arg_3_0:addMessage(var_3_6)
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

function var_0_3.specialAttackEffect(arg_5_0, arg_5_1, arg_5_2)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_5_0.target:playHPDeltas(-arg_5_1, arg_5_2)

	if not arg_5_0.target.shayuEffect_ then
		local var_5_0 = "skeletons/ui_effect/activity_fish_fight/shayushouji"
		local var_5_1 = var_0_2.createEffect(var_5_0, 0.7)

		var_5_1:addTo(arg_5_0.target:getEffectNode())
		var_5_1:play(function()
			var_5_1:setVisible(false)
		end)
		var_5_1:setPosition(0, 0)
		var_5_1:setScale(arg_5_0:getTeamType() == var_0_2.TeamType.A and -1 or 1)
		var_5_1:setScale(0.8)

		arg_5_0.target.shayuEffect_ = var_5_1
	else
		arg_5_0.target.shayuEffect_:setVisible(true)
		arg_5_0.target.shayuEffect_:play(function()
			arg_5_0.target.shayuEffect_:setVisible(false)
		end)
	end
end

return var_0_3
