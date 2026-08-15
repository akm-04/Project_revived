local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Aoding", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 10002125
local var_0_9 = {
	40012258,
	40012259
}
local var_0_10 = 180
local var_0_11 = 0.1
local var_0_12 = 0.003
local var_0_13 = var_0_2.STAGE_WIDTH
local var_0_14 = 40
local var_0_15 = 30
local var_0_16 = 10002368
local var_0_17 = 10002369
local var_0_18 = {
	AddBuff = 2,
	Collect = 1,
	Stop = 3
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.BlueChildSkillID = 10002370
		arg_2_0.GreenSkillID = 10002371
		arg_2_0.BlueSkillID = 10002372
		arg_2_0.EnergySkillID = 10002373
		arg_2_0.BlueADImmortalBuff = 40012586
		arg_2_0.BlueAPImmortalBuff = 40012587
		arg_2_0.PurpleShieldBuff = 40012588
	else
		arg_2_0.BlueChildSkillID = 10002124
		arg_2_0.GreenSkillID = 20020258
		arg_2_0.BlueSkillID = 30010258
		arg_2_0.EnergySkillID = 50010258
		arg_2_0.BlueADImmortalBuff = 40012260
		arg_2_0.BlueAPImmortalBuff = 40012261
		arg_2_0.PurpleShieldBuff = 40012262
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.selfHarm_ = {}
	arg_3_0.blueEffect = nil
	arg_3_0.blueCollectHarmTag = var_0_18.Stop
	arg_3_0.blueADHarm = 0
	arg_3_0.blueAPHarm = 0
	arg_3_0.purpleHarm = 0
	arg_3_0.energyTarget = nil
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0.BlueSkillID then
		arg_4_0.blueADHarm = 0
		arg_4_0.blueAPHarm = 0
		arg_4_0.blueCollectHarmTag = var_0_18.Collect
	end

	if arg_4_1.rootID_ == arg_4_0:getPugongID() or arg_4_1.rootID_ == arg_4_0.GreenSkillID or arg_4_1.rootID_ == arg_4_0.BlueSkillID or arg_4_1.rootID_ == arg_4_0.EnergySkillID then
		arg_4_0:updateEnergyBy(var_0_15)
	end
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5 = var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)

	local var_5_0 = arg_5_1.fighter

	if var_5_0:getTeamType() ~= arg_5_0:getTeamType() then
		if not arg_5_0.selfHarm_[var_5_0] then
			arg_5_0.selfHarm_[var_5_0] = 0
		end

		arg_5_0.selfHarm_[var_5_0] = arg_5_0.selfHarm_[var_5_0] + arg_5_2
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5
end

