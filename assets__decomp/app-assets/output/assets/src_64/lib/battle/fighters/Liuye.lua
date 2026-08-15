local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liuye", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 40011655
local var_0_9 = 40011656
local var_0_10 = 40011657
local var_0_11 = 10001572
local var_0_12 = 10001575
local var_0_13 = 40011658
local var_0_14 = 40011659
local var_0_15 = 40011660
local var_0_16 = 30
local var_0_17 = 450
local var_0_18 = 150
local var_0_19 = 0.15
local var_0_20 = 0.05
local var_0_21 = 10001573
local var_0_22 = 40011663
local var_0_23 = 40011662
local var_0_24 = 40011661
local var_0_25 = 0.2
local var_0_26 = 0.2
local var_0_27 = 10002277
local var_0_28 = 10002278

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillCount = 0
	arg_1_0.greenBuffCount = 0
	arg_1_0.blueBuffCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.purpleSkillCount < var_0_17 then
		arg_2_0.purpleSkillCount = arg_2_0.purpleSkillCount + 1
	else
		arg_2_0.purpleSkillCount = 0
		arg_2_0.greenBuffCount = 0

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() then
				arg_2_0.greenBuffCount = arg_2_0.greenBuffCount + #iter_2_1:getBuffsByID(var_0_8)
				arg_2_0.greenBuffCount = arg_2_0.greenBuffCount + #iter_2_1:getBuffsByID(var_0_9)
				arg_2_0.greenBuffCount = arg_2_0.greenBuffCount + #iter_2_1:getBuffsByID(var_0_10)
			end
		end

		arg_2_0.blueBuffCount = 0

		for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_3:isDeath() then
				arg_2_0.blueBuffCount = arg_2_0.blueBuffCount + #iter_2_3:getBuffsByID(var_0_13)
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getEnergySkillID() then
		arg_3_0:addBuffs({
			var_0_5.new({
				tableID = var_0_24,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
				fighter = arg_3_0,
				target = arg_3_0
			})
		})
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.skillID
	local var_4_1 = arg_4_1.target

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if var_4_1.hero_:getHeroType() == var_0_2.HeroType.STRENGTH then
			var_4_1:addBuffs({
				var_0_5.new({
					tableID = var_0_9,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
					fighter = arg_4_0,
					target = var_4_1
				})
			})
		elseif var_4_1.hero_:getHeroType() == var_0_2.HeroType.WISE then
			var_4_1:addBuffs({
				var_0_5.new({
					tableID = var_0_8,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
					fighter = arg_4_0,
					target = var_4_1
				})
			})
		else
			var_4_1:addBuffs({
				var_0_5.new({
					tableID = var_0_10,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
					fighter = arg_4_0,
					target = var_4_1
				})
			})
		end
	elseif var_4_0 == arg_4_0:getPugongID() then
		local var_4_2 = var_4_1:getBuffByID(var_0_13)
		local var_4_3 = var_4_1:getBuffByID(var_0_14)

		if var_4_2 then
			var_4_2.leftCount_ = var_4_2.leftCount_ + var_0_16
		end

		if var_4_3 then
			var_4_3.leftCount_ = var_4_3.leftCount_ + var_0_16
		end
	elseif var_4_0 == arg_4_0:getEnergySkillID() then
		if arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_4 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_21)

			for iter_4_0, iter_4_1 in ipairs(var_4_4) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end

		local var_4_5 = var_4_1:getBuffByID(var_0_22)

		if var_4_5 then
			var_4_5.resetXchange_ = (arg_4_0:getX() - var_4_1:getX() + (arg_4_0:getFlipX() and -95 or 95)) * (arg_4_0:getFlipX() and -1 or 1)
			var_4_5.resetYchange_ = arg_4_0:getY() - var_4_1:getY()
			var_4_1.buffMovePath_ = var_4_5:getPath()
		end

		local var_4_6 = var_4_1:getBuffByID(var_0_8)
		local var_4_7 = var_4_1:getBuffByID(var_0_9)
		local var_4_8 = var_4_1:getBuffByID(var_0_10)

		if var_4_6 and var_4_6.fighter == arg_4_0 or var_4_7 and var_4_7.fighter == arg_4_0 or var_4_8 and var_4_8.fighter == arg_4_0 then
			var_4_1:addBuffs({
				var_0_5.new({
					tableID = var_0_24,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
					fighter = arg_4_0,
					target = var_4_1
				})
			})
		end

		local var_4_9 = var_4_1:getBuffByID(var_0_13)
		local var_4_10 = var_4_1:getBuffByID(var_0_14)

		if var_4_9 and var_4_9.fighter == arg_4_0 or var_4_10 and var_4_10.fighter == arg_4_0 then
			var_4_1:addBuffs({
				var_0_5.new({
					tableID = var_0_23,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
					fighter = arg_4_0,
					target = var_4_1
				})
			})
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == var_0_24 then
		arg_5_1.manualDharm = arg_5_1.target:getHp() * var_0_25
	end

	if arg_5_0.skinSkillIndex_ == 1 and (arg_5_1:getTableID() == var_0_8 or arg_5_1:getTableID() == var_0_9 or arg_5_1:getTableID() == var_0_10 or arg_5_1:getTableID() == var_0_13 or arg_5_1:getTableID() == var_0_14) then
		local var_5_0 = (var_0_7:time(arg_5_1:getTableID()) + arg_5_1:getLevel() * arg_5_1:getTimeStep()) * var_0_26

		arg_5_1:setExtraTime(var_5_0)
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_9 or arg_6_1:getTableID() == var_0_8 or arg_6_1:getTableID() == var_0_10 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_0 = arg_6_0:createAttackUnits({
				arg_6_1.target
			}, var_0_11)

			for iter_6_0, iter_6_1 in ipairs(var_6_0) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	elseif arg_6_1:getTableID() == var_0_24 and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_6_1 = var_0_6:scope(arg_6_0:getEnergySkillID()) / 2

		for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_3:isDeath() and not iter_6_3:isAffected() and var_6_1 > math.abs(iter_6_3:getX() - arg_6_0:getX()) then
				iter_6_3:addBuffs({
					var_0_5.new({
						tableID = var_0_14,
						start = var_0_1.ctx.battle.count,
						level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
						skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
						fighter = arg_6_0,
						target = iter_6_3
					}),
					var_0_5.new({
						tableID = var_0_13,
						start = var_0_1.ctx.battle.count,
						level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
						skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
						fighter = arg_6_0,
						target = iter_6_3
					})
				})
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0 = arg_7_1.target
	local var_7_1 = arg_7_1.fighter
	local var_7_2 = var_7_0:getBuffByID(var_0_13)
	local var_7_3 = var_7_0:getBuffByID(var_0_14)

	if arg_7_1.fighter:getTeamType() == arg_7_0:getTeamType() and arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() and (var_7_2 and var_7_2.fighter == arg_7_0 or var_7_3 and var_7_3.fighter == arg_7_0) and arg_7_4 > 0 then
		local var_7_4 = arg_7_0:createAttackUnits({
			var_7_0
		}, var_0_12)

		for iter_7_0, iter_7_1 in ipairs(var_7_4) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		if arg_7_0.skinSkillIndex_ == 1 then
			local var_7_5 = var_0_27

			if var_7_1:isHasBuffByID(var_0_8) or var_7_1:isHasBuffByID(var_0_8) or var_7_1:isHasBuffByID(var_0_8) then
				var_7_5 = var_0_28
			end

			local var_7_6 = arg_7_0:createAttackUnits({
				var_7_1
			}, var_7_5)

			for iter_7_2, iter_7_3 in ipairs(var_7_6) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end

	if arg_7_0.purpleSkillCount < var_0_18 then
		if var_7_0:getTeamType() == arg_7_0:getTeamType() and arg_7_4 > 0 then
			arg_7_7 = arg_7_7 + arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_19 * math.min(arg_7_0.greenBuffCount, 5)
		end

		if var_7_0:getTeamType() ~= arg_7_0:getTeamType() and arg_7_4 > 0 then
			arg_7_4 = arg_7_4 + arg_7_4 * var_0_20 * math.min(arg_7_0.blueBuffCount, 5)
		end
	end

	if arg_7_1.fighter == arg_7_0 and var_7_0:getTeamType() == arg_7_0:getTeamType() then
		arg_7_4 = 0
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.selectTargetByTypeD5(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = var_0_6:distance(arg_8_1)
	local var_8_1 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and (arg_8_0:getFlipX() and arg_8_0:getX() > iter_8_1:getX() and var_8_0 > arg_8_0:getX() - iter_8_1:getX() or arg_8_0:getX() < iter_8_1:getX() and var_8_0 > iter_8_1:getX() - arg_8_0:getX()) then
			table.insert(var_8_1, iter_8_1)
		end
	end

	for iter_8_2, iter_8_3 in ipairs(arg_8_0.targetTeam_) do
		if not iter_8_3:isDeath() and not iter_8_3:isAffected() and (arg_8_0:getFlipX() and arg_8_0:getX() > iter_8_3:getX() and var_8_0 > arg_8_0:getX() - iter_8_3:getX() or arg_8_0:getX() < iter_8_3:getX() and var_8_0 > iter_8_3:getX() - arg_8_0:getX()) then
			table.insert(var_8_1, iter_8_3)
		end
	end

	return var_8_1
end

return var_0_3
