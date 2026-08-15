local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Quancong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 50010206
local var_0_7 = 40011407
local var_0_8 = 40011408
local var_0_9 = 40011411
local var_0_10 = 10001318
local var_0_11 = 10001319
local var_0_12 = 10001320
local var_0_13 = 30010206
local var_0_14 = 30010206
local var_0_15 = 40011402
local var_0_16 = 150
local var_0_17 = 40011403
local var_0_18 = 10001321
local var_0_19 = 10001325
local var_0_20 = 40010206
local var_0_21 = 10020206
local var_0_22 = 80010206
local var_0_23 = 0.1
local var_0_24 = 10001669
local var_0_25 = 90
local var_0_26 = 40011772
local var_0_27 = 10001681
local var_0_28 = 10001685
local var_0_29 = 5

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")

	arg_1_0.skinKongjuCount = 0
	arg_1_0.skinHarmCount = 0
end

function var_0_3.updateUnitInfoBySpecialHero(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_1.target == arg_2_0 and arg_2_0.skinSkillID_ == var_0_22 and arg_2_1.fighter:getTeamType() ~= arg_2_0:getTeamType() and not arg_2_1.fighter.isSceneFighter and arg_2_0.skinHarmCount <= 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_2_0.skinHarmCount = var_0_29

		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_1.fighter
		}, var_0_24)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			iter_2_1.basicHarm = arg_2_4 * var_0_23

			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0
	local var_3_1
	local var_3_2 = 999999999
	local var_3_3 = 999999999

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and not iter_3_1:isBoss() then
			local var_3_4 = iter_3_1:getAttrByType(var_0_2.AttributeType.AGILE)

			if iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
				if var_3_4 <= var_3_2 then
					var_3_0 = iter_3_1
					var_3_2 = var_3_4
				end
			elseif var_3_4 <= var_3_3 then
				var_3_1 = iter_3_1
				var_3_3 = var_3_4
			end
		end
	end

	if var_3_0 then
		return {
			var_3_0
		}
	else
		return {
			var_3_1
		}
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_10 then
		local var_4_0 = 0
		local var_4_1 = arg_4_1.target:getFlipX() and 125 or -125

		arg_4_0:x(arg_4_1.target:getX() + var_4_1)
		arg_4_0:y(arg_4_1.target:getY())
	end

	if arg_4_1.skillID == (arg_4_0.skinSkillID_ == var_0_22 and var_0_27 or var_0_11) then
		local var_4_2 = var_0_5.new({
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(var_0_6),
			skillID = var_0_12,
			fighter = arg_4_0,
			target = arg_4_0
		})

		var_4_2:setForceTarget(arg_4_1.target)
		arg_4_0:addBuffs({
			var_4_2
		})

		local var_4_3 = var_0_5.new({
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(var_0_6),
			skillID = var_0_11,
			fighter = arg_4_0,
			target = arg_4_1.target
		})

		var_4_3:setForceTarget(arg_4_0)
		arg_4_1.target:addBuffs({
			var_4_3
		})

		arg_4_0.forceTarget = arg_4_1.target
	end
end

