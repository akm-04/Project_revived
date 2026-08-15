local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuanfeizuozhu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 90
local var_0_8 = 300
local var_0_9 = 0
local var_0_10 = 25
local var_0_11 = 0
local var_0_12 = 0.3
local var_0_13 = {
	40010282,
	40010283,
	40010284,
	40010290
}
local var_0_14 = 150
local var_0_15 = 50010114
local var_0_16 = 20010114
local var_0_17 = 40010114
local var_0_18 = 10000487
local var_0_19 = 10000488
local var_0_20 = 10001879
local var_0_21 = 10001876
local var_0_22 = 10001878
local var_0_23 = 10001880
local var_0_24 = 10001881

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTargets_ = {}
	arg_1_0.greenUnits_ = {}
	arg_1_0.xuliSkill_ = nil
	arg_1_0.xuliCount_ = 0
	arg_1_0.isEnergyBuff_ = false
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.EnergySkill = var_0_20
		arg_2_0.GreenSkill = var_0_21
		arg_2_0.PurpleSkill = var_0_22
		arg_2_0.GreenCureSkill = var_0_23
		arg_2_0.GreenEnergySkill = var_0_24
	else
		arg_2_0.EnergySkill = var_0_15
		arg_2_0.GreenSkill = var_0_16
		arg_2_0.PurpleSkill = var_0_17
		arg_2_0.GreenCureSkill = var_0_18
		arg_2_0.GreenEnergySkill = var_0_19
	end
end

function var_0_3.isHurtBreak(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = var_0_3.super.isHurtBreak(arg_3_0, arg_3_1, arg_3_2)

	if var_3_0 and arg_3_0.xuliSkill_ then
		arg_3_0.isEnergyBuff_ = false

		arg_3_0:energyAttack()
	end

	return var_3_0
end

function var_0_3.beginAttack(arg_4_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0.reportSkills_[1]

		if not var_4_0 or var_0_1.ctx.battle.count ~= var_4_0.startCount_ then
			if arg_4_0.reportSkills_[2] and arg_4_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_4_0.reportSkills_, 1)
			else
				return
			end
		end
	elseif not arg_4_0:canAttack() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_4_0.reportSkills_[1].rootID_ == arg_4_0:getEnergySkillID() then
			arg_4_0.xuliSkill_ = true
			arg_4_0.xuliCount_ = 1

			if arg_4_0:getTeamType() == var_0_2.TeamType.A and arg_4_0.bottomWnd then
				arg_4_0.bottomWnd:setXuliSkillEffect(arg_4_0, var_0_1.ctx.battle.teamA, true)
			end
		end
	elseif arg_4_0:getFrontSkill() == arg_4_0:getEnergySkillID() then
		arg_4_0.xuliSkill_ = true
		arg_4_0.xuliCount_ = 1

		if arg_4_0:getTeamType() == var_0_2.TeamType.A and arg_4_0.bottomWnd then
			arg_4_0.bottomWnd:setXuliSkillEffect(arg_4_0, var_0_1.ctx.battle.teamA, true)
		end
	end

	var_0_3.super.beginAttack(arg_4_0)
end

function var_0_3.checkSkillBreak(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_1 == var_0_2.BreakSkillType.AP then
		if arg_5_0:getCurrentSkillType() == var_0_2.AttackType.AP or arg_5_0:getCurrentSkillType() == var_0_2.AttackType.CURE then
			if arg_5_0:isCreatingUnits() then
				arg_5_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_5_0:getTeamType())
				arg_5_0:skillIsBreak(arg_5_2)
			end

			arg_5_0.isEnergySkill_ = false
		end

		if arg_5_0.xuliSkill_ then
			arg_5_0.isEnergyBuff_ = false

			arg_5_0:energyAttack()
		end
	elseif arg_5_1 == var_0_2.BreakSkillType.AD then
		if arg_5_0:isAdBreakImmortal() then
			return
		end

		arg_5_0:setBreakInterval()

		if not arg_5_0:isPause() then
			arg_5_0:attacked()
		end

		if arg_5_0:getCurrentSkillType() == var_0_2.AttackType.AD then
			if arg_5_0:isCreatingUnits() then
				arg_5_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BREAK
				}, arg_5_0:getTeamType())
				arg_5_0:skillIsBreak(arg_5_2)
			end

			arg_5_0.isEnergySkill_ = false
		end

		if arg_5_0.xuliSkill_ then
			arg_5_0.isEnergyBuff_ = false

			arg_5_0:energyAttack()
		end
	end
end

function var_0_3.clickAvatar(arg_6_0, arg_6_1)
	if arg_6_0.xuliSkill_ and arg_6_1.name == "ended" and var_0_1.ctx.battle.autoA ~= true then
		if arg_6_0:isCreatingUnits() then
			arg_6_0:skillIsBreak()
		end

		arg_6_0.isEnergySkill_ = false
		arg_6_0.isEnergyBuff_ = false

		arg_6_0:energyAttack()
	end
