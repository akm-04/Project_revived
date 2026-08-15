local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Handang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 5
local var_0_7 = 10000661
local var_0_8 = 0.005
local var_0_9 = 0
local var_0_10 = 0.007
local var_0_11 = 0
local var_0_12 = 180
local var_0_13 = 10000662
local var_0_14 = 10
local var_0_15 = 40010647
local var_0_16 = 0.1
local var_0_17 = 450
local var_0_18 = 10001263

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.isSkinSkillOn_ then
		arg_2_0.GreenBuffID = 40012554
		arg_2_0.BlueBuffID = 40012555
		arg_2_0.GreenSkill = 10002344
		arg_2_0.EnergySkill = 10002346
	else
		arg_2_0.GreenBuffID = 40010642
		arg_2_0.BlueBuffID = 40010643
		arg_2_0.GreenSkill = 20010146
		arg_2_0.EnergySkill = 50010146
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.purpleSkillCount = 0
	arg_3_0.records_.blue_buff_remove = {}
	arg_3_0.greenMainTarget_ = nil
	arg_3_0.greenLinkTargets_ = {}
	arg_3_0.greenHarms_ = 0
	arg_3_0.energySkillRegion = {}
	arg_3_0.energyBuffTargets = {}
	arg_3_0.lastEnergyTime_ = nil
end

function var_0_3.toDoPerFrames(arg_4_0)
	arg_4_0:updateEnergyEffect()

	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			local var_4_0 = iter_4_1.harm
			local var_4_1 = iter_4_1.fighter
			local var_4_2 = iter_4_1.target
			local var_4_3 = iter_4_1.skillID

			if var_4_0 > 0 and var_4_2 == arg_4_0.greenMainTarget_ and var_4_3 ~= var_0_7 and var_4_3 ~= var_0_18 then
				if not var_4_2:isDeath() and var_4_2:getBuffByID(arg_4_0.GreenBuffID) then
					arg_4_0.greenHarms_ = var_4_0

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_4_4 = {}

						for iter_4_2, iter_4_3 in ipairs(arg_4_0.greenLinkTargets_) do
							if not iter_4_3:isDeath() and not iter_4_3:isAffected() then
								table.insert(var_4_4, iter_4_3)
							end
						end

						local var_4_5 = arg_4_0:createAttackUnits(var_4_4, var_0_7)

						for iter_4_4, iter_4_5 in ipairs(var_4_5) do
							table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
							table.insert(arg_4_0.records_.special_units, iter_4_5)
						end
					end
				else
					arg_4_0:removeLastGreen()

					arg_4_0.greenMainTarget_ = nil
					arg_4_0.greenLinkTargets_ = {}
					arg_4_0.greenHarms_ = 0
				end
			end
		end
	end

	local var_4_6 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

	if var_4_6 > 0 then
		for iter_4_6, iter_4_7 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			if iter_4_7.target:getTeamType() == arg_4_0:getTeamType() and iter_4_7.target:getBuffByID(arg_4_0.BlueBuffID) and iter_4_7:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				local var_4_7 = false

				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					if arg_4_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)] then
						var_4_7 = true
					end
				else
					local var_4_8 = var_0_10 * var_4_6 + var_0_11
					local var_4_9 = math.min(1, var_4_8)

					var_4_7 = var_0_2.weightedChoise({
						var_4_9,
						1 - var_4_9
					}) == 1

					if var_4_7 then
						arg_4_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)] = 1
					end
				end

				if var_4_7 then
					iter_4_7.target:removeBuffs(iter_4_7)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_1.skillID == var_0_7 then
		local var_5_0 = var_0_5:type(var_0_7)
		local var_5_1
		local var_5_2 = arg_5_1.target
		local var_5_3 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

		if var_5_0 == var_0_2.AttackType.AD then
			var_5_1 = arg_5_0.greenHarms_ * var_5_2:getADJianShang() * (var_0_8 * var_5_3 + var_0_9)
		else
			var_5_1 = arg_5_0.greenHarms_ * var_5_2:getAPJianShang() * (var_0_8 * var_5_3 + var_0_9)
		end

		arg_5_4 = arg_5_4 + var_5_1
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		local var_6_0 = arg_6_0.GreenSkill

		if arg_6_1.skillID == var_6_0 then
			local var_6_1 = arg_6_1.target

			if arg_6_0.greenMainTarget_ ~= var_6_1 then
				arg_6_0:removeLastGreen()
			end

			arg_6_0.greenMainTarget_ = var_6_1
			arg_6_0.greenLinkTargets_ = {}

			local var_6_2 = var_6_1.hero_:getHeroType()

			for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
				if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1.hero_:getHeroType() == var_6_2 and iter_6_1 ~= var_6_1 then
					local var_6_3 = arg_6_0:newBuff({
						arg_6_0.GreenBuffID
					}, iter_6_1, var_6_0)

					iter_6_1:addBuffs(var_6_3)
					table.insert(arg_6_0.greenLinkTargets_, iter_6_1)
				end
			end
		end
	end

	if arg_6_1.skillID == arg_6_0.EnergySkill then
		local var_6_4 = {
			x = arg_6_1.target:getX(),
			y = arg_6_1.target:getY()
		}
		local var_6_5 = var_0_12
		local var_6_6 = var_0_1.ctx.battle.getSpine(arg_6_0.EnergySkill, "area", 1)

		var_6_6:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_6_6:pos(var_6_4.x, var_6_4.y)
		var_6_6:playRepeat()

		local var_6_7 = {
			pos = var_6_4,
			time = var_6_5,
			effect = var_6_6
		}

		table.insert(arg_6_0.energySkillRegion, var_6_7)
		arg_6_0:updateEnergyEffect()
	end
