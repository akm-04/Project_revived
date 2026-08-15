local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhurong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 10000042
local var_0_8 = 80110002
local var_0_9 = 10
local var_0_10 = 20001441
local var_0_11 = 40012245
local var_0_12 = 10002111
local var_0_13 = 3

function var_0_3.buffRemoveAction(arg_1_0, arg_1_1)
	if arg_1_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_1_0 = arg_1_1:getRemoveSkill()
	local var_1_1 = {
		arg_1_1.target
	}
	local var_1_2 = arg_1_0:createAttackUnits(var_1_1, var_1_0)

	for iter_1_0, iter_1_1 in ipairs(var_1_2) do
		table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
		table.insert(arg_1_0.records_.special_units, iter_1_1)
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	if var_0_1.ctx.battle.battleID > 0 and var_0_1.ctx.battle.battleID <= var_0_1.ctx.battleConst.guideCampaignId - 1 and var_0_2.StoryData.get():getStoryID() <= var_0_1.ctx.battle.battleID then
		arg_2_0.playGuide_ = true
		arg_2_0.showGuideCounts_ = 0
	end

	arg_2_0.records_.skin_child_count = {}
	arg_2_0.skinTarget_ = nil
	arg_2_0.elementCount = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if not arg_3_0.playGuide_ then
		return
	end

	if arg_3_0:checkEnergySkill() and arg_3_0.showGuideCounts_ < 300 and arg_3_0:getNearestTarget() and not arg_3_0:getNearestTarget():isDeath() then
		arg_3_0.showGuideCounts_ = arg_3_0.showGuideCounts_ + 1

		arg_3_0.bottomWnd:showGuideTalk(true, arg_3_0:getTeamIndex())

		local var_3_0, var_3_1 = arg_3_0:getNearestTarget():getPos()
		local var_3_2 = arg_3_0.bottomWnd:getGuideHand(arg_3_0:getTeamIndex())
		local var_3_3, var_3_4 = var_3_2:getPosition()
		local var_3_5 = 4
		local var_3_6 = math.sqrt((var_3_1 - var_3_4) * (var_3_1 - var_3_4) + (var_3_0 - var_3_3) * (var_3_0 - var_3_3))

		if var_3_6 < var_3_5 then
			var_3_2:play(nil, true)
			var_3_2:pos(var_3_2.initPos[1], var_3_2.initPos[2])
		else
			local var_3_7 = (var_3_0 - var_3_3) / var_3_6 * var_3_5
			local var_3_8 = (var_3_1 - var_3_4) / var_3_6 * var_3_5

			var_3_2:pos(var_3_3 + var_3_7, var_3_4 + var_3_8)
		end

		var_3_2:show()
		arg_3_0:showGuideManual(arg_3_0:getTeamIndex(), true)
	else
		arg_3_0.bottomWnd:getGuideHand(arg_3_0:getTeamIndex()):hide()
		arg_3_0.bottomWnd:showGuideTalk(false, arg_3_0:getTeamIndex())
		arg_3_0:showGuideManual(arg_3_0:getTeamIndex(), false)
	end
end