end

function var_0_3.energyAttack(arg_7_0)
	if arg_7_0:isDeath() or not arg_7_0.xuliSkill_ then
		arg_7_0.xuliSkill_ = nil

		return
	end

	local var_7_0 = var_0_6:xuliChild(arg_7_0:getEnergySkillID())
	local var_7_1 = var_0_6:sound(var_7_0)

	var_0_1.ctx.battle.pushSoundQueue(var_7_1)

	local var_7_2 = var_0_6:attackIndex(var_7_0)

	arg_7_0:playAttack(var_7_2)

	arg_7_0.unitSkills_ = var_0_5.new({
		fighter = arg_7_0,
		skillID = var_7_0
	})

	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)

	local var_7_3 = {}
	local var_7_4 = arg_7_0:getEnergySkillID()

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			table.insert(var_7_3, iter_7_1)
		end
	end

	if arg_7_0.xuliCount_ >= var_0_14 then
		for iter_7_2, iter_7_3 in ipairs(var_7_3) do
			iter_7_3:addBuffs(arg_7_0:newBuff(var_0_13, iter_7_3, var_7_4))
		end
	else
		for iter_7_4, iter_7_5 in ipairs(var_7_3) do
			iter_7_5:addBuffs(arg_7_0:newBuff({
				var_0_13[1],
				var_0_13[2]
			}, iter_7_5, var_7_4))
		end
	end

	if arg_7_0:getTeamType() == var_0_2.TeamType.A and arg_7_0.bottomWnd then
		arg_7_0.bottomWnd:setXuliSkillEffect(arg_7_0, var_0_1.ctx.battle.teamA, false)
	end

	arg_7_0.xuliSkill_ = nil
	arg_7_0.xuliCount_ = 0
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if var_0_6:father(arg_8_1.skillID) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_8_0 = var_0_1.ctx.battle.getSpine(arg_8_1.skillID, "area", 1)

		var_8_0:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_8_0:pos(arg_8_1.target:getX(), arg_8_1.target:getY())
		var_8_0:playRepeat()

		local var_8_1

		if arg_8_1.skillID == arg_8_0.GreenCureSkill then
			var_8_1 = "cure"
		elseif arg_8_1.skillID == arg_8_0.GreenEnergySkill then
			var_8_1 = "energy"
		end

		local var_8_2 = {
			area = var_8_0,
			posX = arg_8_1.target:getX(),
			scope = var_0_6:scope(arg_8_1.skillID),
			leftTime = var_0_8,
			randomEffect = var_8_1
		}
		local var_8_3 = {
			area = var_8_0,
			targets = {}
		}

		table.insert(arg_8_0.greenUnits_, var_8_2)
		table.insert(arg_8_0.greenTargets_, var_8_3)
	elseif arg_8_1.skillID == arg_8_0.EnergySkill then
		arg_8_0:getFighterModel():playAnimation_("gongji06", true)

		arg_8_0.isEnergyBuff_ = true
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0, arg_9_1, arg_9_2)
	local function var_9_0(arg_10_0, arg_10_1)
		local var_10_0 = {}

		table.insert(var_10_0, arg_10_0)

		for iter_10_0, iter_10_1 in ipairs(arg_9_0.selfTeam_) do
			if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1 ~= arg_10_0 and arg_10_1 >= math.abs(iter_10_1:getX() - arg_10_0:getX()) then
				table.insert(var_10_0, iter_10_1)
			end
		end

		return #var_10_0
	end

	local var_9_1 = {}
	local var_9_2 = 0
	local var_9_3 = var_0_6:scope(arg_9_1) * 0.5

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
			local var_9_4 = var_9_0(iter_9_1, var_9_3)

			if var_9_2 < var_9_4 then
				var_9_1 = {
					iter_9_1
				}
				var_9_2 = var_9_4
			end
		end
	end

	return var_9_1
end

function var_0_3.canAttack(arg_11_0)
	if arg_11_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.canAttack(arg_11_0)
	end
end

