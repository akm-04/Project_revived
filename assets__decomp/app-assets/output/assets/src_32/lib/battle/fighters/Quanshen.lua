local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Quanshen", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 90
local var_0_8 = 150
local var_0_9 = 40011581
local var_0_10 = 10001536
local var_0_11 = 40011582
local var_0_12 = 40011583
local var_0_13 = 10001518
local var_0_14 = 40011587
local var_0_15 = 0
local var_0_16 = 5
local var_0_17 = 40011588
local var_0_18 = 30
local var_0_19 = 90

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("action_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.AddSkinExtarBuffTime = {}
end

function var_0_3.selectTargetByTypeD2(arg_3_0, arg_3_1, arg_3_2)
	local function var_3_0(arg_4_0)
		local var_4_0 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_3_0.targetTeam_) do
			if iter_4_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1.hero_:getHeroType() == arg_4_0 then
				table.insert(var_4_0, iter_4_1)
			end
		end

		return var_4_0
	end

	local var_3_1 = var_3_0(var_0_2.HeroType.WISE)

	if not next(var_3_1) then
		if var_0_2.weightedChoise({
			0.5,
			0.5
		}) == 1 then
			var_3_1 = var_3_0(var_0_2.HeroType.STRENGTH)

			if not next(var_3_1) then
				var_3_1 = var_3_0(var_0_2.HeroType.AGILE)
			end
		else
			var_3_1 = var_3_0(var_0_2.HeroType.AGILE)

			if not next(var_3_1) then
				var_3_1 = var_3_0(var_0_2.HeroType.STRENGTH)
			end
		end
	end

	return var_3_1
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("action_info")) do
		if iter_5_1.action_type == var_0_2.ActionType.attack then
			local var_5_0 = iter_5_1.fighter:getBuffByID(var_0_9)

			if var_5_0 and var_5_0.fighter == arg_5_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_1 = arg_5_0:createAttackUnits({
					iter_5_1.fighter
				}, var_0_10)

				for iter_5_2, iter_5_3 in ipairs(var_5_1) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
					table.insert(arg_5_0.records_.special_units, iter_5_3)
				end
			end

			local var_5_2 = iter_5_1.fighter:getBuffByID(var_0_11)

			if var_5_2 and var_5_2.fighter == arg_5_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_3 = arg_5_0:createAttackUnits({
					iter_5_1.fighter
				}, var_0_13)

				for iter_5_4, iter_5_5 in ipairs(var_5_3) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
					table.insert(arg_5_0.records_.special_units, iter_5_5)
				end
			end
		end
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_5_0:isHasBuffByID(var_0_14) then
		arg_5_0:addBuffs({
			var_0_4.new({
				tableID = var_0_14,
				start = var_0_1.ctx.battle.count,
				level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_5_0,
				target = arg_5_0
			})
		})
	end

	local var_5_4 = arg_5_0:getBuffByID(var_0_14)

	if var_5_4 then
		local var_5_5 = 0

		for iter_5_6, iter_5_7 in ipairs(arg_5_0.sideTeam_) do
			if var_5_5 == 5 then
				break
			end

			if iter_5_7:getSummonType() == var_0_2.summonMonsterType.None and iter_5_7:getDebuffNum() > 0 then
				var_5_5 = var_5_5 + 1
			end
		end

		for iter_5_8, iter_5_9 in ipairs(arg_5_0.selfTeam_) do
			if var_5_5 == 5 then
				break
			end

			if iter_5_9:getSummonType() == var_0_2.summonMonsterType.None and iter_5_9:getDebuffNum() > 0 then
				var_5_5 = var_5_5 + 1
			end
		end

		var_5_4.manualRevise = var_5_5 * (arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_16 + var_0_15)
		arg_5_0.___attrCache[var_5_4:getAttrType()] = nil

		if var_5_5 == 5 and not arg_5_0:isHasBuffByID(var_0_17) then
			arg_5_0:addBuffs({
				var_0_4.new({
					tableID = var_0_17,
					start = var_0_1.ctx.battle.count,
					level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
					skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
					fighter = arg_5_0,
					target = arg_5_0
				})
			})
		end
	end

	if arg_5_0.skinSkillIndex_ == 1 then
		for iter_5_10, iter_5_11 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
			if iter_5_11.fighter:getTeamType() == arg_5_0:getTeamType() and (iter_5_11:dBuffType() > 0 or iter_5_11:getBuffForm() == var_0_2.BuffForm.DEBUFF) and (not arg_5_0.AddSkinExtarBuffTime[iter_5_11.fighter] or var_0_1.ctx.battle.count - arg_5_0.AddSkinExtarBuffTime[iter_5_11.fighter] > var_0_19) then
				iter_5_11:setExtraTime(var_0_18)

				if iter_5_11.fighter ~= arg_5_0 then
					arg_5_0.AddSkinExtarBuffTime[iter_5_11.fighter] = var_0_1.ctx.battle.count
				end
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_1 and arg_6_1.rootID_ == arg_6_0:getEnergySkillID() then
		local var_6_0 = 0
		local var_6_1 = 0
		local var_6_2 = var_0_5.B2(arg_6_0, arg_6_1)

		if #var_6_2 > 0 then
			for iter_6_0, iter_6_1 in ipairs(var_6_2) do
				var_6_0 = var_6_0 + iter_6_1:getX()
				var_6_1 = var_6_1 + iter_6_1:getY()
			end

			local var_6_3 = var_6_0 / #var_6_2
			local var_6_4 = var_6_1 / #var_6_2

			arg_6_0.energyEffect = var_0_1.ctx.battle.getSpine(arg_6_0:getEnergySkillID(), "area", 1)

			arg_6_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_6_0.energyEffect:pos(var_6_3 + arg_6_0.energyEffect:getSizeX() / 2, var_6_4 + 125)
			arg_6_0.energyEffect:setScale(1)
			arg_6_0.energyEffect:playOnce()
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0:getEnergySkillID() then
		if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
			for iter_7_0, iter_7_1 in ipairs(var_0_6:buffs(arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))) do
				local var_7_0 = arg_7_1.target:getBuffsByID(iter_7_1)

				if next(var_7_0) then
					for iter_7_2, iter_7_3 in ipairs(var_7_0) do
						iter_7_3.leftCount_ = iter_7_3.leftCount_ + var_0_7
					end
				else
					arg_7_1.target:addBuffs({
						var_0_4.new({
							tableID = iter_7_1,
							start = var_0_1.ctx.battle.count,
							level = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
							skillID = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
							fighter = arg_7_0,
							target = arg_7_1.target
						})
					})
				end
			end
		end

		if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
			for iter_7_4, iter_7_5 in ipairs(var_0_6:buffs(arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))) do
				local var_7_1 = arg_7_1.target:getBuffsByID(iter_7_5)

				if next(var_7_1) then
					for iter_7_6, iter_7_7 in ipairs(var_7_1) do
						iter_7_7.leftCount_ = iter_7_7.leftCount_ + var_0_8
					end
				else
					arg_7_1.target:addBuffs({
						var_0_4.new({
							tableID = iter_7_5,
							start = var_0_1.ctx.battle.count,
							level = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
							skillID = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
							fighter = arg_7_0,
							target = arg_7_1.target
						})
					})
				end
			end
		end
	end
end

return var_0_3
