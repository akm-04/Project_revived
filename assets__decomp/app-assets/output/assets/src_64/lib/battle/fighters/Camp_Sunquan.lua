local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunquan", var_0_1.ctx.battle.requireFighter("CampWarBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_7 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 40010056
local var_0_11 = 45
local var_0_12 = 10000181
local var_0_13 = {
	20010113,
	20010114
}
local var_0_14 = 300
local var_0_15 = 120
local var_0_16 = 10000180
local var_0_17 = 30010025
local var_0_18 = 15

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isChanged = false
	arg_1_0.copyHeros = {}
	arg_1_0.count = false
	arg_1_0.copyMonsterID = 80000108
	arg_1_0.greenSkillCD_ = 0
	arg_1_0.greenExist = false

	if arg_1_0:getTeamType() == var_0_2.TeamType.A and arg_1_0.bottomWnd then
		arg_1_0.bottomWnd:setXuliSkillEffect(arg_1_0, var_0_1.ctx.battle.teamA, false)
	end
end

function var_0_3.jugeGreenSkill(arg_2_0)
	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		arg_2_0.greenExist = true
		arg_2_0.greenRatio = math.abs(var_0_9:init(var_0_17) + var_0_9:step(var_0_17) * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.green))
	else
		arg_2_0.greenExist = false
	end
end

function var_0_3.getExtraHarm(arg_3_0)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_3_0.extraHarm then
		arg_3_0.extraHarm = var_0_8:init(var_0_12) + var_0_8:step(var_0_12) * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end
end

function var_0_3.singleLoop(arg_4_0)
	if not arg_4_0.count then
		arg_4_0:jugeGreenSkill()
		arg_4_0:getExtraHarm()

		arg_4_0.count = true
	end

	var_0_3.super.singleLoop(arg_4_0)

	if arg_4_0:acttionInBlack() and not arg_4_0:isDeath() then
		if arg_4_0.isReady then
			arg_4_0.readyTime = arg_4_0.readyTime - 1

			if arg_4_0.readyTime == 0 then
				arg_4_0:changeToCopy()

				arg_4_0.isReady = false
			end
		end

		if next(arg_4_0.copyHeros) ~= nil and arg_4_0.copyTime then
			arg_4_0.copyTime = arg_4_0.copyTime - 1

			if arg_4_0.copyTime == 0 then
				for iter_4_0, iter_4_1 in ipairs(arg_4_0.copyHeros) do
					iter_4_1[1]:updateHp(0)
					iter_4_1[1]:die()
				end

				arg_4_0.copyHeros = {}
			elseif arg_4_0.copyTime < 30 and arg_4_0:isAutoFighter() and not arg_4_0.isChanged and not arg_4_0:isFear() and not arg_4_0:isApUnable() and not arg_4_0:isApUnable() and not arg_4_0:isAttackFriend() and not arg_4_0:isDeath() then
				arg_4_0:readyToChange()

				arg_4_0.isChanged = true
			end

			for iter_4_2 = #arg_4_0.copyHeros, 1, -1 do
				local var_4_0 = arg_4_0.copyHeros[iter_4_2]

				if var_4_0[1]:isDeath() then
					table.remove(arg_4_0.copyHeros, iter_4_2)
				elseif var_4_0[2] and var_4_0[2]:isDeath() then
					var_4_0[2] = var_4_0[1]:getNearestTarget()
				end
			end

			if next(arg_4_0.copyHeros) == nil and arg_4_0:getTeamType() == var_0_2.TeamType.A and arg_4_0.bottomWnd then
				arg_4_0.bottomWnd:setXuliSkillEffect(arg_4_0, var_0_1.ctx.battle.teamA, false)
			end
		end

		if arg_4_0.unitSkills_ and var_0_8:father(arg_4_0.unitSkills_.rootID_) == arg_4_0:getEnergySkillID() then
			if arg_4_0.frontTime then
				arg_4_0.frontTime = arg_4_0.frontTime - 1

				if arg_4_0.frontTime == 0 then
					if next(arg_4_0.copyHeros) ~= nil then
						for iter_4_3, iter_4_4 in ipairs(arg_4_0.copyHeros) do
							if not iter_4_4[1]:isDeath() then
								iter_4_4[1]:updateHp(0)
								iter_4_4[1]:die()
							end
						end

						arg_4_0.copyHeros = {}
					end

					local var_4_1 = var_0_8:summonMonster(arg_4_0.unitSkills_.rootID_)[1]

					arg_4_0:setSummonMonsters(var_4_1, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), arg_4_0.hero_:getColor())

					arg_4_0.frontTime = nil
				end
			end
		else
			if arg_4_0.frontTime and arg_4_0:getTeamType() == var_0_2.TeamType.A and arg_4_0.bottomWnd then
				arg_4_0.bottomWnd:setXuliSkillEffect(arg_4_0, var_0_1.ctx.battle.teamA, false)
			end

			arg_4_0.frontTime = nil
		end
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0.greenExist then
		if arg_5_0.greenSkillCD_ > 0 then
			arg_5_0.greenSkillCD_ = arg_5_0.greenSkillCD_ - 1
		elseif arg_5_0:getOriHurt() ~= 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_5_0.reflectHarm = arg_5_0:getOriHurt() * arg_5_0.greenRatio
			arg_5_0.oriHurt = 0

			local var_5_0 = var_0_16
			local var_5_1 = var_0_4.B8(arg_5_0, var_5_0)
			local var_5_2 = arg_5_0:createAttackUnits(var_5_1, var_5_0)

			for iter_5_0, iter_5_1 in ipairs(var_5_2) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end

			arg_5_0.greenSkillCD_ = var_0_11
		end
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if var_0_8:father(arg_6_1.rootID_) == arg_6_0:getEnergySkillID() then
		arg_6_0.isChanged = false
		arg_6_0.frontTime = var_0_8:pretime(arg_6_0:getEnergySkillID())

		if arg_6_0:getTeamType() == var_0_2.TeamType.A and arg_6_0.bottomWnd then
			arg_6_0.bottomWnd:setXuliSkillEffect(arg_6_0, var_0_1.ctx.battle.teamA, true)
		end
	end

	if arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_6_0:addSpecialBuff()
	end
