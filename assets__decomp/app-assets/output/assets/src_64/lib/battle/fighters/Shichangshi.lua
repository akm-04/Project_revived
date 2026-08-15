local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shichangshi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 50010210
local var_0_9 = 10001432
local var_0_10 = 10001433
local var_0_11 = 10001386
local var_0_12 = 10001387
local var_0_13 = 20010210
local var_0_14 = 10001436
local var_0_15 = 10001437
local var_0_16 = 30010210
local var_0_17 = 10001401
local var_0_18 = 10001400
local var_0_19 = 10001402
local var_0_20 = 10001403
local var_0_21 = 40010210
local var_0_22 = 10001404
local var_0_23 = 80010210
local var_0_24 = 10001414
local var_0_25 = 10001415
local var_0_26 = 10001434
local var_0_27 = 10001435
local var_0_28 = 10001438
local var_0_29 = 10001439
local var_0_30 = 10001429
local var_0_31 = 10001428
local var_0_32 = 10001430
local var_0_33 = 10001431

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("attack_info")

	arg_1_0.alliesADHarmTillNow = {}
	arg_1_0.alliesAPHarmTillNow = {}
	arg_1_0.energyCD = 150
	arg_1_0.nGhostFires = 0
	arg_1_0.totalADHarm = 0
	arg_1_0.totalAPHarm = 0
end

function var_0_3.selectTargetByTypeD2(arg_2_0, arg_2_1, arg_2_2)
	if not var_0_4.timeSeed_ then
		var_0_4.timeSeed_ = 1
	end

	math.randomseed(tonumber(tostring(os.time() + var_0_4.timeSeed_):reverse():sub(1, 6)))

	local var_2_0 = math.random(tonumber(os.time()))

	var_0_4.timeSeed_ = var_2_0

	math.randomseed(var_2_0)

	local var_2_1 = 1 + math.random(4)
	local var_2_2 = {}

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and var_2_1 > 0 then
			table.insert(var_2_2, iter_2_1)

			var_2_1 = var_2_1 - 1
		end
	end

	return var_2_2
end

function var_0_3.getFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getFrontSkill(arg_3_0)

	if arg_3_0.skinSkillID_ ~= var_0_23 then
		if var_3_0 == var_0_13 then
			if arg_3_0.totalADHarm > arg_3_0.totalAPHarm then
				var_3_0 = var_0_14
			else
				var_3_0 = var_0_15
			end
		elseif var_3_0 == var_0_8 then
			if arg_3_0:getAD() > arg_3_0:getAP() then
				var_3_0 = var_0_10
			else
				var_3_0 = var_0_9
			end
		end
	elseif var_3_0 == var_0_13 then
		if arg_3_0.totalADHarm > arg_3_0.totalAPHarm then
			var_3_0 = var_0_28
		else
			var_3_0 = var_0_29
		end
	elseif var_3_0 == var_0_8 then
		if arg_3_0:getAD() > arg_3_0:getAP() then
			var_3_0 = var_0_27
		else
			var_3_0 = var_0_26
		end
	end

	return var_3_0
end

function var_0_3.checkEnergySkill(arg_4_0)
	if arg_4_0.energyCD > 0 then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_4_0)
end

