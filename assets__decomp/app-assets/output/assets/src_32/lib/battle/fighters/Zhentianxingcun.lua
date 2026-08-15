local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhentianxingcun", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 10001048
local var_0_12 = 10001050
local var_0_13 = 10001049
local var_0_14 = 40011157
local var_0_15 = 40011159
local var_0_16 = 10001051
local var_0_17 = 40011158
local var_0_18 = 30010186
local var_0_19 = 10001055
local var_0_20 = 20010186
local var_0_21 = 10001052
local var_0_22 = 10001053
local var_0_23 = 10001054
local var_0_24 = 40010186
local var_0_25 = 10001056
local var_0_26 = 40011164
local var_0_27 = 20
local var_0_28 = 450
local var_0_29 = 300
local var_0_30 = 20070005
local var_0_31 = 40011952
local var_0_32 = 80
local var_0_33 = "skeletons/zhentianxingcun/ball"
local var_0_34 = {
	Black = 2,
	White = 1
}
local var_0_35 = 80010186
local var_0_36 = 0.6

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skillBallQueue = {}
	arg_1_0.EnergySkillCount = var_0_29

	arg_1_0:removeBalls()

	arg_1_0.nextSkillBall = nil
	arg_1_0.firstTarget = nil
	arg_1_0.secondTarget = nil
	arg_1_0.purpleBuffCount = 0
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.extraManualHarmRevise = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_30)] or 0
		arg_2_0.extraManualHarmRevise = arg_2_0.extraSkillLevel * var_0_32
	end

	if var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % var_0_28 == 0 then
		arg_2_0:addBallAction(var_0_34.White)
	end

	arg_2_0.EnergySkillCount = arg_2_0.EnergySkillCount - 1
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_0.skinSkillID_ == var_0_35 and arg_3_1.attackType == var_0_2.AttackType.AP and not arg_3_1.target:isBoss() then
		for iter_3_0, iter_3_1 in ipairs(arg_3_1.target:getBuffs()) do
			if iter_3_1:getTableID() == var_0_14 or iter_3_1:getTableID() == var_0_15 or iter_3_1:getTableID() == var_0_17 then
				arg_3_4 = arg_3_4 + arg_3_4 * var_0_36

				break
			end
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.skillID

	if var_4_0 == var_0_12 and arg_4_0.extraSkillLevel > 0 then
		local var_4_1 = var_0_7.new({
			tableID = var_0_31,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0.extraSkillLevel,
			fighter = arg_4_0,
			target = arg_4_1.target,
			manualHarmRevise = arg_4_0.extraManualHarmRevise
		})

		arg_4_1.target:addBuffs({
			var_4_1
		})
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if var_4_0 == arg_4_0:getEnergySkillID() and arg_4_0.nextSkillBall then
			if arg_4_0.nextSkillBall == var_0_34.White then
				local var_4_2 = var_0_8:sound(var_0_11)

				var_0_1.ctx.battle.pushSoundQueue(var_4_2)

				local var_4_3 = var_0_8:attackIndex(var_0_11)

				arg_4_0:playAttack(var_4_3)

				arg_4_0.unitSkills_ = var_0_5.new({
					fighter = arg_4_0,
					skillID = var_0_11
				})

				arg_4_0:beginAttackEnd(arg_4_0.unitSkills_)
			else
				local var_4_4 = var_0_8:sound(var_0_12)

				var_0_1.ctx.battle.pushSoundQueue(var_4_4)

				local var_4_5 = var_0_8:attackIndex(var_0_12)

				arg_4_0:playAttack(var_4_5)

				arg_4_0.unitSkills_ = var_0_5.new({
					fighter = arg_4_0,
					skillID = var_0_12
				})

				arg_4_0:beginAttackEnd(arg_4_0.unitSkills_)
			end

			arg_4_0.nextSkillBall = nil
		elseif var_4_0 == var_0_11 then
			local var_4_6 = arg_4_0:createAttackUnits({
				arg_4_0
			}, var_0_13)

			for iter_4_0, iter_4_1 in ipairs(var_4_6) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		elseif var_4_0 == var_0_12 and not arg_4_1.target:isHasBuffByID(var_0_17) then
			local var_4_7 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_16)

			for iter_4_2, iter_4_3 in ipairs(var_4_7) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0.purpleBuffCount < var_0_27 then
				local var_4_8 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_4_4, iter_4_5 in ipairs(var_4_8) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end

				arg_4_0.purpleBuffCount = arg_4_0.purpleBuffCount + 1
			end
		elseif var_4_0 == var_0_18 then
			local var_4_9 = arg_4_0:createAttackUnits({
				arg_4_0
			}, var_0_19)

			for iter_4_6, iter_4_7 in ipairs(var_4_9) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
				table.insert(arg_4_0.records_.special_units, iter_4_7)
			end

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0.purpleBuffCount < var_0_27 then
				local var_4_10 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_4_8, iter_4_9 in ipairs(var_4_10) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_9)
					table.insert(arg_4_0.records_.special_units, iter_4_9)
				end

				arg_4_0.purpleBuffCount = arg_4_0.purpleBuffCount + 1

				local var_4_11 = arg_4_0:createAttackUnits({
					arg_4_1.target
				}, var_0_25)

				for iter_4_10, iter_4_11 in ipairs(var_4_11) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_11)
					table.insert(arg_4_0.records_.special_units, iter_4_11)
				end
			end
		elseif var_4_0 == var_0_21 and not arg_4_1.target:isHasBuffByID(var_0_14) and not arg_4_1.target:isHasBuffByID(var_0_15) then
			local var_4_12 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_23)

			for iter_4_12, iter_4_13 in ipairs(var_4_12) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_13)
				table.insert(arg_4_0.records_.special_units, iter_4_13)
			end

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0.purpleBuffCount < var_0_27 then
				local var_4_13 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_4_14, iter_4_15 in ipairs(var_4_13) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_15)
					table.insert(arg_4_0.records_.special_units, iter_4_15)
				end

				arg_4_0.purpleBuffCount = arg_4_0.purpleBuffCount + 1

				local var_4_14 = arg_4_0:createAttackUnits({
					arg_4_1.target
				}, var_0_25)

				for iter_4_16, iter_4_17 in ipairs(var_4_14) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_17)
					table.insert(arg_4_0.records_.special_units, iter_4_17)
				end
			end
		elseif var_4_0 == var_0_22 and not arg_4_1.target:isHasBuffByID(var_0_14) and not arg_4_1.target:isHasBuffByID(var_0_15) then
			local var_4_15 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_23)

			for iter_4_18, iter_4_19 in ipairs(var_4_15) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_19)
				table.insert(arg_4_0.records_.special_units, iter_4_19)
			end

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0.purpleBuffCount < var_0_27 then
				local var_4_16 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_4_20, iter_4_21 in ipairs(var_4_16) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_21)
					table.insert(arg_4_0.records_.special_units, iter_4_21)
				end

				arg_4_0.purpleBuffCount = arg_4_0.purpleBuffCount + 1

				local var_4_17 = arg_4_0:createAttackUnits({
					arg_4_1.target
				}, var_0_25)

				for iter_4_22, iter_4_23 in ipairs(var_4_17) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_23)
					table.insert(arg_4_0.records_.special_units, iter_4_23)
				end
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	var_0_3.super.buffRemoveAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_14 or arg_5_1:getTableID() == var_0_15 or arg_5_1:getTableID() == var_0_17 then
		arg_5_0.purpleBuffCount = arg_5_0.purpleBuffCount - 1

		arg_5_1.target:removeBuffByID(var_0_26)
	end
