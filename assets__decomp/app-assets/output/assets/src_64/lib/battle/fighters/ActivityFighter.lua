local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ActivityFighter", var_0_0.import("lib.battle.BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("MoveUnit")
local var_0_7 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_8 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_9 = var_0_1.ctx.battle.getRequire("FighterModel")
local var_0_10 = var_0_1.ctx.battle.getRequire("SpineEffect")
local var_0_11 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_12 = var_0_2.tables.skill
local var_0_13 = var_0_2.tables.hero
local var_0_14 = var_0_2.tables.model
local var_0_15 = var_0_2.tables.dbuff
local var_0_16 = var_0_2.tables.skinSkill
local var_0_17 = var_0_2.tables.objectBook
local var_0_18 = var_0_2.tables.battleConfig
local var_0_19 = 180
local var_0_20 = 90
local var_0_21 = math.min
local var_0_22 = math.max
local var_0_23 = math.abs
local var_0_24 = math.floor
local var_0_25 = math.ceil
local var_0_26 = math.sqrt

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.isMainRole_ = false
end

function var_0_3.setIsMainRole(arg_2_0, arg_2_1)
	arg_2_0.isMainRole_ = arg_2_1
end

function var_0_3.isMainRole(arg_3_0)
	return arg_3_0.isMainRole_
end

