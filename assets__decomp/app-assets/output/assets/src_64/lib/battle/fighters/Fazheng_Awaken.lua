local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fazheng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 140
local var_0_10 = var_0_2.tables.cabinetSkillTable
local var_0_11 = 10350002
local var_0_12 = 80010040
local var_0_13 = 10001024
local var_0_14 = 10001025
local var_0_15 = 0.2
local var_0_16 = 10001026
local var_0_17 = 10001027

function var_0_3.setTeamType(arg_1_0, arg_1_1)
	var_0_3.super.setTeamType(arg_1_0, arg_1_1)

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = var_0_1.ctx.battle.getRequire("HeroAnimation")
		local var_1_1 = var_0_6:summonMonster(arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))[1]

		assert(var_1_1 ~= nil)

		local var_1_2 = var_0_7:modelID(var_1_1)

		arg_1_0.effectFighter = var_1_0.new(var_1_1, var_1_2, arg_1_0:getScale())

		arg_1_0.effectFighter:retain()
		arg_1_0.effectFighter:hide()
		arg_1_0.effectFighter:addTo(var_0_1.ctx.battle.unitLayer)

		arg_1_0.effectFighterTwiceAwake = var_1_0.new(var_1_1, var_1_2, arg_1_0:getScale())

		arg_1_0.effectFighterTwiceAwake:retain()
		arg_1_0.effectFighterTwiceAwake:hide()
		arg_1_0.effectFighterTwiceAwake:addTo(var_0_1.ctx.battle.unitLayer)

		arg_1_0.effectFighterTwiceAwakeExtra = var_1_0.new(var_1_1, var_1_2, arg_1_0:getScale())

		arg_1_0.effectFighterTwiceAwakeExtra:retain()
		arg_1_0.effectFighterTwiceAwakeExtra:hide()
		arg_1_0.effectFighterTwiceAwakeExtra:addTo(var_0_1.ctx.battle.unitLayer)

		if arg_1_0:getTeamType() == var_0_2.TeamType.A then
			arg_1_0.effectFighter:pos(100, 250)
			arg_1_0.effectFighter:flipX(false)
			arg_1_0.effectFighterTwiceAwake:pos(100, 350)
			arg_1_0.effectFighterTwiceAwake:flipX(false)
			arg_1_0.effectFighterTwiceAwakeExtra:pos(100, 450)
			arg_1_0.effectFighterTwiceAwakeExtra:flipX(false)
		else
			arg_1_0.effectFighter:flipX(true)
			arg_1_0.effectFighter:pos(var_0_2.STAGE_WIDTH - 100, 250)
			arg_1_0.effectFighterTwiceAwake:flipX(true)
			arg_1_0.effectFighterTwiceAwake:pos(var_0_2.STAGE_WIDTH - 100, 350)
			arg_1_0.effectFighterTwiceAwakeExtra:flipX(true)
			arg_1_0.effectFighterTwiceAwakeExtra:pos(var_0_2.STAGE_WIDTH - 100, 450)
		end
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.xuliSkill_ = nil
	arg_2_0.xuliCount_ = 0
	arg_2_0.isExtra_ = false
	arg_2_0.energyInterval_ = 0
	arg_2_0.xuliReport_ = {}
	arg_2_0.energyEffectPos_ = {}

	if arg_2_0.effectFighter then
		arg_2_0.effectFighter:hide()
		arg_2_0.effectFighter:addTo(var_0_1.ctx.battle.unitLayer)

		if arg_2_0:getTeamType() == var_0_2.TeamType.A then
			arg_2_0.effectFighter:pos(100, 250)
			arg_2_0.effectFighter:flipX(false)
		else
			arg_2_0.effectFighter:flipX(true)
			arg_2_0.effectFighter:pos(var_0_2.STAGE_WIDTH - 100, 250)
		end
	end

	if arg_2_0.effectFighterTwiceAwake then
		arg_2_0.effectFighterTwiceAwake:hide()
		arg_2_0.effectFighterTwiceAwake:addTo(var_0_1.ctx.battle.unitLayer)

		if arg_2_0:getTeamType() == var_0_2.TeamType.A then
			arg_2_0.effectFighterTwiceAwake:pos(100, 350)
			arg_2_0.effectFighterTwiceAwake:flipX(false)
		else
			arg_2_0.effectFighterTwiceAwake:flipX(true)
			arg_2_0.effectFighterTwiceAwake:pos(var_0_2.STAGE_WIDTH - 100, 350)
		end
	end

	if arg_2_0.effectFighterTwiceAwakeExtra then
		arg_2_0.effectFighterTwiceAwakeExtra:hide()
		arg_2_0.effectFighterTwiceAwakeExtra:addTo(var_0_1.ctx.battle.unitLayer)

		if arg_2_0:getTeamType() == var_0_2.TeamType.A then
			arg_2_0.effectFighterTwiceAwakeExtra:pos(100, 450)
			arg_2_0.effectFighterTwiceAwakeExtra:flipX(false)
		else
			arg_2_0.effectFighterTwiceAwakeExtra:flipX(true)
			arg_2_0.effectFighterTwiceAwakeExtra:pos(var_0_2.STAGE_WIDTH - 100, 450)
		end
	end

	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
