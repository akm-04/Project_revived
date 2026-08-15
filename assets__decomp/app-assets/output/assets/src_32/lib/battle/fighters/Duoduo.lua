local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 360
local var_0_6 = 0.5
local var_0_7 = 40010463
local var_0_8 = 40010467
local var_0_9 = 0.2
local var_0_10 = 0.003

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyTargets_ = {}
	arg_2_0.energyCount_ = 0
	arg_2_0.purpleCount_ = 0
	arg_2_0.records_.hit_target = {}
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.energyTargets_[arg_3_1.target] = true
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.energyTargets_ = {}
		arg_4_0.energyCount_ = var_0_5
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0.purpleCount_ > 0 then
		arg_5_0.purpleCount_ = arg_5_0.purpleCount_ - 1

		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
			if iter_5_1.target:getTeamType() == arg_5_0:getTeamType() and iter_5_1.target:isHasBuffByID(var_0_8) and iter_5_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				local var_5_0 = iter_5_1:getAttr()

				if var_5_0 < 0 and iter_5_1:getAttrType() > 0 then
					local var_5_1 = iter_5_1.manualRevise
					local var_5_2 = var_5_0 - var_5_1
					local var_5_3 = var_0_9 + var_0_10 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

					iter_5_1.manualRevise = var_5_3 * -1 * var_5_2 + (1 - var_5_3) * var_5_1
				end
			end
		end
	end

	if arg_5_0.energyCount_ > 0 then
		arg_5_0.energyCount_ = arg_5_0.energyCount_ - 1

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			for iter_5_2, iter_5_3 in ipairs(arg_5_0:getInfoByKey("attack_info")) do
				local var_5_4 = iter_5_3.fighter_

				if arg_5_0.energyTargets_[var_5_4] and var_0_4:type(iter_5_3.rootID_) == var_0_2.AttackType.AP then
					if var_5_4:isHasBuffByID(var_0_7) and not var_5_4:isDeath() then
						local var_5_5 = var_0_6

						if arg_5_0.isStarEnergy_ then
							var_5_5 = var_5_5 + 0.1
						end

						if var_0_2.weightedChoise({
							var_5_5,
							1 - var_5_5
						}) == 1 then
							local var_5_6 = var_0_2.split(var_5_4.fighterIndex, "|")
							local var_5_7 = tonumber(var_5_6[2])

							if not arg_5_0.records_.hit_target[tostring(var_0_1.ctx.battle.count)] then
								arg_5_0.records_.hit_target[tostring(var_0_1.ctx.battle.count)] = {
									var_5_7
								}
							else
								table.insert(arg_5_0.records_.hit_target[tostring(var_0_1.ctx.battle.count)], var_5_7)
							end

							if not var_5_4:isBreakImmortal() then
								var_5_4:setBreakInterval()

								if not var_5_4:isPause() and var_0_1.ctx.battle.isEnergySkilling then
									var_5_4:getFighterModel():resume()
								end

								if not var_5_4:isPause() then
									var_5_4:attacked()
								end

								if var_5_4:isCreatingUnits() then
									var_5_4.fighterModel:playFloatText({
										var_0_2.BattleFloatType.BREAK
									}, var_5_4:getTeamType())
									var_5_4:skillIsBreak()
								end
							end
						end
					else
						arg_5_0.energyTargets_[var_5_4] = false
					end
				end
			end
		else
			local var_5_8 = arg_5_0.hitTarget_[tostring(var_0_1.ctx.battle.count)]

			if var_5_8 then
				for iter_5_4, iter_5_5 in ipairs(var_5_8) do
					for iter_5_6, iter_5_7 in ipairs(arg_5_0.sideTeam_) do
						local var_5_9 = var_0_2.split(iter_5_7.fighterIndex, "|")

						if tonumber(var_5_9[2]) == iter_5_5 then
							if not iter_5_7:isBreakImmortal() then
								iter_5_7:setBreakInterval()

								if not iter_5_7:isPause() and var_0_1.ctx.battle.isEnergySkilling then
									iter_5_7:getFighterModel():resume()
								end

								if not iter_5_7:isPause() then
									iter_5_7:attacked()
								end

								iter_5_7.fighterModel:playFloatText({
									var_0_2.BattleFloatType.BREAK
								}, iter_5_7:getTeamType())
							end

							break
						end
					end
				end
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			local var_6_2 = iter_6_1:getHp() / iter_6_1:getHpLimit()

			if not var_6_0 or var_6_2 < var_6_0 then
				var_6_1 = iter_6_1
				var_6_0 = var_6_2
			end
		end
	end

	return {
		var_6_1
	}
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	if arg_7_1:getSkillID() == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if arg_7_0.isPurpleStar_ then
			arg_7_1:setExtraTime(60)
		end

		arg_7_0.purpleCount_ = arg_7_1:getTime()
	end

	if arg_7_0.isBlueStar_ and arg_7_1:getSkillID() == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_7_1:setShieldNum(arg_7_1:getShieldNum() + 2)
	end
end

function var_0_3.setupReport(arg_8_0, arg_8_1)
	var_0_3.super.setupReport(arg_8_0, arg_8_1)

	arg_8_0.hitTarget_ = arg_8_1.hit_target
end

function var_0_3.writeReport(arg_9_0)
	local var_9_0 = var_0_3.super.writeReport(arg_9_0)

	var_9_0.hit_target = arg_9_0.records_.hit_target

	return var_9_0
end

function var_0_3.checkMove(arg_10_0)
	if arg_10_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_10_0.hero_:enterDuration() then
			arg_10_0.isWalking_ = 1

			if not arg_10_0:isWalking() then
				arg_10_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_10_0:isWalking() == 2 then
				local var_10_0 = arg_10_0:getFlipX() and -1 or 1

				arg_10_0:moveByX(arg_10_0.hero_:enterSpeed() * var_10_0)
			end

			if arg_10_0:getCurrentAnimation() ~= "run" then
				arg_10_0:modelWalk()
			end
		elseif not arg_10_0.playedEnterSkill_ then
			if arg_10_0:isWalking() ~= 3 then
				arg_10_0.preWalk_ = false
				arg_10_0.isWalking_ = false
				arg_10_0.behindWalk_ = false
				arg_10_0.playedEnterSkill_ = true
				arg_10_0.walk2Position_ = false

				if arg_10_0:getCurrentAnimation() == "run" then
					arg_10_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_10_0.hero_:enterDelayDuration() then
			arg_10_0.isEnterSkill_ = nil
			arg_10_0.walk2Position_ = false
			arg_10_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_10_0)
end

function var_0_3.setFormation(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	arg_11_0.isEnterSkill_ = arg_11_0:enterSkill() > 0 and arg_11_0:getSkillLevelByID(arg_11_0:enterSkill()) > 0

	if arg_11_0.isEnterSkill_ then
		arg_11_0.playedEnterSkill_ = false

		local var_11_0 = arg_11_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_11_0:x(var_11_0)
		arg_11_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_11_3 - 90 * (arg_11_2 % 2))

		return arg_11_2 + 1
	end

	return var_0_3.super.setFormation(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
end

function var_0_3.enterSkill(arg_12_0)
	return arg_12_0.hero_:enterSkill()
end

return var_0_3