function var_0_3.setAvatar(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	if not arg_4_1 then
		return
	end

	arg_4_0.avatar_ = arg_4_1
	arg_4_0.hpBar_ = arg_4_2
	arg_4_0.mpBar_ = arg_4_3

	arg_4_0:updateHpBar(true)

	arg_4_0.avatarIndex_ = arg_4_4
end

function var_0_3.updateHpBar(arg_5_0, arg_5_1)
	if arg_5_0.hpBar_ and arg_5_0.avatarIndex_ then
		arg_5_0.bottomWnd:setHPProgress(arg_5_0:getHp() / arg_5_0:getHpLimit(), arg_5_0.avatarIndex_, arg_5_1)
	end

	local var_5_0 = arg_5_0:getHp() / arg_5_0:getHpLimit()

	arg_5_0.fighterModel:setHPProgress(var_5_0, arg_5_1, nil, var_0_1.ctx.battle.count)
	arg_5_0.fighterModel:updateHeroHeaderView(var_0_1.ctx.battle.count, arg_5_0.showDHarmbuff_)
end

function var_0_3.updateEnergyBar(arg_6_0, arg_6_1)
	if arg_6_0.mpBar_ then
		if arg_6_0.avatarIndex_ then
			arg_6_0.bottomWnd:setMPProgress(arg_6_0.energy_ / var_0_2.ENERGY_DECIMAL_BASE, arg_6_0.avatarIndex_, arg_6_1)
		else
			arg_6_0.bottomWnd:setPetMPProgress(arg_6_0.energy_ / var_0_2.ENERGY_DECIMAL_BASE, false)
		end
	end
end

function var_0_3.checkMove(arg_7_0)
	if var_0_1.ctx.battle.isEnergySkilling or arg_7_0:isDeath() or arg_7_0.isEscapeEnemyMove then
		return
	end

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		if arg_7_0.reportMoveX_[tostring(var_0_1.ctx.battle.count)] then
			arg_7_0:flipX(arg_7_0.reportMoveX_[tostring(var_0_1.ctx.battle.count)] < arg_7_0:getX())
			arg_7_0:x(arg_7_0.reportMoveX_[tostring(var_0_1.ctx.battle.count)])
		end

		if arg_7_0.reportWalkState_[tostring(var_0_1.ctx.battle.count)] and arg_7_0.reportWalkState_[tostring(var_0_1.ctx.battle.count)] < 3 and not arg_7_0:isWalkAnimation() then
			arg_7_0:modelWalk()
		elseif not arg_7_0.reportWalkState_[tostring(var_0_1.ctx.battle.count)] and arg_7_0:isWalkAnimation() then
			arg_7_0:resumeIdle()
		end
	elseif var_0_1.ctx.battle.walk2NextBattle_ and arg_7_0:getTeamType() == var_0_2.TeamType.A then
		arg_7_0.isWalking_ = 1
		arg_7_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		arg_7_0:flipX(false)

		if not arg_7_0:isWalking() then
			arg_7_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_7_0:isWalking() == 2 then
			arg_7_0:moveByX(arg_7_0:getCurrentSpeed() * var_0_2.tables.battleConfig.speedAccelerate)
		end

		if not arg_7_0:isWalkAnimation() then
			arg_7_0:modelWalk()
		end
	elseif arg_7_0:isMoveUnable() or arg_7_0:isInSkillRoll() or arg_7_0.manualDirection_ then
		if arg_7_0:isWalkAnimation() then
			arg_7_0:resumeIdle()
		end

		arg_7_0.walk2Position_ = false
		arg_7_0.preWalk_ = false
		arg_7_0.isWalking_ = false
		arg_7_0.behindWalk_ = false
	elseif arg_7_0.walk2Position_ then
		if arg_7_0:isWalked2Position() then
			arg_7_0.walk2Position_ = false

			if arg_7_0:isTargetBeyondReach() then
				arg_7_0.isWalking_ = 1
			else
				arg_7_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk
			end
		else
			arg_7_0.isWalking_ = 1

			if not arg_7_0:isWalking() then
				arg_7_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_7_0:isWalking() == 2 then
				local var_7_0 = arg_7_0:getFlipX() and -1 or 1

				arg_7_0:moveByX(arg_7_0:getCurrentSpeed() * var_7_0)
			end

			if not arg_7_0:isWalkAnimation() then
				arg_7_0:modelWalk()
			end
		end

		arg_7_0:writeWalkState()
	elseif arg_7_0:isFear() and arg_7_0:isMainRole() then
		arg_7_0.walk2Position_ = false
		arg_7_0.isWalking_ = 1
		arg_7_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		local var_7_1 = arg_7_0:getTeamType() == var_0_2.TeamType.A and -1 or 1

		if arg_7_0.fearMoveDir_ then
			var_7_1 = -var_7_1
		end

		arg_7_0:flipX(var_7_1 < 0)

		local var_7_2 = arg_7_0:getCurrentSpeed() * var_7_1

		if arg_7_0:getX() + var_7_2 < arg_7_0:getFighterModel():getWidth() / 2 and var_7_2 < 0 then
			var_7_2 = arg_7_0:getFighterModel():getWidth() / 2 - arg_7_0:getX()
		end

		if not var_0_1.ctx.battle.isUnlimitBattle then
			if arg_7_0:getX() + var_7_2 > var_0_2.STAGE_WIDTH - arg_7_0:getFighterModel():getWidth() / 2 and var_7_2 > 0 then
				var_7_2 = var_0_2.STAGE_WIDTH - arg_7_0:getFighterModel():getWidth() / 2 - arg_7_0:getX()
			end
		elseif arg_7_0:getX() + var_7_2 > var_0_2.UNLIMIT_STAGE_WIDTH - arg_7_0:getFighterModel():getWidth() / 2 and var_7_2 > 0 then
			var_7_2 = var_0_2.UNLIMIT_STAGE_WIDTH - arg_7_0:getFighterModel():getWidth() / 2 - arg_7_0:getX()
		end

		if not arg_7_0:isWalking() then
			arg_7_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_7_0:isWalking() == 2 then
			arg_7_0:moveByX(var_7_2)
		end

		if not arg_7_0:isWalkAnimation() then
			arg_7_0:modelWalk()
		end

		arg_7_0:writeWalkState()
	elseif arg_7_0:isTargetBeyondReach() then
		arg_7_0.isWalking_ = 1
		arg_7_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		local var_7_3 = arg_7_0:getNearestTarget():getX() > arg_7_0:getX() and 1 or -1

		arg_7_0:flipX(var_7_3 < 0)

		if not arg_7_0:isWalking() then
			arg_7_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_7_0:isWalking() == 2 then
			arg_7_0:moveByX(arg_7_0:getCurrentSpeed() * var_7_3)
		end

		if not arg_7_0:isWalkAnimation() then
			arg_7_0:modelWalk()
		end

		arg_7_0:writeWalkState()
	elseif arg_7_0:isWalking() ~= 3 then
		arg_7_0.preWalk_ = false
		arg_7_0.isWalking_ = false
		arg_7_0.behindWalk_ = false

		if arg_7_0:isWalkAnimation() then
			arg_7_0:resumeIdle()
		end
	else
		arg_7_0:writeWalkState()
	end
end

function var_0_3.checkEnergySkill(arg_8_0)
	if not arg_8_0:isMainRole() then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_8_0)
