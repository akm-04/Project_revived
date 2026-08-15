local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunshangxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 20001446
local var_0_8 = 90

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("unit_info")

	arg_1_0.elementCD = 0

	if var_0_1.ctx.battle.battleID > 0 and var_0_1.ctx.battle.battleID <= var_0_1.ctx.battleConst.guideCampaignId - 1 and var_0_2.StoryData.get():getStoryID() <= var_0_1.ctx.battle.battleID then
		arg_1_0.playGuide_ = true
		arg_1_0.showGuideCounts_ = 0
	end
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0.playGuide_ then
		if arg_2_0:checkEnergySkill() and arg_2_0.showGuideCounts_ < 300 and arg_2_0:getNearestTarget() and not arg_2_0:getNearestTarget():isDeath() then
			arg_2_0.showGuideCounts_ = arg_2_0.showGuideCounts_ + 1

			arg_2_0.bottomWnd:showGuideTalk(true, arg_2_0:getTeamIndex())

			local var_2_0, var_2_1 = arg_2_0:getNearestTarget():getPos()
			local var_2_2 = arg_2_0.bottomWnd:getGuideHand(arg_2_0:getTeamIndex())
			local var_2_3, var_2_4 = var_2_2:getPosition()
			local var_2_5 = 4
			local var_2_6 = math.sqrt((var_2_1 - var_2_4) * (var_2_1 - var_2_4) + (var_2_0 - var_2_3) * (var_2_0 - var_2_3))

			if var_2_6 < var_2_5 then
				var_2_2:play(nil, true)
				var_2_2:pos(var_2_2.initPos[1], var_2_2.initPos[2])
			else
				local var_2_7 = (var_2_0 - var_2_3) / var_2_6 * var_2_5
				local var_2_8 = (var_2_1 - var_2_4) / var_2_6 * var_2_5

				var_2_2:pos(var_2_3 + var_2_7, var_2_4 + var_2_8)
			end

			var_2_2:show()
			arg_2_0:showGuideManual(arg_2_0:getTeamIndex(), true)
		else
			arg_2_0.bottomWnd:getGuideHand(arg_2_0:getTeamIndex()):hide()
			arg_2_0.bottomWnd:showGuideTalk(false, arg_2_0:getTeamIndex())
			arg_2_0:showGuideManual(arg_2_0:getTeamIndex(), false)
		end
	end

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:hasElementEquipByID(var_0_7) then
		if arg_2_0.elementCD > 0 then
			arg_2_0.elementCD = arg_2_0.elementCD - 1

			return
		end

		local var_2_9 = var_0_7
		local var_2_10 = var_0_6:battleAttr(var_2_9, arg_2_0:getElementEquipLevelByID(var_2_9)) * arg_2_0.hero_:getElementEquipActiveRate(var_2_9)

		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("unit_info")) do
			local var_2_11 = iter_2_1.fighter
			local var_2_12 = iter_2_1.target

			if var_2_11:getTeamType() == arg_2_0:getTeamType() and iter_2_1.attackType == var_0_2.AttackType.AD and var_0_2.weightedChoise({
				var_2_10,
				1 - var_2_10
			}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_13 = var_0_6:skillIDs(var_2_9)[1]
				local var_2_14 = arg_2_0:createAttackUnits({
					var_2_12
				}, var_2_13)

				for iter_2_2, iter_2_3 in ipairs(var_2_14) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end

				arg_2_0.elementCD = var_0_8

				return
			end
		end
	end
end

function var_0_3.showGuideManual(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_0.guideTarget_ and arg_3_0.guideTarget_:isDeath() then
		arg_3_0.guideTarget_:removeTargetCircle(arg_3_1)

		arg_3_0.guideTarget_ = nil
	end

	if not arg_3_0.guideTarget_ and arg_3_0:getNearestTarget() then
		arg_3_0.guideTarget_ = arg_3_0:getNearestTarget()
	end

	if not arg_3_0.guideTarget_ or arg_3_0.guideTarget_:isDeath() then
		if arg_3_0.guideManual_ then
			arg_3_0.guideManual_:hide()
		end

		return
	end

	if arg_3_2 then
		arg_3_0.guideTarget_:playTargetCircle(arg_3_1)
	else
		arg_3_0.guideTarget_:removeTargetCircle(arg_3_1)
	end

	local var_3_0 = arg_3_0.guideTarget_

	if not arg_3_0.guideManual_ then
		arg_3_0.guideManual_ = var_0_2.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_3_0.guideManual_:opacity(180)
		arg_3_0.guideManual_:addTo(var_0_1.ctx.battle.playerLayer, 0)
		arg_3_0.guideManual_:align(display.CENTER)
	end

	if not arg_3_2 then
		arg_3_0.guideManual_:hide()

		return
	end

	arg_3_0.guideManual_:show()

	local var_3_1 = arg_3_0.bottomWnd:getContainerByIndex(arg_3_1):getX()
	local var_3_2 = arg_3_0.bottomWnd:getContainerByIndex(arg_3_1):getY()
	local var_3_3 = math.atan2(var_3_0:getY() - var_3_2, var_3_0:getX() - var_3_1) / math.pi * -180
	local var_3_4 = math.sqrt((var_3_0:getY() - var_3_2) * (var_3_0:getY() - var_3_2) + (var_3_0:getX() - var_3_1) * (var_3_0:getX() - var_3_1))
	local var_3_5 = math.max(var_3_4, 0)

	arg_3_0.guideManual_:setScaleX(var_3_5 / arg_3_0.guideManual_:getWidth())
	arg_3_0.guideManual_:pos(var_3_0:getX() / 2 + var_3_1 / 2, var_3_0:getY() / 2 + var_3_2 / 2)
	arg_3_0.guideManual_:setRotation(var_3_3)
end

function var_0_3.getTeamIndex(arg_4_0)
	if not arg_4_0.teamIndex_ then
		arg_4_0.teamIndex_ = var_0_0.table.keyof(arg_4_0.selfTeam_, arg_4_0)
	end

	return arg_4_0.teamIndex_
end

function var_0_3.energyAction(arg_5_0, arg_5_1)
	var_0_3.super.energyAction(arg_5_0, arg_5_1)

	arg_5_0.showGuideCounts_ = 0
end

function var_0_3.processAfterBattleEnd(arg_6_0, arg_6_1)
	if not arg_6_0.playGuide_ then
		return
	end

	if arg_6_0.bottomWnd and not tolua.isnull(arg_6_0.bottomWnd) then
		arg_6_0.bottomWnd:getGuideHand(arg_6_0:getTeamIndex()):hide()
		arg_6_0.bottomWnd:showGuideTalk(false, arg_6_0:getTeamIndex())
		arg_6_0:showGuideManual(arg_6_0:getTeamIndex(), false)
	end
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = var_0_4.B1(arg_7_0, arg_7_1, arg_7_2)

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			local var_7_1 = false

			for iter_7_2, iter_7_3 in ipairs(iter_7_1:getBuffs()) do
				if var_0_5:dbuffType(iter_7_3:getTableID()) == var_0_2.DBuffType.CHEN_MO then
					var_7_1 = true
				end
			end

			if var_7_1 then
				table.insert(var_7_0, iter_7_1)
			end
		end
	end

	return var_7_0
end

function var_0_3.selectTargetByTypeD2(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = var_0_4.B1(arg_8_0, arg_8_1, arg_8_2)

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() then
			local var_8_1 = false

			for iter_8_2, iter_8_3 in ipairs(iter_8_1:getBuffs()) do
				if var_0_5:dbuffType(iter_8_3:getTableID()) == var_0_2.DBuffType.CHEN_MO then
					var_8_1 = true
				end
			end

			if var_8_1 then
				table.insert(var_8_0, iter_8_1)
			end
		end
	end

	return var_8_0
end

function var_0_3.selectTargetByTypeD3(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = var_0_4.B3(arg_9_0, arg_9_1, arg_9_2)

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
			local var_9_1 = false

			for iter_9_2, iter_9_3 in ipairs(iter_9_1:getBuffs()) do
				if var_0_5:dbuffType(iter_9_3:getTableID()) == var_0_2.DBuffType.CHEN_MO then
					var_9_1 = true
				end
			end

			if var_9_1 then
				table.insert(var_9_0, iter_9_1)
			end
		end
	end

	return var_9_0
end

return var_0_3
