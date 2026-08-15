local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Aoding", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 10002125
local var_0_9 = {
	40012258,
	40012259
}
local var_0_10 = 10002124
local var_0_11 = 180
local var_0_12 = 0.1
local var_0_13 = 0.003
local var_0_14 = 40012262
local var_0_15 = var_0_2.STAGE_WIDTH
local var_0_16 = 40
local var_0_17 = 40012260
local var_0_18 = 40012261
local var_0_19 = 450
local var_0_20 = {
	40012260,
	40012261
}
local var_0_21 = {
	AddBuff = 2,
	Collect = 1,
	Stop = 3
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.selfHarm_ = {}
	arg_2_0.blueEffect = nil
	arg_2_0.blueCollectHarmTag = var_0_21.Stop
	arg_2_0.blueADHarm = 0
	arg_2_0.blueAPHarm = 0
	arg_2_0.purpleHarm = 0
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0.blueADHarm = 0
		arg_3_0.blueAPHarm = 0
		arg_3_0.blueCollectHarmTag = var_0_21.Collect
	end
end

function var_0_3.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5 = var_0_3.super.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)

	local var_4_0 = arg_4_1.fighter

	if var_4_0:getTeamType() ~= arg_4_0:getTeamType() then
		if not arg_4_0.selfHarm_[var_4_0] then
			arg_4_0.selfHarm_[var_4_0] = 0
		end

		arg_4_0.selfHarm_[var_4_0] = arg_4_0.selfHarm_[var_4_0] + arg_4_2
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5
end