function var_0_3.showGuideManual(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_0.guideTarget_ and arg_4_0.guideTarget_:isDeath() then
		arg_4_0.guideTarget_:removeTargetCircle(arg_4_1)

		arg_4_0.guideTarget_ = nil
	end

	if not arg_4_0.guideTarget_ and arg_4_0:getNearestTarget() then
		arg_4_0.guideTarget_ = arg_4_0:getNearestTarget()
	end

	if not arg_4_0.guideTarget_ or arg_4_0.guideTarget_:isDeath() then
		if arg_4_0.guideManual_ then
			arg_4_0.guideManual_:hide()
		end

		return
	end

	if arg_4_2 then
		arg_4_0.guideTarget_:playTargetCircle(arg_4_1)
	else
		arg_4_0.guideTarget_:removeTargetCircle(arg_4_1)
	end

	local var_4_0 = arg_4_0.guideTarget_

	if not arg_4_0.guideManual_ then
		arg_4_0.guideManual_ = var_0_2.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_4_0.guideManual_:opacity(180)
		arg_4_0.guideManual_:addTo(var_0_1.ctx.battle.playerLayer, 0)
		arg_4_0.guideManual_:align(display.CENTER)
	end

	if not arg_4_2 then
		arg_4_0.guideManual_:hide()

		return
	end

	arg_4_0.guideManual_:show()

	local var_4_1 = arg_4_0.bottomWnd:getContainerByIndex(arg_4_1):getX()
	local var_4_2 = arg_4_0.bottomWnd:getContainerByIndex(arg_4_1):getY()
	local var_4_3 = math.atan2(var_4_0:getY() - var_4_2, var_4_0:getX() - var_4_1) / math.pi * -180
	local var_4_4 = math.sqrt((var_4_0:getY() - var_4_2) * (var_4_0:getY() - var_4_2) + (var_4_0:getX() - var_4_1) * (var_4_0:getX() - var_4_1))
	local var_4_5 = math.max(var_4_4, 0)

	arg_4_0.guideManual_:setScaleX(var_4_5 / arg_4_0.guideManual_:getWidth())
	arg_4_0.guideManual_:pos(var_4_0:getX() / 2 + var_4_1 / 2, var_4_0:getY() / 2 + var_4_2 / 2)
	arg_4_0.guideManual_:setRotation(var_4_3)
end

function var_0_3.getTeamIndex(arg_5_0)
	if not arg_5_0.teamIndex_ then
		arg_5_0.teamIndex_ = var_0_0.table.keyof(arg_5_0.selfTeam_, arg_5_0)
	end

	return arg_5_0.teamIndex_
end

function var_0_3.energyAction(arg_6_0, arg_6_1)
	var_0_3.super.energyAction(arg_6_0, arg_6_1)

	arg_6_0.showGuideCounts_ = 0
end

function var_0_3.processAfterBattleEnd(arg_7_0, arg_7_1)
	if not arg_7_0.playGuide_ then
		return
	end

	if arg_7_0.bottomWnd and not tolua.isnull(arg_7_0.bottomWnd) then
		arg_7_0.bottomWnd:getGuideHand(arg_7_0:getTeamIndex()):hide()
		arg_7_0.bottomWnd:showGuideTalk(false, arg_7_0:getTeamIndex())
		arg_7_0:showGuideManual(arg_7_0:getTeamIndex(), false)
	end
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_1.skillID == var_0_7 and arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_8 and not arg_8_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_8_0:skinSkill(arg_8_1.target)
	end

	if arg_8_0:isHasBuffByID(var_0_11) and arg_8_1.attackType == var_0_2.AttackType.AP and arg_8_0:hasElementEquipByID(var_0_10) then
		local var_8_0 = var_0_10
		local var_8_1 = var_0_6:battleAttr(var_8_0, arg_8_0:getElementEquipLevelByID(var_8_0))
		local var_8_2 = arg_8_0.hero_:getElementEquipActiveRate(var_8_0)

		arg_8_0:updateEnergyBy(var_8_1 * var_8_2)
	end
end

function var_0_3.skinSkill(arg_9_0, arg_9_1)
	arg_9_0.skinTarget_ = arg_9_1

	local var_9_0 = var_0_8
	local var_9_1 = var_0_5:sound(var_9_0)

	var_0_1.ctx.battle.pushSoundQueue(var_9_1)

	local var_9_2 = var_0_5:attackIndex(var_9_0)

	arg_9_0:playAttack(var_9_2)

	arg_9_0.unitSkills_ = var_0_4.new({
		fighter = arg_9_0,
		skillID = var_9_0
	})

	arg_9_0:beginAttackEnd(arg_9_0.unitSkills_)
end

function var_0_3.beginAttackEnd(arg_10_0, arg_10_1)
	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) <= 0 and arg_10_1.rootID_ == var_0_8 then
		arg_10_1.idQueue_ = {}
		arg_10_1.pretimeQueue_ = {}

		local var_10_0 = var_0_5:children(arg_10_1.rootID_)

		if var_10_0 and #var_10_0 > 1 then
			local var_10_1 = 1

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				if arg_10_0.skinChildCount and arg_10_0.skinChildCount[tostring(var_0_1.ctx.battle.count)] then
					var_10_1 = tonumber(arg_10_0.skinChildCount[tostring(var_0_1.ctx.battle.count)])
				end
			else
				local var_10_2 = #arg_10_0:selectTargetByTypeD2(var_0_8)

				if var_10_2 >= 2 and var_10_2 <= 3 then
					var_10_1 = 2
				elseif var_10_2 > 3 then
					var_10_1 = 3
				end

				arg_10_0.records_.skin_child_count[tostring(var_0_1.ctx.battle.count)] = var_10_1
			end

			local var_10_3 = 0

			for iter_10_0 = 1, var_10_1 do
				for iter_10_1, iter_10_2 in ipairs(var_10_0) do
					local var_10_4 = var_0_5:pretime(iter_10_2) + var_10_3 * var_0_9

					table.insert(arg_10_1.pretimeQueue_, var_10_4)
					table.insert(arg_10_1.idQueue_, iter_10_2)
				end

				var_10_3 = var_10_3 + 1
			end
		end
	end

	return var_0_3.super.beginAttackEnd(arg_10_0, arg_10_1)
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.skinChildCount = arg_11_1.skin_child_count
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.skin_child_count = arg_12_0.records_.skin_child_count

	return var_12_0
end

function var_0_3.selectTargetByTypeD1(arg_13_0, arg_13_1, arg_13_2)
	if not arg_13_0.skinTarget_ or arg_13_0.skinTarget_:isDeath() then
		return {}
	end

	return {
		arg_13_0.skinTarget_
	}
end

function var_0_3.selectTargetByTypeD2(arg_14_0, arg_14_1, arg_14_2)
	if not arg_14_0.skinTarget_ or arg_14_0.skinTarget_:isDeath() then
		return {}
	end

	local var_14_0 = var_0_5:scope(arg_14_1) / 2
	local var_14_1 = arg_14_0.skinTarget_:getX()
	local var_14_2 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and var_14_0 >= math.abs(iter_14_1:getX() - var_14_1) then
			table.insert(var_14_2, iter_14_1)
		end
	end

	return var_14_2
end

function var_0_3.applyHurtFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5)
	arg_15_2, arg_15_3, arg_15_4, arg_15_5 = var_0_3.super.applyHurtFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5)

	if arg_15_2 > 0 and arg_15_0:hasElementEquipByID(var_0_10) then
		arg_15_0.elementCount = arg_15_0.elementCount + 1

		if arg_15_0.elementCount >= var_0_13 then
			arg_15_0.elementCount = 0

			local var_15_0 = arg_15_0:createNewBuffs({
				var_0_11
			}, arg_15_0, var_0_12)

			arg_15_0:addBuffs(var_15_0)
		end
	end

	return arg_15_2, arg_15_3, arg_15_4, arg_15_5
end

return var_0_3