end

function var_0_3.skillQueueTest(arg_9_0)
	local var_9_0 = true

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.skillQueue_) do
		if arg_9_0:getSkillLevelByID(iter_9_1) > 0 and var_0_12:snowmanUsable(iter_9_1) > 0 then
			var_9_0 = false

			break
		end
	end

	if var_9_0 then
		arg_9_0.invalidSkillQueue_ = true
	end
end

function var_0_3.popColorSkill(arg_10_0)
	if next(arg_10_0.startSkillQueue_) ~= nil then
		local var_10_0 = arg_10_0.startSkillQueue_[1]

		if arg_10_0:getSkillLevelByID(var_10_0) <= 0 or var_0_12:snowmanUsable(var_10_0) <= 0 then
			table.remove(arg_10_0.startSkillQueue_, 1)
			arg_10_0:popColorSkill()
		end
	elseif arg_10_0.invalidSkillQueue_ then
		return arg_10_0:getOrbOfFrontSkill()
	else
		local var_10_1 = arg_10_0.skillQueue_[1]

		if arg_10_0:getTableID() == 10001008 or arg_10_0:getTableID() == 11001008 then
			dump("skillID---" .. var_10_1)
			dump(var_0_12:snowmanUsable(var_10_1))
		end

		if arg_10_0:getSkillLevelByID(var_10_1) <= 0 or var_0_12:snowmanUsable(var_10_1) <= 0 then
			table.remove(arg_10_0.skillQueue_, 1)
			table.insert(arg_10_0.skillQueue_, var_10_1)
			arg_10_0:popColorSkill()
		end
	end

	return arg_10_0:getOrbOfFrontSkill()
end

function var_0_3.getSkillLevelByID(arg_11_0, arg_11_1)
	if not arg_11_0:isMainRole() and var_0_12:snowmanUsable(arg_11_1) <= 0 then
		return 0
	end

	local var_11_0 = var_0_12:father(arg_11_1)

	if var_11_0 == arg_11_0.specialAttackSkillID_ then
		return arg_11_0.specialAttackSkillLevel_
	end

	local var_11_1 = arg_11_0.skillLevelByID_[var_11_0]

	if var_11_1 and var_11_1 > 0 then
		for iter_11_0, iter_11_1 in ipairs(arg_11_0.skillDownBuff_) do
			var_11_1 = math.max(1, var_11_1 - math.ceil(iter_11_1:getLevel() / var_0_15:skillDownReq(iter_11_1:getTableID())))
		end
	end

	return var_11_1 or 0
end