end

function var_0_3.specialAttack(arg_3_0)
	if not arg_3_0.xuliSkill_ then
		return
	end

	local var_3_0 = var_0_6:xuliChild(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))
	local var_3_1 = arg_3_0:getEnergyTargets(var_3_0)

	if not next(var_3_1) then
		-- block empty
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	table.insert(arg_3_0.xuliReport_, var_0_1.ctx.battle.count)

	local var_3_2 = var_0_6:sound(var_3_0)

	var_0_1.ctx.battle.pushSoundQueue(var_3_2)
	arg_3_0:playEffectAttack(2)

	if arg_3_0:getTeamType() == var_0_2.TeamType.A and arg_3_0.bottomWnd then
		arg_3_0.bottomWnd:setXuliSkillEffect(arg_3_0, var_0_1.ctx.battle.teamA, false)
	end

	local var_3_3 = arg_3_0:createAttackUnits(var_3_1, var_3_0)

	for iter_3_0, iter_3_1 in ipairs(var_3_3) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
		table.insert(arg_3_0.records_.special_units, iter_3_1)
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_3_4 = arg_3_0:createAttackUnits(var_3_1, var_0_13)

		for iter_3_2, iter_3_3 in ipairs(var_3_4) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end

		if arg_3_0.isExtra_ then
			local var_3_5 = arg_3_0:createAttackUnits(var_3_1, var_0_14)

			for iter_3_4, iter_3_5 in ipairs(var_3_5) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
				table.insert(arg_3_0.records_.special_units, iter_3_5)
			end
		end
	end

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_12 then
		local var_3_6 = arg_3_0:getAwakeSkinSkillTargets(var_0_12)

		if not var_0_0.table.keyof(var_3_6, arg_3_0) then
			table.insert(var_3_6, arg_3_0)
		end

		local var_3_7 = arg_3_0:createAttackUnits(var_3_6, var_0_12)

		for iter_3_6, iter_3_7 in ipairs(var_3_7) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
			table.insert(arg_3_0.records_.special_units, iter_3_7)
		end

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			local var_3_8 = arg_3_0:createAttackUnits(var_3_6, var_0_16)

			for iter_3_8, iter_3_9 in ipairs(var_3_8) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_9)
				table.insert(arg_3_0.records_.special_units, iter_3_9)
			end

			if arg_3_0.isExtra_ then
				local var_3_9 = arg_3_0:createAttackUnits(var_3_6, var_0_17)

				for iter_3_10, iter_3_11 in ipairs(var_3_9) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_11)
					table.insert(arg_3_0.records_.special_units, iter_3_11)
				end
			end
		end
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		local var_3_10
		local var_3_11, var_3_12 = var_0_6:areaResource(var_3_0)

		if var_3_11 and var_3_11 ~= "" and var_3_12 and var_3_12 ~= "" then
			var_3_10 = var_0_1.ctx.battle.getSpine(var_3_0, "area", arg_3_0:getScale())
		end

		if var_3_10 then
			var_3_10:addTo(var_0_1.ctx.battle.unitLayer)
			var_3_10:playOnce()

			if arg_3_0.effectFighter:getFlipX() then
				var_3_10:pos(var_0_2.STAGE_WIDTH - 100, 250)
				var_3_10:flipX(true)
			else
				var_3_10:pos(100, 250)
			end
		end

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			local var_3_13
			local var_3_14, var_3_15 = var_0_6:areaResource(var_0_13)

			if var_3_14 and var_3_14 ~= "" and var_3_15 and var_3_15 ~= "" then
				var_3_13 = var_0_1.ctx.battle.getSpine(var_0_13, "area", arg_3_0:getScale())
			end

			if var_3_13 then
				var_3_13:addTo(var_0_1.ctx.battle.unitLayer)
				var_3_13:playOnce()

				if arg_3_0.effectFighterTwiceAwake:getFlipX() then
					var_3_13:pos(var_0_2.STAGE_WIDTH - 100, 350)
					var_3_13:flipX(true)
				else
					var_3_13:pos(100, 350)
				end
			end

			if arg_3_0.isExtra_ then
				local var_3_16
				local var_3_17, var_3_18 = var_0_6:areaResource(var_0_14)

				if var_3_17 and var_3_17 ~= "" and var_3_18 and var_3_18 ~= "" then
					var_3_16 = var_0_1.ctx.battle.getSpine(var_0_14, "area", arg_3_0:getScale())
				end

				if var_3_16 then
					var_3_16:addTo(var_0_1.ctx.battle.unitLayer)
					var_3_16:playOnce()

					if arg_3_0.effectFighterTwiceAwakeExtra:getFlipX() then
						var_3_16:pos(var_0_2.STAGE_WIDTH - 100, 450)
						var_3_16:flipX(true)
					else
						var_3_16:pos(100, 450)
					end
				end
			end
		end
	end

	arg_3_0.xuliSkill_ = nil
