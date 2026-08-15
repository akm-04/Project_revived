local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huaxin", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = "skeletons/huaxin/huaxinbuff05"
local var_0_9 = 10001248
local var_0_10 = 10001249
local var_0_11 = 10001247
local var_0_12 = 10001246
local var_0_13 = 0.002
local var_0_14 = 10001244
local var_0_15 = 10001245
local var_0_16 = 162
local var_0_17 = 100
local var_0_18 = {
	40011316,
	40011317,
	40011318
}
local var_0_19 = 10001243
local var_0_20 = 1280
local var_0_21 = 150
local var_0_22 = 150
local var_0_23 = 46
local var_0_24 = {
	40012144,
	40012145
}
local var_0_25 = 80010201

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.bluePosX_ = 0
	arg_2_0.bluePosY_ = 0
	arg_2_0.purpleStep = 0
	arg_2_0.energyCount = 0
	arg_2_0.blueEffect_ = nil
	arg_2_0.purpleCount = 0
	arg_2_0.RandomEnergySkill = 0
	arg_2_0.energyPreCount = 0
	arg_2_0.records_.rect_id = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() and iter_3_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
				if arg_3_0:isFighterInSpecialArea(iter_3_1) then
					for iter_3_2, iter_3_3 in pairs(var_0_18) do
						if not iter_3_1:getBuffByID(iter_3_3) then
							local var_3_0 = var_0_4.new({
								tableID = iter_3_3,
								start = var_0_1.ctx.battle.count,
								level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
								skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
								fighter = arg_3_0,
								target = iter_3_1
							})

							var_3_0.manualRevise = (var_3_0:initAttr() + var_3_0:step() * var_3_0.level_) * arg_3_0.purpleStep * var_0_13
							var_3_0.manualHarmRevise = (var_0_6:baseHarm(iter_3_3) + var_0_6:stepBase(iter_3_3) * var_3_0.level_) * arg_3_0.purpleStep * var_0_13

							iter_3_1:addBuffs({
								var_3_0
							})
						else
							local var_3_1 = iter_3_1:getBuffByID(iter_3_3)

							var_3_1.manualRevise = (var_3_1:initAttr() + var_3_1:step() * var_3_1.level_) * arg_3_0.purpleStep * var_0_13
							var_3_1.manualHarmRevise = (var_0_6:baseHarm(iter_3_3) + var_0_6:stepBase(iter_3_3) * var_3_1.level_) * arg_3_0.purpleStep * var_0_13
						end
					end

					if arg_3_0.isSkinSkillOn_ and (not iter_3_1:getBuffByID(var_0_24[1]) or not iter_3_1:getBuffByID(var_0_24[2])) then
						local var_3_2 = arg_3_0:createNewBuffs(var_0_24, iter_3_1, var_0_25)

						iter_3_1:addBuffs(var_3_2)
					end
				else
					for iter_3_4, iter_3_5 in pairs(var_0_18) do
						if iter_3_1:getBuffByID(iter_3_5) then
							iter_3_1:removeBuffByID(iter_3_5)
						end
					end

					if arg_3_0.isSkinSkillOn_ then
						for iter_3_6, iter_3_7 in pairs(var_0_24) do
							if iter_3_1:getBuffByID(iter_3_7) then
								iter_3_1:removeBuffByID(iter_3_7)
							end
						end
					end
				end
			end
		end
	end

	if arg_3_0.energyCount > 0 then
		arg_3_0.energyCount = arg_3_0.energyCount - 1

		if arg_3_0.energyCount <= 0 then
			for iter_3_8, iter_3_9 in pairs(arg_3_0.sideTeam_) do
				if not iter_3_9:isDeath() and iter_3_9:getSummonType() ~= var_0_2.summonMonsterType.Pet then
					local var_3_3 = iter_3_9:getBuffs()

					for iter_3_10, iter_3_11 in pairs(var_3_3) do
						if iter_3_11.specialFighter == arg_3_0 then
							iter_3_11.specialFighter = nil
							iter_3_11.manualRevise = 0
						end
					end
				end
			end
		end
	end

	if arg_3_0.energyPreCount and arg_3_0.energyPreCount > 0 then
		arg_3_0.energyPreCount = arg_3_0.energyPreCount - 1

		if arg_3_0.energyPreCount <= 0 then
			arg_3_0:createEnergySkillUnits(arg_3_0.RandomEnergySkill)

			arg_3_0.RandomEnergySkill = 0
		end
	end

	if arg_3_0.purpleCount and arg_3_0.purpleCount > 0 then
		arg_3_0.purpleCount = arg_3_0.purpleCount - 1
	end
end