function var_0_3.toDoPerFrames(arg_12_0)
	if not arg_12_0.stopTimeCount_ and var_0_1.ctx.battle.count % 10 == 0 then
		for iter_12_0, iter_12_1 in ipairs(arg_12_0.greenUnits_) do
			if next(iter_12_1) then
				local var_12_0

				for iter_12_2, iter_12_3 in ipairs(arg_12_0.greenTargets_) do
					if iter_12_3.area == iter_12_1.area then
						var_12_0 = iter_12_3.targets
					end
				end

				for iter_12_4, iter_12_5 in ipairs(arg_12_0.selfTeam_) do
					if not iter_12_5:isDeath() and not iter_12_5:isAffected() then
						local var_12_1 = arg_12_0:isInGreenTable(iter_12_5, var_12_0)

						if var_12_1 > 0 then
							if arg_12_0:isInGreenCircle(iter_12_5, iter_12_1) then
								var_12_0[var_12_1].time = var_12_0[var_12_1].time + 10

								if var_12_0[var_12_1].time >= var_0_7 then
									var_12_0[var_12_1].time = 0

									arg_12_0:doGreenEffect(iter_12_5, iter_12_1.randomEffect)
								end
							else
								table.remove(var_12_0, var_12_1)
							end
						elseif arg_12_0:isInGreenCircle(iter_12_5, iter_12_1) then
							local var_12_2 = {
								time = 0,
								target = iter_12_5
							}

							table.insert(var_12_0, var_12_2)
						end
					end
				end

				iter_12_1.leftTime = iter_12_1.leftTime - 10

				if iter_12_1.leftTime <= 0 then
					arg_12_0:removeGreenEffect(iter_12_0)
				end
			end
		end
	end

	if arg_12_0:isDeath() then
		return
	end

	if arg_12_0.xuliSkill_ then
		arg_12_0.xuliCount_ = arg_12_0.xuliCount_ + 1

		if arg_12_0.xuliCount_ >= var_0_14 then
			arg_12_0.isEnergyBuff_ = false

			arg_12_0:energyAttack()
		end
	else
		arg_12_0.xuliCount_ = 0
	end
end

function var_0_3.getOrbOfFrontSkill(arg_13_0)
	local var_13_0 = var_0_3.super.getOrbOfFrontSkill(arg_13_0)

	if var_13_0 == arg_13_0.GreenSkill or var_13_0 == arg_13_0.PurpleSkill then
		local var_13_1 = var_0_6:randomOrb(var_13_0)

		if next(var_13_1) then
			local var_13_2 = {}

			for iter_13_0, iter_13_1 in ipairs(var_13_1) do
				table.insert(var_13_2, 1)
			end

			return var_13_1[var_0_2.weightedChoise(var_13_2)]
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_13_0)
end

function var_0_3.isInGreenTable(arg_14_0, arg_14_1, arg_14_2)
	for iter_14_0, iter_14_1 in ipairs(arg_14_2) do
		if iter_14_1.target == arg_14_1 then
			return iter_14_0
		end
	end

	return -1
end

function var_0_3.isInGreenCircle(arg_15_0, arg_15_1, arg_15_2)
	if math.abs(arg_15_1:getX() - arg_15_2.posX) <= arg_15_2.scope * 0.5 then
		return true
	else
		return false
	end
end

function var_0_3.doGreenEffect(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

	if arg_16_2 == "cure" then
		local var_16_1 = (var_0_9 + var_0_10 * var_16_0) * arg_16_1:getDCureRate()

		arg_16_1:updateHp(arg_16_1:getHp() + var_16_1)
		arg_16_1.fighterModel:playHPDeltas({
			{
				var_16_1,
				false
			}
		}, nil)
	elseif arg_16_2 == "energy" then
		local var_16_2 = var_0_11 + var_0_12 * var_16_0

		arg_16_1:updateEnergyBy(var_16_2)
		arg_16_1.fighterModel:playEnergyFloat(var_16_2)
	end
end

function var_0_3.removeGreenEffect(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0.greenUnits_[arg_17_1]

	if var_17_0 then
		for iter_17_0, iter_17_1 in ipairs(arg_17_0.greenTargets_) do
			if iter_17_1.area == var_17_0.area then
				table.remove(arg_17_0.greenTargets_, iter_17_0)

				break
			end
		end

		var_17_0.area:removeSelf()
		table.remove(arg_17_0.greenUnits_, arg_17_1)
	end
end

function var_0_3.newBuff(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = {}

	for iter_18_0, iter_18_1 in ipairs(arg_18_1) do
		local var_18_1 = var_0_4.new({
			tableID = iter_18_1,
			start = var_0_1.ctx.battle.count,
			level = arg_18_0:getSkillLevelByID(arg_18_3),
			skillID = arg_18_3,
			fighter = arg_18_0,
			target = arg_18_2
		})

		var_18_1:setIsHit(true)
		var_18_1:setDirection(arg_18_0:getFighterModel():getFlipX())
		table.insert(var_18_0, var_18_1)
	end

	return var_18_0
end

function var_0_3.checkEnergySkill(arg_19_0)
	if arg_19_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_19_0)
	end
end

function var_0_3.die(arg_20_0)
	arg_20_0.xuliSkill_ = nil

	if arg_20_0:getTeamType() == var_0_2.TeamType.A and arg_20_0.bottomWnd then
		arg_20_0.bottomWnd:setXuliSkillEffect(arg_20_0, var_0_1.ctx.battle.teamA, false)
	end

	var_0_3.super.die(arg_20_0)
end

return var_0_3