end

function var_0_3.playEffectAttack(arg_4_0, arg_4_1)
	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.CreateReport then
		return
	end

	arg_4_0.effectFighter:show()

	if arg_4_1 == 1 then
		if arg_4_0:getTeamType() == var_0_2.TeamType.A then
			arg_4_0.effectFighter:flipX(false)
		else
			arg_4_0.effectFighter:flipX(true)
		end

		arg_4_0.energyFlip_ = arg_4_0.effectFighter:getFlipX()
	end

	arg_4_0.effectFighter:attack(arg_4_1, nil, nil, function()
		arg_4_0.effectFighter:hide()
	end)

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_4_0.effectFighterTwiceAwake:show()

		if arg_4_1 == 1 then
			if arg_4_0:getTeamType() == var_0_2.TeamType.A then
				arg_4_0.effectFighterTwiceAwake:flipX(false)
			else
				arg_4_0.effectFighterTwiceAwake:flipX(true)
			end
		end

		arg_4_0.effectFighterTwiceAwake:attack(arg_4_1, nil, nil, function()
			arg_4_0.effectFighterTwiceAwake:hide()
		end)

		if arg_4_0.isExtra_ then
			arg_4_0.effectFighterTwiceAwakeExtra:show()

			if arg_4_1 == 1 then
				if arg_4_0:getTeamType() == var_0_2.TeamType.A then
					arg_4_0.effectFighterTwiceAwakeExtra:flipX(false)
				else
					arg_4_0.effectFighterTwiceAwakeExtra:flipX(true)
				end
			end

			arg_4_0.effectFighterTwiceAwakeExtra:attack(arg_4_1, nil, nil, function()
				arg_4_0.effectFighterTwiceAwakeExtra:hide()
			end)
		end
	end
end