function var_0_3.moveUnitArrive(arg_5_0, arg_5_1)
	var_0_3.super.moveUnitArrive(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_0.skinSkillID_ == var_0_22 and var_0_28 or var_0_14

	if arg_5_1.skillID == var_5_0 then
		arg_5_0.BlueEffect = var_0_1.ctx.battle.getSpine(var_5_0, "area", 1)

		arg_5_0.BlueEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_5_0.BlueEffect:pos(arg_5_1.desX_, arg_5_1.desY_)
		arg_5_0.BlueEffect:setScale(0.5)
		arg_5_0.BlueEffect:playRepeat()

		arg_5_0.BlueEffectEndCount = var_0_1.ctx.battle.count + (3 + 0.05 * arg_5_0:getSkillLevelByID(var_0_13)) * 30
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	arg_6_0.skinHarmCount = arg_6_0.skinHarmCount - 1

	if arg_6_0.skinSkillID_ == var_0_22 then
		if arg_6_0.skinKongjuCount <= 0 then
			for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("buff_info")) do
				if iter_6_1.target == arg_6_0 and iter_6_1.fighter:getTeamType() ~= arg_6_0:getTeamType() and not iter_6_1.fighter:isAffected() and (iter_6_1:isFear() or iter_6_1:isApUnable() or iter_6_1:isAdUnable() or iter_6_1:isExcuteAdCircle() or iter_6_1:isAttackFriend() or iter_6_1:isPugongOnly()) then
					arg_6_0.skinKongjuCount = var_0_25

					iter_6_1.fighter:addBuffs({
						var_0_5.new({
							tableID = var_0_26,
							start = var_0_1.ctx.battle.count,
							level = arg_6_0:getLevel(),
							skillID = var_0_22,
							fighter = arg_6_0,
							target = iter_6_1.fighter
						})
					})
				end
			end
		else
			arg_6_0.skinKongjuCount = arg_6_0.skinKongjuCount - 1
		end
	end

	if arg_6_0.BlueEffect ~= nil and var_0_1.ctx.battle.count > arg_6_0.BlueEffectEndCount then
		arg_6_0.BlueEffect:stop()

		arg_6_0.BlueEffect = nil
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_3:isDeath() and not iter_6_3:isAffected() then
			local var_6_0 = arg_6_0.BlueEffect ~= nil and arg_6_0.BlueEffect:getX() - var_0_16 < iter_6_3:getX() and iter_6_3:getX() < arg_6_0.BlueEffect:getX() + var_0_16
			local var_6_1 = iter_6_3:isHasBuffByID(var_0_15)

			if not var_6_1 and var_6_0 then
				local var_6_2 = var_0_5.new({
					tableID = var_0_15,
					start = var_0_1.ctx.battle.count,
					level = arg_6_0:getSkillLevelByID(var_0_13),
					skillID = BlueDebuffSkillID,
					fighter = arg_6_0,
					target = iter_6_3
				})

				iter_6_3:addBuffs({
					var_6_2
				})
			end

			if var_6_1 and not var_6_0 then
				iter_6_3:removeBuffByID(var_0_15)
			end
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0.PassiveSkillTarget ~= nil and not arg_6_0.PassiveSkillTarget:isDeath() then
		local var_6_3 = math.max(arg_6_0.PassiveSkillTarget:getEnergy() - 1, 0) * arg_6_0:getAP() * 0.01 * (arg_6_0.nPassiveBuffs or 0)

		if var_6_3 > 0 then
			local var_6_4 = arg_6_0:createAttackUnits({
				arg_6_0.PassiveSkillTarget
			}, var_0_19)

			for iter_6_4, iter_6_5 in ipairs(var_6_4) do
				iter_6_5.basicHarm = var_6_3

				table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
				table.insert(arg_6_0.records_.special_units, iter_6_5)
			end
		end

		arg_6_0.PassiveSkillTarget:updateEnergyTo(0)
	end
end

function var_0_3.die(arg_7_0)
	var_0_3.super.die(arg_7_0)

	if arg_7_0:isForverNeverDie() then
		arg_7_0:updateHp(1)
	end
end

function var_0_3.forceDie(arg_8_0)
	if arg_8_0:getSkillLevelByID(var_0_20) > 0 and arg_8_0:getSummonType() == var_0_2.summonMonsterType.None and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_0
		local var_8_1
		local var_8_2 = 0
		local var_8_3 = 0

		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() and not iter_8_1:isBoss() then
				if iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
					if var_8_2 <= iter_8_1:getEnergy() then
						var_8_2 = iter_8_1:getEnergy()
						var_8_0 = iter_8_1
					end
				elseif var_8_3 <= iter_8_1:getEnergy() then
					var_8_3 = iter_8_1:getEnergy()
					var_8_1 = iter_8_1
				end
			end
		end

		if var_8_0 or var_8_1 then
			local var_8_4 = arg_8_0:createAttackUnits({
				var_8_0 or var_8_1
			}, var_0_20)

			for iter_8_2, iter_8_3 in ipairs(var_8_4) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end

			arg_8_0.PassiveSkillTarget = var_8_0 or var_8_1
		end
	end

	var_0_3.super.forceDie(arg_8_0)
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_0.skinSkillID_ == var_0_22 and arg_9_1:getTableID() == var_0_7 and arg_9_1.target == arg_9_0 then
		arg_9_0:updateHp(arg_9_0:getHp() + (arg_9_0:getHpLimit() - arg_9_0:getHp()) * 0.15)
	end
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	if arg_10_1 == arg_10_0.forceTarget then
		arg_10_0:removeBuffByID(var_0_7)
		arg_10_0:removeBuffByID(var_0_8)
		arg_10_0:removeBuffByID(var_0_9)

		arg_10_0.forceTarget = nil
	end

	if arg_10_0:getSkillLevelByID(var_0_20) > 0 and arg_10_1:getSummonType() == var_0_2.summonMonsterType.None then
		local var_10_0 = var_0_5.new({
			tableID = var_0_17,
			start = var_0_1.ctx.battle.count,
			level = arg_10_0:getSkillLevelByID(var_0_20),
			skillID = var_0_18,
			fighter = arg_10_0,
			target = arg_10_0
		})

		arg_10_0:addBuffs({
			var_10_0
		})

		arg_10_0.nPassiveBuffs = (arg_10_0.nPassiveBuffs or 0) + 1
	end
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if arg_11_1.skillID == var_0_21 and arg_11_0:getSkillLevelByID(var_0_20) > 0 then
		var_11_5 = -(arg_11_0.nPassiveBuffs or 0) * 0.2 * (arg_11_0:getSkillLevelByID(var_0_20) + 50)
	elseif arg_11_1.skillID == var_0_24 then
		var_11_2 = arg_11_1.basicHarm
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

return var_0_3
