local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Haimudaer", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = 40011818
local var_0_9 = 0.7
local var_0_10 = 40011812
local var_0_11 = 10001721
local var_0_12 = 40011826
local var_0_13 = 0.2
local var_0_14 = 0.005
local var_0_15 = 40011825
local var_0_16 = 10001720
local var_0_17 = 810004
local var_0_18 = 2
local var_0_19 = 250
local var_0_20 = 0.75
local var_0_21 = {
	Purple = 1,
	Heart = 3,
	Skin = 2
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.gears = {}
	arg_2_0.hearts = {}
	arg_2_0.ally2Reborn = {}
	arg_2_0.allyReborned = {}
	arg_2_0.rebornFuncApplied = false
	arg_2_0.zqsj = false
	arg_2_0.rebornOnce = false
	arg_2_0.skinRebornCount = var_0_18
	arg_2_0.selfRebornType = nil
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillIndex_ == 1 then
		arg_3_0.SummonHeartID = 80000322
		arg_3_0.SummonGearID = 80000323
		arg_3_0.GreenSubSkill = 10002127
		arg_3_0.EnergyRebornSkill = 10002128
		arg_3_0.GreenMarkBuff = 40012265
	else
		arg_3_0.SummonHeartID = 80000306
		arg_3_0.SummonGearID = 80000307
		arg_3_0.GreenSubSkill = 10001717
		arg_3_0.EnergyRebornSkill = 10001719
		arg_3_0.GreenMarkBuff = 40011811
	end
end

function var_0_3.energyAction(arg_4_0, arg_4_1)
	var_0_3.super.energyAction(arg_4_0, arg_4_1)

	if var_0_4:father(arg_4_1) == arg_4_0:getEnergySkillID() then
		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport and not var_0_1.ctx.battle.isUnlimitBattle then
			var_0_1.ctx.battle.setupBackground("zqsj.png")
		end

		arg_4_0.zqsj = true

		local var_4_0 = math.min(#arg_4_0.ally2Reborn, math.min(#arg_4_0.hearts, math.floor(#arg_4_0.gears / 2)))

		while var_4_0 > 0 do
			var_4_0 = var_4_0 - 1

			arg_4_0.hearts[#arg_4_0.hearts]:forceDie()
			table.remove(arg_4_0.hearts, #arg_4_0.hearts)
			arg_4_0.gears[#arg_4_0.gears]:forceDie()
			table.remove(arg_4_0.gears, #arg_4_0.gears)
			arg_4_0.gears[#arg_4_0.gears]:forceDie()
			table.remove(arg_4_0.gears, #arg_4_0.gears)

			local var_4_1 = arg_4_0.ally2Reborn[#arg_4_0.ally2Reborn]

			table.remove(arg_4_0.ally2Reborn, #arg_4_0.ally2Reborn)
			var_4_1:removeBuffByID(var_0_8)
			var_4_1:updateHp(var_4_1:getHpLimit())

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_2 = arg_4_0:createAttackUnits({
					var_4_1
				}, arg_4_0.EnergyRebornSkill)

				for iter_4_0, iter_4_1 in ipairs(var_4_2) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end
			end

			table.insert(arg_4_0.allyReborned, var_4_1)
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_1:getTableID() == var_0_10 and arg_5_0.zqsj then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, var_0_11)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_6_0 = var_0_4:scope(arg_6_0.GreenSubSkill)
		local var_6_1 = {}

		if arg_6_1.target:getX() < arg_6_0:getX() then
			for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
				if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getX() <= arg_6_1.target:getX() and var_6_0 >= arg_6_1.target:getX() - iter_6_1:getX() and iter_6_1 ~= arg_6_1.target then
					table.insert(var_6_1, iter_6_1)
				end
			end
		else
			for iter_6_2, iter_6_3 in ipairs(arg_6_0.targetTeam_) do
				if not iter_6_3:isDeath() and not iter_6_3:isAffected() and iter_6_3:getX() >= arg_6_1.target:getX() and var_6_0 >= iter_6_3:getX() - arg_6_1.target:getX() and iter_6_3 ~= arg_6_1.target then
					table.insert(var_6_1, iter_6_3)
				end
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, arg_6_0.GreenSubSkill)

			for iter_6_4, iter_6_5 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
				table.insert(arg_6_0.records_.special_units, iter_6_5)
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_7_0)
	if arg_7_0.skinRebornCount ~= 0 and arg_7_0.skinSkillID_ ~= var_0_17 then
		arg_7_0.skinRebornCount = 0
	end

	if arg_7_0:isDeath() then
		return
	end

	if not arg_7_0.rebornFuncApplied then
		arg_7_0.rebornFuncApplied = true

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if iter_7_1 ~= arg_7_0 and not iter_7_1:isDeath() and not iter_7_1.rebornFuncApplied and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
				iter_7_1.rebornFuncApplied = true

				local var_7_0 = iter_7_1.forceDie

				function iter_7_1.forceDie(arg_8_0)
					if not arg_7_0:isDeath() and not arg_8_0.battleEndDie then
						arg_8_0:updateEnergyTo(0)
						arg_8_0:deathFeedbacks()
						arg_8_0:deadForceRemoveSkill()
						arg_8_0:cleanAllBuffs()
						arg_8_0:updateStateNumber()

						if arg_7_0:getTeamType() == var_0_2.TeamType.A and arg_7_0.bottomWnd then
							arg_7_0.bottomWnd:updateUIEffect(arg_8_0, var_0_1.ctx.battle.teamA, false)
						end

						arg_8_0:addBuffs({
							var_0_7.new({
								tableID = var_0_8,
								start = var_0_1.ctx.battle.count,
								level = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
								skillID = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
								fighter = arg_7_0,
								target = arg_8_0
							})
						})
						arg_8_0:updateHp(0)

						local var_8_0 = arg_7_0:setSummonMonsters(arg_7_0.SummonHeartID, nil, nil, {
							x = arg_8_0:getX(),
							y = arg_8_0:getY()
						}, arg_7_0:getEnergySkillID())

						table.insert(arg_7_0.hearts, var_8_0)
						table.insert(arg_7_0.ally2Reborn, arg_8_0)
					else
						var_7_0(arg_8_0)
					end
				end
			end
		end
	end

	for iter_7_2, iter_7_3 in ipairs(arg_7_0:getInfoByKey("attack_info")) do
		if var_0_4:father(iter_7_3.rootID_) == iter_7_3.fighter_:getEnergySkillID() then
			local var_7_1 = arg_7_0:setSummonMonsters(arg_7_0.SummonGearID, nil, nil, {
				x = iter_7_3.fighter_:getX(),
				y = iter_7_3.fighter_:getY()
			}, arg_7_0:getEnergySkillID())

			table.insert(arg_7_0.gears, var_7_1)
		end
	end

	for iter_7_4, iter_7_5 in ipairs(arg_7_0:getInfoByKey("buff_info")) do
		if iter_7_5.target and not iter_7_5.target:isDeath() and iter_7_5.target:getTeamType() ~= arg_7_0:getTeamType() and iter_7_5:canRemove() and iter_7_5.target:isHasBuffByID(arg_7_0.GreenMarkBuff) and (iter_7_5:getBuffForm() == var_0_2.BuffForm.GAIN or iter_7_5:getDHarm() > 0) then
			iter_7_5.target:removeBuffByID(arg_7_0.GreenMarkBuff)

			local var_7_2 = var_0_5.A3(arg_7_0)[1]

			if var_7_2 then
				local var_7_3 = var_0_7.new({
					tableID = iter_7_5:getTableID(),
					start = var_0_1.ctx.battle.count,
					level = iter_7_5.level_,
					skillID = iter_7_5.skillID_,
					fighter = arg_7_0,
					target = var_7_2
				})

				var_7_3.manualRevise = iter_7_5.manualRevise or 0
				var_7_3.manualHarmRevise = iter_7_5.manualHarmRevise or 0
				var_7_3.manualDharm = iter_7_5.manualDharm or 0
				var_7_3.extraTime_ = iter_7_5.extraTime_
				var_7_3.leftCount_ = iter_7_5.leftCount_ * var_0_9

				var_7_2:addBuffs({
					var_7_3
				})
			end

			iter_7_5.target:removeBuffs(iter_7_5)
		end
	end
end

function var_0_3.setSummonMonsters(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	local var_9_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0 = arg_9_0:getSummonMonster()
	else
		local var_9_1 = var_0_6.new()

		var_9_1:populateWithTableID(arg_9_1)

		var_9_1.level_ = arg_9_2 or var_9_1.level_
		var_9_1.color_ = arg_9_3 or var_9_1.color_

		for iter_9_0, iter_9_1 in ipairs(var_9_1.skillLev_) do
			local var_9_2 = arg_9_0.hero_:getSkillLevel(iter_9_0)

			if var_9_2 and var_9_2 > 0 then
				var_9_1.skillLev_[iter_9_0] = var_0_0.clone(var_9_2)
			end
		end

		local var_9_3 = var_9_1:className()

		var_9_0 = var_0_1.ctx.battle.requireFighter(var_9_3).new({
			is_arena = arg_9_0.isInArena_
		})

		var_9_0:populateWithHero(var_9_1)
		var_9_0:initModels()
		var_9_0.fighterModel:initHeaderView(arg_9_0:getTeamType() - 1)

		var_9_0.fighterIndex = arg_9_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_9_0:setFormationDelay(0, 50)
	end

	if var_9_0 then
		var_9_0:setTeamType(arg_9_0:getTeamType())

		var_9_0.summoner = arg_9_0

		var_9_0.fighterModel:pos(arg_9_4.x, arg_9_4.y)

		var_9_0.isImmuneControl = true

		var_9_0:updateHp(var_9_0:getHpLimit())
		var_9_0:getFighterModel():flipX(arg_9_0:getTeamType() == var_0_2.TeamType.B)
		var_9_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
		var_9_0:born()
		var_9_0:setGlobalBuffs()

		local var_9_4 = var_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

		table.insert(var_9_4, var_9_0)
		table.insert(var_0_1.ctx.battle.yOrder, var_9_0)
		var_0_1.ctx.battle.updateZorder()

		function var_9_0.isAffected(arg_10_0)
			return true
		end

		function var_9_0.isMoveUnable(arg_11_0)
			return true
		end
	end

	return var_9_0
end

function var_0_3.forceDie(arg_12_0)
	if (arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 or arg_12_0.skinSkillID_ == var_0_17) and (#arg_12_0.hearts > 0 or not arg_12_0.rebornOnce or arg_12_0.skinRebornCount > 0) or arg_12_0:isHasBuffByID(var_0_12) then
		arg_12_0:updateHp(1)

		if not arg_12_0:isHasBuffByID(var_0_12) then
			local var_12_0 = var_0_7.new({
				tableID = var_0_12,
				start = var_0_1.ctx.battle.count,
				level = arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_12_0,
				target = arg_12_0
			})

			var_12_0.manualHarmRevise = arg_12_0:getHpLimit() / math.ceil(var_12_0.leftCount_ / 30)

			if arg_12_0.skinRebornCount > 0 then
				arg_12_0.skinRebornCount = arg_12_0.skinRebornCount - 1
				arg_12_0.selfRebornType = var_0_21.Skin
			elseif #arg_12_0.hearts <= 0 and not arg_12_0.rebornOnce then
				arg_12_0.rebornOnce = true
				arg_12_0.selfRebornType = var_0_21.Purple
			else
				arg_12_0.hearts[#arg_12_0.hearts]:forceDie()
				table.remove(arg_12_0.hearts, #arg_12_0.hearts)

				arg_12_0.selfRebornType = var_0_21.Heart
			end

			arg_12_0:addBuffs({
				var_12_0
			})
		end
	else
		if arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_12_1 = arg_12_0:createAttackUnits(arg_12_0.allyReborned, var_0_16)

				for iter_12_0, iter_12_1 in ipairs(var_12_1) do
					table.insert(arg_12_0.moveAttackUnits_, iter_12_1)
					table.insert(arg_12_0.records_.special_units, iter_12_1)
				end
			end
		else
			for iter_12_2, iter_12_3 in ipairs(arg_12_0.allyReborned) do
				if iter_12_3 and not iter_12_3:isDeath() then
					iter_12_3:forceDie()
				end
			end
		end

		for iter_12_4, iter_12_5 in ipairs(arg_12_0.gears) do
			if iter_12_5 and not iter_12_5:isDeath() then
				iter_12_5:forceDie()
			end
		end

		for iter_12_6, iter_12_7 in ipairs(arg_12_0.hearts) do
			if iter_12_7 and not iter_12_7:isDeath() then
				iter_12_7:forceDie()
			end
		end

		for iter_12_8, iter_12_9 in ipairs(arg_12_0.ally2Reborn) do
			if iter_12_9 and not iter_12_9:isDeath() then
				iter_12_9:forceDie()
			end
		end

		var_0_3.super.forceDie(arg_12_0)
	end
end

function var_0_3.buffRemoveAction(arg_13_0, arg_13_1)
	if arg_13_1:getTableID() == var_0_15 then
		if arg_13_1.target and not arg_13_1.target:isDeath() then
			arg_13_1.target:forceDie()
		end
	elseif arg_13_1:getTableID() == var_0_12 then
		arg_13_1.target:updateHp(arg_13_1.target:getHpLimit())

		if arg_13_0.selfRebornType == var_0_21.Skin then
			arg_13_0:updateEnergyBy(var_0_19)
		end
	end
end

function var_0_3.getHpLimit(arg_14_0)
	if arg_14_0.selfRebornType == var_0_21.Purple then
		return var_0_3.super.getHpLimit(arg_14_0) * (var_0_13 + var_0_14 * arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	elseif arg_14_0.selfRebornType == var_0_21.Skin then
		return var_0_3.super.getHpLimit(arg_14_0) * var_0_20
	else
		return var_0_3.super.getHpLimit(arg_14_0)
	end
end

function var_0_3.getAD(arg_15_0)
	if arg_15_0.selfRebornType == var_0_21.Purple then
		return var_0_3.super.getAD(arg_15_0) * (var_0_13 + var_0_14 * arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	elseif arg_15_0.selfRebornType == var_0_21.Skin then
		return var_0_3.super.getAD(arg_15_0) * var_0_20
	else
		return var_0_3.super.getAD(arg_15_0)
	end
end

function var_0_3.getAP(arg_16_0)
	if arg_16_0.selfRebornType == var_0_21.Purple then
		return var_0_3.super.getAP(arg_16_0) * (var_0_13 + var_0_14 * arg_16_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	elseif arg_16_0.selfRebornType == var_0_21.Skin then
		return var_0_3.super.getAP(arg_16_0) * var_0_20
	else
		return var_0_3.super.getAP(arg_16_0)
	end
end

function var_0_3.processAfterBattleEnd(arg_17_0, arg_17_1)
	if not arg_17_1 then
		for iter_17_0, iter_17_1 in ipairs(arg_17_0.ally2Reborn) do
			if iter_17_1 and not iter_17_1:isDeath() then
				iter_17_1.battleEndDie = true

				iter_17_1:forceDie()
			end
		end

		arg_17_0.ally2Reborn = {}
	end

	for iter_17_2, iter_17_3 in ipairs(arg_17_0.gears) do
		if iter_17_3 and not iter_17_3:isDeath() then
			iter_17_3:forceDie()
		end
	end

	for iter_17_4, iter_17_5 in ipairs(arg_17_0.hearts) do
		if iter_17_5 and not iter_17_5:isDeath() then
			iter_17_5:forceDie()
		end
	end

	arg_17_0.gears = {}
	arg_17_0.hearts = {}
end

return var_0_3