end

function var_0_3.addSpecialBuff(arg_7_0)
	local function var_7_0(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
		local var_8_0 = {}

		for iter_8_0, iter_8_1 in ipairs(arg_8_0) do
			local var_8_1 = var_0_5.new({
				tableID = iter_8_1,
				start = var_0_1.ctx.battle.count,
				level = arg_8_2,
				skillID = arg_8_1,
				fighter = arg_7_0,
				target = arg_8_3
			})

			table.insert(var_8_0, var_8_1)
		end

		return var_8_0
	end

	local var_7_1 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_7_2 = arg_7_0:getSkillLevelByID(var_7_1)

	arg_7_0:addBuffs(var_7_0(var_0_13, var_7_1, var_7_2, arg_7_0))
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and next(arg_9_1.target.buffs_) ~= nil then
		for iter_9_0 = #arg_9_1.target.buffs_, 1, -1 do
			local var_9_0 = arg_9_1.target.buffs_[iter_9_0]

			if var_9_0:getType() == var_0_2.BuffType.D_HARM then
				arg_9_1.target:removeBuffs(var_9_0)

				if arg_9_1.target.showDHarmbuff_ == var_9_0 then
					arg_9_1.target.showDHarmbuff_ = nil

					arg_9_1.target.fighterModel:updateHeroHeaderView(var_0_1.ctx.battle.count, arg_9_1.target.showDHarmbuff_)
				end
			end
		end
	end
end

function var_0_3.setSummonMonsters(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_10_0, iter_10_1 in ipairs(var_10_0) do
		if iter_10_1:getSummonType() == 0 and not iter_10_1:isDeath() then
			local var_10_1
			local var_10_2 = {
				x = iter_10_1:getX(),
				y = iter_10_1:getY()
			}

			if iter_10_1:getTeamType() == var_0_2.TeamType.A then
				var_10_2.x = var_10_2.x + var_0_15
			else
				var_10_2.x = var_10_2.x - var_0_15
			end

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				local var_10_3 = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

				var_10_1 = var_0_1.ctx.battle.summonMonsters[var_10_3]
			else
				local var_10_4 = var_0_7.new()

				var_10_4:populateWithTableID(arg_10_1)

				var_10_4.level_ = arg_10_2 or var_10_4.level_
				var_10_4.color_ = arg_10_3 or var_10_4.color_

				for iter_10_2, iter_10_3 in ipairs(var_10_4.skillLev_) do
					local var_10_5 = var_10_4:getSkillId(iter_10_2)
					local var_10_6 = arg_10_0.hero_:getSkillLevelByID(var_10_5)

					if var_10_6 and var_10_6 > 0 then
						var_10_4.skillLev_[iter_10_2] = var_0_0.clone(var_10_6)
					end
				end

				local var_10_7 = var_10_4:className()

				var_10_1 = var_0_1.ctx.battle.requireFighter(var_10_7).new({
					is_arena = arg_10_0.isInArena_
				})

				var_10_1:populateWithHero(var_10_4)
				var_10_1:initModels()
				var_10_1.fighterModel:initHeaderView(arg_10_0:getTeamType() - 1)

				var_10_1.fighterIndex = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

				var_10_1:setFormationDelay(0, 100)
			end

			var_10_1:setTeamType(arg_10_0:getTeamType())

			var_10_1.summoner = arg_10_0

			var_10_1.fighterModel:pos(var_10_2.x, var_10_2.y)
			var_10_1:updateHp(var_10_1:getHpLimit())
			var_10_1:getFighterModel():flipX(arg_10_0:getTeamType() == var_0_2.TeamType.B)
			var_10_1.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
			var_10_1:born()
			var_10_1:setGlobalBuffs()

			local var_10_8 = var_10_1:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

			table.insert(var_10_8, var_10_1)
			table.insert(var_0_1.ctx.battle.yOrder, var_10_1)
			var_0_1.ctx.battle.updateZorder()

			arg_10_0.copyTime = var_0_0.clone(var_0_14)

			table.insert(arg_10_0.copyHeros, {
				var_10_1,
				iter_10_1
			})
		end
	end
end

function var_0_3.die(arg_11_0)
	var_0_3.super.die(arg_11_0)

	if arg_11_0:getTeamType() == var_0_2.TeamType.A and arg_11_0.bottomWnd then
		arg_11_0.bottomWnd:setXuliSkillEffect(arg_11_0, var_0_1.ctx.battle.teamA, false)
	end

	if next(arg_11_0.copyHeros) ~= nil then
		for iter_11_0, iter_11_1 in ipairs(arg_11_0.copyHeros) do
			if not iter_11_1[1]:isDeath() then
				iter_11_1[1]:updateHp(0)
				iter_11_1[1]:die()
			end
		end

		arg_11_0.copyHeros = {}
	end
end

function var_0_3.clickAvatar(arg_12_0, arg_12_1)
	if arg_12_1.name == "ended" and var_0_1.ctx.battle.autoA ~= true then
		if arg_12_0:getWin() then
			if arg_12_0:getTeamType() == var_0_2.TeamType.A and arg_12_0.bottomWnd then
				arg_12_0.bottomWnd:setXuliSkillEffect(arg_12_0, var_0_1.ctx.battle.teamA, false)
			end
		elseif not arg_12_0:isFear() and not arg_12_0:isApUnable() and not arg_12_0:isApUnable() and not arg_12_0:isAttackFriend() and not arg_12_0:isDeath() and next(arg_12_0.copyHeros) ~= nil and not arg_12_0.isChanged then
			arg_12_0:readyToChange()

			arg_12_0.isChanged = true
		end
	end

	var_0_3.super.clickAvatar(arg_12_0, arg_12_1)
end

function var_0_3.getWin(arg_13_0)
	if next(arg_13_0.copyHeros) ~= nil then
		for iter_13_0, iter_13_1 in ipairs(arg_13_0.copyHeros) do
			if iter_13_1[2] and not iter_13_1[2]:isDeath() then
				return false
			end
		end

		return true
	end

	return false
end

function var_0_3.readyToChange(arg_14_0)
	arg_14_0:getFighterModel():playAnimation_("gongji04")

	arg_14_0.isReady = true
	arg_14_0.readyTime = var_0_0.clone(var_0_18)
end

function var_0_3.changeToCopy(arg_15_0)
	local var_15_0
	local var_15_1
	local var_15_2
	local var_15_3

	if arg_15_0:getTeamType() == var_0_2.TeamType.A and arg_15_0.bottomWnd then
		arg_15_0.bottomWnd:setXuliSkillEffect(arg_15_0, var_0_1.ctx.battle.teamA, false)
	end

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.copyHeros) do
		if not iter_15_1[1]:isDeath() and iter_15_1[2] then
			if not var_15_0 then
				var_15_2 = iter_15_1[1]
				var_15_0 = iter_15_1[2]
				var_15_1 = iter_15_1[2]:getHp() / iter_15_1[2]:getHpLimit()
				var_15_3 = iter_15_0
			else
				local var_15_4 = iter_15_1[2]:getHp() / iter_15_1[2]:getHpLimit()

				if var_15_4 < var_15_1 then
					var_15_2 = iter_15_1[1]
					var_15_0 = iter_15_1[2]
					var_15_1 = var_15_4
					var_15_3 = iter_15_0
				elseif var_15_4 == var_15_1 and iter_15_1[2]:getHp() < var_15_0:getHp() then
					var_15_0 = iter_15_1[2]
					var_15_1 = var_15_4
					var_15_2 = iter_15_1[1]
					var_15_3 = iter_15_0
				end
			end
		end
	end

	if var_15_2 then
		local var_15_5 = var_15_2:getX()
		local var_15_6 = var_15_2:getY()

		arg_15_0:x(var_15_5)
		arg_15_0:y(var_15_6)
		table.remove(arg_15_0.copyHeros, var_15_3)
		var_15_2.fighterModel:setVisible(false)
		var_15_2:updateHp(0)
		var_15_2:die()
	end
end

function var_0_3.calculateUnitData(arg_16_0, arg_16_1)
	local var_16_0, var_16_1, var_16_2, var_16_3, var_16_4, var_16_5 = var_0_3.super.calculateUnitData(arg_16_0, arg_16_1)

	if arg_16_1.skillID == var_0_10 and var_16_2 > 0 then
		local var_16_6 = 0

		for iter_16_0, iter_16_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if not iter_16_1:isDeath() and iter_16_1:getSummonType() == 0 then
				var_16_6 = var_16_6 + 1
			end
		end

		for iter_16_2, iter_16_3 in ipairs(var_0_1.ctx.battle.teamB) do
			if not iter_16_3:isDeath() and iter_16_3:getSummonType() == 0 then
				var_16_6 = var_16_6 + 1
			end
		end

		if var_16_6 <= 10 and var_16_2 > 0 then
			var_16_2 = var_16_2 + (10 - var_16_6) * arg_16_0.extraHarm * arg_16_1.target:getADJianShang()
		end
	elseif arg_16_1.skillID == var_0_16 then
		var_16_2 = arg_16_0.reflectHarm * arg_16_1.target:getADJianShang()
	end

	return var_16_0, var_16_1, var_16_2, var_16_3, var_16_4, var_16_5
end

function var_0_3.checkMove(arg_17_0)
	if arg_17_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_17_0.hero_:enterDuration() then
			arg_17_0.isWalking_ = 1

			if not arg_17_0:isWalking() then
				arg_17_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_17_0:isWalking() == 2 then
				local var_17_0 = arg_17_0:getFlipX() and -1 or 1

				arg_17_0:moveByX(arg_17_0.hero_:enterSpeed() * var_17_0)
			end

			if arg_17_0:getCurrentAnimation() ~= "run" then
				arg_17_0:modelWalk()
			end
		elseif not arg_17_0.playedEnterSkill_ then
			if arg_17_0:isWalking() ~= 3 then
				arg_17_0.preWalk_ = false
				arg_17_0.isWalking_ = false
				arg_17_0.behindWalk_ = false
				arg_17_0.playedEnterSkill_ = true
				arg_17_0.walk2Position_ = false

				if arg_17_0:getCurrentAnimation() == "run" then
					arg_17_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_17_0.hero_:enterDelayDuration() then
			arg_17_0.isEnterSkill_ = nil
			arg_17_0.walk2Position_ = false
			arg_17_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_17_0)
end

function var_0_3.setFormation(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	arg_18_0.isEnterSkill_ = arg_18_0:enterSkill() > 0 and arg_18_0:getSkillLevelByID(arg_18_0:enterSkill()) > 0

	if arg_18_0.isEnterSkill_ then
		arg_18_0.playedEnterSkill_ = false

		local var_18_0 = arg_18_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_18_0:x(var_18_0)
		arg_18_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_18_3 - 90 * (arg_18_2 % 2))

		return arg_18_2 + 1
	end

	return var_0_3.super.setFormation(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
end

function var_0_3.enterSkill(arg_19_0)
	return arg_19_0.hero_:enterSkill()
end

return var_0_3