function var_0_3.getSkillLevelByColor(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.hero_:getSkillId(arg_12_1)

	if not var_12_0 or not arg_12_0:isMainRole() and var_0_12:snowmanUsable(var_12_0) <= 0 then
		return 0
	end

	local var_12_1 = arg_12_0.skillLevelByColor_[arg_12_1]

	if var_12_1 and var_12_1 > 0 then
		for iter_12_0, iter_12_1 in ipairs(arg_12_0.skillDownBuff_) do
			var_12_1 = math.max(1, var_12_1 - math.ceil(iter_12_1:getLevel() / var_0_15:skillDownReq(iter_12_1:getTableID())))
		end
	end

	return var_12_1 or 0
end

function var_0_3.isTargetBeyondReach(arg_13_0)
	if arg_13_0:isMainRole() then
		return var_0_3.super.isTargetBeyondReach(arg_13_0)
	end

	return false
end

function var_0_3.isAffected(arg_14_0)
	if not arg_14_0:isMainRole() then
		return true
	end

	return var_0_3.super.isAffected(arg_14_0)
end

function var_0_3.getUnitData(arg_15_0, arg_15_1)
	local var_15_0
	local var_15_1
	local var_15_2
	local var_15_3
	local var_15_4
	local var_15_5

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = unpack(arg_15_1.reportData_.calculate[tostring(var_0_1.ctx.battle.count)])
	else
		var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = arg_15_0:calculateUnitData(arg_15_1)
		var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = arg_15_1.target:updateUnitDataByTarget(arg_15_1, var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5)
		var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = arg_15_0:updateUnitDataByFighter(arg_15_1, var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5)

		for iter_15_0, iter_15_1 in ipairs(arg_15_0.selfTeam_) do
			if not iter_15_1:isDeath() then
				var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = iter_15_1:updateUnitDataBySpecialHero(arg_15_1, var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5)
			end
		end

		for iter_15_2, iter_15_3 in ipairs(arg_15_0.sideTeam_) do
			if not iter_15_3:isDeath() then
				var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = iter_15_3:updateUnitDataBySpecialHero(arg_15_1, var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5)
			end
		end

		if not arg_15_0:isMainRole() then
			var_15_3 = 0
		end

		arg_15_1:recordData(var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5)
	end

	local var_15_6 = arg_15_0:checkHarmValid(var_15_2)

	return var_15_0, var_15_1, var_15_6, var_15_3, var_15_4, var_15_5
end

function var_0_3.updateUnitDataByTarget(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
	local var_16_0, var_16_1, var_16_2, var_16_3, var_16_4, var_16_5 = var_0_3.super.updateUnitDataByTarget(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)

	if var_16_2 > 0 and not arg_16_1.fighter:isMainRole() then
		var_16_2 = 0
	end

	return var_16_0, var_16_1, var_16_2, var_16_3, var_16_4, var_16_5
end

function var_0_3.updateUnitDataByFighter(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7)
	local var_17_0, var_17_1, var_17_2, var_17_3, var_17_4, var_17_5 = var_0_3.super.updateUnitDataByFighter(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7)

	if var_17_2 > 0 and not arg_17_1.fighter:isMainRole() then
		var_17_2 = 0
	end

	return var_17_0, var_17_1, var_17_2, var_17_3, var_17_4, var_17_5
end

function var_0_3.applyBuffHarm(arg_18_0)
	local var_18_0 = 0
	local var_18_1 = 0
	local var_18_2 = 0
	local var_18_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_18_0, var_18_1, var_18_2 = unpack(arg_18_0.reportBuffHarms_[tostring(var_0_1.ctx.battle.count)] or {
			0,
			0,
			0
		})
	else
		local function var_18_4(arg_19_0)
			for iter_19_0 = #arg_19_0, 1, -1 do
				local var_19_0 = arg_19_0[iter_19_0]

				if var_19_0:getType() == var_0_2.BuffType.CONTINUE_HARM and not arg_18_0:isImmortal() then
					local var_19_1 = var_19_0:getHarm() * var_19_0.fighter:getBuffHarmRate()

					var_18_0 = var_18_0 + var_19_1
					var_18_3 = var_19_0.fighter

					if var_19_0:getHarm() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						var_18_3:updateHarms(var_19_1)
					end

					var_18_2 = var_18_2 + var_19_0:getMana()
				elseif (var_19_0:getType() == var_0_2.BuffType.GAIN or var_19_0:getType() == var_0_2.BuffType.REVIVIE) and var_19_0.fighter:isMainRole() then
					var_18_1 = var_18_1 + var_19_0:getHarm()
				end
			end
		end

		var_18_4(arg_18_0.buffs_)
		var_18_4(arg_18_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB)

		var_18_1 = var_18_1 * arg_18_0:getDCureRate()

		if var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD and arg_18_0:getTeamType() == var_0_2.TeamType.B then
			var_18_1 = 0
		end

		arg_18_0.records_.buff_harms[tostring(var_0_1.ctx.battle.count)] = {
			var_18_0,
			var_18_1,
			var_18_2
		}
	end

	if var_18_1 == 0 and var_18_0 == 0 and var_18_2 == 0 then
		return
	end

	local var_18_5 = var_0_22(0, arg_18_0:getHp() - var_18_0 + var_18_1)

	if var_18_1 - var_18_0 > 0 then
		var_18_5 = var_0_21(arg_18_0:getHp() - var_18_0 + var_18_1, arg_18_0:getHpLimit())
	end

	if var_18_1 ~= 0 then
		arg_18_0.cureHp = arg_18_0.cureHp + var_18_1
	end

	if var_18_0 - var_18_1 > 0 and next(arg_18_0.shieldBuffs_) then
		local var_18_6 = arg_18_0.shieldBuffs_[1]
		local var_18_7 = arg_18_0.shieldBuffs_[1].fighter
		local var_18_8 = var_18_6:getShieldNum() - 1

		if var_18_0 - var_18_1 > var_18_6:getShieldMaxHarm() then
			var_18_5 = var_0_22(0, arg_18_0:getHp() - var_18_0 + var_18_1 + var_18_6:getShieldMaxHarm())

			arg_18_0:updateHp(var_18_5)
		end

		if var_18_8 <= 0 then
			arg_18_0:removeBuffByID(var_18_6:getTableID())
		else
			var_18_6:setShieldNum(var_18_8)
		end

		var_18_7:shieldFeedBack(arg_18_0)
	else
		arg_18_0:updateHp(var_18_5)
	end

	arg_18_0:updateEnergyTo(arg_18_0:getEnergy() + var_18_2)
	arg_18_0:setOriHurt(var_18_0)

	return var_18_3
end

function var_0_3.canAttack(arg_20_0)
	if arg_20_0:isDeath() then
		return false
	end

	if arg_20_0:getLeftInterval() > 0 then
		return false
	end

	if arg_20_0:isBattleUnable() then
		return false
	end

	if arg_20_0.isEnergySkill_ and arg_20_0:isCreatingUnits() then
		return false
	end

	if arg_20_0.isEnergySkill_ then
		return true
	end

	if arg_20_0.invalidSkillQueue_ and not next(arg_20_0.startSkillQueue_) then
		return false
	end

	if arg_20_0:isCreatingUnits() then
		return false
	end

	if arg_20_0:isInSkillRoll() then
		return false
	end

	if arg_20_0:isWalking() or arg_20_0:isAdjustY() or var_0_1.ctx.battle.isEnergySkilling then
		return false
	end

	if not arg_20_0:getNearestTarget() then
		return false
	end

	if arg_20_0:isTargetBeyondReach() then
		return false
	end

	return true
end

function var_0_3.fliterBuffs(arg_21_0, arg_21_1)
	var_0_3.super.fliterBuffs(arg_21_0, arg_21_1)

	for iter_21_0 = #arg_21_1, 1, -1 do
		local var_21_0 = arg_21_1[iter_21_0]

		if not var_21_0.fighter:isMainRole() and var_21_0.fighter:getTeamType() ~= arg_21_0:getTeamType() then
			table.remove(arg_21_1, iter_21_0)
		end
	end
end

function var_0_3.applyHurtFighter(arg_22_0, arg_22_1, arg_22_2, arg_22_3, arg_22_4, arg_22_5)
	if not arg_22_1.fighter:isMainRole() and arg_22_1.fighter:getTeamType() ~= arg_22_0:getTeamType() then
		return 0, 0, false, true
	end

	if var_0_1.ctx.battle.infoListener.harm_info then
		local var_22_0 = {
			harm = arg_22_2,
			target = arg_22_1.target,
			fighter = arg_22_1.fighter,
			type = arg_22_1.attackType
		}

		table.insert(var_0_1.ctx.battle.infoListener.harm_info, var_22_0)
	end

	arg_22_2 = arg_22_2 > 0 and var_0_22(arg_22_2, 1) or 0

	if arg_22_0:isHurtBreak(arg_22_2, arg_22_1) and not arg_22_0:isAdBreakImmortal() and not arg_22_0:isBreakImmortal() then
		arg_22_0:setBreakInterval()

		if not arg_22_0:isPause() and arg_22_2 > 0 and var_0_1.ctx.battle.isEnergySkilling then
			arg_22_0:getFighterModel():resume()
		end

		if not arg_22_0:isPause() then
			arg_22_0:attacked()
		end

		if arg_22_0:isCreatingUnits() then
			arg_22_0.fighterModel:playFloatText({
				var_0_2.BattleFloatType.BREAK
			}, arg_22_0:getTeamType())
			arg_22_0:skillIsBreak(arg_22_1)
		end
	end

	local var_22_1 = arg_22_2 - arg_22_0:getHp()
	local var_22_2 = var_0_22(0, arg_22_0:getHp() - arg_22_2)
	local var_22_3 = arg_22_0:getHp()
	local var_22_4 = arg_22_2

	if var_22_1 > 0 then
		var_22_2 = arg_22_0:getLastDHarmBuff(var_22_1, arg_22_1.attackType) > 0 and 0 or 1
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if next(arg_22_0.shieldBuffs_) and (not arg_22_1.fighter or not arg_22_1.fighter:isIgnoreShield()) then
			local var_22_5 = arg_22_0.shieldBuffs_[1]
			local var_22_6 = arg_22_0.shieldBuffs_[1].fighter
			local var_22_7 = var_22_5:getShieldNum() - 1

			if arg_22_2 > var_22_5:getShieldMaxHarm() then
				arg_22_2 = arg_22_2 - var_22_5:getShieldMaxHarm()
			else
				arg_22_2 = 0
			end

			if var_22_7 <= 0 then
				arg_22_0:removeBuffByID(var_22_5:getTableID())
			else
				var_22_5:setShieldNum(var_22_7)
			end

			var_22_6:shieldFeedBack(arg_22_0)
		end

		arg_22_0:updateHp(arg_22_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][1])
		arg_22_0:updateEnergyTo(arg_22_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][2])

		if arg_22_0:isPossessed() then
			arg_22_0:updateEnergyByHarm(arg_22_2)
		end
	else
		if next(arg_22_0.shieldBuffs_) and (not arg_22_1.fighter or not arg_22_1.fighter:isIgnoreShield()) then
			local var_22_8 = arg_22_0.shieldBuffs_[1]
			local var_22_9 = arg_22_0.shieldBuffs_[1].fighter
			local var_22_10 = var_22_8:getShieldNum() - 1

			if arg_22_2 > var_22_8:getShieldMaxHarm() then
				var_22_2 = var_0_22(0, arg_22_0:getHp() - arg_22_2 + var_22_8:getShieldMaxHarm())

				arg_22_0:updateHp(var_22_2)

				arg_22_2 = arg_22_2 - var_22_8:getShieldMaxHarm()
				var_22_4 = arg_22_2
			else
				arg_22_2 = 0
			end

			if var_22_10 <= 0 then
				arg_22_0:removeBuffByID(var_22_8:getTableID())
			else
				var_22_8:setShieldNum(var_22_10)
			end

			var_22_9:shieldFeedBack(arg_22_0)
		else
			arg_22_0:updateHp(var_22_2)
		end

		arg_22_0:updateEnergyByHarm(arg_22_2)
	end

	arg_22_0:hurtSkillEffect(arg_22_1)

	if arg_22_2 > 0 then
		local var_22_11 = var_0_22(1, var_22_4)

		arg_22_0.fighterModel:playHPDeltas({
			{
				-var_22_11,
				arg_22_4
			}
		}, nil)
	end

	arg_22_1:recordTargetState("after")

	if arg_22_0:isDeath() then
		arg_22_1.target.killer_ = arg_22_1.fighter

		arg_22_0:die()
	end

	arg_22_0:hurtTrueHarm(arg_22_1, arg_22_2)

	arg_22_2 = var_0_21(arg_22_2, var_22_3)

	return arg_22_2, arg_22_3, arg_22_4, arg_22_5
