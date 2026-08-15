local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luzhi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0.3
local var_0_8 = 10000677
local var_0_9 = 10000674
local var_0_10 = 40010701
local var_0_11 = 40010702
local var_0_12 = 40010712
local var_0_13 = 20
local var_0_14 = 10
local var_0_15 = 15
local var_0_16 = 80010150
local var_0_17 = 0.5
local var_0_18 = 0.3
local var_0_19 = var_0_2.tables.elementEquip
local var_0_20 = 20001497
local var_0_21 = 10002428
local var_0_22 = 10002430
local var_0_23 = 40012638
local var_0_24 = 240
local var_0_25 = 0.5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.purpleSkillTarget = nil
	arg_1_0.purpleSkillEffect = nil
	arg_1_0.purpleSkillTargetPos = {}
	arg_1_0.purpleInitTargetPos = false
	arg_1_0.pathQueue_ = {}
	arg_1_0.elementCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0.purpleSkillEffect then
		arg_2_0:moveSkillEffect()
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if var_3_2 > 0 and arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_16 then
		local var_3_6

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.summonMonsters_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() then
				var_3_6 = iter_3_1
			end
		end

		if var_3_6 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_7 = arg_3_0:createAttackUnits({
				var_3_6
			}, var_0_16)

			for iter_3_2, iter_3_3 in ipairs(var_3_7) do
				iter_3_3.cureHp = var_3_2 * var_0_17

				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	elseif arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_16 and arg_3_1.skillID == var_0_16 and arg_3_1.cureHp then
		var_3_3 = arg_3_1.cureHp
	elseif arg_3_0:hasElementEquipByID(var_0_20) and arg_3_1.skillID == var_0_22 and arg_3_1.cureHp then
		var_3_3 = arg_3_1.cureHp
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local function var_4_0(arg_5_0, arg_5_1)
		local var_5_0 = {}

		table.insert(var_5_0, arg_5_0)

		for iter_5_0, iter_5_1 in ipairs(arg_4_0.sideTeam_) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1 ~= arg_5_0 and arg_5_1 >= math.abs(iter_5_1:getX() - arg_5_0:getX()) then
				table.insert(var_5_0, iter_5_1)
			end
		end

		return var_5_0
	end

	local var_4_1 = {}
	local var_4_2 = 0
	local var_4_3 = var_0_6:scope(arg_4_1) * 0.5

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			local var_4_4 = var_4_0(iter_4_1, var_4_3)

			if var_4_2 < #var_4_4 then
				var_4_1 = {
					iter_4_1
				}
				var_4_2 = #var_4_4
			end
		end
	end

	return var_4_1
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		local var_6_0 = arg_6_1.target
		local var_6_1 = arg_6_0:getEnergySkillID()
		local var_6_2 = var_0_6:summonMonster(var_6_1)

		if next(var_6_2) == nil then
			return
		end

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			local var_6_3 = arg_6_0:getSkillLevelByID(var_6_1)
			local var_6_4 = arg_6_0.hero_:getColor()
			local var_6_5

			if var_6_0:isBoss() then
				local var_6_6 = var_6_0:getFlipX() == true and -1 or 1

				var_6_5 = var_6_0:getX() + var_6_6 * 100
			else
				var_6_5 = arg_6_0:getX() < var_6_0:getX() and var_6_0:getX() - 100 or var_6_0:getX() + 100
			end

			local var_6_7 = var_0_1.ctx.battle.adjustX(var_6_5, arg_6_0)
			local var_6_8 = {
				y = 230,
				x = var_6_7
			}

			if var_6_0:avoidHeroMoveBehind() then
				var_6_8.x = var_6_8.x - var_6_0:getFighterModel():getWidth()
			end

			local var_6_9 = true

			if arg_6_0.summonMonsters_ and next(arg_6_0.summonMonsters_) then
				for iter_6_2 = #arg_6_0.summonMonsters_, 1, -1 do
					if arg_6_0.summonMonsters_[iter_6_2] and not arg_6_0.summonMonsters_[iter_6_2]:isDeath() then
						var_6_9 = false

						arg_6_0.summonMonsters_[iter_6_2]:updateHp(0)
						arg_6_0.summonMonsters_[iter_6_2]:die()
					end
				end

				arg_6_0.summonMonsters_ = {}
			end

			arg_6_0:setSummonMonsters(iter_6_1, var_6_3, var_6_4, var_6_8, var_6_9)
		end
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_10 = 0

		if arg_6_0.isBlueAddSpeedBuff_ then
			var_6_10 = var_0_9
		else
			var_6_10 = var_0_8
		end

		local var_6_11 = {
			arg_6_1.target
		}
		local var_6_12 = arg_6_0:createAttackUnits(var_6_11, var_6_10)

		for iter_6_3, iter_6_4 in ipairs(var_6_12) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_4)
			table.insert(arg_6_0.records_.special_units, iter_6_4)
		end
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if not arg_6_1.target:isBoss() then
			arg_6_0:playEnterSKillEffect(arg_6_1.target)
		else
			arg_6_1.target:removeBuffByID(var_0_12)
		end
	end

	if arg_6_0:hasElementEquipByID(var_0_20) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and (arg_6_0.elementCount == 0 or var_0_1.ctx.battle.count - arg_6_0.elementCount > var_0_24) and (arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) or arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)) then
		local var_6_13 = arg_6_0:getTargets(var_0_21)
		local var_6_14 = arg_6_0:createAttackUnits(var_6_13, var_0_21)

		arg_6_0.elementCount = var_0_1.ctx.battle.count

		for iter_6_5, iter_6_6 in ipairs(var_6_14) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_6)
			table.insert(arg_6_0.records_.special_units, iter_6_6)
		end
	end