function var_0_3.selectTargetByTypeD1(arg_5_0)
	local var_5_0
	local var_5_1 = 0

	for iter_5_0, iter_5_1 in pairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and (not var_5_0 or arg_5_0.selfHarm_[iter_5_1] and var_5_1 < arg_5_0.selfHarm_[iter_5_1]) then
			var_5_0 = iter_5_1

			if arg_5_0.selfHarm_[iter_5_1] then
				var_5_1 = arg_5_0.selfHarm_[iter_5_1]
			end
		end
	end

	if var_5_0 then
		return {
			var_5_0
		}
	end

	return var_0_7.B1(arg_5_0)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if var_0_4:father(arg_6_1.skillID) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_6_0 = arg_6_0:createNewBuffs(var_0_9, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_6_0:addBuffs(var_6_0)
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_6_0.blueEffect = var_0_1.ctx.battle.getSpine(var_0_10, "area", 1)

		arg_6_0.blueEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_6_0.blueEffect:pos(arg_6_0:getX(), var_0_2.STAGE_HEIGHT / 2)
		arg_6_0.blueEffect:setScale(1)
		arg_6_0.blueEffect:playRepeat()

		arg_6_0.blueDisX = arg_6_0:getX() + (arg_6_0:getFlipX() and -var_0_15 or var_0_15)
	elseif arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		arg_6_0:energySkill(arg_6_1)
	end
end

function var_0_3.energySkill(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.target
	local var_7_1 = {}
	local var_7_2 = var_0_4:scope(var_0_8)

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if var_7_0 ~= iter_7_1 and not iter_7_1:isDeath() and not iter_7_1:isAffected() and math.abs(var_7_0:getX() - iter_7_1:getX()) <= var_7_2 / 2 then
			table.insert(var_7_1, iter_7_1)
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_3 = arg_7_0:createAttackUnits(var_7_1, var_0_8)

		for iter_7_2, iter_7_3 in ipairs(var_7_3) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
			table.insert(arg_7_0.records_.special_units, iter_7_3)
		end
	end
end

function var_0_3.afterDamageHarm(arg_8_0, arg_8_1, arg_8_2)
	var_0_3.super.afterDamageHarm(arg_8_0, arg_8_1, arg_8_2)

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_8_0.purpleHarm = arg_8_0.purpleHarm + arg_8_1
	end
end

function var_0_3.toDoPerFrames(arg_9_0)
	if arg_9_0.blueEffect then
		local var_9_0 = arg_9_0.blueDisX and arg_9_0.blueEffect:getX() < arg_9_0.blueDisX or not arg_9_0.blueDisX and arg_9_0.blueEffect:getX() < arg_9_0:getX()

		arg_9_0.blueEffect:flipX(not var_9_0)

		local var_9_1 = arg_9_0.blueEffect:getX()
		local var_9_2 = arg_9_0.blueEffect:getX() + (var_9_0 and var_0_16 or -var_0_16)

		arg_9_0.blueEffect:x(var_9_2)

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_1:isDeath() and not iter_9_1:isAffected() and (var_9_0 and var_9_1 <= iter_9_1:getX() and var_9_2 >= iter_9_1:getX() or not var_9_0 and var_9_1 >= iter_9_1:getX() and var_9_2 <= iter_9_1:getX()) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_9_3 = arg_9_0:createAttackUnits({
					iter_9_1
				}, var_0_10)

				for iter_9_2, iter_9_3 in ipairs(var_9_3) do
					table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
					table.insert(arg_9_0.records_.special_units, iter_9_3)
				end
			end
		end

		if var_9_0 then
			if arg_9_0.blueDisX then
				if arg_9_0.blueEffect:getX() > arg_9_0.blueDisX then
					arg_9_0.blueDisX = nil
				end
			elseif arg_9_0.blueEffect:getX() > arg_9_0:getX() then
				arg_9_0.blueEffect:stop()

				arg_9_0.blueEffect = nil
				arg_9_0.blueCollectHarmTag = var_0_21.AddBuff
			end
		elseif arg_9_0.blueDisX then
			if arg_9_0.blueEffect:getX() < arg_9_0.blueDisX then
				arg_9_0.blueDisX = nil
			end
		elseif arg_9_0.blueEffect:getX() < arg_9_0:getX() then
			arg_9_0.blueEffect:stop()

			arg_9_0.blueEffect = nil
			arg_9_0.blueCollectHarmTag = var_0_21.AddBuff
		end
	end

	if arg_9_0:isDeath() then
		return
	end

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % var_0_11 == 0 and arg_9_0.purpleHarm > 0 then
		local var_9_4 = var_0_12 + var_0_13 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_9_5 = arg_9_0.purpleHarm * var_9_4
		local var_9_6 = var_9_5 - (arg_9_0:getHpLimit() - arg_9_0:getHp())

		if var_9_6 > 0 then
			arg_9_0:updateHp(arg_9_0:getHpLimit())

			local var_9_7 = arg_9_0:createNewBuffs({
				var_0_14
			}, arg_9_0, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_9_7[1].manualDharm = var_9_6

			arg_9_0:addBuffs(var_9_7)
		else
			arg_9_0:updateHp(arg_9_0:getHp() + var_9_5)
		end

		arg_9_0.purpleHarm = 0
	end

	if arg_9_0.blueCollectHarmTag == var_0_21.Collect then
		for iter_9_4, iter_9_5 in ipairs(arg_9_0:getInfoByKey("harm_info")) do
			if iter_9_5.fighter:getTeamType() ~= arg_9_0:getTeamType() then
				if iter_9_5.type == var_0_2.AttackType.AD then
					arg_9_0.blueADHarm = arg_9_0.blueADHarm + iter_9_5.harm
				elseif iter_9_5.type == var_0_2.AttackType.AP then
					arg_9_0.blueAPHarm = arg_9_0.blueAPHarm + iter_9_5.harm
				end
			end
		end
	elseif arg_9_0.blueCollectHarmTag == var_0_21.AddBuff then
		if arg_9_0.blueADHarm >= arg_9_0.blueAPHarm then
			local var_9_8 = arg_9_0:createNewBuffs({
				var_0_17
			}, arg_9_0, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_9_0:addBuffs(var_9_8)
		else
			local var_9_9 = arg_9_0:createNewBuffs({
				var_0_18
			}, arg_9_0, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_9_0:addBuffs(var_9_9)
		end

		arg_9_0.blueADHarm = 0
		arg_9_0.blueAPHarm = 0
		arg_9_0.blueCollectHarmTag = var_0_21.Stop
	end
end

function var_0_3.fliterBuffs(arg_10_0, arg_10_1)
	var_0_3.super.fliterBuffs(arg_10_0, arg_10_1)

	if arg_10_0:isDHarm() or arg_10_0:isHasBuffByID(var_0_20[1]) or arg_10_0:isHasBuffByID(var_0_20[2]) then
		for iter_10_0 = #arg_10_1, 1, -1 do
			if arg_10_1[iter_10_0]:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				table.remove(arg_10_1, iter_10_0)
			end
		end
	end
end

function var_0_3.getHuJia(arg_11_0)
	local var_11_0 = math.floor(var_0_1.ctx.battle.count / var_0_19)
	local var_11_1 = 1

	if var_11_0 > 0 then
		for iter_11_0 = 1, var_11_0 do
			var_11_1 = var_11_1 * 0.7
		end
	end

	return arg_11_0:getAttrByType(var_0_2.AttributeType.HUJIA) * var_11_1
end

function var_0_3.getMoKang(arg_12_0)
	local var_12_0 = math.floor(var_0_1.ctx.battle.count / var_0_19)
	local var_12_1 = 1

	if var_12_0 > 0 then
		for iter_12_0 = 1, var_12_0 do
			var_12_1 = var_12_1 * 0.7
		end
	end

	return arg_12_0:getAttrByType(var_0_2.AttributeType.MOKANG) * var_12_1
end

return var_0_3