function var_0_3.isBreakImmortal(arg_5_0)
	return arg_5_0.isEnergySkill_ or var_0_3.super.isBreakImmortal(arg_5_0)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.nGhostFires > 0 then
		arg_6_0:updateStateNumber(arg_6_0.nGhostFires)
	end

	local var_6_0 = arg_6_0:getSkillLevelByID(var_0_8)

	for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("attack_info")) do
		if iter_6_1.fighter_ == arg_6_0 and var_0_7:father(iter_6_1.rootID_) == var_0_8 then
			arg_6_0.energyCD = (15 - arg_6_0.nGhostFires * 1.5) * 30

			arg_6_0:setupHpLimit()
			arg_6_0:resetHpLimit(arg_6_0:getHpLimit() + arg_6_0.nGhostFires * var_6_0 * 70)
		end
	end

	if arg_6_0.energyCD > 0 then
		arg_6_0.energyCD = arg_6_0.energyCD - 1
	elseif arg_6_0.energyCD == 0 then
		arg_6_0.energyCD = arg_6_0.energyCD - 1

		arg_6_0:setupHpLimit()
		arg_6_0:resetHpLimit(arg_6_0:getHpLimit() + 9 * var_6_0 * 70)
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0:getInfoByKey("harm_info")) do
		if iter_6_3.fighter:getTeamType() == arg_6_0:getTeamType() then
			if iter_6_3.type == var_0_2.AttackType.AD then
				arg_6_0.totalADHarm = arg_6_0.totalADHarm + iter_6_3.harm
			elseif iter_6_3.type == var_0_2.AttackType.AP then
				arg_6_0.totalAPHarm = arg_6_0.totalAPHarm + iter_6_3.harm
			end
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0:getSkillLevelByID(var_0_16) > 0 then
		for iter_6_4, iter_6_5 in ipairs(arg_6_0:getInfoByKey("harm_info")) do
			local var_6_1 = iter_6_5.fighter

			if not var_6_1:isDeath() and not var_6_1:isAffected() and var_6_1:getTeamType() == arg_6_0:getTeamType() and var_6_1 ~= arg_6_0 and var_6_1:getSummonType() == var_0_2.summonMonsterType.None then
				if iter_6_5.type == var_0_2.AttackType.AD and var_6_1.hero_:getHeroType() ~= var_0_2.HeroType.WISE then
					arg_6_0.alliesADHarmTillNow[var_6_1] = (arg_6_0.alliesADHarmTillNow[var_6_1] or 0) + iter_6_5.harm

					if arg_6_0.alliesADHarmTillNow[var_6_1] > var_6_1:getHpLimit() * 0.3 then
						arg_6_0.alliesADHarmTillNow[var_6_1] = 0

						local var_6_2 = arg_6_0.skinSkillID_ == var_0_23 and var_0_31 or var_0_18
						local var_6_3 = arg_6_0:createAttackUnits({
							arg_6_0
						}, var_6_2)

						for iter_6_6, iter_6_7 in ipairs(var_6_3) do
							table.insert(arg_6_0.moveAttackUnits_, iter_6_7)
							table.insert(arg_6_0.records_.special_units, iter_6_7)
						end

						local var_6_4 = arg_6_0.skinSkillID_ == var_0_23 and var_0_30 or var_0_17
						local var_6_5 = arg_6_0:createAttackUnits({
							var_6_1
						}, var_6_4)

						for iter_6_8, iter_6_9 in ipairs(var_6_5) do
							table.insert(arg_6_0.moveAttackUnits_, iter_6_9)
							table.insert(arg_6_0.records_.special_units, iter_6_9)
						end

						if arg_6_0:getSkillLevelByID(var_0_21) > 0 then
							local var_6_6 = arg_6_0:createAttackUnits({
								var_6_1
							}, var_0_22)

							for iter_6_10, iter_6_11 in ipairs(var_6_6) do
								table.insert(arg_6_0.moveAttackUnits_, iter_6_11)
								table.insert(arg_6_0.records_.special_units, iter_6_11)
							end
						end
					end
				elseif iter_6_5.type == var_0_2.AttackType.AP and var_6_1.hero_:getHeroType() == var_0_2.HeroType.WISE then
					arg_6_0.alliesAPHarmTillNow[var_6_1] = (arg_6_0.alliesAPHarmTillNow[var_6_1] or 0) + iter_6_5.harm

					if arg_6_0.alliesAPHarmTillNow[var_6_1] > var_6_1:getHpLimit() * 0.3 then
						arg_6_0.alliesAPHarmTillNow[var_6_1] = 0

						local var_6_7 = arg_6_0.skinSkillID_ == var_0_23 and var_0_33 or var_0_20
						local var_6_8 = arg_6_0:createAttackUnits({
							var_6_1
						}, var_6_7)

						for iter_6_12, iter_6_13 in ipairs(var_6_8) do
							table.insert(arg_6_0.moveAttackUnits_, iter_6_13)
							table.insert(arg_6_0.records_.special_units, iter_6_13)
						end

						local var_6_9 = arg_6_0.skinSkillID_ == var_0_23 and var_0_32 or var_0_19
						local var_6_10 = arg_6_0:createAttackUnits({
							arg_6_0
						}, var_6_9)

						for iter_6_14, iter_6_15 in ipairs(var_6_10) do
							table.insert(arg_6_0.moveAttackUnits_, iter_6_15)
							table.insert(arg_6_0.records_.special_units, iter_6_15)
						end

						if arg_6_0:getSkillLevelByID(var_0_21) > 0 then
							arg_6_0.nGhostFires = math.min(arg_6_0.nGhostFires + 1, 9)
						end
					end
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	local var_7_0 = arg_7_1.target

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if var_0_7:father(arg_7_1.skillID) == var_0_8 and arg_7_1.skillID ~= var_0_25 and arg_7_1.skillID ~= var_0_12 and arg_7_1.skillID ~= var_0_24 and arg_7_1.skillID ~= var_0_11 then
		if var_7_0:getTeamType() == arg_7_0:getTeamType() then
			local var_7_1 = arg_7_0.skinSkillID_ == var_0_23 and var_0_25 or var_0_12
			local var_7_2 = arg_7_0:createAttackUnits({
				var_7_0
			}, var_7_1)

			for iter_7_0, iter_7_1 in ipairs(var_7_2) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		else
			local var_7_3 = arg_7_0.skinSkillID_ == var_0_23 and var_0_24 or var_0_11
			local var_7_4 = var_0_7:scope(var_7_3) / 2
			local var_7_5 = {}

			for iter_7_2, iter_7_3 in ipairs(arg_7_0.sideTeam_) do
				if not iter_7_3:isDeath() and not iter_7_3:isAffected() and var_7_4 > math.abs(iter_7_3:getX() - var_7_0:getX()) then
					table.insert(var_7_5, iter_7_3)
				end
			end

			local var_7_6 = arg_7_0:createAttackUnits(var_7_5, var_7_3)

			for iter_7_4, iter_7_5 in ipairs(var_7_6) do
				iter_7_5:setExtraHarm(arg_7_0.nGhostFires * arg_7_0:getAP() * 0.11)
				table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
				table.insert(arg_7_0.records_.special_units, iter_7_5)
			end

			local var_7_7 = var_0_1.ctx.battle.getSpine(var_7_3, "area", 1)

			var_7_7:addTo(var_0_1.ctx.battle.unitBottomLayer)
			var_7_7:pos(var_7_0:getX(), var_7_0:getY())
			var_7_7:setScale(0.64)
			var_7_7:playOnce()
		end
	end
end

return var_0_3
