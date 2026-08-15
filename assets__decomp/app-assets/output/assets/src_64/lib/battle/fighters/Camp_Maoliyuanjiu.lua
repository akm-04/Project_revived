local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Maoliyuanjiu", var_0_1.ctx.battle.requireFighter("CampWarBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40010756
local var_0_8 = 40010757
local var_0_9 = 40010759
local var_0_10 = 10000491
local var_0_11 = 10000695
local var_0_12 = 10000696
local var_0_13 = 10000697
local var_0_14 = 200
local var_0_15 = 10000700
local var_0_16 = 5

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	arg_2_0.beginEnergyBack_ = false
	arg_2_0.destinationX_ = nil
	arg_2_0.energyTarget_ = nil
	arg_2_0.blueRemoveTargets_ = {}

	var_0_3.super.init(arg_2_0)
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getEnergySkillID() then
		arg_3_0.destinationX_ = arg_3_0:getX()

		arg_3_0:setImmuneControl(true)
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID ~= arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_4_1.target:isHasBuffByID(var_0_7) and not arg_4_1.target:isHasBuffByID(var_0_8) then
		local var_4_0 = var_0_4.new({
			tableID = var_0_8,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
			skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
			fighter = arg_4_0,
			target = arg_4_1.target
		})

		var_4_0:setIsHit(true)
		var_4_0:setDirection(arg_4_0:getFighterModel():getFlipX())
		var_4_0:setYongJiu()
		arg_4_0:setBlueExtraHarm(var_4_0)
		arg_4_1.target:addBuffs({
			var_4_0
		})
	end

	if arg_4_1.skillID == var_0_11 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_1 = var_0_6:scope(var_0_10)
			local var_4_2 = {}

			for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
				if not iter_4_1:isDeath() and not iter_4_1:isAffected() and math.abs(iter_4_1:getX() - arg_4_1.target:getX()) <= var_4_1 * 0.5 then
					table.insert(var_4_2, iter_4_1)
				end
			end

			local var_4_3 = arg_4_0:createAttackUnits(var_4_2, var_0_10)

			for iter_4_2, iter_4_3 in ipairs(var_4_3) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end

		local var_4_4 = arg_4_0:getX() >= arg_4_1.target:getX() and 1 or -1
		local var_4_5
		local var_4_6 = var_4_4 == 1 and true or false

		arg_4_0:x(arg_4_1.target:getX() + var_4_4 * 50)
		arg_4_0:y(arg_4_1.target:getY())
		arg_4_0:flipX(var_4_6)

		if arg_4_1.target:isHasBuffByID(var_0_9) then
			arg_4_0.energyTarget_ = arg_4_1.target
		end

		arg_4_0.direction_ = var_4_4
	elseif arg_4_1.skillID == var_0_13 then
		arg_4_0.beginEnergyBack_ = true
		arg_4_0.speed_ = math.abs(arg_4_0.destinationX_ - arg_4_0:getX()) / 20
	elseif arg_4_1.skillID == var_0_15 and arg_4_1.target and not arg_4_1.target:isDeath() then
		local var_4_7 = {}

		for iter_4_4 = 1, var_0_16 do
			local var_4_8 = var_0_4.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
				skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
				fighter = arg_4_0,
				target = arg_4_1.target
			})

			var_4_8:setIsHit(true)
			var_4_8:setDirection(arg_4_0:getFighterModel():getFlipX())
			table.insert(var_4_7, var_4_8)
		end

		arg_4_1.target:addBuffs(var_4_7)
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if next(arg_5_0.blueRemoveTargets_) then
		for iter_5_0 = #arg_5_0.blueRemoveTargets_, 1, -1 do
			arg_5_0.blueRemoveTargets_[iter_5_0]:removeBuffByID(var_0_8)
			table.remove(arg_5_0.blueRemoveTargets_, iter_5_0)
		end
	end

	if not arg_5_0.stopTimeCount_ and arg_5_0.beginEnergyBack_ then
		if arg_5_0.energyTarget_ and math.abs(arg_5_0:getX() - arg_5_0.energyTarget_:getX()) >= var_0_14 or arg_5_0:isDeath() then
			arg_5_0.beginEnergyBack_ = false
			arg_5_0.energyTarget_ = nil

			arg_5_0:setImmuneControl(false)
		elseif math.abs(arg_5_0:getX() - arg_5_0.destinationX_) < arg_5_0.speed_ then
			arg_5_0.beginEnergyBack_ = false
			arg_5_0.energyTarget_ = nil

			arg_5_0:setImmuneControl(false)
		elseif arg_5_0.direction_ then
			arg_5_0:moveByX(arg_5_0.direction_ * arg_5_0.speed_)

			if arg_5_0.energyTarget_ then
				arg_5_0.energyTarget_:moveByX(arg_5_0.direction_ * arg_5_0.speed_)
			end
		end
	end

	for iter_5_1, iter_5_2 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
		local var_5_0 = iter_5_2:getTableID()
		local var_5_1 = iter_5_2.target

		if var_5_0 == var_0_7 and var_5_1 and var_5_1:getTeamType() ~= arg_5_0:getTeamType() then
			local var_5_2 = #var_5_1:getBuffsByID(var_0_7)

			for iter_5_3, iter_5_4 in ipairs(var_5_1:getBuffs()) do
				if iter_5_4:getTableID() == var_5_0 then
					iter_5_4.leftCount_ = iter_5_2.leftCount_
				elseif iter_5_4:getTableID() == var_0_8 and var_5_2 > 1 then
					iter_5_4.manualHarmRevise = (var_5_2 - 1) * (var_0_5:baseHarm(var_0_8) + var_0_5:stepBase(var_0_8) * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
				end
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1:getTableID()
	local var_6_1 = arg_6_1.target

	if var_6_0 == var_0_7 then
		table.insert(arg_6_0.blueRemoveTargets_, var_6_1)
	end
end

function var_0_3.isMoveUnable(arg_7_0)
	if arg_7_0.beginEnergyBack_ then
		return false
	else
		return var_0_3.super.isMoveUnable(arg_7_0)
	end
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1 = {}
	local var_8_2 = {}
	local var_8_3

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.targetTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
			if iter_8_1.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI then
				table.insert(var_8_0, iter_8_1)
			elseif iter_8_1.hero_:getDistanceType() == var_0_2.DistanceType.ZHONGPAI then
				table.insert(var_8_1, iter_8_1)
			else
				table.insert(var_8_2, iter_8_1)
			end
		end
	end

	if next(var_8_2) then
		var_8_3 = var_8_2[math.random(1, #var_8_2)]
	elseif next(var_8_1) then
		var_8_3 = var_8_1[math.random(1, #var_8_1)]
	elseif next(var_8_0) then
		var_8_3 = var_8_0[math.random(1, #var_8_0)]
	end

	return {
		var_8_3
	}
end

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_0.energyTarget_ and not arg_9_0.energyTarget_:isDeath() then
		return {
			arg_9_0.energyTarget_
		}
	else
		return {}
	end
end

function var_0_3.addBuffs(arg_10_0, arg_10_1)
	arg_10_0:fliterBuffs(arg_10_1)

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		if iter_10_1:getDHarm() > 0 then
			arg_10_0.showDHarmbuff_ = iter_10_1

			arg_10_0:updateHpBar(true)
		end

		if iter_10_1.fighter then
			iter_10_1.fighter:buffAddAction(iter_10_1)
		end

		if iter_10_1:isCover() and iter_10_1:getDHarm() <= 0 then
			local var_10_0

			for iter_10_2, iter_10_3 in ipairs(arg_10_0.buffs_) do
				if iter_10_3:getTableID() == iter_10_1:getTableID() then
					iter_10_3.leftCount_ = iter_10_1.leftCount_
					var_10_0 = true

					break
				end
			end

			if not var_10_0 then
				arg_10_0:distributeBuff(iter_10_1)
				arg_10_0.fighterModel:addBuffs({
					iter_10_1
				})
			end
		else
			arg_10_0:distributeBuff(iter_10_1)
			arg_10_0.fighterModel:addBuffs({
				iter_10_1
			})
		end

		arg_10_0:specialBuffCheck(iter_10_1)
	end
end

function var_0_3.setBlueExtraHarm(arg_11_0, arg_11_1)
	local var_11_0 = #arg_11_0:getBuffsByID(var_0_7)

	if var_11_0 > 1 then
		arg_11_1.manualHarmRevise = (var_11_0 - 1) * (var_0_5:baseHarm(var_0_8) + var_0_5:stepBase(var_0_8) * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	end
end

return var_0_3