function var_0_3.selectTargetByTypeD1(arg_6_0)
	if arg_6_0.energyTarget and not arg_6_0.energyTarget:isAffected() and not arg_6_0.energyTarget:isDeath() then
		return {
			arg_6_0.energyTarget
		}
	end

	arg_6_0.energyTarget = nil

	local var_6_0
	local var_6_1 = 0

	for iter_6_0, iter_6_1 in pairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and (not var_6_0 or arg_6_0.selfHarm_[iter_6_1] and var_6_1 < arg_6_0.selfHarm_[iter_6_1]) then
			var_6_0 = iter_6_1

			if arg_6_0.selfHarm_[iter_6_1] then
				var_6_1 = arg_6_0.selfHarm_[iter_6_1]
			end
		end
	end

	if var_6_0 then
		arg_6_0.energyTarget = var_6_0

		return {
			var_6_0
		}
	end

	return var_0_7.B1(arg_6_0)
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.target:isDeath()

	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if var_0_4:father(arg_7_1.skillID) == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_7_1 = arg_7_0:createNewBuffs(var_0_9, arg_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_7_0:addBuffs(var_7_1)
	elseif arg_7_1.skillID == arg_7_0.BlueSkillID then
		arg_7_0.blueEffect = var_0_1.ctx.battle.getSpine(arg_7_0.BlueChildSkillID, "area", 1)

		arg_7_0.blueEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_7_0.blueEffect:pos(arg_7_0:getX(), var_0_2.STAGE_HEIGHT / 2)
		arg_7_0.blueEffect:setScale(1)
		arg_7_0.blueEffect:playRepeat()

		arg_7_0.blueDisX = arg_7_0:getX() + (arg_7_0:getFlipX() and -var_0_13 or var_0_13)
	elseif arg_7_1.skillID == arg_7_0.EnergySkillID then
		arg_7_0:energySkill(arg_7_1)

		if arg_7_0.skinSkillIndex_ == 1 then
			if not var_7_0 and arg_7_1.target:isDeath() then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_7_2 = arg_7_0:createAttackUnits({
						arg_7_0
					}, var_0_17)

					for iter_7_0, iter_7_1 in ipairs(var_7_2) do
						table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
						table.insert(arg_7_0.records_.special_units, iter_7_1)
					end
				end
			elseif not arg_7_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_3 = arg_7_0:createAttackUnits({
					arg_7_0
				}, var_0_16)

				for iter_7_2, iter_7_3 in ipairs(var_7_3) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
					table.insert(arg_7_0.records_.special_units, iter_7_3)
				end
			end
		end
	end
end

function var_0_3.energySkill(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.target
	local var_8_1 = {}
	local var_8_2 = var_0_4:scope(var_0_8)

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if var_8_0 ~= iter_8_1 and not iter_8_1:isDeath() and not iter_8_1:isAffected() and math.abs(var_8_0:getX() - iter_8_1:getX()) <= var_8_2 / 2 then
			table.insert(var_8_1, iter_8_1)
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_3 = arg_8_0:createAttackUnits(var_8_1, var_0_8)

		for iter_8_2, iter_8_3 in ipairs(var_8_3) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
			table.insert(arg_8_0.records_.special_units, iter_8_3)
		end
	end
end

function var_0_3.afterDamageHarm(arg_9_0, arg_9_1, arg_9_2)
	var_0_3.super.afterDamageHarm(arg_9_0, arg_9_1, arg_9_2)

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_9_0.purpleHarm = arg_9_0.purpleHarm + arg_9_1
	end
end

function var_0_3.toDoPerFrames(arg_10_0)
	if arg_10_0.blueEffect then
		local var_10_0 = arg_10_0.blueDisX and arg_10_0.blueEffect:getX() < arg_10_0.blueDisX or not arg_10_0.blueDisX and arg_10_0.blueEffect:getX() < arg_10_0:getX()

		arg_10_0.blueEffect:flipX(not var_10_0)

		local var_10_1 = arg_10_0.blueEffect:getX()
		local var_10_2 = arg_10_0.blueEffect:getX() + (var_10_0 and var_0_14 or -var_0_14)

		arg_10_0.blueEffect:x(var_10_2)

		for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
			if not iter_10_1:isDeath() and not iter_10_1:isAffected() and (var_10_0 and var_10_1 <= iter_10_1:getX() and var_10_2 >= iter_10_1:getX() or not var_10_0 and var_10_1 >= iter_10_1:getX() and var_10_2 <= iter_10_1:getX()) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_10_3 = arg_10_0:createAttackUnits({
					iter_10_1
				}, arg_10_0.BlueChildSkillID)

				for iter_10_2, iter_10_3 in ipairs(var_10_3) do
					table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
					table.insert(arg_10_0.records_.special_units, iter_10_3)
				end
			end
		end

		if var_10_0 then
			if arg_10_0.blueDisX then
				if arg_10_0.blueEffect:getX() > arg_10_0.blueDisX then
					arg_10_0.blueDisX = nil
				end
			elseif arg_10_0.blueEffect:getX() > arg_10_0:getX() then
				arg_10_0.blueEffect:stop()

				arg_10_0.blueEffect = nil
				arg_10_0.blueCollectHarmTag = var_0_18.AddBuff
			end
		elseif arg_10_0.blueDisX then
			if arg_10_0.blueEffect:getX() < arg_10_0.blueDisX then
				arg_10_0.blueDisX = nil
			end
		elseif arg_10_0.blueEffect:getX() < arg_10_0:getX() then
			arg_10_0.blueEffect:stop()

			arg_10_0.blueEffect = nil
			arg_10_0.blueCollectHarmTag = var_0_18.AddBuff
		end
	end

	if arg_10_0:isDeath() then
		return
	end

	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % var_0_10 == 0 and arg_10_0.purpleHarm > 0 then
		local var_10_4 = var_0_11 + var_0_12 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_10_5 = arg_10_0.purpleHarm * var_10_4
		local var_10_6 = var_10_5 - (arg_10_0:getHpLimit() - arg_10_0:getHp())

		if var_10_6 > 0 then
			arg_10_0:updateHp(arg_10_0:getHpLimit())

			local var_10_7 = arg_10_0:createNewBuffs({
				arg_10_0.PurpleShieldBuff
			}, arg_10_0, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_10_7[1].manualDharm = var_10_6

			arg_10_0:addBuffs(var_10_7)
		else
			arg_10_0:updateHp(arg_10_0:getHp() + var_10_5)
		end

		arg_10_0.purpleHarm = 0
	end

	if arg_10_0.blueCollectHarmTag == var_0_18.Collect then
		for iter_10_4, iter_10_5 in ipairs(arg_10_0:getInfoByKey("harm_info")) do
			if iter_10_5.fighter:getTeamType() ~= arg_10_0:getTeamType() then
				if iter_10_5.type == var_0_2.AttackType.AD then
					arg_10_0.blueADHarm = arg_10_0.blueADHarm + iter_10_5.harm
				elseif iter_10_5.type == var_0_2.AttackType.AP then
					arg_10_0.blueAPHarm = arg_10_0.blueAPHarm + iter_10_5.harm
				end
			end
		end
	elseif arg_10_0.blueCollectHarmTag == var_0_18.AddBuff then
		if arg_10_0.blueADHarm >= arg_10_0.blueAPHarm then
			local var_10_8 = arg_10_0:createNewBuffs({
				arg_10_0.BlueADImmortalBuff
			}, arg_10_0, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_10_0:addBuffs(var_10_8)
		else
			local var_10_9 = arg_10_0:createNewBuffs({
				arg_10_0.BlueAPImmortalBuff
			}, arg_10_0, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_10_0:addBuffs(var_10_9)
		end

		arg_10_0.blueADHarm = 0
		arg_10_0.blueAPHarm = 0
		arg_10_0.blueCollectHarmTag = var_0_18.Stop
	end
end

return var_0_3