function var_0_3.getFrontSkillDistance(arg_4_0)
	if arg_4_0:isSelfInSpecialArea() then
		return var_0_20
	else
		return var_0_3.super.getFrontSkillDistance(arg_4_0)
	end
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	local var_5_0, var_5_1, var_5_2, var_5_3 = var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)

	if arg_5_0.purpleCount > 0 then
		var_5_3 = true
	end

	return var_5_0, var_5_1, var_5_2, var_5_3
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_6_0.bluePosX_ = arg_6_0:getX()
		arg_6_0.bluePosY_ = arg_6_0:getY()

		if not arg_6_0.blueEffect_ then
			local var_6_0, var_6_1 = var_0_7:areaResource(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			if var_6_0 and var_6_0 ~= "" and var_6_1 and var_6_1 ~= "" then
				arg_6_0.blueEffect_ = var_0_1.ctx.battle.getSpine(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), "area", arg_6_0:getScale())

				arg_6_0.blueEffect_:addTo(var_0_1.ctx.battle.unitBottomLayer)
			end
		end

		if arg_6_0.blueEffect_ then
			arg_6_0.blueEffect_:pos(arg_6_0.bluePosX_, arg_6_0.bluePosY_)
			arg_6_0.blueEffect_:playRepeat()
		end
	elseif arg_6_1.skillID == var_0_14 then
		arg_6_0.purpleStep = arg_6_0.purpleStep + 1
	elseif arg_6_1.skillID == var_0_15 then
		arg_6_0:x(arg_6_0.bluePosX_)
		arg_6_0:y(arg_6_0.bluePosY_)

		arg_6_0.purpleCount = var_0_22
	elseif arg_6_1.skillID == var_0_9 then
		arg_6_0.energyCount = var_0_21

		for iter_6_0, iter_6_1 in pairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
				for iter_6_2, iter_6_3 in pairs(iter_6_1.dHarmBuffs_) do
					iter_6_1:removeBuffs(iter_6_3)
				end

				local var_6_2 = iter_6_1:getBuffs()

				for iter_6_4, iter_6_5 in pairs(var_6_2) do
					if iter_6_5:getAttrType() == var_0_2.AttributeType.AD_JIANSHANG or iter_6_5:getAttrType() == var_0_2.AttributeType.AP_JIANSHANG then
						iter_6_5.manualRevise = 0 - iter_6_5:getAttr()
						iter_6_5.specialFighter = arg_6_0
						iter_6_5.target.___attrCache[var_0_2.AttributeType.AD_JIANSHANG] = nil
						iter_6_5.target.___attrCache[var_0_2.AttributeType.AP_JIANSHANG] = nil
					end
				end
			end
		end
	end
end

function var_0_3.moveUnitArrive(arg_7_0, arg_7_1)
	var_0_3.super.moveUnitArrive(arg_7_0, arg_7_1)

	if arg_7_1.skillID == var_0_14 then
		arg_7_1:getAreaResource():pos(arg_7_0.bluePosX_, arg_7_0.bluePosY_)
	end
end

function var_0_3.popFrontSkill(arg_8_0)
	if arg_8_0.invalidSkillQueue_ and (not var_0_1.ctx.battle.isActivity or not next(arg_8_0.startSkillQueue_)) then
		if arg_8_0.isEnergySkill_ then
			arg_8_0.isEnergySkill_ = false
		end

		return
	end

	if arg_8_0.isEnergySkill_ then
		arg_8_0.isEnergySkill_ = false
	elseif next(arg_8_0.startSkillQueue_) ~= nil then
		local var_8_0 = arg_8_0.startSkillQueue_[1]

		table.remove(arg_8_0.startSkillQueue_, 1)

		if arg_8_0:getSkillLevelByID(var_8_0) <= 0 then
			arg_8_0:popFrontSkill()
		end
	else
		local var_8_1 = table.remove(arg_8_0.skillQueue_, 1)

		table.insert(arg_8_0.skillQueue_, var_8_1)

		if arg_8_0:getSkillLevelByID(arg_8_0.skillQueue_[1]) <= 0 then
			arg_8_0:popFrontSkill()
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_9_0)
	local var_9_0 = arg_9_0:getFrontSkill()
	local var_9_1 = var_0_7:orb(var_9_0)

	if not arg_9_0.blueEffect_ and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		var_9_0 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

		return var_9_0
	elseif var_9_0 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if arg_9_0:isSelfInSpecialArea() then
			var_9_0 = var_0_14
		else
			var_9_0 = var_0_15
		end

		return var_9_0
	elseif (var_9_0 == arg_9_0:getPugongID() or var_9_0 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) and arg_9_0:isSelfInSpecialArea() and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		return var_0_19
	end

	if var_9_1 == 0 or arg_9_0:getSkillLevelByID(var_9_1) < 1 then
		return var_0_3.super.getOrbOfFrontSkill(arg_9_0)
	end

	return var_9_1
end

