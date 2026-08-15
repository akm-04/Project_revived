local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.2
local var_0_5 = 20

function var_0_3.skill(arg_1_0)
	local var_1_0 = arg_1_0:getHp() / arg_1_0:getHpLimit()
	local var_1_1 = arg_1_0.target:getHp() / arg_1_0.target:getHpLimit()

	arg_1_0:updateHp(math.ceil(var_1_1 * arg_1_0:getHpLimit()) + var_0_5)
	arg_1_0.target:updateHp(math.ceil(var_1_0 * arg_1_0.target:getHpLimit()))
	arg_1_0:playHPDeltas(var_0_5, false)
	arg_1_0:addSkillEffect()
	arg_1_0:addSkillMessage()
end

function var_0_3.skillAction(arg_2_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		arg_2_0:skill()
	else
		arg_2_0:buffAction(arg_2_0.skill)
	end
end

function var_0_3.addSkillMessage(arg_3_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_0:getRandomMessage("luyu")
	local var_3_1 = string.format(var_3_0[1], arg_3_0:getName(), arg_3_0:getSkillName())
	local var_3_2 = string.format(var_3_0[2], arg_3_0:getName(), var_0_5)
	local var_3_3 = var_3_1 .. "|" .. var_3_2

	arg_3_0:addMessage(var_3_3)
end

function var_0_3.addSkillEffect(arg_4_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_4_0.luyuEffect then
		local var_4_0 = "skeletons/ui_effect/activity_fish_fight/luyubuff"
		local var_4_1 = var_0_2.createEffect(var_4_0, 0.7)

		var_4_1:addTo(arg_4_0:getEffectNode())
		var_4_1:play(function()
			var_4_1:setVisible(false)
		end)

		arg_4_0.luyuEffect = var_4_1

		local var_4_2 = var_0_2.createEffect(var_4_0, 0.7)

		var_4_2:addTo(arg_4_0.target:getEffectNode())
		var_4_2:play(function()
			var_4_2:setVisible(false)
		end)

		arg_4_0.target.luyuEffect = var_4_2
	else
		arg_4_0.luyuEffect:setVisible(true)
		arg_4_0.luyuEffect:play(function()
			arg_4_0.luyuEffect:setVisible(false)
		end)
		arg_4_0.target.luyuEffect:setVisible(true)
		arg_4_0.target.luyuEffect:play(function()
			arg_4_0.target.luyuEffect:setVisible(false)
		end)
	end
end

function var_0_3.getCurrentSkill(arg_9_0)
	if var_0_2.weightedChoise({
		var_0_4,
		1 - var_0_4
	}) == 1 then
		return var_0_2.FishSkill.SKILL
	else
		return var_0_2.FishSkill.PUGONG
	end
end

return var_0_3
