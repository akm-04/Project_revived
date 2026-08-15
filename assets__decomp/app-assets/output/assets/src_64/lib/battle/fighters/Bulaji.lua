local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Bulaji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.dbuff
local var_0_9 = 3
local var_0_10 = 180
local var_0_11 = 0.15
local var_0_12 = 0.002
local var_0_13 = 40012492
local var_0_14 = 0.2
local var_0_15 = 0.003
local var_0_16 = 10002303
local var_0_17 = 10002304
local var_0_18 = 10002305
local var_0_19 = 10002306
local var_0_20 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyEffectCount = 0
	arg_1_0.energyEffectX = 0
	arg_1_0.records_.take_effect = {}
	arg_1_0.playEffect = false
	arg_1_0.purpleSkillCD = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		local var_2_0 = var_0_6.B2(arg_2_0, var_0_16)

		if next(var_2_0) then
			local var_2_1 = 0
			local var_2_2 = 0

			for iter_2_0, iter_2_1 in ipairs(var_2_0) do
				var_2_1 = var_2_1 + iter_2_1:getX()
				var_2_2 = var_2_2 + iter_2_1:getY()
			end

			local var_2_3 = var_2_1 / #var_2_0
			local var_2_4 = var_2_2 / #var_2_0 + 100

			arg_2_0.energyEffect1 = var_0_1.ctx.battle.getSpine(var_0_16, "area", 1)

			arg_2_0.energyEffect1:addTo(var_0_1.ctx.battle.unitBottomLayer)

			arg_2_0.energyEffectX = var_2_3
			arg_2_0.energyEffectY = var_2_4

			arg_2_0.energyEffect1:pos(var_2_3, var_2_4)
			arg_2_0.energyEffect1:setScale(0.5)
			arg_2_0.energyEffect1:play()
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_18 and not arg_3_0.playEffect then
		local var_3_0 = var_0_6.B2(arg_3_0, var_0_18)

		if next(var_3_0) then
			local var_3_1 = 0
			local var_3_2 = 0
			local var_3_3 = arg_3_0.energyEffectX
			local var_3_4 = arg_3_0.energyEffectY

			arg_3_0.energyEffect = var_0_1.ctx.battle.getSpine(var_0_19, "area", 1)

			arg_3_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_3_0.energyEffect:pos(var_3_3, var_3_4)
			arg_3_0.energyEffect:setScale(0.5)
			arg_3_0.energyEffect:playRepeat()

			arg_3_0.energyEffectCount = var_0_10
			arg_3_0.playEffect = true
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0
	local var_4_1

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			local var_4_2 = iter_4_1.hero_:getDistance()

			if not var_4_0 or var_4_2 < var_4_0 then
				var_4_1 = iter_4_1
				var_4_0 = var_4_2
			end
		end
	end

	return {
		var_4_1
	}
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0.energyEffectCount > 0 then
		arg_5_0.energyEffectCount = arg_5_0.energyEffectCount - 1

		local var_5_0 = var_0_7:scope(var_0_18)

		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() and var_5_0 > math.abs(arg_5_0.energyEffectX - iter_5_1:getX()) then
				local var_5_1 = var_0_9

				if iter_5_1:getX() < arg_5_0.energyEffectX then
					iter_5_1:moveByX(var_5_1)
				else
					iter_5_1:moveByX(-var_5_1)
				end
			end
		end
	elseif arg_5_0.energyEffect then
		arg_5_0.energyEffect:stop()

		arg_5_0.energyEffect = nil
		arg_5_0.playEffect = false
	end

	arg_5_0.purpleSkillCD = arg_5_0.purpleSkillCD - 1
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_1:getTableID() == var_0_13 then
		arg_6_1.manualDharm = arg_6_0:getHpLimit() * (var_0_11 + var_0_12 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	end
end

function var_0_3.addBuffBySpecialHero(arg_7_0, arg_7_1)
	var_0_3.super.addBuffBySpecialHero(arg_7_0, arg_7_1)

	for iter_7_0 = #arg_7_1, 1, -1 do
		local var_7_0 = arg_7_1[iter_7_0]
		local var_7_1 = var_7_0.target

		if var_7_1 and not var_7_1:isDeath() and var_7_1:getTeamType() == arg_7_0:getTeamType() and var_0_8:dbuffType(var_7_0:getTableID()) > 0 and arg_7_0.purpleSkillCD <= 0 then
			local var_7_2 = var_0_14 + var_0_15 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
			local var_7_3 = true

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				var_7_3 = arg_7_0.takeEffect_[tostring(var_0_1.ctx.battle.count)] or true
			else
				var_7_3 = var_0_2.weightedChoise({
					var_7_2,
					1 - var_7_2
				}) == 1
				arg_7_0.records_.take_effect[tostring(var_0_1.ctx.battle.count)] = var_7_3
			end

			if var_7_3 then
				table.remove(arg_7_1, iter_7_0)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_7_4 = var_0_6.A3(arg_7_0, var_0_16)
					local var_7_5 = arg_7_0:createAttackUnits(var_7_4, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					for iter_7_1, iter_7_2 in ipairs(var_7_5) do
						table.insert(arg_7_0.moveAttackUnits_, iter_7_2)
						table.insert(arg_7_0.records_.special_units, iter_7_2)
					end
				end
			end

			arg_7_0.purpleSkillCD = var_0_20
		end
	end
end

function var_0_3.setupReport(arg_8_0, arg_8_1)
	var_0_3.super.setupReport(arg_8_0, arg_8_1)

	arg_8_0.takeEffect_ = arg_8_1.take_effect or {}
end

function var_0_3.writeReport(arg_9_0)
	local var_9_0 = var_0_3.super.writeReport(arg_9_0)

	var_9_0.take_effect = arg_9_0.records_.take_effect

	return var_9_0
end

return var_0_3
