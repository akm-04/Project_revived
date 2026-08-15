local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lvmeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.elementEquip
local var_0_8 = var_0_2.tables.skinSkill
local var_0_9 = 10350001
local var_0_10 = 50
local var_0_11 = 40010268
local var_0_12 = 0.6
local var_0_13 = 0.6
local var_0_14 = 0.02
local var_0_15 = 0.3
local var_0_16 = 0.3
local var_0_17 = 20001432
local var_0_18 = 200

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	if var_0_1.ctx.battle.battleID > 0 and var_0_1.ctx.battle.battleID <= var_0_1.ctx.battleConst.guideCampaignId - 1 and var_0_2.StoryData.get():getStoryID() <= var_0_1.ctx.battle.battleID then
		arg_2_0.playGuide_ = true
		arg_2_0.showGuideCounts_ = 0
	end

	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
	arg_2_0.skinADJianshang = var_0_15
	arg_2_0.skinAPJianshang = var_0_16
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_3_0.extraSkillLevel > 0 then
		local var_3_0 = var_0_4.new({
			tableID = var_0_11,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0.extraSkillLevel,
			skillID = arg_3_1.skillID,
			fighter = arg_3_0,
			target = arg_3_1.target
		})

		var_3_0:setIsHit(true)
		var_3_0:setDirection(arg_3_0:getFighterModel():getFlipX())
		arg_3_1.target:addBuffs({
			var_3_0
		})
	end
end

function var_0_3.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_0.isSkinSkillOn_ and arg_4_4 > 0 and arg_4_0.skinAPJianshang ~= 0 then
		local var_4_0 = var_0_6:type(arg_4_1.skillID)

		if var_4_0 == var_0_2.AttackType.AP then
			arg_4_4 = arg_4_4 * (1 - arg_4_0.skinAPJianshang)
		elseif var_4_0 == var_0_2.AttackType.AD then
			arg_4_4 = arg_4_4 * (1 - arg_4_0.skinADJianshang)
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.getTargets(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}
	local var_5_1 = var_0_6:selectType(arg_5_1)

	if arg_5_0:getForceTarget() and not arg_5_0:getForceTarget():isDeath() then
		if var_5_1 == "C11" then
			local var_5_2 = arg_5_0:getForceTarget()

			if (arg_5_2.iniX_ < var_5_2:getX() and var_5_2:getX() <= arg_5_2:getX() or arg_5_2.iniX_ > var_5_2:getX() and var_5_2:getX() >= arg_5_2:getX()) and not arg_5_2.targets[var_5_2.fighterIndex] then
				arg_5_2.targets[var_5_2.fighterIndex] = var_5_2

				return {
					var_5_2
				}
			end

			return {}
		end

		return {
			arg_5_0:getForceTarget()
		}
	end

	if arg_5_0["selectTargetByType" .. var_5_1] then
		var_5_0 = arg_5_0["selectTargetByType" .. var_5_1](arg_5_0, arg_5_1, arg_5_2)
	elseif arg_5_1 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_0.extraSkillLevel > 0 then
		var_5_0 = arg_5_0:selectTargetByTypeD1(arg_5_1, arg_5_2)
	else
		var_5_0 = var_0_5[var_5_1](arg_5_0, arg_5_1, arg_5_2)
	end

	return var_5_0
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}
	local var_6_1 = var_0_6:scope(arg_6_1) + var_0_10
	local var_6_2, var_6_3 = arg_6_0:getPos()

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
		local var_6_4, var_6_5 = iter_6_1:getPos()

		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_1 >= math.abs(var_6_4 - var_6_2) then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