end

function var_0_3.unitAfterCreate(arg_6_0, arg_6_1, arg_6_2)
	for iter_6_0, iter_6_1 in ipairs(arg_6_2) do
		if iter_6_1.skillID == var_0_21 and not arg_6_0.firstTarget then
			arg_6_0.firstTarget = iter_6_1.target
		end

		if iter_6_1.skillID == var_0_22 and not arg_6_0.secondTarget then
			arg_6_0.secondTarget = iter_6_1.target
		end
	end
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	if arg_7_1:getTableID() == var_0_14 or arg_7_1:getTableID() == var_0_15 then
		arg_7_1:setForceTarget(arg_7_0)
	elseif arg_7_1:getTableID() == var_0_17 then
		if arg_7_1.target == arg_7_0.firstTarget and arg_7_0.secondTarget then
			arg_7_1:setForceTarget(arg_7_0.secondTarget)
		end

		if arg_7_1.target == arg_7_0.secondTarget and arg_7_0.firstTarget then
			arg_7_1:setForceTarget(arg_7_0.firstTarget)
		end
	end
end

function var_0_3.beginAttack(arg_8_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_8_0 = arg_8_0.reportSkills_[1]

		if not var_8_0 or var_0_1.ctx.battle.count ~= var_8_0.startCount_ then
			if arg_8_0.reportSkills_[2] and arg_8_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_8_0.reportSkills_, 1)
			else
				return
			end
		end
	elseif not arg_8_0:canAttack() then
		return
	end

	if arg_8_0:popSkillByType() == var_0_20 then
		arg_8_0.firstTarget = nil
		arg_8_0.secondTarget = nil

		arg_8_0:removeWhiteBallBuffs()
	end

	var_0_3.super.beginAttack(arg_8_0)