function var_0_3.playEffectReport(arg_8_0)
	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
		return
	end

	if not arg_8_0.xuliCountReport_[1] then
		return
	end

	if var_0_1.ctx.battle.count > arg_8_0.xuliCountReport_[1] then
		table.remove(arg_8_0.xuliCountReport_, 1)

		return
	end

	if var_0_1.ctx.battle.count < arg_8_0.xuliCountReport_[1] then
		return
	end

	arg_8_0.xuliSkill_ = nil

	table.remove(arg_8_0.xuliCountReport_, 1)

	local var_8_0 = var_0_6:xuliChild(arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))
	local var_8_1 = var_0_6:sound(var_8_0)

	var_0_1.ctx.battle.pushSoundQueue(var_8_1)
	arg_8_0:playEffectAttack(2)

	if arg_8_0:getTeamType() == var_0_2.TeamType.A and arg_8_0.bottomWnd then
		arg_8_0.bottomWnd:setXuliSkillEffect(arg_8_0, var_0_1.ctx.battle.teamA, false)
	end

	local var_8_2
	local var_8_3, var_8_4 = var_0_6:areaResource(var_8_0)

	if var_8_3 and var_8_3 ~= "" and var_8_4 and var_8_4 ~= "" then
		var_8_2 = var_0_1.ctx.battle.getSpine(var_8_0, "area", arg_8_0:getScale())
	end

	if var_8_2 then
		var_8_2:addTo(var_0_1.ctx.battle.unitLayer)
		var_8_2:playOnce()

		local var_8_5 = arg_8_0.effectFighter:getPosition()

		var_8_2:pos(var_8_5, 250)

		if arg_8_0.effectFighter:getFlipX() then
			var_8_2:flipX(true)
		else
			var_8_2:flipX(false)
		end
	end

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_8_6
		local var_8_7, var_8_8 = var_0_6:areaResource(var_0_13)

		if var_8_7 and var_8_7 ~= "" and var_8_8 and var_8_8 ~= "" then
			var_8_6 = var_0_1.ctx.battle.getSpine(var_0_13, "area", arg_8_0:getScale())
		end

		if var_8_6 then
			var_8_6:addTo(var_0_1.ctx.battle.unitLayer)
			var_8_6:playOnce()

			if arg_8_0.effectFighterTwiceAwake:getFlipX() then
				var_8_6:pos(var_0_2.STAGE_WIDTH - 100, 350)
				var_8_6:flipX(true)
			else
				var_8_6:pos(100, 350)
			end
		end

		if arg_8_0.isExtra_ then
			local var_8_9
			local var_8_10, var_8_11 = var_0_6:areaResource(var_0_14)

			if var_8_10 and var_8_10 ~= "" and var_8_11 and var_8_11 ~= "" then
				var_8_9 = var_0_1.ctx.battle.getSpine(var_0_14, "area", arg_8_0:getScale())
			end

			if var_8_9 then
				var_8_9:addTo(var_0_1.ctx.battle.unitLayer)
				var_8_9:playOnce()

				if arg_8_0.effectFighterTwiceAwakeExtra:getFlipX() then
					var_8_9:pos(var_0_2.STAGE_WIDTH - 100, 450)
					var_8_9:flipX(true)
				else
					var_8_9:pos(100, 450)
				end
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == arg_9_0:getEnergySkillID() then
		local var_9_0 = arg_9_1.rootID_

		if arg_9_0:getTeamType() == var_0_2.TeamType.A and arg_9_0.bottomWnd then
			arg_9_0.bottomWnd:setXuliSkillEffect(arg_9_0, var_0_1.ctx.battle.teamA, true)
		end

		arg_9_0.isExtra_ = false

		if var_0_2.weightedChoise({
			var_0_15,
			1 - var_0_15
		}) == 1 then
			arg_9_0.isExtra_ = true
		end

		arg_9_0:playEffectAttack(1)

		arg_9_0.xuliCount_ = 0
		arg_9_0.xuliSkill_ = var_0_6:xuliChild(arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))
	end
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_1.skillID == var_0_6:xuliChild(arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)) then
		arg_10_4 = arg_10_4 * math.min(arg_10_0.xuliCount_ * arg_10_0.xuliCount_ / (var_0_9 * var_0_9), 1)
	elseif arg_10_1.skillID == var_0_13 then
		arg_10_4 = arg_10_4 * math.min(arg_10_0.xuliCount_ * arg_10_0.xuliCount_ / (var_0_9 * var_0_9), 1)
	elseif arg_10_1.skillID == var_0_14 then
		arg_10_4 = arg_10_4 * math.min(arg_10_0.xuliCount_ * arg_10_0.xuliCount_ / (var_0_9 * var_0_9), 1)
	elseif arg_10_1.skillID == var_0_12 then
		arg_10_5 = arg_10_5 * math.min(arg_10_0.xuliCount_ * arg_10_0.xuliCount_ / (var_0_9 * var_0_9), 1)
	elseif arg_10_1.skillID == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_10_5 = arg_10_5 + arg_10_0.extraSkillLevel * var_0_10:attrValues(var_0_11)
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.getEnergyTargets(arg_11_0, arg_11_1)
	if not next(arg_11_0.energyEffectPos_) then
		if arg_11_0:getTeamType() == var_0_2.TeamType.A then
			arg_11_0.energyEffectPos_ = {
				x = 100,
				y = 250
			}
			arg_11_0.energyFlip_ = false
		else
			arg_11_0.energyEffectPos_ = {
				y = 250,
				x = var_0_2.STAGE_WIDTH - 100
			}
			arg_11_0.energyFlip_ = true
		end
	end

	local var_11_0 = arg_11_0.energyFlip_
	local var_11_1 = arg_11_0.energyEffectPos_.x
	local var_11_2 = arg_11_0.energyEffectPos_.y
	local var_11_3 = var_0_6:scope(arg_11_1)
	local var_11_4 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.targetTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
			local var_11_5, var_11_6 = iter_11_1:getPos()

			if var_11_0 then
				if var_11_5 < var_11_1 and var_11_3 >= var_11_1 - var_11_5 then
					table.insert(var_11_4, iter_11_1)
				end
			elseif var_11_1 < var_11_5 and var_11_3 >= var_11_5 - var_11_1 then
				table.insert(var_11_4, iter_11_1)
			end
		end
	end

	return var_11_4
