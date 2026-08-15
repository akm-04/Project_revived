local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Beimihu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.battleConfig
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_10 = 40011282
local var_0_11 = 40011283
local var_0_12 = 10001171
local var_0_13 = 10001166
local var_0_14 = 10001167
local var_0_15 = 20
local var_0_16 = 40011285
local var_0_17 = 60
local var_0_18 = "skeletons/beimihu/beimihu04huaban.plist"
local var_0_19 = 80010197
local var_0_20 = 40012358
local var_0_21 = 0.3

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.BlueStunBuff = 40012359
		arg_2_0.EnergyBuff = 40012360
		arg_2_0.BlueSkillID = 10002205
	else
		arg_2_0.BlueStunBuff = 40011282
		arg_2_0.EnergyBuff = 40011285
		arg_2_0.BlueSkillID = 30010197
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.energyCenterTarget = nil
	arg_3_0.backPosX = nil
	arg_3_0.backPosY = nil
	arg_3_0.backCount = nil
	arg_3_0.energyEffectTime_ = 0
	arg_3_0.energyEffect = nil
	arg_3_0.cureInfo = {}
	arg_3_0.buffMap = {}
end

function var_0_3.toDoPerFrames(arg_4_0)
	arg_4_0.energyEffectTime_ = arg_4_0.energyEffectTime_ - 1

	if arg_4_0.energyEffectTime_ <= 0 and var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		if arg_4_0.energyEffect and not tolua.isnull(arg_4_0.energyEffect) then
			arg_4_0.energyEffect:removeSelf()
		end

		arg_4_0.energyEffect = nil
	end

	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			if iter_4_1.target:isHasBuffByID(var_0_10) and iter_4_1:getType() == var_0_2.BuffType.REVIVIE then
				local var_4_0 = var_0_4.new({
					tableID = var_0_11,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByID(arg_4_0.BlueSkillID),
					skillID = arg_4_0.BlueSkillID,
					fighter = arg_4_0,
					target = iter_4_1.target,
					manualHarmRevise = iter_4_1:getHarm()
				})

				iter_4_1.target:removeBuffs(iter_4_1)
				iter_4_1.target:addBuffs({
					var_4_0
				})
			end

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and iter_4_1:getType() == var_0_2.BuffType.REVIVIE and not arg_4_0.buffMap[iter_4_1] then
				arg_4_0.buffMap[iter_4_1] = true

				if not arg_4_0.cureInfo[iter_4_1.fighter] then
					arg_4_0.cureInfo[iter_4_1.fighter] = iter_4_1:getHarm()
				else
					arg_4_0.cureInfo[iter_4_1.fighter] = arg_4_0.cureInfo[iter_4_1.fighter] + iter_4_1:getHarm()
				end
			end
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_2, iter_4_3 in ipairs(arg_4_0:getInfoByKey("unit_info")) do
			if iter_4_3.attackType == var_0_2.AttackType.CURE and iter_4_3.cure then
				if not arg_4_0.cureInfo[iter_4_3.fighter] then
					arg_4_0.cureInfo[iter_4_3.fighter] = iter_4_3.cure
				else
					arg_4_0.cureInfo[iter_4_3.fighter] = arg_4_0.cureInfo[iter_4_3.fighter] + iter_4_3.cure
				end
			end
		end
	end

	if arg_4_0.backCount then
		arg_4_0.backCount = arg_4_0.backCount - 1

		if arg_4_0.backCount <= 0 then
			if arg_4_0.backPosX and arg_4_0.backPosY and not var_0_1.ctx.battle.walk2NextBattle_ then
				arg_4_0:x(arg_4_0.backPosX)
				arg_4_0:y(arg_4_0.backPosY)
			end

			arg_4_0:setImmuneControl(false)

			arg_4_0.backCount = nil
			arg_4_0.backPosX = nil
			arg_4_0.backPosY = nil
			arg_4_0.energyCenterTarget = nil
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == var_0_12 and arg_5_1.harmTotal then
		var_5_2 = var_5_2 + arg_5_1.harmTotal
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_6_1.attackType == var_0_2.AttackType.CURE and arg_6_5 > 0 and arg_6_1.target:isHasBuffByID(var_0_10) then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_0 = arg_6_0:createAttackUnits({
				arg_6_1.target
			}, var_0_12)

			for iter_6_0, iter_6_1 in ipairs(var_6_0) do
				iter_6_1.harmTotal = arg_6_5

				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end

		arg_6_5 = 0
	end

	if arg_6_1.target:isHasBuffByID(var_0_16) then
		arg_6_2 = false
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)

	if arg_7_1.rootID_ == var_0_13 then
		arg_7_0:setImmuneControl(true)
	elseif arg_7_1.rootID_ == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_7_0.energyEffectTime_ = var_0_17

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			arg_7_0.energyEffect = cc.ParticleSystemQuad:create(var_0_18)

			arg_7_0.energyEffect:addTo(var_0_1.ctx.battle.unitLayer)
			arg_7_0.energyEffect:setPosition(var_0_2.STAGE_WIDTH / 2 + 300, var_0_2.STAGE_HEIGHT / 2)
		end
	end
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_1.skillID == var_0_13 then
		local var_8_0 = arg_8_1.target:getX()
		local var_8_1 = arg_8_1.target:getY()
		local var_8_2

		if arg_8_0:getTeamType() == var_0_2.TeamType.A then
			var_8_2 = -1

			arg_8_0:flipX(false)
		else
			var_8_2 = 1

			arg_8_0:flipX(true)
		end

		arg_8_0.backPosX = arg_8_0:getX()
		arg_8_0.backPosY = arg_8_0:getY()

		arg_8_0:x(var_8_0 + (100 + var_0_6:scope(arg_8_1.skillID) * 0.5) * var_8_2)
		arg_8_0:y(var_8_1 + 50)
	elseif arg_8_1.skillID == var_0_14 then
		arg_8_0.backCount = var_0_15
	end

	if arg_8_0.skinSkillIndex_ == 1 and var_0_2.tables.skill:type(arg_8_1.skillID) ~= var_0_2.AttackType.None and var_0_2.tables.skill:skillType(arg_8_1.skillID) ~= var_0_2.SkillType.PU_GONG and (arg_8_1.skillID == arg_8_0.BlueSkillID or arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) or arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_3 = var_0_9.A4(arg_8_0, var_0_19)
		local var_8_4 = arg_8_0:createAttackUnits(var_8_3, var_0_19)

		for iter_8_0, iter_8_1 in ipairs(var_8_4) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0)
	local var_9_0 = {}
	local var_9_1 = -1
	local var_9_2
	local var_9_3 = -1
	local var_9_4

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and (not var_9_2 or var_9_1 < (arg_9_0.cureInfo[iter_9_1] or 0)) then
			var_9_2 = iter_9_1
			var_9_1 = arg_9_0.cureInfo[iter_9_1] or 0
		end
	end

	if var_9_2 then
		for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_3:isDeath() and not iter_9_3:isAffected() then
				if not var_9_4 or var_9_3 < (arg_9_0.cureInfo[iter_9_3] or 0) then
					var_9_4 = iter_9_3
					var_9_3 = arg_9_0.cureInfo[iter_9_3] or 0
				end

				if var_9_1 < (arg_9_0.cureInfo[iter_9_3] or 0) then
					table.insert(var_9_0, iter_9_3)
				end
			end
		end
	end

	if not next(var_9_0) and var_9_4 then
		table.insert(var_9_0, var_9_4)
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeD2(arg_10_0)
	local function var_10_0(arg_11_0, arg_11_1)
		local var_11_0 = {}

		table.insert(var_11_0, arg_11_0)

		for iter_11_0, iter_11_1 in ipairs(arg_10_0.sideTeam_) do
			if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1 ~= arg_11_0 and arg_11_1 >= math.abs(iter_11_1:getX() - arg_11_0:getX()) then
				table.insert(var_11_0, iter_11_1)
			end
		end

		return var_11_0
	end

	local var_10_1
	local var_10_2 = 0
	local var_10_3 = var_0_6:scope(var_0_13) * 0.5

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
			local var_10_4 = var_10_0(iter_10_1, var_10_3)

			if not var_10_1 or var_10_2 < #var_10_4 then
				var_10_1 = iter_10_1
				var_10_2 = #var_10_4
			end
		end
	end

	arg_10_0.energyCenterTarget = var_10_1

	return {
		var_10_1
	}
end

function var_0_3.selectTargetByTypeD3(arg_12_0)
	local function var_12_0(arg_13_0, arg_13_1)
		local var_13_0 = {}

		table.insert(var_13_0, arg_13_0)

		for iter_13_0, iter_13_1 in ipairs(arg_12_0.sideTeam_) do
			if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1 ~= arg_13_0 and arg_13_1 >= math.abs(iter_13_1:getX() - arg_13_0:getX()) then
				table.insert(var_13_0, iter_13_1)
			end
		end

		return var_13_0
	end

	local var_12_1 = {}
	local var_12_2 = var_0_6:scope(var_0_13) * 0.5

	if arg_12_0.energyCenterTarget then
		var_12_1 = var_12_0(arg_12_0.energyCenterTarget, var_12_2)
	end

	return var_12_1
end

function var_0_3.buffAddAction(arg_14_0, arg_14_1)
	var_0_3.super.buffAddAction(arg_14_0, arg_14_1)

	if arg_14_0.skinSkillIndex_ == 1 and arg_14_1.tableID_ == var_0_20 then
		arg_14_1.manualHarmRevise = arg_14_0:getHpLimit() * var_0_21
	end
end

return var_0_3