end

function var_0_3.setGlobalBuffs(arg_23_0)
	local function var_23_0(arg_24_0, arg_24_1, arg_24_2)
		local var_24_0 = {}

		for iter_24_0, iter_24_1 in ipairs(arg_24_0) do
			local var_24_1 = var_0_4.new({
				tableID = iter_24_1,
				start = var_0_1.ctx.battle.count,
				level = arg_24_2,
				skillID = arg_24_1,
				fighter = arg_23_0
			})

			var_24_1:setYongJiu()
			table.insert(var_24_0, var_24_1)
		end

		return var_24_0
	end

	local var_23_1 = arg_23_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB

	if arg_23_0:getTeamType() ~= var_0_2.TeamType.A or not var_0_1.ctx.battle.globalBuffsB then
		local var_23_2 = var_0_1.ctx.battle.globalBuffsA
	end

	local var_23_3 = arg_23_0:buffSkill()

	for iter_23_0, iter_23_1 in pairs(var_23_3) do
		if arg_23_0:getSkillLevelByID(iter_23_1) > 0 then
			local var_23_4 = var_0_12:skillType(iter_23_1)
			local var_23_5 = var_23_0(var_0_12:buffs(iter_23_1), iter_23_1, arg_23_0:getSkillLevelByID(iter_23_1))

			if var_23_4 == var_0_2.SkillType.BUFF_ALL then
				for iter_23_2, iter_23_3 in ipairs(var_23_5) do
					table.insert(var_0_1.ctx.battle.globalBuffs, iter_23_3)
					var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, iter_23_3:getAttrType())
					var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, iter_23_3:getAttrType())
				end
			elseif var_23_4 == var_0_2.SkillType.BUFF_ENEMY then
				-- block empty
			elseif var_23_4 == var_0_2.SkillType.BUFF_FRIEND then
				for iter_23_4, iter_23_5 in ipairs(var_23_5) do
					var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, iter_23_5:getAttrType())
					table.insert(var_23_1, iter_23_5)
				end
			elseif var_23_4 == var_0_2.SkillType.SELF_FUNCTION_BUFF then
				for iter_23_6, iter_23_7 in ipairs(var_23_5) do
					iter_23_7.target = arg_23_0
				end

				arg_23_0:addBuffs(var_23_5)
			end
		end
	end
end

function var_0_3.writeReport(arg_25_0)
	local var_25_0 = var_0_3.super.writeReport(arg_25_0)

	var_25_0.is_main_role = arg_25_0:isMainRole() and 1 or 0

	return var_25_0
end

function var_0_3.getInterval(arg_26_0)
	if arg_26_0:isMainRole() then
		return var_0_13:interval(arg_26_0:getTableID())
	end

	return var_0_18.activityArenaPartnerInterval
end

function var_0_3.energyAction(arg_27_0, arg_27_1)
	if var_0_12:father(arg_27_1) == arg_27_0:getEnergySkillID() then
		arg_27_0:getFighterModel():playEnergyEffect_()
		arg_27_0:updateEnergyTo(arg_27_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		if arg_27_0:isMainRole() then
			arg_27_0:addBlackLayer()
		end
	end
end

return var_0_3