end

function var_0_3.removeLastGreen(arg_7_0)
	for iter_7_0 = #arg_7_0.greenLinkTargets_, 1, -1 do
		local var_7_0 = arg_7_0.greenLinkTargets_[iter_7_0]

		if not var_7_0:isDeath() then
			var_7_0:removeBuffByID(arg_7_0.GreenBuffID)
		end
	end

	arg_7_0.greenLinkTargets_ = {}
end

function var_0_3.checkGreenTarget(arg_8_0, arg_8_1)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.greenMainTarget_) do
		if iter_8_1 == arg_8_1 then
			return iter_8_0
		end
	end

	return false
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == arg_9_0.EnergySkill then
		arg_9_0.lastEnergyTime_ = var_0_1.ctx.battle.count
	end

	arg_9_0.purpleSkillCount = arg_9_0.purpleSkillCount + 1

	if arg_9_0.purpleSkillCount == var_0_6 then
		arg_9_0.purpleSkillCount = 0

		arg_9_0:createSpecialSkill()
	end
end

function var_0_3.createSpecialSkill(arg_10_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_10_0 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_10_1
	local var_10_2 = 100

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.selfTeam_) do
		if (not iter_10_1:isDeath() or iter_10_1:canReborn()) and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None and var_10_2 >= iter_10_1:getHp() / iter_10_1:getHpLimit() then
			var_10_2 = iter_10_1:getHp() / iter_10_1:getHpLimit()
			var_10_1 = iter_10_1
		end
	end

	local var_10_3 = {
		var_10_1
	}
	local var_10_4 = arg_10_0:createAttackUnits(var_10_3, var_10_0)

	for iter_10_2, iter_10_3 in ipairs(var_10_4) do
		table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
		table.insert(arg_10_0.records_.special_units, iter_10_3)
	end
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.blueBuffRemove = arg_11_1.blue_buff_remove
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.blue_buff_remove = arg_12_0.records_.blue_buff_remove

	return var_12_0
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_1 = var_0_4.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(arg_13_3),
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_1:setIsHit(true)
		var_13_1:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