end

function var_0_3.getAwakeSkinSkillTargets(arg_12_0, arg_12_1)
	if not next(arg_12_0.energyEffectPos_) then
		if arg_12_0:getTeamType() == var_0_2.TeamType.A then
			arg_12_0.energyEffectPos_ = {
				x = 100,
				y = 250
			}
			arg_12_0.energyFlip_ = false
		else
			arg_12_0.energyEffectPos_ = {
				y = 250,
				x = var_0_2.STAGE_WIDTH - 100
			}
			arg_12_0.energyFlip_ = true
		end
	end

	local var_12_0 = arg_12_0.energyFlip_
	local var_12_1 = arg_12_0.energyEffectPos_.x
	local var_12_2 = arg_12_0.energyEffectPos_.y
	local var_12_3 = var_0_6:scope(arg_12_1)
	local var_12_4 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.selfTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() then
			local var_12_5, var_12_6 = iter_12_1:getPos()

			if var_12_0 then
				if var_12_5 < var_12_1 and var_12_3 >= var_12_1 - var_12_5 then
					table.insert(var_12_4, iter_12_1)
				end
			elseif var_12_1 < var_12_5 and var_12_3 >= var_12_5 - var_12_1 then
				table.insert(var_12_4, iter_12_1)
			end
		end
	end

	return var_12_4
end

function var_0_3.toDoPerFrames(arg_13_0)
	if not arg_13_0.extraSkillJudge then
		arg_13_0.extraSkillJudge = true
		arg_13_0.extraSkillLevel = arg_13_0.hero_:skillBook()[tostring(var_0_11)] or 0
	end
end

function var_0_3.clickAvatar(arg_14_0, arg_14_1)
	if arg_14_0.xuliSkill_ and arg_14_1.name == "ended" and var_0_1.ctx.battle.autoA ~= true then
		arg_14_0:specialAttack()

		arg_14_0.energyInterval_ = 2
	end
end

function var_0_3.updateBaseInfo(arg_15_0)
	var_0_3.super.updateBaseInfo(arg_15_0)

	arg_15_0.xuliCount_ = arg_15_0.xuliSkill_ and arg_15_0.xuliCount_ + 1 or arg_15_0.xuliCount_
	arg_15_0.energyInterval_ = arg_15_0.energyInterval_ - 1

	if arg_15_0.xuliCount_ >= var_0_9 and arg_15_0.xuliSkill_ then
		arg_15_0:specialAttack()
	end

	arg_15_0:playEffectReport()
end

function var_0_3.die(arg_16_0)
	if arg_16_0:getTeamType() == var_0_2.TeamType.A and arg_16_0.bottomWnd then
		arg_16_0.bottomWnd:setXuliSkillEffect(arg_16_0, var_0_1.ctx.battle.teamA, false)
	end

	var_0_3.super.die(arg_16_0)
end

function var_0_3.checkEnergySkill(arg_17_0)
	if arg_17_0.xuliSkill_ or arg_17_0.energyInterval_ > 0 then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_17_0)
end

function var_0_3.writeReport(arg_18_0)
	local var_18_0 = var_0_3.super.writeReport(arg_18_0)

	var_18_0.xuli_count = arg_18_0.xuliReport_

	return var_18_0
end

function var_0_3.setupReport(arg_19_0, arg_19_1)
	var_0_3.super.setupReport(arg_19_0, arg_19_1)

	arg_19_0.xuliCountReport_ = arg_19_1.xuli_count
end

return var_0_3
