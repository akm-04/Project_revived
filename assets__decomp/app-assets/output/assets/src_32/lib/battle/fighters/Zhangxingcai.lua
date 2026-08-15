local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangxingcai", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 10020211
local var_0_9 = 10001372
local var_0_10 = 10001374
local var_0_11 = 10001443
local var_0_12 = 10001444
local var_0_13 = 40011453
local var_0_14 = 10001373
local var_0_15 = 30010211
local var_0_16 = 30010211
local var_0_17 = 10001441
local var_0_18 = 10001370
local var_0_19 = 10001371
local var_0_20 = 3
local var_0_21 = 50010211
local var_0_22 = 10001375
local var_0_23 = 40011454
local var_0_24 = 500
local var_0_25 = 200
local var_0_26 = 40011455
local var_0_27 = 80010211
local var_0_28 = 10001376
local var_0_29 = 40011451
local var_0_30 = var_0_2.tables.elementEquip
local var_0_31 = 20001479
local var_0_32 = 10002275
local var_0_33 = 40012467
local var_0_34 = 0.2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.enterSkillCount_ = var_0_7:pretime(var_0_16)
	arg_1_0.enemiesInBlueRegion = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_0.BlueEffect and not var_0_1.ctx.battle.walk2NextBattle_ then
		local var_2_0 = arg_2_0.BlueEffect:getX()
		local var_2_1 = var_0_7:scope(var_0_15) / 2

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				if var_2_1 > math.abs(iter_2_1:getX() - var_2_0) then
					if not arg_2_0.enemiesInBlueRegion[iter_2_1] then
						arg_2_0.enemiesInBlueRegion[iter_2_1] = true

						local var_2_2 = arg_2_0:createAttackUnits({
							iter_2_1
						}, var_0_18)

						for iter_2_2, iter_2_3 in ipairs(var_2_2) do
							table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
							table.insert(arg_2_0.records_.special_units, iter_2_3)
						end

						local var_2_3 = arg_2_0:createAttackUnits({
							arg_2_0
						}, var_0_19)

						for iter_2_4, iter_2_5 in ipairs(var_2_3) do
							table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
							table.insert(arg_2_0.records_.special_units, iter_2_5)
						end

						if arg_2_0:hasElementEquipByID(var_0_31) then
							local var_2_4 = arg_2_0:createAttackUnits({
								arg_2_0
							}, var_0_32)

							for iter_2_6, iter_2_7 in ipairs(var_2_4) do
								table.insert(arg_2_0.moveAttackUnits_, iter_2_7)
								table.insert(arg_2_0.records_.special_units, iter_2_7)
							end
						end
					end
				else
					arg_2_0.enemiesInBlueRegion[iter_2_1] = false
				end
			end
		end
	end

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.unitSkills_ and arg_2_0.unitSkills_.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_2_5 = arg_2_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

		arg_2_0:x(arg_2_0:getX() + var_2_5 * var_0_20)
	end
end

function var_0_3.checkMove(arg_3_0)
	if arg_3_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_3_0.hero_:enterDuration() then
			arg_3_0.isWalking_ = 1

			if not arg_3_0:isWalking() then
				arg_3_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_3_0:isWalking() == 2 then
				local var_3_0 = arg_3_0:getFlipX() and -1 or 1

				arg_3_0:moveByX(arg_3_0.hero_:enterSpeed() * var_3_0)
			end

			if arg_3_0:getCurrentAnimation() ~= "run" then
				arg_3_0:modelWalk()
			end
		elseif not arg_3_0.playedEnterSkill_ then
			if arg_3_0:isWalking() ~= 3 then
				arg_3_0.preWalk_ = false
				arg_3_0.isWalking_ = false
				arg_3_0.behindWalk_ = false
				arg_3_0.playedEnterSkill_ = true
				arg_3_0.walk2Position_ = false

				if arg_3_0:getCurrentAnimation() == "run" then
					arg_3_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_3_0.hero_:enterDelayDuration() then
			arg_3_0.isEnterSkill_ = nil
			arg_3_0.walk2Position_ = false
			arg_3_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_3_0)
end

