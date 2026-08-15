local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mifuren", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.cabinetSkillTable
local var_0_8 = 40010852
local var_0_9 = 40010853
local var_0_10 = 100
local var_0_11 = 40010849
local var_0_12 = 10000790
local var_0_13 = 10000781
local var_0_14 = 10000780
local var_0_15 = {
	0,
	100,
	250,
	650
}
local var_0_16 = {
	3.5,
	1.7,
	1.2,
	0.5
}
local var_0_17 = 90
local var_0_18 = 10000782
local var_0_19 = 10000783
local var_0_20 = 10000791
local var_0_21 = 50
local var_0_22 = 10000787
local var_0_23 = 10000792
local var_0_24 = 10000793
local var_0_25 = 10000784
local var_0_26 = 40010851
local var_0_27 = 50
local var_0_28 = 50
local var_0_29 = 5
local var_0_30 = 90
local var_0_31 = 20020004
local var_0_32 = 690
local var_0_33 = 0.1
local var_0_34 = 0.06
local var_0_35 = 30
local var_0_36 = 40011098
local var_0_37 = var_0_2.tables.elementEquip
local var_0_38 = 20001485
local var_0_39 = 40012520
local var_0_40 = 15

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("death_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenSecondAttack = false
	arg_2_0.greenSkillLock = false
	arg_2_0.blueCount = 0
	arg_2_0.purpleBuffOn_ = false
	arg_2_0.specialSkillOnAttack_ = false
	arg_2_0.purpleBuffTarget = nil
	arg_2_0.greenSkillSecondReady = false
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
	arg_2_0.extraSkillTimeCount_ = 0
	arg_2_0.extraSkillTimeCD_ = 0
	arg_2_0.skinSkillCount = 0
end

function var_0_3.applyUnitMoves(arg_3_0)
	for iter_3_0 = #arg_3_0.moveUnits_, 1, -1 do
		if next(arg_3_0.moveUnits_) and arg_3_0.moveUnits_[iter_3_0].arrived then
			local var_3_0 = arg_3_0.moveUnits_[iter_3_0]

			table.remove(arg_3_0.moveUnits_, iter_3_0)
			arg_3_0:moveUnitArrive(var_3_0)
		elseif arg_3_0.moveUnits_[iter_3_0] ~= nil then
			local var_3_1 = arg_3_0.moveUnits_[iter_3_0]

			var_3_1:rotate()
			var_3_1:movePosition()

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and var_3_1.selectType == "C11" then
				local var_3_2 = var_3_1:getReportUnits()

				for iter_3_1, iter_3_2 in ipairs(var_3_2) do
					table.insert(arg_3_0.applyUnits_, iter_3_2)
				end
			elseif var_3_1.selectType == "C11" then
				local var_3_3 = arg_3_0:getTargets(var_3_1.skillID, var_3_1)

				if next(var_3_3) then
					local var_3_4 = var_3_1:createAttacks(var_3_3)

					for iter_3_3, iter_3_4 in ipairs(var_3_4) do
						table.insert(arg_3_0.applyUnits_, iter_3_4)
					end

					if var_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
						var_3_1.arrived = true

						arg_3_0:moveUnitArrive(var_3_1)

						if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
							arg_3_0.greenSkillSecondReady = true
						end
					end
				end
			end
		end
	end

	for iter_3_5 = #arg_3_0.moveAttackUnits_, 1, -1 do
		local var_3_5 = arg_3_0.moveAttackUnits_[iter_3_5]

		if var_3_5.arrived then
			if not var_0_0.table.keyof(arg_3_0.applyUnits_, var_3_5) then
				table.insert(arg_3_0.applyUnits_, var_3_5)
			end

			if var_3_5.collisionNum > 1 then
				-- block empty
			else
				if var_3_5.resource and not var_0_1.ctx.battle.isReleased(var_3_5.resource) then
					var_3_5.resource:stop()

					var_3_5.resource = nil
				else
					var_3_5.resource = nil
				end

				table.remove(arg_3_0.moveAttackUnits_, iter_3_5)
			end
		end

		if var_3_5.speed == 0 and var_3_5.arrived and (var_3_5.unitEffectType == var_0_2.UnitEffectType.ShanDianLian or var_3_5.unitEffectType == var_0_2.UnitEffectType.ShenMieZhan) then
			local var_3_6 = #var_3_5.targets_ > 1 and var_3_5.targets_[#var_3_5.targets_ - 1] or arg_3_0
			local var_3_7 = var_3_5.target
			local var_3_8 = #var_3_5.targets_ > 1 and var_3_6:getX() + var_3_6:getFighterModel().attackedPoint.x or var_3_5:getIniPos("x")
			local var_3_9 = var_3_7:getX() + var_3_7:getFighterModel().attackedPoint.x
			local var_3_10 = #var_3_5.targets_ > 1 and var_3_6:getY() + var_3_6:getFighterModel().attackedPoint.y or var_3_5:getIniPos("y")
			local var_3_11 = var_3_7:getY() + var_3_7:getFighterModel().attackedPoint.y
			local var_3_12 = var_3_5:createResource()
			local var_3_13 = var_3_12:getSizeX() - 10

			var_3_13 = var_3_13 < 0 and 180 or var_3_13

			var_3_12:addTo(var_0_1.ctx.battle.unitLayer)
			var_3_12:setScaleX(math_sqrt((var_3_9 - var_3_8) * (var_3_9 - var_3_8) + (var_3_11 - var_3_10) * (var_3_11 - var_3_10)) / var_3_13)
			var_3_12:setRotation(math.atan2(var_3_11 - var_3_10, var_3_9 - var_3_8) / math.pi * -180)
			var_3_12:x((var_3_9 + var_3_8) / 2)
			var_3_12:y((var_3_11 + var_3_10) / 2)
			var_3_12:playOnce()
			arg_3_0:flipX(var_3_5.target:getX() < arg_3_0:getX())
		end

		if var_3_5.speed > 0 and not var_3_5.arrived then
			if var_3_5.count ~= var_0_1.ctx.battle.count then
				var_3_5:rotate()
				var_3_5:movePosition()
			end

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				if var_3_5.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)] then
					var_3_5:resetTarget(var_3_5.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)])
				end
			elseif var_3_5.isResetTarget and var_3_5.target:isDeath() then
				local var_3_14 = arg_3_0:getTargets(var_3_5.skillID, var_3_5)

				if var_3_14 and next(var_3_14) then
					var_3_5:resetTarget(var_3_14[1])
				end
			end
		elseif var_3_5.speed == 0 and not var_3_5.arrived then
			var_3_5.collisionCount = var_3_5.collisionCount - 1

			if var_3_5:getCollisionCount() <= 0 then
				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					if var_3_5.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)] then
						var_3_5:resetTarget(var_3_5.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)])
					end
				elseif var_3_5.isResetTarget and var_3_5.target:isDeath() then
					local var_3_15 = arg_3_0:getTargets(var_3_5.skillID, var_3_5)

					if var_3_15 and next(var_3_15) then
						var_3_5:resetTarget(var_3_15[1])
					end
				end

				var_3_5.arrived = true

				var_3_5:setCollisionCount()
			end
		end
	end