function var_0_3.updateEnergyEffect(arg_14_0)
	if not arg_14_0:acttionInBlack() then
		return
	end

	if next(arg_14_0.energySkillRegion) ~= nil then
		for iter_14_0 = #arg_14_0.energySkillRegion, 1, -1 do
			local var_14_0 = arg_14_0.energySkillRegion[iter_14_0]

			var_14_0.time = var_14_0.time - 1

			if var_14_0.time == 0 then
				arg_14_0:addEnergyDebuff()
				arg_14_0:removeAllEnergyBuff()
				var_14_0.effect:removeSelf()

				var_14_0.effect = nil

				table.remove(arg_14_0.energySkillRegion, iter_14_0)
			else
				for iter_14_1, iter_14_2 in ipairs(arg_14_0.selfTeam_) do
					if not iter_14_2:isDeath() and not iter_14_2:isAffected() and iter_14_2:getSummonType() == var_0_2.summonMonsterType.None and not var_0_0.table.indexof(arg_14_0.energyBuffTargets, iter_14_2) and arg_14_0:isInCircle(var_14_0, iter_14_2) then
						table.insert(arg_14_0.energyBuffTargets, iter_14_2)
						arg_14_0:addEnergyBuff(iter_14_2)
					end
				end

				for iter_14_3, iter_14_4 in ipairs(arg_14_0.sideTeam_) do
					if not iter_14_4:isDeath() and not iter_14_4:isAffected() and iter_14_4:getSummonType() == var_0_2.summonMonsterType.None and not var_0_0.table.indexof(arg_14_0.energyBuffTargets, iter_14_4) and arg_14_0:isInCircle(var_14_0, iter_14_4) then
						table.insert(arg_14_0.energyBuffTargets, iter_14_4)
						arg_14_0:addEnergyBuff(iter_14_4)
					end
				end

				if next(arg_14_0.energyBuffTargets) ~= nil then
					for iter_14_5 = #arg_14_0.energyBuffTargets, 1, -1 do
						local var_14_1 = arg_14_0.energyBuffTargets[iter_14_5]

						if not arg_14_0:isInCircle(var_14_0, var_14_1) then
							var_14_1:removeBuffByID(var_0_15)
							var_14_1:setMinHpValue(0, true)
							table.remove(arg_14_0.energyBuffTargets, iter_14_5)
						end
					end
				end
			end
		end
	end
end

function var_0_3.addEnergyDebuff(arg_15_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.energyBuffTargets) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and not iter_15_1:isBoss() then
			table.insert(var_15_0, iter_15_1)
		end
	end

	local var_15_1 = arg_15_0:createAttackUnits(var_15_0, var_0_13)

	for iter_15_2, iter_15_3 in ipairs(var_15_1) do
		table.insert(arg_15_0.moveAttackUnits_, iter_15_3)
		table.insert(arg_15_0.records_.special_units, iter_15_3)
	end
end

function var_0_3.removeAllEnergyBuff(arg_16_0)
	for iter_16_0 = #arg_16_0.energyBuffTargets, 1, -1 do
		local var_16_0 = arg_16_0.energyBuffTargets[iter_16_0]

		var_16_0:removeBuffByID(var_0_15)
		var_16_0:setMinHpValue(0, true)
		table.remove(arg_16_0.energyBuffTargets, iter_16_0)
	end
end

function var_0_3.isInCircle(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_2:getX()
	local var_17_1 = arg_17_1.pos.x

	if var_0_5:scope(arg_17_0.EnergySkill) / 2 >= math.abs(var_17_0 - var_17_1) then
		return true
	end

	return false
end

function var_0_3.addEnergyBuff(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0.EnergySkill
	local var_18_1 = arg_18_0:newBuff({
		var_0_15
	}, arg_18_1, var_18_0)

	arg_18_1:addBuffs(var_18_1)
	arg_18_1:setMinHpValue(var_0_16)
end

function var_0_3.checkEnergySkill(arg_19_0)
	if arg_19_0.lastEnergyTime_ and var_0_1.ctx.battle.count - arg_19_0.lastEnergyTime_ < var_0_17 then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_19_0)
end

return var_0_3
