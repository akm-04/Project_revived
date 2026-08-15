local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("FightFish")
local var_0_4 = var_0_2.tables.activityFish
local var_0_5 = 0.25
local var_0_6 = 2
local var_0_7 = {
	0.5,
	0.15,
	0.1,
	0.1,
	0.15
}
local var_0_8 = 0.6
local var_0_9 = 5

function var_0_3.ctor(arg_1_0)
	arg_1_0:init()
end

function var_0_3.init(arg_2_0)
	arg_2_0.records_ = {}
	arg_2_0.records_.attack = {}
	arg_2_0.records_.skill = {}
	arg_2_0.records_.trigger_skill = {}
	arg_2_0.records_.special_skill = {}
	arg_2_0.records_.random_event = {}
	arg_2_0.___attrCache = {}
end

function var_0_3.populateWithTableID(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.tableID = arg_3_1

	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport then
		arg_3_0.scene = cc.Director:getInstance():getRunningScene()
		arg_3_0.window = arg_3_0.scene.window
	end

	arg_3_0.leftInterval_ = arg_3_0:getInterval()
	arg_3_0.buffs_ = {}
	arg_3_0.sceneBuffs_ = {}
	arg_3_0.buffsEffect_ = {}

	arg_3_0:initHp()
	arg_3_0:initModel()
end

function var_0_3.initHp(arg_4_0)
	arg_4_0:setupHpLimit()

	arg_4_0.hp_ = arg_4_0:getHpLimit()
end

function var_0_3.setupHpLimit(arg_5_0)
	arg_5_0.hpLimit_ = arg_5_0:getAttrByType(var_0_2.FishAttributeType.HP)
end

function var_0_3.getHpLimit(arg_6_0)
	return arg_6_0.hpLimit_
end

function var_0_3.initModel(arg_7_0)
	if not arg_7_0.fighterModel and var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_7_0.fighterModel = var_0_2.AssetLoader.get():loadSprite("windows/activities/1226/fish/" .. arg_7_0:getTableID() .. ".png")
	end
end

function var_0_3.getAttrByType(arg_8_0, arg_8_1)
	if not arg_8_0.___attrCache[arg_8_1] then
		local var_8_0 = var_0_4:attr(arg_8_0:getTableID(), arg_8_1) + arg_8_0:getBuffAttr(arg_8_1)

		arg_8_0.___attrCache[arg_8_1] = math.max(var_8_0, 0)
	end

	return arg_8_0.___attrCache[arg_8_1]
end

function var_0_3.canAttack(arg_9_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return arg_9_0.reportSkills_[tostring(var_0_1.ctx.battle.count)]
	else
		return arg_9_0.leftInterval_ <= 0
	end
end

function var_0_3.getLeftInterval(arg_10_0)
	return arg_10_0.leftInterval_
end

function var_0_3.updateLeftInterval(arg_11_0)
	arg_11_0.leftInterval_ = arg_11_0.leftInterval_ - arg_11_0:getAttrByType(var_0_2.FishAttributeType.SPEED)
end

function var_0_3.getFighterModel(arg_12_0)
	if not arg_12_0.fighterModel then
		return
	end

	return arg_12_0.fighterModel
end

function var_0_3.resetLeftInterval(arg_13_0)
	arg_13_0.leftInterval_ = arg_13_0:getInterval()
end

function var_0_3.getInterval(arg_14_0)
	return 1000
end

function var_0_3.getTableID(arg_15_0)
	return arg_15_0.tableID
end

function var_0_3.setTarget(arg_16_0, arg_16_1)
	arg_16_0.target = arg_16_1
end

function var_0_3.getTarget(arg_17_0)
	return arg_17_0.target
end

function var_0_3.beginAttack(arg_18_0)
	local var_18_0 = arg_18_0:getSkill()
	local var_18_1 = arg_18_0:randomEvent()

	if arg_18_0:isDeath() then
		arg_18_0:delayStartBattle()

		return
	end

	arg_18_0:resetLeftInterval()
	arg_18_0:updateBuffHpDelta()

	local var_18_2 = arg_18_0.target:beforeAttack(var_18_0)

	if not var_18_1 or not var_18_2 or arg_18_0:isDeath() then
		arg_18_0:delayStartBattle()

		return
	end

	arg_18_0:attack(var_18_0)

	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		arg_18_0:updateBuffCount()
	end
end

function var_0_3.startBattle(arg_19_0)
	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_19_0:updateBuffCount()
	end

	arg_19_0.scene:startBattle()
end

function var_0_3.delayStartBattle(arg_20_0, arg_20_1)
	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_20_0.scene:delayStartBattle(arg_20_1, handler(arg_20_0, arg_20_0.updateBuffCount))
	end
end

function var_0_3.beginSpecialSkill(arg_21_0, arg_21_1)
	if not arg_21_0.target:beforeSpecialSkill(arg_21_1) then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_21_0.records_.special_skill[tostring(var_0_1.ctx.battle.count)] = arg_21_1
	end

	arg_21_0:specialSkill(arg_21_1)
end

function var_0_3.beforeAttack(arg_22_0, arg_22_1)
	return true
end

function var_0_3.beforeSpecialSkill(arg_23_0, arg_23_1)
	return true
end

function var_0_3.beforeTrigger(arg_24_0, arg_24_1)
	return true
end

function var_0_3.inputSpecialSkill(arg_25_0, arg_25_1, arg_25_2)
	if arg_25_2 then
		table.insert(var_0_1.ctx.battle.specialSkill, 1, {
			fighter = arg_25_0,
			skillID = arg_25_1
		})
	else
		table.insert(var_0_1.ctx.battle.specialSkill, {
			fighter = arg_25_0,
			skillID = arg_25_1
		})
	end
end

function var_0_3.getSkill(arg_26_0)
	local var_26_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_26_0 = arg_26_0.reportSkills_[tostring(var_0_1.ctx.battle.count)]
	else
		var_26_0 = arg_26_0:getCurrentSkill()
		var_26_0 = arg_26_0:getSkillBySceneBuff(var_26_0)
		arg_26_0.records_.skill[tostring(var_0_1.ctx.battle.count)] = var_26_0
	end

	return var_26_0
end

function var_0_3.getCurrentSkill(arg_27_0)
	return var_0_2.FishSkill.PUGONG
end

function var_0_3.getSkillBySceneBuff(arg_28_0, arg_28_1)
	if arg_28_1 == var_0_2.FishSkill.PUGONG then
		for iter_28_0 = #arg_28_0.sceneBuffs_, 1, -1 do
			if arg_28_0.sceneBuffs_[iter_28_0].event == var_0_2.FishEvent.NUAN_LIU then
				return arg_28_0:getCurrentSkill()
			end
		end
	elseif arg_28_1 == var_0_2.FishSkill.SKILL then
		for iter_28_1 = #arg_28_0.sceneBuffs_, 1, -1 do
			if arg_28_0.sceneBuffs_[iter_28_1].event == var_0_2.FishEvent.BING_HE then
				return arg_28_0:getCurrentSkill()
			end
		end
	end

	return arg_28_1
end

function var_0_3.isTriggerSkill(arg_29_0)
	local var_29_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_29_0 = arg_29_0.reportTriggerSkills_[tostring(var_0_1.ctx.battle.count)]
	else
		var_29_0 = arg_29_0:getTriggerFlag()
		var_29_0 = arg_29_0:getTriggerFlagBySceneBuff(var_29_0)

		if var_29_0 then
			arg_29_0.records_.trigger_skill[tostring(var_0_1.ctx.battle.count)] = var_29_0
		end
	end

	return var_29_0
end

function var_0_3.getTriggerFlag(arg_30_0)
	return false
end

function var_0_3.getTriggerFlagBySceneBuff(arg_31_0, arg_31_1)
	if arg_31_1 == false then
		for iter_31_0 = #arg_31_0.sceneBuffs_, 1, -1 do
			if arg_31_0.sceneBuffs_[iter_31_0].event == var_0_2.FishEvent.NUAN_LIU then
				return arg_31_0:getTriggerFlag()
			end
		end
	elseif arg_31_1 == true then
		for iter_31_1 = #arg_31_0.sceneBuffs_, 1, -1 do
			if arg_31_0.sceneBuffs_[iter_31_1].event == var_0_2.FishEvent.BING_HE then
				return arg_31_0:getTriggerFlag()
			end
		end
	end

	return arg_31_1
end

function var_0_3.attack(arg_32_0, arg_32_1)
	if arg_32_1 == var_0_2.FishSkill.PUGONG then
		arg_32_0:pugongAction(arg_32_1)
	else
		arg_32_0:skillAction(arg_32_1)
	end
end

function var_0_3.specialSkill(arg_33_0, arg_33_1)
	arg_33_0:skillSpecialAction(arg_33_1)
end

function var_0_3.enterAction(arg_34_0)
	local var_34_0 = arg_34_0:getFighterModel()

	var_34_0:setPositionY(var_34_0:getPositionY() - 80)
	var_34_0:stopAllActions()

	local var_34_1 = cc.Spawn:create({
		cc.MoveBy:create(0.2, cc.p(0, 90)),
		cc.ScaleTo:create(0.2, 1.2 * var_0_8)
	})
	local var_34_2 = cc.Spawn:create({
		cc.MoveBy:create(0.2, cc.p(0, -10)),
		cc.ScaleTo:create(0.2, 1 * var_0_8)
	})
	local var_34_3 = cc.Sequence:create({
		var_34_1,
		var_34_2,
		cc.CallFunc:create(function()
			arg_34_0:waitAction()
		end)
	})

	var_34_0:runAction(var_34_3)

	local var_34_4 = "skeletons/ui_effect/activity_fish_fight/chuxian"
	local var_34_5 = var_0_2.createEffect(var_34_4)

	var_34_5:addTo(arg_34_0:getEffectNode())
	var_34_5:setPositionY(-arg_34_0:getFighterModel():getHeight() * var_0_8 / 2 + 50)
	var_34_5:play()
end

function var_0_3.waitAction(arg_36_0)
	local var_36_0 = arg_36_0:getFighterModel()

	var_36_0:setPosition(cc.p(0, 0))
	var_36_0:stopAllActions()

	local var_36_1 = cc.MoveBy:create(0.3, cc.p(0, 5))
	local var_36_2 = cc.MoveBy:create(0.6, cc.p(0, -10))
	local var_36_3 = cc.MoveBy:create(0.3, cc.p(0, 5))
	local var_36_4 = cc.Sequence:create({
		var_36_1,
		var_36_2,
		var_36_3
	})

	var_36_0:runAction(cc.RepeatForever:create(var_36_4))
end

function var_0_3.pugongAction(arg_37_0, arg_37_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		arg_37_0:applySingleUnit(arg_37_1)
	else
		arg_37_0:normalAction(arg_37_0.applySingleUnit, arg_37_1)
	end
end

function var_0_3.normalAction(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = arg_38_0:getFighterModel()

	var_38_0:setPosition(cc.p(0, 0))
	var_38_0:stopAllActions()

	local var_38_1 = arg_38_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_38_2 = cc.Spawn:create({
		cc.RotateBy:create(0.4, -30 * var_38_1),
		cc.MoveBy:create(0.4, cc.p(-10 * var_38_1, 2))
	})
	local var_38_3 = cc.Spawn:create({
		cc.RotateBy:create(0.06666666666666667, 45 * var_38_1),
		cc.MoveBy:create(0.06666666666666667, cc.p(90 * var_38_1, -5))
	})
	local var_38_4 = cc.Spawn:create({
		cc.RotateBy:create(0.23333333333333334, 5 * var_38_1),
		cc.MoveBy:create(0.23333333333333334, cc.p(2 * var_38_1, -2))
	})
	local var_38_5 = cc.Spawn:create({
		cc.RotateBy:create(0.3, -20 * var_38_1),
		cc.MoveBy:create(0.3, cc.p(-82 * var_38_1, 5))
	})
	local var_38_6 = transition.sequence({
		var_38_2,
		var_38_3,
		cc.CallFunc:create(function()
			arg_38_1(arg_38_0, arg_38_2)
		end),
		var_38_4,
		var_38_5,
		cc.CallFunc:create(function()
			arg_38_0:delayStartBattle()
			arg_38_0:waitAction()
		end)
	})

	arg_38_0.scene:pauseBattle()
	arg_38_0:getFighterModel():runAction(var_38_6)
end

function var_0_3.xuliAction(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0 = arg_41_0:getFighterModel()

	var_41_0:setPosition(cc.p(0, 0))
	var_41_0:stopAllActions()

	local var_41_1 = arg_41_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_41_2 = cc.Spawn:create({
		cc.RotateBy:create(0.4, -30 * var_41_1),
		cc.MoveBy:create(0.4, cc.p(-20 * var_41_1, 5))
	})
	local var_41_3 = cc.Spawn:create({
		cc.RotateBy:create(0.06666666666666667, 45 * var_41_1),
		cc.MoveBy:create(0.06666666666666667, cc.p(180 * var_41_1, -10))
	})
	local var_41_4 = cc.Spawn:create({
		cc.RotateBy:create(0.23333333333333334, 5 * var_41_1),
		cc.MoveBy:create(0.23333333333333334, cc.p(5 * var_41_1, -5))
	})
	local var_41_5 = cc.Spawn:create({
		cc.RotateBy:create(0.3, -20 * var_41_1),
		cc.MoveBy:create(0.3, cc.p(-165 * var_41_1, 10))
	})
	local var_41_6 = transition.sequence({
		var_41_2,
		var_41_3,
		cc.CallFunc:create(function()
			arg_41_1(arg_41_0, arg_41_2)
		end),
		var_41_4,
		var_41_5,
		cc.CallFunc:create(function()
			arg_41_0:delayStartBattle()
			arg_41_0:waitAction()
		end)
	})

	arg_41_0.scene:pauseBattle()
	arg_41_0:getFighterModel():runAction(var_41_6)
end

function var_0_3.buffAction(arg_44_0, arg_44_1, arg_44_2)
	local var_44_0 = arg_44_0:getFighterModel()

	var_44_0:setPosition(cc.p(0, 0))
	var_44_0:stopAllActions()

	local var_44_1 = arg_44_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_44_2 = cc.Spawn:create({
		cc.RotateBy:create(0.6, 2 * var_44_1),
		cc.MoveBy:create(0.6, cc.p(0, -8))
	})
	local var_44_3 = cc.Spawn:create({
		cc.RotateBy:create(0.16666666666666666, -12 * var_44_1),
		cc.MoveBy:create(0.16666666666666666, cc.p(0, 36))
	})
	local var_44_4 = cc.Spawn:create({
		cc.RotateBy:create(0.4666666666666667, -2 * var_44_1),
		cc.MoveBy:create(0.4666666666666667, cc.p(0, 2))
	})
	local var_44_5 = cc.Spawn:create({
		cc.RotateBy:create(0.26666666666666666, 12 * var_44_1),
		cc.MoveBy:create(0.26666666666666666, cc.p(0, -30))
	})
	local var_44_6 = cc.CallFunc:create(function()
		audio.playSound(var_0_2.tables.sound:getSound("douyu_buff"))
	end)
	local var_44_7 = transition.sequence({
		var_44_2,
		var_44_6,
		var_44_3,
		cc.CallFunc:create(function()
			arg_44_1(arg_44_0, arg_44_2)
		end),
		var_44_4,
		var_44_5,
		cc.CallFunc:create(function()
			arg_44_0:delayStartBattle()
			arg_44_0:waitAction()
		end)
	})

	arg_44_0.scene:pauseBattle()
	arg_44_0:getFighterModel():runAction(var_44_7)
end

function var_0_3.hurtAction(arg_48_0)
	audio.playSound(var_0_2.tables.sound:getSound("douyu_shouji"))

	local var_48_0 = arg_48_0:getFighterModel()

	var_48_0:setPosition(cc.p(0, 0))
	var_48_0:stopAllActions()

	local var_48_1 = arg_48_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_48_2 = cc.Spawn:create({
		cc.RotateBy:create(0.03333333333333333, 5 * var_48_1),
		cc.MoveBy:create(0.03333333333333333, cc.p(5 * var_48_1, -5))
	})
	local var_48_3 = cc.Spawn:create({
		cc.RotateBy:create(0.1, -15 * var_48_1),
		cc.MoveBy:create(0.1, cc.p(-15 * var_48_1, 10))
	})
	local var_48_4 = cc.Spawn:create({
		cc.RotateBy:create(0.2, 10 * var_48_1),
		cc.MoveBy:create(0.2, cc.p(10 * var_48_1, -5))
	})
	local var_48_5 = transition.sequence({
		var_48_2,
		var_48_3,
		var_48_4,
		arg_48_0:waitAction()
	})

	arg_48_0:getFighterModel():runAction(var_48_5)
end

function var_0_3.skillAction(arg_49_0, arg_49_1)
	return
end

function var_0_3.skillSpecialAction(arg_50_0, arg_50_1)
	return
end

function var_0_3.applySingleUnit(arg_51_0, arg_51_1)
	local var_51_0, var_51_1, var_51_2, var_51_3, var_51_4, var_51_5 = arg_51_0:getUnitData(arg_51_1)

	if arg_51_1 == var_0_2.FishSkill.PUGONG then
		arg_51_0:addPugongMessage(var_51_0, var_51_1, var_51_2, var_51_3, var_51_4)
	else
		arg_51_0:addSkillMessage(var_51_0, var_51_1, var_51_2, var_51_3, var_51_4)
	end

	if var_51_0 then
		arg_51_0.target:playShanbi()

		return
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType and var_51_5 ~= arg_51_0.target:getHp() then
		print("applySingleUnit!!!!!!!!!!!!", var_51_5, arg_51_0.target:getHp(), var_51_2, var_0_1.ctx.battle.count)
	end

	if var_51_2 > 0 then
		arg_51_0.target:updateHp(arg_51_0.target:getHp() - var_51_2)

		if arg_51_1 ~= var_0_2.FishSkill.PUGONG and arg_51_0.specialAttackEffect then
			arg_51_0:specialAttackEffect(var_51_2, var_51_1)
		else
			arg_51_0.target:playHPDeltas(-var_51_2, var_51_1)
			arg_51_0:attackEffect(var_51_2)
		end
	end

	if arg_51_0.target:isDeath() then
		return
	end

	arg_51_0.target:afterHurt(arg_51_1, var_51_0, var_51_1, var_51_2, var_51_3, var_51_4)

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_51_0.target:hurtAction()
	end
end

function var_0_3.attackEffect(arg_52_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_52_0.target.attackEffect_ then
		local var_52_0 = "skeletons/ui_effect/activity_fish_fight/tongyongshouji"
		local var_52_1 = var_0_2.createEffect(var_52_0)

		var_52_1:addTo(arg_52_0.target:getEffectNode())
		var_52_1:play(function()
			var_52_1:setVisible(false)
		end)
		var_52_1:setPosition(0, 0)
		var_52_1:setScale(arg_52_0:getTeamType() == var_0_2.TeamType.A and -1 or 1)

		arg_52_0.target.attackEffect_ = var_52_1
	else
		arg_52_0.target.attackEffect_:setVisible(true)
		arg_52_0.target.attackEffect_:play(function()
			arg_52_0.target.attackEffect_:setVisible(false)
		end)
	end
end

function var_0_3.rehpEffect(arg_55_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_55_0.rehpEffect_ then
		local var_55_0 = "skeletons/ui_effect/activity_fish_fight/huixue"
		local var_55_1 = var_0_2.createEffect(var_55_0)
		local var_55_2 = 0.6

		var_55_1:setScale(var_55_2)
		var_55_1:addTo(arg_55_0:getEffectNode())
		var_55_1:play(function()
			var_55_1:setVisible(false)
		end)
		var_55_1:setPosition(0, 20)
		var_55_1:setScaleX(arg_55_0:getTeamType() == var_0_2.TeamType.A and -var_55_2 or var_55_2)

		arg_55_0.rehpEffect_ = var_55_1
	else
		arg_55_0.rehpEffect_:setVisible(true)
		arg_55_0.rehpEffect_:play(function()
			arg_55_0.rehpEffect_:setVisible(false)
		end)
	end
end

function var_0_3.addMessage(arg_58_0, arg_58_1, arg_58_2)
	local var_58_0 = arg_58_2 or arg_58_0:getTeamType()

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_58_0.window:addMessage(arg_58_1, var_58_0)
	end
end

function var_0_3.addPugongMessage(arg_59_0, arg_59_1, arg_59_2, arg_59_3, arg_59_4, arg_59_5)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_59_0 = arg_59_0:getRandomMessage("pugong")
	local var_59_1 = string.format(var_59_0[1], arg_59_0:getName(), arg_59_0.target:getName())
	local var_59_2

	if arg_59_1 then
		local var_59_3 = arg_59_0:getRandomMessage("shanbi")

		var_59_2 = string.format(var_59_3[1], arg_59_0.target:getName())
	elseif arg_59_2 then
		local var_59_4 = arg_59_0:getRandomMessage("baoji")

		var_59_2 = string.format(var_59_4[1], arg_59_0.target:getName(), arg_59_3)
	else
		local var_59_5 = arg_59_0:getRandomMessage("mingzhong")

		var_59_2 = string.format(var_59_5[1], arg_59_0.target:getName(), arg_59_3)
	end

	local var_59_6 = var_59_1 .. "|" .. var_59_2

	arg_59_0:addMessage(var_59_6)
end

function var_0_3.addSkillMessage(arg_60_0, arg_60_1, arg_60_2, arg_60_3, arg_60_4, arg_60_5)
	return
end

function var_0_3.addGuiyuMessage(arg_61_0, arg_61_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_61_0 = arg_61_0:getRandomMessage("diaoyu")
	local var_61_1 = string.format(var_61_0[1], arg_61_0:getName(), var_0_4:skill(arg_61_1))

	arg_61_0:addMessage(var_61_1)
end

function var_0_3.addRehpMessage(arg_62_0, arg_62_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_62_0 = arg_62_0:getRandomMessage("huixue")
	local var_62_1 = string.format(var_62_0[1], arg_62_0:getName(), arg_62_1)

	arg_62_0:addMessage(var_62_1)
end

function var_0_3.addStopMessage(arg_63_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_63_0 = arg_63_0:getRandomMessage("wufaxingdong")
	local var_63_1 = string.format(var_63_0[1], arg_63_0:getName())

	arg_63_0:addMessage(var_63_1)
end

function var_0_3.getUnitData(arg_64_0, arg_64_1)
	local var_64_0
	local var_64_1
	local var_64_2
	local var_64_3
	local var_64_4
	local var_64_5

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_64_0, var_64_1, var_64_2, var_64_3, var_64_4, var_64_5 = unpack(arg_64_0.reportAttacks_[tostring(var_0_1.ctx.battle.count)])
	else
		var_64_0, var_64_1, var_64_2, var_64_3, var_64_4 = arg_64_0:calculateBaseData()
		var_64_0, var_64_1, var_64_2, var_64_3, var_64_4 = arg_64_0:getTarget():updateUnitDataByTarget(arg_64_1, var_64_0, var_64_1, var_64_2, var_64_3, var_64_4)
		var_64_0, var_64_1, var_64_2, var_64_3, var_64_4 = arg_64_0:updateUnitDataByFighter(arg_64_1, var_64_0, var_64_1, var_64_2, var_64_3, var_64_4)
		var_64_0, var_64_1, var_64_2, var_64_3, var_64_4 = arg_64_0:updateUnitDataByEvent(arg_64_1, var_64_0, var_64_1, var_64_2, var_64_3, var_64_4)

		arg_64_0:recordData(var_64_0, var_64_1, var_64_2, var_64_3, var_64_4)
	end

	return var_64_0, var_64_1, var_64_2, var_64_3, var_64_4, var_64_5
end

function var_0_3.calculateBaseData(arg_65_0)
	local var_65_0
	local var_65_1
	local var_65_2
	local var_65_3
	local var_65_4
	local var_65_5 = arg_65_0.target:getAttrByType(var_0_2.FishAttributeType.SHANBI)
	local var_65_6 = var_0_2.weightedChoise({
		var_65_5,
		1 - var_65_5
	}) == 1
	local var_65_7 = arg_65_0:getAttrByType(var_0_2.FishAttributeType.BAOJI)
	local var_65_8 = var_0_2.weightedChoise({
		var_65_7,
		1 - var_65_7
	}) == 1
	local var_65_9 = arg_65_0:getAttrByType(var_0_2.FishAttributeType.AD) - arg_65_0.target:getAttrByType(var_0_2.FishAttributeType.HUJIA)
	local var_65_10 = math.max(var_65_9, 0) * (1 + 0.5 * math.floor(var_0_1.ctx.battle.count / 120))

	if var_65_8 then
		var_65_10 = var_65_10 * 2
	end

	local var_65_11 = 0
	local var_65_12 = 0

	return var_65_6, var_65_8, var_65_10, var_65_11, var_65_12
end

function var_0_3.updateUnitDataByTarget(arg_66_0, arg_66_1, arg_66_2, arg_66_3, arg_66_4, arg_66_5, arg_66_6)
	return arg_66_2, arg_66_3, arg_66_4, arg_66_5, arg_66_6
end

function var_0_3.updateUnitDataByFighter(arg_67_0, arg_67_1, arg_67_2, arg_67_3, arg_67_4, arg_67_5, arg_67_6)
	return arg_67_2, arg_67_3, arg_67_4, arg_67_5, arg_67_6
end

function var_0_3.updateUnitDataByEvent(arg_68_0, arg_68_1, arg_68_2, arg_68_3, arg_68_4, arg_68_5, arg_68_6)
	if not arg_68_2 then
		for iter_68_0 = #arg_68_0.sceneBuffs_, 1, -1 do
			local var_68_0 = arg_68_0.sceneBuffs_[iter_68_0]

			if var_68_0.event == var_0_2.FishEvent.GONG_JI then
				arg_68_4 = arg_68_4 * 2

				arg_68_0:removeSceneBuff(var_68_0)
			end
		end
	end

	return arg_68_2, arg_68_3, arg_68_4, arg_68_5, arg_68_6
end

function var_0_3.afterHurt(arg_69_0, arg_69_1, arg_69_2, arg_69_3, arg_69_4, arg_69_5, arg_69_6)
	return
end

function var_0_3.recordData(arg_70_0, arg_70_1, arg_70_2, arg_70_3, arg_70_4, arg_70_5)
	arg_70_0.records_.attack[tostring(var_0_1.ctx.battle.count)] = {
		arg_70_1,
		arg_70_2,
		arg_70_3,
		arg_70_4,
		arg_70_5,
		arg_70_0.target:getHp()
	}
end

function var_0_3.writeReport(arg_71_0)
	return {
		attack = arg_71_0.records_.attack,
		skill = arg_71_0.records_.skill,
		trigger_skill = arg_71_0.records_.trigger_skill,
		special_skill = arg_71_0.records_.special_skill,
		random_event = arg_71_0.records_.random_event
	}
end

function var_0_3.setupReport(arg_72_0, arg_72_1)
	arg_72_0.reportAttacks_ = arg_72_1.attack
	arg_72_0.reportSkills_ = arg_72_1.skill
	arg_72_0.reportTriggerSkills_ = arg_72_1.trigger_skill
	arg_72_0.reportSpecialSkills_ = arg_72_1.special_skill
	arg_72_0.reportRandomEvents_ = arg_72_1.random_event
end

function var_0_3.isDeath(arg_73_0)
	return arg_73_0.hp_ <= 0
end

function var_0_3.playShanbi(arg_74_0)
	arg_74_0:playFloatText(var_0_2.BattleFloatType.MISS, arg_74_0:getTeamType())
end

function var_0_3.updateHp(arg_75_0, arg_75_1)
	if arg_75_1 > arg_75_0:getHpLimit() then
		arg_75_1 = arg_75_0:getHpLimit()
	end

	arg_75_0.hp_ = arg_75_1

	arg_75_0:updateHpBar()

	if arg_75_0:isDeath() then
		arg_75_0:dieAction()
	end
end

function var_0_3.updateHpBar(arg_76_0, arg_76_1)
	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_76_0.window:setHPProgress(arg_76_0:getHp() / arg_76_0:getHpLimit(), arg_76_0:getTeamType(), arg_76_1)
	end
end

function var_0_3.getHp(arg_77_0)
	return arg_77_0.hp_
end

function var_0_3.playHPDeltas(arg_78_0, arg_78_1, arg_78_2)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_78_0 = var_0_2.AssetLoader.get():loadLabel({
		text = string.format("%s%d", arg_78_1 >= 0 and "+" or "", arg_78_1)
	}, arg_78_1 >= 0 and "battle_float_green" or "battle_float_red"):align(display.CENTER, 0, arg_78_0:getFighterModel():getHeight() * var_0_8 / 2)

	if arg_78_2 then
		var_78_0:setScale(1.5)
		var_78_0:y(arg_78_0:getFighterModel():getHeight() * var_0_8 / 2 + 20)
	end

	arg_78_0:playNumberFloat_(var_78_0)
end

function var_0_3.playNumberFloat_(arg_79_0, arg_79_1, arg_79_2, arg_79_3)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_79_0 = var_0_2.tables.battleConfig.floatAnimationDuration
	local var_79_1 = var_0_2.tables.battleConfig.floatAnimationDeltaY
	local var_79_2 = var_0_2.tables.battleConfig.battleFloatScaleDuration

	arg_79_3 = arg_79_3 or 0

	local var_79_3 = arg_79_1:getScale()

	arg_79_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_79_1:addTo(arg_79_0:getEffectNode())
	var_0_2.setCascadeOpacityEnabled(arg_79_1, true)
	arg_79_1:scale(0)

	local var_79_4 = {}

	table.insert(var_79_4, cc.ScaleTo:create(var_79_2, 1.4 * var_79_3, 1.4 * var_79_3))
	table.insert(var_79_4, cc.ScaleTo:create(var_79_2 / 2, var_79_3, var_79_3))

	local var_79_5 = cc.Spawn:create({
		cc.MoveBy:create(var_79_0, cc.p(0, var_79_1)),
		cc.FadeOut:create(var_79_0)
	})

	table.insert(var_79_4, var_79_5)
	arg_79_1:runActionOnce(transition.sequence(var_79_4), true, arg_79_2, arg_79_3)
end

function var_0_3.playFloatText(arg_80_0, arg_80_1, arg_80_2, arg_80_3)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_80_2 = arg_80_2 or 1

	local var_80_0 = "images/battle/float_text/"

	if arg_80_1 == var_0_2.BattleFloatType.MISS then
		var_80_0 = var_80_0 .. "miss" .. tostring(arg_80_2) .. ".png"
	elseif arg_80_1 == var_0_2.BattleFloatType.AP_IMMORTAL then
		var_80_0 = var_80_0 .. "ap_immortal" .. tostring(arg_80_2) .. ".png"
	elseif arg_80_1 == var_0_2.BattleFloatType.AD_IMMORTAL then
		var_80_0 = var_80_0 .. "ad_immortal" .. tostring(arg_80_2) .. ".png"
	elseif arg_80_1 == var_0_2.BattleFloatType.BREAK then
		var_80_0 = var_80_0 .. "break" .. tostring(arg_80_2) .. ".png"
	elseif arg_80_1 == var_0_2.BattleFloatType.BUFF_MISS then
		var_80_0 = var_80_0 .. "buff_miss" .. tostring(arg_80_2) .. ".png"
	elseif arg_80_1 == var_0_2.BattleFloatType.KILLING then
		var_80_0 = var_80_0 .. "killing_award" .. tostring(arg_80_2) .. ".png"
	elseif arg_80_1 == var_0_2.BattleFloatType.KILL_GIFT then
		var_80_0 = var_80_0 .. "kill_gift" .. tostring(arg_80_2) .. ".png"
	end

	local var_80_1 = var_0_2.AssetLoader.get():loadSprite(var_80_0)

	var_80_1:align(display.CENTER, 0, arg_80_0:getFighterModel():getHeight() * var_0_8 / 2 + 70)
	arg_80_0:playFloatAnimations_(var_80_1, arg_80_3)
end

function var_0_3.playFloatAnimations_(arg_81_0, arg_81_1, arg_81_2, arg_81_3)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_81_3 = arg_81_3 or 0

	local var_81_0 = var_0_2.tables.battleConfig.floatAnimationDuration
	local var_81_1 = var_0_2.tables.battleConfig.floatAnimationDeltaY
	local var_81_2 = var_0_2.tables.battleConfig.battleFloatScaleDuration
	local var_81_3 = var_0_2.tables.battleConfig.floatFadeOutDelay
	local var_81_4 = arg_81_1:getScale()

	arg_81_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_81_1:addTo(arg_81_0:getEffectNode())
	var_0_2.setCascadeOpacityEnabled(arg_81_1, true)
	arg_81_1:scale(0)

	local var_81_5 = {}

	table.insert(var_81_5, cc.ScaleTo:create(var_81_2, 1.2 * var_81_4, 1.2 * var_81_4))
	table.insert(var_81_5, cc.ScaleTo:create(var_81_2, var_81_4, var_81_4))
	table.insert(var_81_5, cc.DelayTime:create(var_81_3))
	table.insert(var_81_5, cc.FadeOut:create(var_81_0 - var_81_3))
	arg_81_1:runActionOnce(transition.sequence(var_81_5), true, arg_81_2, arg_81_3)
end

function var_0_3.setTeamType(arg_82_0, arg_82_1)
	arg_82_0.teamType = arg_82_1
end

function var_0_3.getTeamType(arg_83_0)
	return arg_83_0.teamType
end

function var_0_3.dieAction(arg_84_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	var_0_2.setCascadeOpacityEnabled(arg_84_0:getEffectNode(), true)
	arg_84_0:getEffectNode():runActionOnce(cc.Sequence:create({
		cc.DelayTime:create(0.3333333333333333),
		cc.FadeOut:create(0.16666666666666666)
	}))

	local var_84_0 = arg_84_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_84_1 = cc.Spawn:create({
		cc.RotateBy:create(0.16666666666666666, -10 * var_84_0),
		cc.MoveBy:create(0.16666666666666666, cc.p(-5 * var_84_0, 5))
	})
	local var_84_2 = cc.Spawn:create({
		cc.RotateBy:create(0.3333333333333333, 25 * var_84_0),
		cc.MoveBy:create(0.3333333333333333, cc.p(20 * var_84_0, -20))
	})
	local var_84_3 = cc.Sequence:create({})
	local var_84_4 = cc.Spawn:create({
		var_84_2,
		var_84_3
	})
	local var_84_5 = transition.sequence({
		var_84_1,
		var_84_4
	})

	arg_84_0:getFighterModel():runAction(var_84_5)
end

function var_0_3.addBuff(arg_85_0, arg_85_1)
	local var_85_0

	if arg_85_1.fighter:getTableID() == var_0_9 then
		var_85_0 = arg_85_1.fighter.bianshenTableID
	else
		var_85_0 = arg_85_1.fighter:getTableID()
	end

	local var_85_1 = var_0_4:buffTexiao(var_85_0)

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType and var_85_1 ~= "" then
		local var_85_2 = false

		for iter_85_0 = #arg_85_0.buffs_, 1, -1 do
			local var_85_3 = arg_85_0.buffs_[iter_85_0]

			if arg_85_1.fighter == var_85_3.fighter then
				var_85_2 = true

				break
			end
		end

		if not var_85_2 then
			local var_85_4 = var_0_4:buffTiaozheng(var_85_0)
			local var_85_5 = arg_85_0:getFighterModel()
			local var_85_6 = var_85_4[1]
			local var_85_7 = var_85_4[2]
			local var_85_8 = var_85_4[3]
			local var_85_9 = var_85_7 + var_85_5:getWidth() / 2
			local var_85_10 = var_85_8 + var_85_5:getHeight() / 2
			local var_85_11 = var_85_1 .. ".json"
			local var_85_12 = var_85_1 .. ".atlas"
			local var_85_13 = sp.SkeletonAnimation:create(var_85_11, var_85_12, var_85_6)

			var_85_13:setAnimation(0, "texiao", true)
			var_85_13:addTo(var_85_5)
			var_85_13:setPosition(var_85_9, var_85_10)
			var_85_13:setScaleX(var_85_6 * arg_85_0:getTeamType() == var_0_2.TeamType.A and -1 or 1)

			arg_85_0.buffsEffect_[var_85_1] = var_85_13
		end
	end

	table.insert(arg_85_0.buffs_, arg_85_1)

	if arg_85_1.attributeType then
		arg_85_0.___attrCache[arg_85_1.attributeType] = nil
	end
end

function var_0_3.addSceneBuff(arg_86_0, arg_86_1)
	table.insert(arg_86_0.sceneBuffs_, arg_86_1)

	if arg_86_1.attributeType then
		arg_86_0.___attrCache[arg_86_1.attributeType] = nil
	end
end

function var_0_3.newBuff(arg_87_0, arg_87_1, arg_87_2, arg_87_3, arg_87_4, arg_87_5, arg_87_6, arg_87_7)
	return {
		count = arg_87_1 + 1,
		attributeType = arg_87_2,
		value = arg_87_3,
		hpDelta = arg_87_4,
		fighter = arg_87_5,
		target = arg_87_6,
		path = arg_87_7
	}
end

function var_0_3.newSceneBuff(arg_88_0, arg_88_1, arg_88_2, arg_88_3, arg_88_4)
	return {
		count = arg_88_1 + 1,
		attributeType = arg_88_2,
		value = arg_88_3,
		event = arg_88_4
	}
end

function var_0_3.updateBuffHpDelta(arg_89_0)
	local var_89_0 = 0

	for iter_89_0 = #arg_89_0.buffs_, 1, -1 do
		local var_89_1 = arg_89_0.buffs_[iter_89_0]

		if var_89_1.hpDelta then
			var_89_0 = var_89_0 + var_89_1.hpDelta
		end
	end

	if var_89_0 > 0 then
		arg_89_0:updateHp(arg_89_0:getHp() + var_89_0)
		arg_89_0:playHPDeltas(var_89_0, false)
		arg_89_0:addRehpMessage(var_89_0)
		arg_89_0:rehpEffect()
	end
end

function var_0_3.updateBuffCount(arg_90_0)
	for iter_90_0 = #arg_90_0.buffs_, 1, -1 do
		local var_90_0 = arg_90_0.buffs_[iter_90_0]

		var_90_0.count = var_90_0.count - 1

		if var_90_0.count <= 0 then
			arg_90_0:removeBuff(var_90_0)

			if var_90_0.attributeType then
				arg_90_0.___attrCache[var_90_0.attributeType] = nil
			end
		end
	end

	for iter_90_1 = #arg_90_0.sceneBuffs_, 1, -1 do
		local var_90_1 = arg_90_0.sceneBuffs_[iter_90_1]

		var_90_1.count = var_90_1.count - 1

		if var_90_1.count <= 0 then
			arg_90_0:removeSceneBuff(var_90_1)

			if var_90_1.attributeType then
				arg_90_0.___attrCache[var_90_1.attributeType] = nil
			end
		end
	end
end

function var_0_3.getBuffAttr(arg_91_0, arg_91_1)
	local var_91_0 = 0

	for iter_91_0 = #arg_91_0.buffs_, 1, -1 do
		local var_91_1 = arg_91_0.buffs_[iter_91_0]

		if var_91_1.attributeType == arg_91_1 then
			var_91_0 = var_91_0 + var_91_1.value
		end
	end

	for iter_91_1 = #arg_91_0.sceneBuffs_, 1, -1 do
		local var_91_2 = arg_91_0.sceneBuffs_[iter_91_1]

		if var_91_2.attributeType == arg_91_1 then
			var_91_0 = var_91_0 + var_91_2.value
		end
	end

	return var_91_0
end

function var_0_3.removeBuff(arg_92_0, arg_92_1)
	for iter_92_0 = #arg_92_0.buffs_, 1, -1 do
		if arg_92_1 == arg_92_0.buffs_[iter_92_0] then
			table.remove(arg_92_0.buffs_, iter_92_0)

			if arg_92_1.attributeType then
				arg_92_0.___attrCache[arg_92_1.attributeType] = nil
			end
		end
	end

	local var_92_0

	if arg_92_1.fighter:getTableID() == var_0_9 then
		var_92_0 = arg_92_1.fighter.bianshenTableID
	else
		var_92_0 = arg_92_1.fighter:getTableID()
	end

	local var_92_1 = var_0_4:buffTexiao(var_92_0)

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType and var_92_1 then
		local var_92_2 = false

		for iter_92_1 = #arg_92_0.buffs_, 1, -1 do
			local var_92_3 = arg_92_0.buffs_[iter_92_1]

			if arg_92_1.fighter == var_92_3.fighter then
				var_92_2 = true

				break
			end
		end

		if not var_92_2 then
			arg_92_0.buffsEffect_[var_92_1]:removeSelf()

			arg_92_0.buffsEffect_[var_92_1] = nil
		end
	end
end

function var_0_3.removeSceneBuff(arg_93_0, arg_93_1)
	for iter_93_0 = #arg_93_0.sceneBuffs_, 1, -1 do
		if arg_93_1 == arg_93_0.sceneBuffs_[iter_93_0] then
			table.remove(arg_93_0.sceneBuffs_, iter_93_0)

			if arg_93_1.attributeType then
				arg_93_0.___attrCache[arg_93_1.attributeType] = nil
			end
		end
	end
end

function var_0_3.getBuffs(arg_94_0)
	return arg_94_0.buffs_
end

function var_0_3.updateBuffShow(arg_95_0)
	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		for iter_95_0 = #arg_95_0.buffs_, 1, -1 do
			local var_95_0 = arg_95_0.buffs_[iter_95_0]
			local var_95_1 = false

			for iter_95_1 = #arg_95_0.buffs_, 1, -1 do
				local var_95_2 = arg_95_0.buffs_[iter_95_1]

				if var_95_0.fighter == var_95_2.fighter then
					var_95_1 = true

					break
				end
			end

			if not var_95_1 then
				local var_95_3 = var_95_0.path

				arg_95_0.buffsEffect_[var_95_3]:removeSelf()

				arg_95_0.buffsEffect_[var_95_3] = nil
			end
		end
	end
end

function var_0_3.setEffectNode(arg_96_0, arg_96_1)
	arg_96_0.effectNode_ = arg_96_1
end

function var_0_3.getEffectNode(arg_97_0)
	return arg_97_0.effectNode_
end

function var_0_3.randomEvent(arg_98_0)
	local var_98_0 = true
	local var_98_1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_98_1 = arg_98_0.reportRandomEvents_[tostring(var_0_1.ctx.battle.count)]
	else
		if not arg_98_0.eventCount then
			arg_98_0.eventCount = 0
		end

		if arg_98_0.eventCount < var_0_6 and var_0_2.weightedChoise({
			var_0_5,
			1 - var_0_5
		}) == 1 then
			arg_98_0.eventCount = arg_98_0.eventCount + 1
			var_98_1 = var_0_2.weightedChoise({
				var_0_7[1],
				var_0_7[2],
				var_0_7[3],
				var_0_7[4],
				var_0_7[5]
			}) - 1 + var_0_2.FishEvent.KOU_XUE
			arg_98_0.records_.random_event[tostring(var_0_1.ctx.battle.count)] = var_98_1
		end
	end

	if not var_98_1 then
		return var_98_0
	end

	local var_98_2 = {
		event = var_98_1
	}

	if var_98_1 == var_0_2.FishEvent.KOU_XUE then
		local var_98_3 = 30

		arg_98_0:updateHp(arg_98_0:getHp() - var_98_3)
		arg_98_0:playHPDeltas(-var_98_3, false)

		var_98_2.fighter = arg_98_0
		var_98_2.hp = var_98_3
	elseif var_98_1 == var_0_2.FishEvent.HUI_XUE then
		local var_98_4 = 30

		arg_98_0:updateHp(arg_98_0:getHp() + var_98_4)
		arg_98_0:playHPDeltas(var_98_4, false)
		arg_98_0:rehpEffect()

		var_98_2.fighter = arg_98_0
		var_98_2.hp = var_98_4
	elseif var_98_1 == var_0_2.FishEvent.GONG_JI then
		local var_98_5 = arg_98_0:newSceneBuff(9999, nil, nil, var_0_2.FishEvent.GONG_JI)

		arg_98_0:addSceneBuff(var_98_5)

		var_98_2.fighter = arg_98_0
	elseif var_98_1 == var_0_2.FishEvent.SU_DU then
		local var_98_6 = arg_98_0:newSceneBuff(3, var_0_2.FishAttributeType.SPEED, 10, var_0_2.FishEvent.SU_DU)

		arg_98_0:addSceneBuff(var_98_6)

		var_98_2.fighter = arg_98_0
	elseif var_98_1 == var_0_2.FishEvent.XING_DONG then
		local var_98_7 = arg_98_0:newSceneBuff(9999, nil, nil, var_0_2.FishEvent.XING_DONG)

		arg_98_0:addSceneBuff(var_98_7)

		var_98_2.fighter = arg_98_0
		var_98_0 = false
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_98_0.scene:addEventMessage(var_98_2)
	end

	return var_98_0
end

function var_0_3.getRandomMessage(arg_99_0, arg_99_1)
	local var_99_0 = var_0_2.tables.activityFishBattleText:getDesc(arg_99_1)
	local var_99_1 = var_99_0[math.random(#var_99_0)]

	return (var_0_2.split(var_99_1))
end

function var_0_3.getName(arg_100_0)
	return var_0_4:name(arg_100_0:getTableID())
end

function var_0_3.getSkillName(arg_101_0)
	return var_0_4:skill(arg_101_0:getTableID())
end

return var_0_3