end

function var_0_3.setSummonMonsters(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	local var_7_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_7_0 = arg_7_0:getSummonMonster()
	else
		local var_7_1 = var_0_5.new()

		var_7_1:populateWithTableID(arg_7_1)

		var_7_1.level_ = arg_7_2 or var_7_1.level_
		var_7_1.color_ = arg_7_3 or var_7_1.color_

		for iter_7_0, iter_7_1 in ipairs(var_7_1.skillLev_) do
			local var_7_2 = arg_7_0.hero_:getSkillLevel(iter_7_0)

			if var_7_2 and var_7_2 > 0 then
				var_7_1.skillLev_[iter_7_0] = var_0_0.clone(var_7_2)
			end
		end

		local var_7_3 = var_7_1:className()

		var_7_0 = var_0_1.ctx.battle.requireFighter(var_7_3).new({
			is_arena = arg_7_0.isInArena_
		})

		var_7_0:populateWithHero(var_7_1)
		var_7_0:initModels()
		var_7_0.fighterModel:initHeaderView(arg_7_0:getTeamType() - 1)

		var_7_0.fighterIndex = arg_7_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)
	end

	var_7_0:setTeamType(arg_7_0:getTeamType())

	var_7_0.summoner = arg_7_0

	var_7_0.fighterModel:pos(arg_7_4.x, arg_7_4.y)
	var_7_0:getFighterModel():flipX(arg_7_0:getTeamType() == var_0_2.TeamType.B)
	var_7_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_7_0:born()
	var_7_0:setGlobalBuffs()
	var_7_0:updateHp(var_7_0:getHpLimit())
	table.insert(arg_7_0.summonMonsters_, var_7_0)

	if arg_7_0.isSkinSkillOn_ and arg_7_0.skinSkillID_ == var_0_16 and not arg_7_5 then
		var_7_0:resetHpLimit(var_7_0:getHpLimit() * (1 + var_0_18))
		var_7_0:updateHp(var_7_0:getHpLimit())
	end

	local var_7_4 = var_7_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_7_4, var_7_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_7_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.selectTargetByTypeD2(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getHp() / iter_8_1:getHpLimit() < var_0_7 then
			table.insert(var_8_0, iter_8_1)
		end
	end

	arg_8_0.isBlueAddSpeedBuff_ = false

	if #var_8_0 == 0 then
		arg_8_0.isBlueAddSpeedBuff_ = true
		var_8_0 = arg_8_0.selfTeam_
	end

	return var_8_0
end

function var_0_3.newBuff(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_1 = var_0_4.new({
			tableID = iter_9_1,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(arg_9_3),
			skillID = arg_9_3,
			fighter = arg_9_0,
			target = arg_9_2
		})

		var_9_1:setIsHit(true)
		var_9_1:setDirection(arg_9_0:getFighterModel():getFlipX())
		table.insert(var_9_0, var_9_1)
	end

	return var_9_0
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	var_0_3.super.buffAddAction(arg_10_0, arg_10_1)

	if arg_10_0:hasElementEquipByID(var_0_20) and arg_10_1:getTableID() == var_0_23 then
		local var_10_0 = var_0_20

		arg_10_1.manualDharm = var_0_19:battleAttr(var_10_0, arg_10_0:getElementEquipLevelByID(var_10_0)) * arg_10_0.hero_:getElementEquipActiveRate(var_10_0)
	end
end

function var_0_3.buffRemoveAction(arg_11_0, arg_11_1)
	var_0_3.super.buffRemoveAction(arg_11_0, arg_11_1)

	if arg_11_1:getTableID() == var_0_10 then
		local var_11_0 = arg_11_0:newBuff({
			var_0_11
		}, arg_11_1.target, arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

		arg_11_1.target:addBuffs(var_11_0)
	elseif arg_11_1:getTableID() == var_0_12 then
		if not arg_11_0.purpleSkillTarget or not arg_11_0.purpleSkillEffect or not next(arg_11_0.purpleSkillTarget) then
			return
		end

		arg_11_0.purpleSkillEffect:removeSelf()

		arg_11_0.purpleSkillEffect = nil

		arg_11_0.purpleSkillTarget:pos(arg_11_0.purpleSkillTarget:getX(), arg_11_0.purpleSkillTargetPos.y)

		arg_11_0.purpleSkillTarget = nil
	elseif arg_11_1:getTableID() == var_0_23 then
		local var_11_1 = {}

		for iter_11_0, iter_11_1 in ipairs(arg_11_0.summonMonsters_) do
			if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
				table.insert(var_11_1, iter_11_1)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_11_2 = arg_11_0:createAttackUnits(var_11_1, var_0_22)

			for iter_11_2, iter_11_3 in ipairs(var_11_2) do
				iter_11_3.cureHp = arg_11_1:totalDHarm() * var_0_25

				table.insert(arg_11_0.moveAttackUnits_, iter_11_3)
				table.insert(arg_11_0.records_.special_units, iter_11_3)
			end
		end
	end
end

function var_0_3.checkMove(arg_12_0)
	if arg_12_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_12_0.hero_:enterDuration() then
			arg_12_0.isWalking_ = 1

			if not arg_12_0:isWalking() then
				arg_12_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_12_0:isWalking() == 2 then
				local var_12_0 = arg_12_0:getFlipX() and -1 or 1

				arg_12_0:moveByX(arg_12_0.hero_:enterSpeed() * var_12_0)
			end

			if arg_12_0:getCurrentAnimation() ~= "run" then
				arg_12_0:modelWalk()
			end
		elseif not arg_12_0.playedEnterSkill_ then
			if arg_12_0:isWalking() ~= 3 then
				arg_12_0.preWalk_ = false
				arg_12_0.isWalking_ = false
				arg_12_0.behindWalk_ = false
				arg_12_0.playedEnterSkill_ = true
				arg_12_0.walk2Position_ = false

				if arg_12_0:getCurrentAnimation() == "run" then
					arg_12_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_12_0.hero_:enterDelayDuration() then
			arg_12_0.isEnterSkill_ = nil
			arg_12_0.walk2Position_ = false
			arg_12_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_12_0)
end

function var_0_3.setFormation(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	arg_13_0.isEnterSkill_ = arg_13_0:enterSkill() > 0 and arg_13_0:getSkillLevelByID(arg_13_0:enterSkill()) > 0

	if arg_13_0.isEnterSkill_ then
		arg_13_0.playedEnterSkill_ = false

		local var_13_0 = arg_13_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_13_0:x(var_13_0)
		arg_13_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_13_3 - 90 * (arg_13_2 % 2))

		return arg_13_2 + 1
	end

	return var_0_3.super.setFormation(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
end

function var_0_3.enterSkill(arg_14_0)
	return arg_14_0.hero_:enterSkill()
end

function var_0_3.playEnterSKillEffect(arg_15_0, arg_15_1)
	if arg_15_0.purpleSkillEffect or arg_15_1:isDeath() or arg_15_1:isAffected() then
		return
	end

	arg_15_0.purpleSkillTarget = arg_15_1
	arg_15_0.purpleSkillTargetPos = {
		x = arg_15_1:getX(),
		y = arg_15_1:getY()
	}

	local var_15_0 = {
		x = arg_15_0:getX(),
		y = var_0_2.STAGE_HEIGHT - 100
	}
	local var_15_1 = {
		x = arg_15_1:getX(),
		y = arg_15_1:getY() + arg_15_1:getFighterModel():getHeight() - 50
	}
	local var_15_2 = var_0_1.ctx.battle.getSpine(arg_15_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), "area", 1)

	var_15_2:addTo(var_0_1.ctx.battle.unitBottomLayer)
	var_15_2:pos(var_15_0.x, var_15_0.y)
	var_15_2:playRepeat()

	local var_15_3 = arg_15_0:getFlipX()

	var_15_2:flipX(var_15_3)

	arg_15_0.purpleSkillEffect = var_15_2

	arg_15_0:getPathQueue(var_15_0, var_15_1, var_15_3)
end

function var_0_3.getPathQueue(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	arg_16_0.pathQueue_ = {}

	local var_16_0 = arg_16_3 == true and -1 or 1
	local var_16_1 = arg_16_1.y - arg_16_2.y
	local var_16_2 = arg_16_1.x - arg_16_2.x
	local var_16_3 = var_0_13
	local var_16_4 = var_16_0 * math.abs(var_16_2) / var_16_3

	local function var_16_5(arg_17_0)
		local var_17_0 = var_16_1 / (var_16_3 * var_16_3)

		return arg_16_1.y - var_17_0 * (arg_17_0 * arg_17_0)
	end

	for iter_16_0 = 1, var_16_3 do
		table.insert(arg_16_0.pathQueue_, {
			var_16_4,
			var_16_5(iter_16_0),
			false
		})
	end

	local var_16_6 = arg_16_2.y
	local var_16_7 = var_0_14
	local var_16_8 = var_0_15 * var_16_0

	for iter_16_1 = 1, var_16_7 do
		var_16_6 = var_16_6 + var_0_15

		table.insert(arg_16_0.pathQueue_, {
			var_16_8,
			var_16_6,
			true
		})
	end
end

function var_0_3.moveSkillEffect(arg_18_0)
	if arg_18_0.pathQueue_ and next(arg_18_0.pathQueue_) and arg_18_0.pathQueue_[1] then
		if not arg_18_0.purpleSkillEffect then
			return
		end

		local var_18_0, var_18_1, var_18_2 = unpack(arg_18_0.pathQueue_[1])
		local var_18_3, var_18_4 = arg_18_0.purpleSkillEffect:getPosition()

		arg_18_0.purpleSkillEffect:pos(var_18_3 + var_18_0, var_18_1)
		table.remove(arg_18_0.pathQueue_, 1)

		if not arg_18_0.purpleInitTargetPos then
			arg_18_0.purpleInitTargetPos = true

			if not arg_18_0.purpleSkillTarget or not next(arg_18_0.purpleSkillTarget) then
				return
			end

			arg_18_0.purpleSkillTarget:pos(arg_18_0.purpleSkillTargetPos.x, arg_18_0.purpleSkillTargetPos.y)
		end

		if var_18_2 then
			if not arg_18_0.purpleSkillTarget or not next(arg_18_0.purpleSkillTarget) then
				return
			end

			local var_18_5, var_18_6 = arg_18_0.purpleSkillTarget:getPos()
			local var_18_7 = arg_18_0:getFlipX() == true and -1 or 1

			arg_18_0.purpleSkillTarget:pos(var_18_5 + var_0_15 * var_18_7, var_18_6 + var_0_15)
		end
	end
end

function var_0_3.die(arg_19_0)
	if arg_19_0.purpleSkillTarget and next(arg_19_0.purpleSkillTarget) then
		arg_19_0.purpleSkillTarget:pos(arg_19_0.purpleSkillTarget:getX(), arg_19_0.purpleSkillTargetPos.y)

		arg_19_0.purpleSkillTarget = nil
	end

	if arg_19_0.purpleSkillEffect then
		arg_19_0.purpleSkillEffect:removeSelf()

		arg_19_0.purpleSkillEffect = nil
	end

	var_0_3.super.die(arg_19_0)
end

function var_0_3.deathFeedback(arg_20_0, arg_20_1)
	if arg_20_0.purpleSkillTarget and next(arg_20_0.purpleSkillTarget) and arg_20_0.purpleSkillTarget == arg_20_1 then
		arg_20_0.purpleSkillTarget:pos(arg_20_0.purpleSkillTarget:getX(), arg_20_0.purpleSkillTargetPos.y)

		arg_20_0.purpleSkillTarget = nil

		if arg_20_0.purpleSkillEffect then
			arg_20_0.purpleSkillEffect:removeSelf()

			arg_20_0.purpleSkillEffect = nil
			arg_20_0.pathQueue_ = {}
			arg_20_0.purpleSkillTarget = nil
		end
	end
end

return var_0_3