end

function var_0_3.removeWhiteBallBuffs(arg_9_0)
	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() then
			iter_9_1:removeBuffByID(var_0_17)
		end
	end
end

function var_0_3.beginAttackEnd(arg_10_0, arg_10_1)
	var_0_3.super.beginAttackEnd(arg_10_0, arg_10_1)

	if arg_10_1.rootID_ == arg_10_0:getEnergySkillID() then
		arg_10_0.EnergySkillCount = var_0_29

		arg_10_0:removeBallAction()
	elseif arg_10_1.rootID_ == var_0_20 then
		arg_10_0:addBallAction(var_0_34.White)
	elseif arg_10_1.rootID_ == var_0_18 then
		arg_10_0:addBallAction(var_0_34.Black)
	end
end

function var_0_3.addBallAction(arg_11_0, arg_11_1)
	table.insert(arg_11_0.skillBallQueue, arg_11_1)

	if arg_11_0:getTeamType() ~= var_0_2.TeamType.A or not arg_11_0.bottomWnd or not not tolua.isnull(arg_11_0.bottomWnd) or var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if #arg_11_0.skillBallQueue <= 3 then
		local var_11_0 = tonumber(var_0_2.split(arg_11_0.fighterIndex, "|")[2])
		local var_11_1 = arg_11_0.bottomWnd.children_["click_node" .. var_11_0]
		local var_11_2 = var_0_33 .. arg_11_1 .. ".png"
		local var_11_3 = cc.Sprite:create(var_11_2)

		if var_11_3 and var_11_1 then
			var_11_3:addTo(var_11_1, 100)
			var_11_3:setPosition(40 + #arg_11_0.skillBall_ * 40, -40)
			var_11_3:setScale(0.8)
			var_11_3:setOpacity(0)
			var_11_3:runAction(cc.FadeIn:create(1))
			table.insert(arg_11_0.skillBall_, var_11_3)
		end
	end
end

function var_0_3.removeBallAction(arg_12_0)
	if not arg_12_0.skillBallQueue or not next(arg_12_0.skillBallQueue) or not arg_12_0.skillBall_ or not next(arg_12_0.skillBall_) then
		return
	end

	arg_12_0.nextSkillBall = arg_12_0.skillBallQueue[1]

	table.remove(arg_12_0.skillBallQueue, 1)

	if arg_12_0:getTeamType() ~= var_0_2.TeamType.A or not arg_12_0.bottomWnd or not not tolua.isnull(arg_12_0.bottomWnd) or var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_12_0.skillBall_ and next(arg_12_0.skillBall_) then
		arg_12_0.skillBall_[1]:removeSelf()
		table.remove(arg_12_0.skillBall_, 1)

		if #arg_12_0.skillBallQueue >= 3 and #arg_12_0.skillBall_ >= 2 then
			arg_12_0.skillBall_[1]:runAction(cc.MoveBy:create(0.8, cc.p(-40, 0)))
			arg_12_0.skillBall_[2]:runAction(cc.Sequence:create({
				cc.MoveBy:create(0.8, cc.p(-40, 0)),
				cc.CallFunc:create(function()
					local var_13_0 = tonumber(var_0_2.split(arg_12_0.fighterIndex, "|")[2])
					local var_13_1 = arg_12_0.bottomWnd.children_["click_node" .. var_13_0]
					local var_13_2 = var_0_33 .. arg_12_0.skillBallQueue[3] .. ".png"
					local var_13_3 = cc.Sprite:create(var_13_2)

					if var_13_3 then
						var_13_3:addTo(var_13_1, 100)
						var_13_3:setPosition(120, -40)
						var_13_3:setScale(0.8)
						var_13_3:setOpacity(0)
						var_13_3:runAction(cc.FadeIn:create(1))
						table.insert(arg_12_0.skillBall_, var_13_3)
					end
				end)
			}))
		elseif #arg_12_0.skillBallQueue == 2 and #arg_12_0.skillBall_ >= 2 then
			arg_12_0.skillBall_[1]:runAction(cc.MoveBy:create(0.8, cc.p(-40, 0)))
			arg_12_0.skillBall_[2]:runAction(cc.MoveBy:create(0.8, cc.p(-40, 0)))
		elseif #arg_12_0.skillBallQueue == 1 and #arg_12_0.skillBall_ >= 1 then
			arg_12_0.skillBall_[1]:runAction(cc.MoveBy:create(0.8, cc.p(-40, 0)))
		end
	end
end

function var_0_3.removeBalls(arg_14_0)
	if not arg_14_0.skillBall_ then
		arg_14_0.skillBall_ = {}
	else
		for iter_14_0, iter_14_1 in ipairs(arg_14_0.skillBall_) do
			arg_14_0.skillBall_[iter_14_0]:removeSelf()
		end

		arg_14_0.skillBall_ = {}
	end
end

function var_0_3.die(arg_15_0)
	var_0_3.super.die(arg_15_0)
	arg_15_0:removeBalls()
end

function var_0_3.selectTargetByTypeD1(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and (not var_16_0 or iter_16_1:getAD() > var_16_0:getAD()) then
			var_16_0 = iter_16_1
		end
	end

	if var_16_0 then
		return {
			var_16_0
		}
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.sideTeam_) do
		if not iter_17_1:isDeath() and not iter_17_1:isAffected() and (not var_17_0 or iter_17_1:getAD() > var_17_0:getAD()) then
			var_17_0 = iter_17_1
		end
	end

	local var_17_1

	if var_17_0 then
		for iter_17_2, iter_17_3 in ipairs(arg_17_0.sideTeam_) do
			if not iter_17_3:isDeath() and not iter_17_3:isAffected() and iter_17_3 ~= var_17_0 and (not var_17_1 or iter_17_3:getAD() > var_17_1:getAD()) then
				var_17_1 = iter_17_3
			end
		end

		if var_17_1 then
			return {
				var_17_1
			}
		else
			return {}
		end
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD3(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.sideTeam_) do
		if not iter_18_1:isDeath() and not iter_18_1:isAffected() and not iter_18_1:isHasBuffByID(var_0_17) and (not var_18_0 or iter_18_1:getAP() > var_18_0:getAP()) then
			var_18_0 = iter_18_1
		end
	end

	if var_18_0 then
		return {
			var_18_0
		}
	else
		return {}
	end
end

function var_0_3.checkEnergySkill(arg_19_0)
	if next(arg_19_0.skillBallQueue) and arg_19_0.EnergySkillCount <= 0 then
		if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
			return false
		end

		if arg_19_0:isDeath() then
			return false
		end

		if arg_19_0:getDelaySkill() > var_0_1.ctx.battle.count then
			return false
		end

		if arg_19_0.walk2Position_ then
			return false
		end

		if arg_19_0:isBattleUnable() then
			return false
		end

		if arg_19_0:isApUnable() and (var_0_8:type(arg_19_0:getEnergySkillID()) == var_0_2.AttackType.AP or var_0_8:type(arg_19_0:getEnergySkillID()) == var_0_2.AttackType.CURE) then
			return false
		end

		if arg_19_0:isAdUnable() and var_0_8:type(arg_19_0:getEnergySkillID()) == var_0_2.AttackType.AD then
			return false
		end

		if arg_19_0.isEnergySkill_ and arg_19_0:isCreatingUnits() then
			return false
		end

		if arg_19_0:isAutoFighter() and arg_19_0:isInSkillRoll() then
			return false
		end

		if arg_19_0:isPugongOnly() then
			return false
		end

		if arg_19_0:isInvalidEnergySkill() then
			return false
		end

		if not arg_19_0:getNearestTarget() then
			return false
		end

		local var_19_0 = var_0_8:distance(arg_19_0:getEnergySkillID())

		if var_19_0 > 0 and var_19_0 < math.abs(arg_19_0:getNearestTarget():getX() - arg_19_0:getX()) then
			return false
		end

		if arg_19_0.leftInterval_ > 0 and arg_19_0.arenaEnergyFull_ ~= true and (var_0_2.CampaignType.ARENA == var_0_1.ctx.battle.campaignType or var_0_2.CampaignType.SUPER_ARENA == var_0_1.ctx.battle.campaignType) then
			return false
		end

		return true
	else
		return false
	end
end

function var_0_3.updateEnergyTo(arg_20_0, arg_20_1)
	return
end

function var_0_3.updateEnergyBy(arg_21_0, arg_21_1, arg_21_2)
	return
end

function var_0_3.updateEnergyByHarm(arg_22_0, arg_22_1)
	return
end

function var_0_3.updateEnergyByCount(arg_23_0)
	return
end

return var_0_3