function var_0_3.setFormation(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	arg_4_0.isEnterSkill_ = arg_4_0:enterSkill() > 0 and arg_4_0:getSkillLevelByID(arg_4_0:enterSkill()) > 0

	if arg_4_0.isEnterSkill_ then
		arg_4_0.playedEnterSkill_ = false

		local var_4_0 = arg_4_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_4_0:x(var_4_0)
		arg_4_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_4_3 - 90 * (arg_4_2 % 2))

		return arg_4_2 + 1
	end

	return var_0_3.super.setFormation(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
end

function var_0_3.enterSkill(arg_5_0)
	return arg_5_0.hero_:enterSkill()
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == var_0_17 then
		arg_6_0.BlueEffect = var_0_1.ctx.battle.getSpine(var_0_15, "area", 1)

		arg_6_0.BlueEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_6_0.BlueEffect:pos(arg_6_0:getTeamType() == var_0_2.TeamType.B and 120 or var_0_2.STAGE_WIDTH - 120, var_0_2.STAGE_HEIGHT / 2)
		arg_6_0.BlueEffect:setScale(0.5)
		arg_6_0.BlueEffect:playRepeat()
	end

	local var_6_0 = arg_6_1.target

	if arg_6_1.skillID == var_0_9 then
		local var_6_1 = var_0_10
		local var_6_2 = var_0_7:scope(var_6_1) / 2
		local var_6_3 = {}

		for iter_6_0, iter_6_1 in ipairs(var_6_0.selfTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_2 > math.abs(iter_6_1:getX() - var_6_0:getX()) then
				table.insert(var_6_3, iter_6_1)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_4 = arg_6_0:createAttackUnits(var_6_3, var_6_1)

			for iter_6_2, iter_6_3 in ipairs(var_6_4) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end
		end
	end

	if arg_6_1.skillID == var_0_10 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_5 = arg_6_0:createAttackUnits({
				var_6_0
			}, var_0_11)

			for iter_6_4, iter_6_5 in ipairs(var_6_5) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
				table.insert(arg_6_0.records_.special_units, iter_6_5)
			end
		end
	elseif arg_6_1.skillID == var_0_11 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_6 = arg_6_0:createAttackUnits({
			var_6_0
		}, var_0_12)

		for iter_6_6, iter_6_7 in ipairs(var_6_6) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_7)
			table.insert(arg_6_0.records_.special_units, iter_6_7)
		end
	end

	if arg_6_1.skillID == var_0_21 or arg_6_1.skillID == var_0_28 then
		local var_6_7 = arg_6_1.target
		local var_6_8 = var_0_7:scope(var_0_22) / 2
		local var_6_9 = {}

		for iter_6_8, iter_6_9 in ipairs(var_6_7.selfTeam_) do
			if not iter_6_9:isDeath() and not iter_6_9:isAffected() and var_6_8 > math.abs(iter_6_9:getX() - var_6_7:getX()) then
				table.insert(var_6_9, iter_6_9)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_10 = arg_6_0:createAttackUnits(var_6_9, var_0_22)

			for iter_6_10, iter_6_11 in ipairs(var_6_10) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_11)
				table.insert(arg_6_0.records_.special_units, iter_6_11)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	if arg_7_1.tableID_ == var_0_13 then
		local var_7_0 = 0

		for iter_7_0, iter_7_1 in ipairs(arg_7_1.target:getBuffs()) do
			if iter_7_1.tableID_ == var_0_13 then
				var_7_0 = var_7_0 + 1
			end
		end

		if var_7_0 >= 5 then
			arg_7_1.target:removeBuffByID(var_0_13)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_1 = arg_7_0:createAttackUnits({
					arg_7_1.target
				}, var_0_14)

				for iter_7_2, iter_7_3 in ipairs(var_7_1) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
					table.insert(arg_7_0.records_.special_units, iter_7_3)
				end

				if arg_7_0:hasElementEquipByID(var_0_31) then
					local var_7_2 = arg_7_0:createAttackUnits({
						arg_7_0
					}, var_0_32)

					for iter_7_4, iter_7_5 in ipairs(var_7_2) do
						table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
						table.insert(arg_7_0.records_.special_units, iter_7_5)
					end
				end
			end
		end
	end

	if arg_7_1.tableID_ == var_0_23 then
		local var_7_3 = math.random(tonumber(os.time()))

		math.randomseed(var_7_3)

		arg_7_1.resetXchange_ = math.random(var_0_24 * 2) - var_0_24
	end

	if arg_7_1:getTableID() == var_0_33 then
		local var_7_4 = var_0_31

		arg_7_1.manualRevise = var_0_30:battleAttr(var_7_4, arg_7_0:getElementEquipLevelByID(var_7_4)) * arg_7_0.hero_:getElementEquipActiveRate(var_7_4)
	end
end

function var_0_3.buffRemoveAction(arg_8_0, arg_8_1)
	if arg_8_1.tableID_ == var_0_23 then
		local var_8_0 = arg_8_1.target:getX()
		local var_8_1 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)
		local var_8_2 = var_0_7:scope(var_8_1)

		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() and math.abs(iter_8_1:getX() - var_8_0) < var_0_25 then
				local var_8_3 = var_0_5.new({
					tableID = var_0_26,
					start = var_0_1.ctx.battle.count,
					level = arg_8_0:getSkillLevelByID(var_8_1),
					skillID = var_8_1,
					fighter = arg_8_0,
					target = iter_8_1
				})

				iter_8_1:addBuffs({
					var_8_3
				})
			end
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_9_0)
	local var_9_0 = arg_9_0:getSkillLevelByID(arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
	local var_9_1 = var_0_3.super.getFrontSkill(arg_9_0)

	if var_9_0 > 0 and var_9_1 == var_0_8 then
		return var_0_9
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_9_0)
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	if arg_10_0.skinSkillID_ == var_0_27 and arg_10_1:getSummonType() == var_0_2.summonMonsterType.None and arg_10_1:getTeamType() == arg_10_0:getTeamType() and arg_10_1.killer_ and arg_10_1.killer_:getTeamType() ~= arg_10_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_10_0 = arg_10_0:createAttackUnits({
			arg_10_1.killer_
		}, var_0_27)

		for iter_10_0, iter_10_1 in ipairs(var_10_0) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end

		if arg_10_0:hasElementEquipByID(var_0_31) then
			local var_10_1 = arg_10_0:createAttackUnits({
				arg_10_0
			}, var_0_32)

			for iter_10_2, iter_10_3 in ipairs(var_10_1) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
				table.insert(arg_10_0.records_.special_units, iter_10_3)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	if arg_11_0:hasElementEquipByID(var_0_31) and arg_11_4 > 0 and arg_11_1.target:isHasBuffByID(var_0_29) then
		arg_11_4 = arg_11_4 + arg_11_4 * var_0_34
	end

	return var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
end

return var_0_3