function var_0_3.toDoPerFrames(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if arg_7_0.isSkinSkillOn_ then
		for iter_7_0, iter_7_1 in ipairs(arg_7_0:getInfoByKey("unit_info")) do
			if iter_7_1.target == arg_7_0 then
				local var_7_0 = var_0_6:type(iter_7_1.skillID)

				if var_7_0 == var_0_2.AttackType.AP and arg_7_0.skinAPJianshang < var_0_13 then
					arg_7_0.skinAPJianshang = arg_7_0.skinAPJianshang + var_0_14
					arg_7_0.skinADJianshang = arg_7_0.skinADJianshang - var_0_14
				elseif var_7_0 == var_0_2.AttackType.AD and arg_7_0.skinADJianshang < var_0_12 then
					arg_7_0.skinAPJianshang = arg_7_0.skinAPJianshang - var_0_14
					arg_7_0.skinADJianshang = arg_7_0.skinADJianshang + var_0_14
				end
			end
		end
	end

	if not arg_7_0.playGuide_ and not arg_7_0.extraSkillJudge then
		arg_7_0.extraSkillJudge = true
		arg_7_0.extraSkillLevel = arg_7_0.hero_:skillBook()[tostring(var_0_9)] or 0
	end

	if not arg_7_0.playGuide_ then
		return
	end

	if arg_7_0:checkEnergySkill() and arg_7_0.showGuideCounts_ < 300 and arg_7_0:getNearestTarget() and not arg_7_0:getNearestTarget():isDeath() then
		arg_7_0.showGuideCounts_ = arg_7_0.showGuideCounts_ + 1

		arg_7_0.bottomWnd:showGuideTalk(true, arg_7_0:getTeamIndex())

		local var_7_1, var_7_2 = arg_7_0:getNearestTarget():getPos()
		local var_7_3 = arg_7_0.bottomWnd:getGuideHand(arg_7_0:getTeamIndex())
		local var_7_4, var_7_5 = var_7_3:getPosition()
		local var_7_6 = 4
		local var_7_7 = math.sqrt((var_7_2 - var_7_5) * (var_7_2 - var_7_5) + (var_7_1 - var_7_4) * (var_7_1 - var_7_4))

		if var_7_7 < var_7_6 then
			var_7_3:play(nil, true)
			var_7_3:pos(var_7_3.initPos[1], var_7_3.initPos[2])
		else
			local var_7_8 = (var_7_1 - var_7_4) / var_7_7 * var_7_6
			local var_7_9 = (var_7_2 - var_7_5) / var_7_7 * var_7_6

			var_7_3:pos(var_7_4 + var_7_8, var_7_5 + var_7_9)
		end

		var_7_3:show()
		arg_7_0:showGuideManual(arg_7_0:getTeamIndex(), true)
	else
		arg_7_0.bottomWnd:getGuideHand(arg_7_0:getTeamIndex()):hide()
		arg_7_0.bottomWnd:showGuideTalk(false, arg_7_0:getTeamIndex())
		arg_7_0:showGuideManual(arg_7_0:getTeamIndex(), false)
	end
end

function var_0_3.showGuideManual(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_0.guideTarget_ and arg_8_0.guideTarget_:isDeath() then
		arg_8_0.guideTarget_:removeTargetCircle(arg_8_1)

		arg_8_0.guideTarget_ = nil
	end

	if not arg_8_0.guideTarget_ and arg_8_0:getNearestTarget() then
		arg_8_0.guideTarget_ = arg_8_0:getNearestTarget()
	end

	if not arg_8_0.guideTarget_ or arg_8_0.guideTarget_:isDeath() then
		if arg_8_0.guideManual_ then
			arg_8_0.guideManual_:hide()
		end

		return
	end

	if arg_8_2 then
		arg_8_0.guideTarget_:playTargetCircle(arg_8_1)
	else
		arg_8_0.guideTarget_:removeTargetCircle(arg_8_1)
	end

	local var_8_0 = arg_8_0.guideTarget_

	if not arg_8_0.guideManual_ then
		arg_8_0.guideManual_ = var_0_2.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_8_0.guideManual_:opacity(180)
		arg_8_0.guideManual_:addTo(var_0_1.ctx.battle.playerLayer, 0)
		arg_8_0.guideManual_:align(display.CENTER)
	end

	if not arg_8_2 then
		arg_8_0.guideManual_:hide()

		return
	end

	arg_8_0.guideManual_:show()

	local var_8_1 = arg_8_0.bottomWnd:getContainerByIndex(arg_8_1):getX()
	local var_8_2 = arg_8_0.bottomWnd:getContainerByIndex(arg_8_1):getY()
	local var_8_3 = math.atan2(var_8_0:getY() - var_8_2, var_8_0:getX() - var_8_1) / math.pi * -180
	local var_8_4 = math.sqrt((var_8_0:getY() - var_8_2) * (var_8_0:getY() - var_8_2) + (var_8_0:getX() - var_8_1) * (var_8_0:getX() - var_8_1))
	local var_8_5 = math.max(var_8_4, 0)

	arg_8_0.guideManual_:setScaleX(var_8_5 / arg_8_0.guideManual_:getWidth())
	arg_8_0.guideManual_:pos(var_8_0:getX() / 2 + var_8_1 / 2, var_8_0:getY() / 2 + var_8_2 / 2)
	arg_8_0.guideManual_:setRotation(var_8_3)
end

function var_0_3.getTeamIndex(arg_9_0)
	if not arg_9_0.teamIndex_ then
		arg_9_0.teamIndex_ = var_0_0.table.keyof(arg_9_0.selfTeam_, arg_9_0)
	end

	return arg_9_0.teamIndex_
end

function var_0_3.energyAction(arg_10_0, arg_10_1)
	var_0_3.super.energyAction(arg_10_0, arg_10_1)

	arg_10_0.showGuideCounts_ = 0
end

function var_0_3.processAfterBattleEnd(arg_11_0, arg_11_1)
	if not arg_11_0.playGuide_ then
		return
	end

	if arg_11_0.bottomWnd and not tolua.isnull(arg_11_0.bottomWnd) then
		arg_11_0.bottomWnd:getGuideHand(arg_11_0:getTeamIndex()):hide()
		arg_11_0.bottomWnd:showGuideTalk(false, arg_11_0:getTeamIndex())
		arg_11_0:showGuideManual(arg_11_0:getTeamIndex(), false)
	end
end

function var_0_3.addBuffBySpecialHero(arg_12_0, arg_12_1)
	var_0_3.super.addBuffBySpecialHero(arg_12_0, arg_12_1)

	if arg_12_0:hasElementEquipByID(var_0_17) then
		for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
			if iter_12_1:Ychange() > 0 and iter_12_1.target:getTeamType() ~= arg_12_0:getTeamType() then
				local var_12_0 = var_0_17
				local var_12_1 = var_0_7:battleAttr(var_12_0, arg_12_0:getElementEquipLevelByID(var_12_0))
				local var_12_2 = arg_12_0.hero_:getElementEquipActiveRate(var_12_0)

				arg_12_0:resetHpLimit(arg_12_0:getHpLimit() + var_12_1 * var_12_2)
				arg_12_0:updateEnergyBy(var_0_18)
			end
		end
	end
end

return var_0_3