function var_0_3.createEnergySkillUnits(arg_10_0, arg_10_1)
	local var_10_0 = {}
	local var_10_1 = 0

	if arg_10_1 == 1 then
		var_10_0 = arg_10_0.sideTeam_
		var_10_1 = var_0_9
	elseif arg_10_1 == 2 then
		var_10_0 = arg_10_0.sideTeam_
		var_10_1 = var_0_10
	elseif arg_10_1 == 3 then
		var_10_0 = arg_10_0.selfTeam_
		var_10_1 = var_0_11
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_10_2 = arg_10_0:createAttackUnits(var_10_0, var_10_1)

		for iter_10_0, iter_10_1 in ipairs(var_10_2) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end

		local var_10_3 = arg_10_0:createAttackUnits(arg_10_0:getEnemiesInSpecialArea(), var_0_12)

		for iter_10_2, iter_10_3 in ipairs(var_10_3) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
			table.insert(arg_10_0.records_.special_units, iter_10_3)
		end
	end
end

function var_0_3.getEnemiesInSpecialArea(arg_11_0)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in pairs(arg_11_0.sideTeam_) do
		if iter_11_1:getSummonType() ~= var_0_2.summonMonsterType.Pet and not iter_11_1:isDeath() and not iter_11_1:isAffected() and arg_11_0:isFighterInSpecialArea(iter_11_1, var_0_17) then
			table.insert(var_11_0, iter_11_1)
		end
	end

	return var_11_0
end

function var_0_3.isSelfInSpecialArea(arg_12_0)
	return arg_12_0:isFighterInSpecialArea(arg_12_0)
end

function var_0_3.isFighterInSpecialArea(arg_13_0, arg_13_1, arg_13_2)
	if arg_13_0.bluePosX_ and not arg_13_0.blueEffect_ then
		return false
	end

	if arg_13_1:getX() < arg_13_0.bluePosX_ + var_0_16 + (arg_13_2 or 0) and arg_13_1:getX() > arg_13_0.bluePosX_ - var_0_16 - (arg_13_2 or 0) then
		return true
	else
		return false
	end
end

function var_0_3.getTeammatesInSpecialArea(arg_14_0)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in pairs(arg_14_0.selfTeam_) do
		if iter_14_1:getSummonType() ~= var_0_2.summonMonsterType.Pet and not iter_14_1:isDeath() and arg_14_0:isFighterInSpecialArea(iter_14_1) then
			table.insert(var_14_0, iter_14_1)
		end
	end

	return var_14_0
end

function var_0_3.energyAction(arg_15_0, arg_15_1)
	var_0_3.super.energyAction(arg_15_0, arg_15_1)

	if var_0_7:father(arg_15_1) == arg_15_0:getEnergySkillID() then
		if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
			arg_15_0.RandomEnergySkill = arg_15_0.randomRect_[tostring(var_0_1.ctx.battle.count)] or 1
		else
			arg_15_0.RandomEnergySkill = math.random(1, 3)
			arg_15_0.records_.rect_id[tostring(var_0_1.ctx.battle.count)] = arg_15_0.RandomEnergySkill
		end

		local var_15_0 = var_0_8 .. ".json"
		local var_15_1 = var_0_8 .. ".atlas"

		if not arg_15_0.energyEffect_ and var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			arg_15_0.energyEffect_ = sp.SkeletonAnimation:create(var_15_0, var_15_1, 1)

			arg_15_0.energyEffect_:addTo(var_0_1.ctx.battle.blackLayer)
			arg_15_0.energyEffect_:pos(640, 460)
			getmetatable(sp.SkeletonAnimation).setTimeScale(arg_15_0.energyEffect_, arg_15_0.timeScale_ or 1)
		end

		arg_15_0.energyPreCount = var_0_23

		if arg_15_0.energyEffect_ then
			arg_15_0.energyEffect_:setVisible(true)
			arg_15_0.energyEffect_:clearTracks()
			arg_15_0.energyEffect_:setAnimation(0, "texiao0" .. arg_15_0.RandomEnergySkill, false)

			if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
				arg_15_0.energyEffect_:registerSpineEventHandler(function(arg_16_0)
					arg_15_0.energyEffect_:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
					arg_15_0.energyEffect_:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
					arg_15_0.energyEffect_:setVisible(false)
				end, sp.EventType.ANIMATION_COMPLETE)
			end
		end
	end
end

function var_0_3.setupReport(arg_17_0, arg_17_1)
	var_0_3.super.setupReport(arg_17_0, arg_17_1)

	arg_17_0.randomRect_ = arg_17_1.rect_id
end

function var_0_3.writeReport(arg_18_0)
	local var_18_0 = var_0_3.super.writeReport(arg_18_0)

	var_18_0.rect_id = arg_18_0.records_.rect_id

	return var_18_0
end

return var_0_3
