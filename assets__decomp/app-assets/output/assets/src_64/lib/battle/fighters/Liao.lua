local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 320
local var_0_7 = 0.5
local var_0_8 = 40010394
local var_0_9 = 40010423

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyTargets_ = {}
	arg_2_0.energyCount_ = 0
	arg_2_0.records_.hit_target = {}
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.energyTargets_[arg_3_1.target] = true
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_3_0.isStarBlue_ then
		local var_3_0 = var_0_4.new({
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_1.skillID),
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

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.energyTargets_ = {}
		arg_4_0.energyCount_ = var_0_6
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0.energyCount_ > 0 then
		arg_5_0.energyCount_ = arg_5_0.energyCount_ - 1

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("attack_info")) do
				local var_5_0 = iter_5_1.fighter_

				if arg_5_0.energyTargets_[var_5_0] and var_0_5:type(iter_5_1.rootID_) == var_0_2.AttackType.AD then
					if var_5_0:isHasBuffByID(var_0_8) and not var_5_0:isDeath() then
						local var_5_1 = var_0_7

						if arg_5_0.isStarEnergy_ then
							var_5_1 = var_5_1 + 0.1
						end

						if var_0_2.weightedChoise({
							var_5_1,
							1 - var_5_1
						}) == 1 then
							local var_5_2 = var_0_2.split(var_5_0.fighterIndex, "|")
							local var_5_3 = tonumber(var_5_2[2])

							if not arg_5_0.records_.hit_target[tostring(var_0_1.ctx.battle.count)] then
								arg_5_0.records_.hit_target[tostring(var_0_1.ctx.battle.count)] = {
									var_5_3
								}
							else
								table.insert(arg_5_0.records_.hit_target[tostring(var_0_1.ctx.battle.count)], var_5_3)
							end

							if not var_5_0:isAdBreakImmortal() and not var_5_0:isBreakImmortal() then
								var_5_0:setBreakInterval()

								if not var_5_0:isPause() and var_0_1.ctx.battle.isEnergySkilling then
									var_5_0:getFighterModel():resume()
								end

								if not var_5_0:isPause() then
									var_5_0:attacked()
								end

								if var_5_0:isCreatingUnits() then
									var_5_0.fighterModel:playFloatText({
										var_0_2.BattleFloatType.BREAK
									}, var_5_0:getTeamType())
									var_5_0:skillIsBreak()
								end
							end
						end
					else
						arg_5_0.energyTargets_[var_5_0] = false
					end
				end
			end
		else
			local var_5_4 = arg_5_0.hitTarget_[tostring(var_0_1.ctx.battle.count)]

			if var_5_4 then
				for iter_5_2, iter_5_3 in ipairs(var_5_4) do
					for iter_5_4, iter_5_5 in ipairs(arg_5_0.sideTeam_) do
						local var_5_5 = var_0_2.split(iter_5_5.fighterIndex, "|")

						if tonumber(var_5_5[2]) == iter_5_3 then
							if not iter_5_5:isAdBreakImmortal() and not iter_5_5:isBreakImmortal() then
								iter_5_5:setBreakInterval()

								if not iter_5_5:isPause() and var_0_1.ctx.battle.isEnergySkilling then
									iter_5_5:getFighterModel():resume()
								end

								if not iter_5_5:isPause() then
									iter_5_5:attacked()
								end

								iter_5_5.fighterModel:playFloatText({
									var_0_2.BattleFloatType.BREAK
								}, iter_5_5:getTeamType())
							end

							break
						end
					end
				end
			end
		end
	end
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.hitTarget_ = arg_6_1.hit_target
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.hit_target = arg_7_0.records_.hit_target

	return var_7_0
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1:getSkillID() == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_8_0.isStarPurple_ then
		arg_8_1:setShieldNum(5)
	end
end

return var_0_3