end

function var_0_3.getFrontSkill(arg_4_0)
	return (var_0_3.super.getFrontSkill(arg_4_0))
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == var_0_12 then
		if arg_5_1.target:getBuffByID(var_0_8) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_0 = var_0_4:sound(var_0_13)

			var_0_1.ctx.battle.pushSoundQueue(var_5_0)

			local var_5_1 = var_0_4:attackIndex(var_0_13)

			arg_5_0.unitSkills_ = var_0_5.new({
				fighter = arg_5_0,
				skillID = var_0_13
			})

			arg_5_0:beginAttackEnd(arg_5_0.unitSkills_)
		end
	elseif arg_5_1.skillID == var_0_18 then
		if not arg_5_0.greenSkillLock then
			if not arg_5_0.greenSecondAttack then
				if arg_5_1.target.hero_:getHeroType() ~= var_0_2.HeroType.STRENGTH then
					arg_5_0.greenSkillLock = true
					arg_5_0.greenSecondAttack = true

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						arg_5_0:createSkillByID(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
					end
				end
			else
				arg_5_0.greenSecondAttack = false
				arg_5_0.greenSkillLock = true
			end
		end
	elseif arg_5_1.skillID == var_0_22 then
		arg_5_0.bluePosX_ = arg_5_1.target:getX()
		arg_5_0.blueCount = var_0_30

		if not arg_5_0.blueEffect_ then
			arg_5_0.blueEffectOn_ = true

			local var_5_2, var_5_3 = var_0_4:areaResource(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			if var_5_2 and var_5_2 ~= "" and var_5_3 and var_5_3 ~= "" then
				arg_5_0.blueEffect_ = var_0_1.ctx.battle.getSpine(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), "area", arg_5_0:getScale())

				arg_5_0.blueEffect_:addTo(var_0_1.ctx.battle.unitBottomLayer)
			end
		end

		if arg_5_0.blueEffect_ then
			arg_5_0.blueEffect_:pos(arg_5_0.bluePosX_, 300)
			arg_5_0.blueEffect_:playRepeat()
		end
	elseif arg_5_1.skillID == var_0_23 then
		arg_5_0.blueNearestTarget = arg_5_1.target
	elseif arg_5_1.skillID == var_0_24 then
		arg_5_0.blueFarthestTarget = arg_5_1.target
	elseif arg_5_1.skillID == arg_5_0:getPugongID() and arg_5_0.extraSkillLevel > 0 and var_0_1.ctx.battle.count - arg_5_0.extraSkillTimeCount_ >= arg_5_0.extraSkillTimeCD_ then
		arg_5_0.extraSkillTimeCount_ = var_0_1.ctx.battle.count

		arg_5_0:createSkillByID(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	end

	if arg_5_0:hasElementEquipByID(var_0_38) then
		arg_5_0:updateEnergyBy(var_0_40)
	end
end

function var_0_3.calculateUnitData(arg_6_0, arg_6_1)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.calculateUnitData(arg_6_0, arg_6_1)

	if arg_6_1.skillID == var_0_14 then
		local var_6_6 = arg_6_0:selectTargetByTypeD1()[1]

		if var_6_6 then
			local var_6_7 = math.abs(arg_6_1.target:getX() - var_6_6:getX())
			local var_6_8 = var_0_16[4]

			for iter_6_0 = 4, 1, -1 do
				if var_6_7 < var_0_15[iter_6_0] then
					var_6_8 = var_0_16[iter_6_0 - 1]
				end
			end

			var_6_2 = var_6_2 * var_6_8
		end
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.createSkillByID(arg_7_0, arg_7_1, arg_7_2)
	arg_7_0:resetLeftInterval()
	arg_7_0:selfSkillEffect()

	arg_7_0.specialAttackSkillID_ = arg_7_1
	arg_7_0.specialAttackSkillLevel_ = arg_7_2

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_7_0.unitSkills_ = arg_7_0.reportSkills_[1]
	else
		arg_7_0.unitSkills_ = var_0_5.new({
			fighter = arg_7_0,
			skillID = arg_7_1
		})
	end

	arg_7_0:pushFrontSkill()
	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)
end

function var_0_3.pushFrontSkill(arg_8_0)
	arg_8_0.specialSkillOnAttack_ = true
end

function var_0_3.popFrontSkill(arg_9_0)
	if arg_9_0.specialSkillOnAttack_ then
		arg_9_0.specialSkillOnAttack_ = false

		return
	else
		var_0_3.super.popFrontSkill(arg_9_0)
	end
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	if arg_10_1:getTableID() == var_0_11 and arg_10_1.target:getBuffByID(var_0_8) then
		arg_10_1:setExtraTime(var_0_17)
	elseif arg_10_1:getTableID() == var_0_39 then
		local var_10_0 = var_0_38

		arg_10_1.manualRevise = var_0_37:battleAttr(var_10_0, arg_10_0:getElementEquipLevelByID(var_10_0)) * arg_10_0.hero_:getElementEquipActiveRate(var_10_0)
	end
end

function var_0_3.toDoPerFrames(arg_11_0)
	arg_11_0.greenSkillLock = false

	if arg_11_0.blueCount > 0 then
		arg_11_0.blueCount = arg_11_0.blueCount - 1

		if arg_11_0.blueCount == 0 then
			if arg_11_0.blueNearestTarget then
				arg_11_0.blueNearestTarget:removeBuffByID(var_0_26)
			end

			if arg_11_0.blueFarthestTarget then
				arg_11_0.blueFarthestTarget:removeBuffByID(var_0_26)
			end

			arg_11_0:blueSkillOver()
		elseif arg_11_0.blueNearestTarget then
			if not arg_11_0.blueNearestTarget:isDeath() and math.abs(arg_11_0.bluePosX_ - arg_11_0.blueNearestTarget:getX()) >= var_0_29 then
				local var_11_0 = arg_11_0.bluePosX_ < arg_11_0.blueNearestTarget:getX() and -1 or 1

				arg_11_0.blueNearestTarget:moveByX(var_11_0 * var_0_29)
			end

			if not arg_11_0.blueFarthestTarget:isDeath() and math.abs(arg_11_0.bluePosX_ - arg_11_0.blueFarthestTarget:getX()) >= var_0_29 then
				local var_11_1 = arg_11_0.bluePosX_ < arg_11_0.blueFarthestTarget:getX() and -1 or 1

				arg_11_0.blueFarthestTarget:moveByX(var_11_1 * var_0_29)
			end

			if not arg_11_0.blueNearestTarget:isDeath() and not arg_11_0.blueFarthestTarget:isDeath() and math.abs(arg_11_0.blueNearestTarget:getX() - arg_11_0.blueFarthestTarget:getX()) < var_0_27 then
				arg_11_0.blueFarthestTarget:removeBuffByID(var_0_26)
				arg_11_0.blueNearestTarget:removeBuffByID(var_0_26)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_11_2 = arg_11_0:getBlueBombTargets()

					for iter_11_0, iter_11_1 in pairs(var_11_2) do
						local var_11_3 = arg_11_0:createAttackUnits({
							iter_11_1
						}, var_0_25)

						table.insert(arg_11_0.moveAttackUnits_, var_11_3[1])
						arg_11_0:unitAfterCreate(nil, var_11_3)
					end
				end

				arg_11_0:blueSkillOver()
			end
		end
	end

	if not arg_11_0.purpleBuffOn_ and arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_11_0:createSkillByID(arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

		arg_11_0.purpleBuffOn_ = true
		arg_11_0.purpleBuffTarget = arg_11_0:getNearestTarget()
	end

	if arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_11_2, iter_11_3 in ipairs(arg_11_0:getInfoByKey("death_info")) do
			if iter_11_3 == arg_11_0.purpleBuffTarget then
				local var_11_4 = arg_11_0:getPurpleNewTarget(arg_11_0.purpleBuffTarget:getX())

				if var_11_4 then
					arg_11_0.purpleBuffTarget = var_11_4

					local var_11_5 = arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
					local var_11_6 = var_0_6.new({
						tableID = var_0_8,
						start = var_0_1.ctx.battle.count,
						level = arg_11_0:getSkillLevelByID(var_11_5),
						skillID = var_11_5,
						fighter = arg_11_0,
						target = var_11_4
					})

					arg_11_0.purpleBuffTarget:addBuffs({
						var_11_6
					})

					if arg_11_0.purpleBuffTarget:getBuffByID(var_0_9) then
						arg_11_0.purpleBuffTarget:removeBuffByID(var_0_9)
					end
				end
			end
		end

		if arg_11_0.purpleBuffTarget then
			arg_11_0:dealWithPurpleTargets()
		end
	end

	if arg_11_0.greenSkillSecondReady and not var_0_1.ctx.battle.isEnergySkilling then
		arg_11_0.greenSkillSecondReady = false

		arg_11_0:createSkillByID(var_0_18, arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	end

	if not arg_11_0.extraSkillJudge then
		arg_11_0.extraSkillJudge = true
		arg_11_0.extraSkillLevel = arg_11_0.hero_:skillBook()[tostring(var_0_31)] or 0
		arg_11_0.extraSkillTimeCD_ = var_0_32 - arg_11_0.extraSkillLevel * var_0_7:attrValues(var_0_31) * 30
	end

	if arg_11_0.isSkinSkillOn_ then
		local var_11_7 = 0

		for iter_11_4, iter_11_5 in ipairs(arg_11_0:getInfoByKey("buff_info")) do
			if iter_11_5:getType() == var_0_2.BuffType.D_HARM and iter_11_5.target ~= arg_11_0 then
				local var_11_8 = iter_11_5:getDHarm() * var_0_33

				var_11_7 = var_11_7 + var_11_8

				iter_11_5:setDHarm(var_11_8)
				iter_11_5.target:updateHpBar(true)
			end
		end

		if arg_11_0.skinSkillCount < var_0_35 then
			arg_11_0.skinSkillCount = arg_11_0.skinSkillCount + 1
		else
			var_11_7 = var_11_7 + arg_11_0:stealShieldBuffPerSecond()
			arg_11_0.skinSkillCount = 0
		end

		if var_11_7 > 0 then
			local var_11_9 = arg_11_0:getBuffByID(var_0_36)

			if not var_11_9 then
				local var_11_10 = arg_11_0:getEnergySkillID()

				var_11_9 = var_0_6.new({
					tableID = var_0_36,
					start = var_0_1.ctx.battle.count,
					level = arg_11_0:getSkillLevelByID(var_11_10),
					skillID = var_11_10,
					fighter = arg_11_0,
					target = arg_11_0
				})

				arg_11_0:addBuffs({
					var_11_9
				})
			end

			var_11_9.manualDharm = var_11_9.manualDharm + var_11_7

			var_11_9:setDHarm(0 - var_11_7)
			arg_11_0:updateHpBar(true)
		end
	end

	if arg_11_0:hasElementEquipByID(var_0_38) and var_0_1.ctx.battle.count == 1 then
		local var_11_11 = arg_11_0:createNewBuffs({
			var_0_39
		}, arg_11_0, arg_11_0:getEnergySkillID())

		arg_11_0:addBuffs(var_11_11)
	end
end

function var_0_3.stealShieldBuffPerSecond(arg_12_0)
	local var_12_0 = 0

	for iter_12_0, iter_12_1 in pairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() then
			local var_12_1 = iter_12_1:getBuffs()

			for iter_12_2, iter_12_3 in pairs(var_12_1) do
				if iter_12_3:getType() == var_0_2.BuffType.D_HARM then
					local var_12_2 = iter_12_3:totalDHarm() * var_0_34

					iter_12_3:setDHarm(var_12_2)
					iter_12_3.target:updateHpBar(true)

					var_12_0 = var_12_0 + var_12_2
				end
			end
		end
	end

	return var_12_0
end

function var_0_3.dealWithPurpleTargets(arg_13_0)
	for iter_13_0, iter_13_1 in pairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1 ~= arg_13_0.purpleBuffTarget then
			if math.abs(iter_13_1:getX() - arg_13_0.purpleBuffTarget:getX()) < var_0_10 then
				if not iter_13_1:getBuffByID(var_0_9) then
					local var_13_0 = arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
					local var_13_1 = var_0_6.new({
						tableID = var_0_9,
						start = var_0_1.ctx.battle.count,
						level = arg_13_0:getSkillLevelByID(var_13_0),
						skillID = var_13_0,
						fighter = arg_13_0,
						target = iter_13_1
					})

					iter_13_1:addBuffs({
						var_13_1
					})
				end
			elseif iter_13_1:getBuffByID(var_0_9) then
				iter_13_1:removeBuffByID(var_0_9)
			end
		end
	end
end

function var_0_3.getPurpleNewTarget(arg_14_0, arg_14_1)
	local var_14_0
	local var_14_1

	for iter_14_0, iter_14_1 in pairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() then
			if not var_14_1 then
				var_14_1 = iter_14_1
				var_14_0 = math.abs(iter_14_1:getX() - arg_14_1)
			elseif var_14_0 > math.abs(iter_14_1:getX() - arg_14_1) then
				var_14_1 = iter_14_1
				var_14_0 = math.abs(iter_14_1:getX() - arg_14_1)
			end
		end
	end

	return var_14_1
end

function var_0_3.blueSkillOver(arg_15_0)
	if arg_15_0.blueEffect_ then
		arg_15_0.blueEffect_:stop()

		arg_15_0.blueEffect_ = nil
	end

	arg_15_0.blueNearestTarget = nil
	arg_15_0.blueFarthestTarget = nil
	arg_15_0.bluePosX_ = nil
	arg_15_0.blueCount = 0
end

function var_0_3.getBlueEffectPosition(arg_16_0)
	local function var_16_0(arg_17_0, arg_17_1)
		local var_17_0 = {}

		table.insert(var_17_0, arg_17_0)

		for iter_17_0, iter_17_1 in ipairs(arg_17_0.selfTeam_) do
			if not iter_17_1:isDeath() and not iter_17_1:isAffected() and iter_17_1 ~= arg_17_0 and arg_17_1 >= math.abs(iter_17_1:getX() - arg_17_0:getX()) then
				table.insert(var_17_0, iter_17_1)
			end
		end

		return var_17_0
	end

	local var_16_1 = {}
	local var_16_2 = 0
	local var_16_3 = var_0_4:scope(skillID) * 0.5

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() then
			local var_16_4 = var_16_0(iter_16_1, var_16_3)

			if var_16_2 < #var_16_4 then
				var_16_1 = var_16_4
				var_16_2 = #var_16_4
			end
		end
	end

	if #var_16_1 >= 1 then
		arg_16_0.blueEffectPosX = var_16_1[1]:getX()

		return arg_16_0.blueEffectPosX
	end
end

function var_0_3.getBlueBombTargets(arg_18_0)
	if arg_18_0.bluePosX_ == 0 then
		return {}
	end

	local var_18_0 = {}

	for iter_18_0, iter_18_1 in pairs(arg_18_0.sideTeam_) do
		if not iter_18_1:isDeath() and not iter_18_1:isAffected() and math.abs(iter_18_1:getX() - arg_18_0.bluePosX_) < var_0_28 then
			table.insert(var_18_0, iter_18_1)
		end
	end

	return var_18_0
end

function var_0_3.selectTargetByTypeD1(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0
	local var_19_1

	for iter_19_0, iter_19_1 in pairs(arg_19_0.sideTeam_) do
		if not var_19_1 and not iter_19_1:isDeath() and not iter_19_1:isAffected() then
			var_19_0 = iter_19_1.hero_:getMainAttr(var_0_2.AttributeType.WISE)
			var_19_1 = iter_19_1
		elseif not iter_19_1:isDeath() and not iter_19_1:isAffected() and var_19_0 > iter_19_1.hero_:getMainAttr(var_0_2.AttributeType.WISE) then
			var_19_0 = iter_19_1.hero_:getMainAttr(var_0_2.AttributeType.WISE)
			var_19_1 = iter_19_1
		end
	end

	return {
		var_19_1
	}
end

function var_0_3.selectTargetByTypeD2(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = {}
	local var_20_1 = var_0_4:scope(arg_20_1) / 2
	local var_20_2 = arg_20_0:selectTargetByTypeD1()[1]

	for iter_20_0, iter_20_1 in pairs(arg_20_0.sideTeam_) do
		if not iter_20_1:isDeath() and not iter_20_1:isAffected() and iter_20_1 ~= var_20_2 and var_20_1 > math.abs(iter_20_1:getX() - var_20_2:getX()) then
			table.insert(var_20_0, iter_20_1)
		end
	end

	return var_20_0
end

function var_0_3.updateHpBar(arg_21_0, arg_21_1)
	if arg_21_0.hpBar_ and arg_21_0.avatarIndex_ then
		arg_21_0.bottomWnd:setHPProgress(arg_21_0:getHp() / arg_21_0:getHpLimit(), arg_21_0.avatarIndex_, arg_21_1)
	end

	local var_21_0 = arg_21_0:getHp() / arg_21_0:getHpLimit()

	arg_21_0.fighterModel:setHPProgress(var_21_0, arg_21_1, nil, var_0_1.ctx.battle.count)

	local var_21_1 = arg_21_0:getBuffByID(var_0_36)

	arg_21_0.fighterModel:updateHeroHeaderView(var_0_1.ctx.battle.count, var_21_1 or arg_21_0.showDHarmbuff_)
end

function var_0_3.getDHarmBuff(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	local var_22_0 = arg_22_1
	local var_22_1 = 0
	local var_22_2 = arg_22_0:getBuffByID(var_0_36)

	if var_22_2 then
		var_22_0 = var_22_2:setDHarm(var_22_0)
	end

	local var_22_3 = false

	for iter_22_0 = #arg_22_0.buffs_, 1, -1 do
		local var_22_4 = arg_22_0.buffs_[iter_22_0]
		local var_22_5 = var_0_0.clone(var_22_0)

		if var_22_4:getDHarm() > 0 and (var_22_4:dHarmType() == arg_22_2 or var_22_4:dHarmType() == var_0_2.HarmType.All) and not var_22_4:isDHarmLast() then
			if var_22_0 == 0 then
				return 0, 0, true
			end

			var_22_0 = var_22_4:setDHarm(var_22_0)

			if var_22_4:getDHarm() == 0 and var_22_4.fighter then
				var_22_4.fighter:dHarmBuffBreakFeedback(arg_22_0, var_22_4, arg_22_3)
			end

			if var_22_4.fighter and not var_22_4.fighter:isDeath() then
				var_22_4.fighter:dHarmBuffFeedback(var_22_4, arg_22_0)
			end

			if var_22_4:harmToHP() > 0 then
				var_22_1 = var_22_1 + var_22_4:harmToHP() * (var_22_5 - var_22_0)
			end

			if var_22_0 == 0 then
				return var_22_0, var_22_1, true
			end

			var_22_3 = true
		end
	end

	return var_22_0, var_22_1, var_22_3
end

return var_0_3
