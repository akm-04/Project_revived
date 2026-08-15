local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("TianfengRedMushroom", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 1
local var_0_5 = 20
local var_0_6 = 0.5
local var_0_7 = 10
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_10 = 60
local var_0_11 = 100
local var_0_12 = 100
local var_0_13 = 90
local var_0_14 = 80010088

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftCount_ = 1
	arg_1_0.summonMonsters_ = {}
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	if arg_2_0.leftCount_ < 1 and not arg_2_0:isDeath() then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

function var_0_3.createUnits(arg_3_0, arg_3_1)
	var_0_3.super.createUnits(arg_3_0)

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_3_0:updateHp(0)
		arg_3_0:die()
	end
end

function var_0_3.singleLoop(arg_4_0)
	var_0_3.super.singleLoop(arg_4_0)

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_4_0.leftCount_ = 0
	end
end

function var_0_3.updateHarms(arg_5_0, arg_5_1)
	if arg_5_0.summoner then
		if arg_5_0.summoner.summoner then
			arg_5_0.summoner.summoner.harms = arg_5_0.summoner.summoner.harms + arg_5_1

			return
		end

		arg_5_0.summoner.harms = arg_5_0.summoner.harms + arg_5_1

		return
	end

	arg_5_0.harms = arg_5_0.harms + arg_5_1
end

function var_0_3.toDoPerFrames(arg_6_0)
	local var_6_0 = false

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and (not iter_6_1:isDeath() or iter_6_1:canReborn()) then
			var_6_0 = true
		end
	end

	if not var_6_0 then
		arg_6_0:updateHp(0)
		arg_6_0:die()
	end

	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.summoner and arg_6_0.summoner.isSkinSkillOn_ and arg_6_0.summoner.skinSkillID_ == var_0_14 and arg_6_0.summoner:getTableID() ~= arg_6_0:getTableID() and arg_6_0.summoner:isDeath() and var_0_1.ctx.battle.count % var_0_13 == 0 then
		local var_6_1 = {}

		table.insert(var_6_1, arg_6_0:getTableID())

		if next(var_6_1) == nil then
			return
		end

		local var_6_2 = {}

		for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_3:isDeath() and iter_6_3:getSummonType() == var_0_2.summonMonsterType.None then
				local var_6_3, var_6_4 = iter_6_3.fighterModel:getPosition()

				table.insert(var_6_2, iter_6_3)
			end
		end

		if #var_6_2 == 0 then
			return
		end

		if arg_6_0:getTeamType() == var_0_2.TeamType.A then
			table.sort(var_6_2, function(arg_7_0, arg_7_1)
				return arg_7_0.fighterModel:getPosition() < arg_7_1.fighterModel:getPosition()
			end)
		else
			table.sort(var_6_2, function(arg_8_0, arg_8_1)
				return arg_8_0.fighterModel:getPosition() > arg_8_1.fighterModel:getPosition()
			end)
		end

		local var_6_5
		local var_6_6

		if #var_6_2 <= 3 then
			local var_6_7, var_6_8 = var_6_2[1].fighterModel:getPosition()
		else
			local var_6_9, var_6_10 = var_6_2[2].fighterModel:getPosition()
		end

		for iter_6_4, iter_6_5 in ipairs(var_6_1) do
			local var_6_11 = arg_6_0.level_
			local var_6_12 = arg_6_0.hero_:getColor()
			local var_6_13 = {}

			if arg_6_0:getFlipX() then
				var_6_13 = {
					x = arg_6_0:getX() - var_0_11,
					y = arg_6_0:getY()
				}
			end

			if arg_6_0:getFlipX() then
				var_6_13 = {
					x = arg_6_0:getX(),
					y = arg_6_0:getY()
				}
			else
				var_6_13 = {
					x = arg_6_0:getX(),
					y = arg_6_0:getY()
				}
			end

			arg_6_0:setSummonMonsters(iter_6_5, var_6_11, var_6_12, var_6_13)
		end
	end
end

function var_0_3.isWalked2Position(arg_9_0)
	if not arg_9_0.walk2Position_ then
		return true
	end

	if arg_9_0:getTeamType() == var_0_2.TeamType.A then
		if arg_9_0:getFlipX() == false then
			return arg_9_0:getX() > arg_9_0:getFormationWalkPosition()
		else
			return arg_9_0:getX() < arg_9_0:getFormationWalkPosition()
		end
	elseif arg_9_0:getFlipX() == true then
		return arg_9_0:getX() < var_0_2.STAGE_WIDTH - arg_9_0:getFormationWalkPosition()
	else
		return arg_9_0:getX() > var_0_2.STAGE_WIDTH - arg_9_0:getFormationWalkPosition()
	end
end

function var_0_3.getAP(arg_10_0)
	if not arg_10_0.summoner then
		return var_0_3.super.getAP(arg_10_0)
	end

	return arg_10_0.summoner:getAP()
end

function var_0_3.updateUnitDataByTarget(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.updateUnitDataByTarget(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_6 = 0

	return var_11_0, var_11_1, var_11_6, var_11_3, var_11_4, var_11_5
end

function var_0_3.isAffected(arg_12_0)
	return true
end

function var_0_3.canAttack(arg_13_0)
	if arg_13_0:isDeath() then
		return false
	end

	if arg_13_0:getLeftInterval() > 0 then
		return false
	end

	if arg_13_0:isBattleUnable() then
		return false
	end

	if arg_13_0.isEnergySkill_ then
		return true
	end

	if arg_13_0.invalidSkillQueue_ then
		return false
	end

	if arg_13_0:isCreatingUnits() then
		return false
	end

	if arg_13_0:isInSkillRoll() then
		return false
	end

	if not arg_13_0:getNearestTarget() then
		return false
	end

	if arg_13_0:isTargetBeyondReach() then
		return false
	end

	return true
end

function var_0_3.checkMove(arg_14_0)
	if arg_14_0:isDeath() then
		return
	end

	if arg_14_0:isMoveUnable() or arg_14_0:isInSkillRoll() or arg_14_0.manualDirection_ then
		if arg_14_0:getCurrentAnimation() == "run" then
			arg_14_0:resumeIdle()
		end

		arg_14_0.preWalk_ = false
		arg_14_0.isWalking_ = false
		arg_14_0.behindWalk_ = false
	elseif arg_14_0.walk2Position_ then
		if arg_14_0:isWalked2Position() then
			arg_14_0.walk2Position_ = false

			if arg_14_0:isTargetBeyondReach() then
				arg_14_0.isWalking_ = 1
			else
				arg_14_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk
			end
		else
			arg_14_0.isWalking_ = 1

			if not arg_14_0:isWalking() then
				arg_14_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_14_0:isWalking() == 2 then
				local var_14_0 = arg_14_0:getFlipX() and -1 or 1

				arg_14_0:moveByX(arg_14_0:getCurrentSpeed() * var_14_0)
			end

			if arg_14_0:getCurrentAnimation() ~= "run" then
				arg_14_0:modelWalk()
			end
		end

		arg_14_0:writeWalkState()
	elseif arg_14_0:isWalking() ~= 3 then
		arg_14_0.preWalk_ = false
		arg_14_0.isWalking_ = false
		arg_14_0.behindWalk_ = false

		if arg_14_0:getCurrentAnimation() == "run" then
			arg_14_0:resumeIdle()
		end
	else
		arg_14_0:writeWalkState()
	end
end

function var_0_3.setSummonMonsters(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	if #arg_15_0.summonMonsters_ >= var_0_10 then
		return
	end

	local var_15_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_15_0 = arg_15_0:getSummonMonster()
	else
		local var_15_1 = var_0_9.new()

		var_15_1:populateWithTableID(arg_15_1)

		var_15_1.level_ = arg_15_2 or var_15_1.level_
		var_15_1.color_ = arg_15_3 or var_15_1.color_

		for iter_15_0, iter_15_1 in ipairs(var_15_1.skillLev_) do
			local var_15_2 = arg_15_0.hero_:getSkillLevel(iter_15_0)

			if var_15_2 and var_15_2 > 0 then
				var_15_1.skillLev_[iter_15_0] = var_0_0.clone(var_15_2)
			end
		end

		local var_15_3 = var_15_1:className()

		var_15_0 = var_0_1.ctx.battle.requireFighter(var_15_3).new({
			is_arena = arg_15_0.isInArena_
		})

		var_15_0:populateWithHero(var_15_1)
		var_15_0:initModels()
		var_15_0.fighterModel:initHeaderView(arg_15_0:getTeamType() - 1)

		var_15_0.fighterIndex = arg_15_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_15_0:setFormationDelay(0, 100)
	end

	var_15_0:setTeamType(arg_15_0:getTeamType())

	var_15_0.summoner = arg_15_0

	var_15_0.fighterModel:pos(arg_15_4.x, arg_15_4.y)
	var_15_0:updateHp(var_15_0:getHpLimit())
	var_15_0:getFighterModel():flipX(arg_15_0:getTeamType() == var_0_2.TeamType.B)
	var_15_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_15_0:born()
	var_15_0:setGlobalBuffs()

	local var_15_4 = var_15_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_15_4, var_15_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_15_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_15_0.summonMonsters_, var_15_0)

	local var_15_5 = arg_15_0.fighterModel:getPosition()
	local var_15_6 = arg_15_0.fighterModel:getPosition()

	if arg_15_0.summoner and #arg_15_0.summoner.littleMushroom > 0 then
		for iter_15_2, iter_15_3 in ipairs(arg_15_0.summoner.littleMushroom) do
			if var_15_6 < iter_15_3.posX_ then
				var_15_6 = iter_15_3.posX_
			end

			if var_15_5 > iter_15_3.posX_ then
				var_15_5 = iter_15_3.posX_
			end
		end

		local var_15_7 = {}
		local var_15_8 = arg_15_0.summoner.littleMushroom

		table.sort(var_15_8, function(arg_16_0, arg_16_1)
			return arg_16_0.posX_ < arg_16_1.posX_
		end)

		for iter_15_4, iter_15_5 in ipairs(var_15_8) do
			if arg_15_0.fighterModel:getPosition() < iter_15_5.posX_ then
				if iter_15_4 == 1 then
					var_15_5 = arg_15_0.fighterModel:getPosition()

					if arg_15_0.fighterModel:getPosition() + var_0_12 < var_15_8[1].posX_ then
						var_15_6 = arg_15_0.fighterModel:getPosition()

						break
					end

					var_15_6 = var_15_8[#var_15_8].posX_

					for iter_15_6 = 2, #var_15_8 do
						if var_15_8[iter_15_6].posX_ - var_15_8[iter_15_6 - 1].posX_ > var_0_12 then
							var_15_6 = var_15_8[iter_15_6 - 1].posX_

							break
						end
					end

					break
				end

				for iter_15_7 = iter_15_4 - 1, 1, -1 do
					if arg_15_0.fighterModel:getPosition() - var_15_8[iter_15_4 - 1].posX_ > var_0_12 then
						var_15_5 = arg_15_0.fighterModel:getPosition()

						break
					else
						var_15_5 = var_15_8[1].posX_

						if iter_15_7 > 1 and var_15_8[iter_15_7].posX_ - var_15_8[iter_15_7 - 1].posX_ > var_0_12 then
							var_15_5 = var_15_8[iter_15_7].posX_

							break
						end
					end
				end

				for iter_15_8 = iter_15_4, #var_15_8 do
					if var_15_8[iter_15_4].posX_ - arg_15_0.fighterModel:getPosition() > var_0_12 then
						var_15_6 = arg_15_0.fighterModel:getPosition()

						break
					else
						var_15_6 = var_15_8[#var_15_8].posX_

						if iter_15_8 < #var_15_8 and var_15_8[iter_15_8 + 1].posX_ - var_15_8[iter_15_8].posX_ > var_0_12 then
							var_15_6 = var_15_8[iter_15_8].posX_

							break
						end
					end
				end

				break
			end

			if iter_15_4 == #var_15_8 then
				var_15_6 = arg_15_0.fighterModel:getPosition()

				if arg_15_0.fighterModel:getPosition() - var_0_12 > var_15_8[#var_15_8].posX_ then
					var_15_5 = arg_15_0.fighterModel:getPosition()
				else
					var_15_5 = var_15_8[1].posX_

					for iter_15_9 = #var_15_8, 2, -1 do
						if var_15_8[iter_15_9].posX_ - var_15_8[iter_15_9 - 1].posX_ > var_0_12 then
							var_15_5 = var_15_8[iter_15_9].posX_

							break
						end
					end
				end
			end
		end

		if var_15_6 < arg_15_0.fighterModel:getPosition() then
			var_15_6 = arg_15_0.fighterModel:getPosition() + var_0_12
		else
			var_15_6 = var_15_6 + var_0_12

			if var_0_1.ctx.battle.isUnlimitBattle then
				if var_15_6 > var_0_2.UNLIMIT_STAGE_WIDTH then
					var_15_6 = var_0_2.UNLIMIT_STAGE_WIDTH
				end
			elseif var_15_6 > var_0_2.STAGE_WIDTH then
				var_15_6 = var_0_2.STAGE_WIDTH
			end
		end

		if var_15_5 > arg_15_0.fighterModel:getPosition() then
			var_15_5 = arg_15_0.fighterModel:getPosition() - var_0_12
		else
			var_15_5 = var_15_5 - var_0_12

			if var_15_5 < 0 then
				var_15_5 = 0
			end
		end
	end

	if arg_15_0:getFlipX() then
		var_15_0:flipX(true)

		var_15_0.walk2Position_ = true

		var_15_0:setFormationDelay(0, var_15_5)

		if arg_15_0:getTeamType() == var_0_2.TeamType.B then
			if var_0_1.ctx.battle.isUnlimitBattle then
				var_15_0:setFormationDelay(0, var_0_2.UNLIMIT_STAGE_WIDTH - var_15_5)
			else
				var_15_0:setFormationDelay(0, var_0_2.STAGE_WIDTH - var_15_5)
			end
		end

		var_15_0.posX_ = var_15_5
	else
		var_15_0:flipX(false)

		var_15_0.walk2Position_ = true

		var_15_0:setFormationDelay(0, var_15_6)

		if arg_15_0:getTeamType() == var_0_2.TeamType.B then
			if var_0_1.ctx.battle.isUnlimitBattle then
				var_15_0:setFormationDelay(0, var_0_2.UNLIMIT_STAGE_WIDTH - var_15_6)
			else
				var_15_0:setFormationDelay(0, var_0_2.STAGE_WIDTH - var_15_6)
			end
		end

		var_15_0.posX_ = var_15_6
	end

	table.insert(arg_15_0.summoner.littleMushroom, var_15_0)
end

return var_0_3
