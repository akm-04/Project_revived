local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Nvheguan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10000549
local var_0_8 = 10000550
local var_0_9 = 0.07
local var_0_10 = 10000548
local var_0_11 = 20
local var_0_12 = 40010392
local var_0_13 = 40010393
local var_0_14 = 10010174
local var_0_15 = 20
local var_0_16 = 0.07
local var_0_17 = 10000551
local var_0_18 = 30
local var_0_19 = 25
local var_0_20 = "skeletons/nvheguan/shaizi"
local var_0_21 = 240
local var_0_22 = 40012080
local var_0_23 = 80010125

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.chipNums_ = 3
	arg_1_0.blueChipNums_ = 0
	arg_1_0.greenEnemyTarget_ = nil
	arg_1_0.selfGreenNum_ = 0
	arg_1_0.sideGreenNum_ = 0
	arg_1_0.greenCount_ = 0
	arg_1_0.rebornCount_ = 0
	arg_1_0.diceCount_ = 0
	arg_1_0.selfDiceShowCount_ = 0
	arg_1_0.timeSeed_ = 1
	arg_1_0.isNextBetSilence_ = false
	arg_1_0.greenHarmBetSilence_ = false
	arg_1_0.isThreeSame_ = false
	arg_1_0.selfDice_ = nil
	arg_1_0.sideDice_ = nil
	arg_1_0.purpleNums_ = {}

	arg_1_0:removeActionNum()

	arg_1_0.records_.self_green_num = {}
	arg_1_0.records_.side_green_num = {}
	arg_1_0.showBetNum_ = false
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_2_0.greenJudge_ = false
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if not arg_3_0.greenEnemyTarget_ and arg_3_1.target == arg_3_0 then
			-- block empty
		else
			if arg_3_1.target ~= arg_3_0 then
				arg_3_0.greenEnemyTarget_ = arg_3_1.target
			end

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				if arg_3_1.target == arg_3_0 then
					arg_3_0.selfGreenNum_ = arg_3_0:greenSkillBet(true)
					arg_3_0.records_.self_green_num[tostring(var_0_1.ctx.battle.count)] = arg_3_0.selfGreenNum_
				else
					arg_3_0.sideGreenNum_ = arg_3_0:greenSkillBet(false)
					arg_3_0.records_.side_green_num[tostring(var_0_1.ctx.battle.count)] = arg_3_0.sideGreenNum_
				end

				if not arg_3_0.greenJudge_ then
					arg_3_0.greenCount_ = var_0_11
					arg_3_0.greenJudge_ = true
				end
			else
				if arg_3_1.target == arg_3_0 then
					arg_3_0.selfGreenNum_ = arg_3_0.selfGreenReportData_[tostring(var_0_1.ctx.battle.count)] or 1
				else
					arg_3_0.sideGreenNum_ = arg_3_0.sideGreenReportData_[tostring(var_0_1.ctx.battle.count)] or 1
				end

				arg_3_0.greenCount_ = var_0_11
			end
		end
	elseif arg_3_1.skillID == var_0_10 and arg_3_1.target ~= arg_3_0 and arg_3_0.greenHarmBetSilence_ then
		local var_3_0 = var_0_4.new({
			tableID = var_0_14,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_1.skillID),
			skillID = arg_3_1.skillID,
			fighter = arg_3_0,
			target = arg_3_1.target
		})

		arg_3_1.target:addBuffs({
			var_3_0
		})

		arg_3_0.greenHarmBetSilence_ = false
	elseif arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		local var_3_1
		local var_3_2

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_3_2 or var_3_2 < iter_3_1.harms) then
				var_3_1 = iter_3_1
				var_3_2 = iter_3_1.harms
			end
		end

		if var_3_1 == arg_3_1.target then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_3 = arg_3_0:createAttackUnits({
					var_3_1
				}, var_0_7)

				for iter_3_2, iter_3_3 in ipairs(var_3_3) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end

				arg_3_0.energyNums_ = arg_3_0.chipNums_
			end

			arg_3_0:updateChip(-arg_3_0.chipNums_)
		else
			arg_3_0:updateChip(-arg_3_0.chipNums_ * 0.5)
		end
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if not arg_4_0.showBetNum_ and not arg_4_0:isDeath() then
		arg_4_0.showBetNum_ = true

		arg_4_0:updateStateNumber(arg_4_0.chipNums_)
	end

	if arg_4_0.greenCount_ > 0 then
		arg_4_0.greenCount_ = arg_4_0.greenCount_ - 1

		if arg_4_0.greenCount_ == 0 then
			local var_4_0

			if arg_4_0.selfGreenNum_ > arg_4_0.sideGreenNum_ then
				var_4_0 = arg_4_0.greenEnemyTarget_

				arg_4_0:updateChip(1)
			elseif arg_4_0.selfGreenNum_ < arg_4_0.sideGreenNum_ then
				var_4_0 = arg_4_0

				arg_4_0:updateChip(-1)
			end

			if arg_4_0.isNextBetSilence_ then
				arg_4_0.greenHarmBetSilence_ = true
				arg_4_0.isNextBetSilence_ = false
			end

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_4_0 then
				local var_4_1 = arg_4_0:createAttackUnits({
					var_4_0
				}, var_0_10)

				for iter_4_0, iter_4_1 in ipairs(var_4_1) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end
			end

			arg_4_0:greenAction()

			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
				arg_4_0:purpleJudge(arg_4_0.selfGreenNum_)
			end
		end
	end

	if arg_4_0.rebornCount_ > 0 then
		arg_4_0.rebornCount_ = arg_4_0.rebornCount_ - 1

		if arg_4_0.rebornCount_ <= 0 then
			if arg_4_0:rebornBet() then
				arg_4_0.isInRebornBet_ = false

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_0.rebornTarget_ and not arg_4_0.rebornTarget_:isDeath() and not arg_4_0.rebornTarget_:isAffected() then
					local var_4_2 = arg_4_0:createAttackUnits({
						arg_4_0.rebornTarget_
					}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

					for iter_4_2, iter_4_3 in ipairs(var_4_2) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
						table.insert(arg_4_0.records_.special_units, iter_4_3)
					end

					arg_4_0.blueChipNums_ = arg_4_0.chipNums_
				end
			else
				arg_4_0.isInRebornBet_ = false
				arg_4_0.killer_ = arg_4_0

				arg_4_0:updateHp(0)
				arg_4_0:die()
			end

			arg_4_0:updateChip(-arg_4_0.chipNums_)
		end
	end

	if arg_4_0.diceCount_ > 0 then
		arg_4_0.diceCount_ = arg_4_0.diceCount_ - 1

		if arg_4_0.diceCount_ <= 0 then
			if arg_4_0.selfDice_ then
				arg_4_0.selfDice_:removeSelf()

				arg_4_0.selfDice_ = nil
			end

			if arg_4_0.sideDice_ then
				arg_4_0.sideDice_:removeSelf()

				arg_4_0.sideDice_ = nil
			end
		end
	end

	if arg_4_0.selfDiceShowCount_ > 0 then
		arg_4_0.selfDiceShowCount_ = arg_4_0.selfDiceShowCount_ - 1

		if arg_4_0.selfDiceShowCount_ <= 0 and arg_4_0.selfDice_ then
			arg_4_0:removeBuffByID(var_0_13)
			arg_4_0.selfDice_:setVisible(true)
		end
	end

	if arg_4_0.skinSkillID_ == var_0_23 and var_0_1.ctx.battle.count % var_0_21 == 1 and not arg_4_0:isHasBuffByID(var_0_22) then
		local var_4_3 = arg_4_0:createNewBuffs({
			var_0_22
		}, arg_4_0, var_0_23)

		arg_4_0:addBuffs(var_4_3)
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}
	local var_5_1
	local var_5_2

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_5_0, iter_5_1)

			if not var_5_2 or var_5_2 < iter_5_1.harms then
				var_5_1 = iter_5_1
				var_5_2 = iter_5_1.harms
			end
		end
	end

	if #var_5_0 == 1 then
		return {
			var_5_1
		}
	else
		local var_5_3 = 0.6 + 0.2 * (arg_5_0.hero_:getStar() - 3)
		local var_5_4

		if arg_5_0:isHasBuffByID(var_0_22) then
			var_5_4 = true

			if arg_5_0.hero_:getStar() ~= 5 then
				arg_5_0:removeBuffByID(var_0_22)
			end
		else
			var_5_4 = var_0_2.weightedChoise({
				var_5_3,
				1 - var_5_3
			}) == 1
		end

		if var_5_4 then
			return {
				var_5_1
			}
		else
			for iter_5_2, iter_5_3 in ipairs(var_5_0) do
				if iter_5_3 == var_5_1 then
					table.remove(var_5_0, iter_5_2)

					break
				end
			end

			if #var_5_0 > 0 then
				return {
					var_5_0[math.random(1, #var_5_0)]
				}
			else
				return {}
			end
		end
	end
end

function var_0_3.selectTargetByTypeD2(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_6_2 = iter_6_1.hero_:getMainAttr(var_0_2.AttributeType.WISE)

			if not var_6_0 or var_6_2 < var_6_0 then
				var_6_1 = iter_6_1
				var_6_0 = var_6_2
			end
		end
	end

	if var_6_1 then
		return {
			var_6_1,
			arg_6_0
		}
	else
		return {}
	end
end

function var_0_3.greenSkillBet(arg_7_0, arg_7_1)
	if arg_7_1 then
		local var_7_0 = 0.47 * arg_7_0.hero_:getMainAttr(var_0_2.AttributeType.WISE) / math.max(1, arg_7_0.greenEnemyTarget_.hero_:getMainAttr(var_0_2.AttributeType.WISE))
		local var_7_1 = math.min(var_7_0, 0.7)
		local var_7_2 = math.max(var_7_1, 0)
		local var_7_3

		if arg_7_0:isHasBuffByID(var_0_22) then
			var_7_3 = true

			arg_7_0:removeBuffByID(var_0_22)
		else
			var_7_3 = var_0_2.weightedChoise({
				var_7_2,
				1 - var_7_2
			}) == 1
		end

		if var_7_3 then
			return 7
		end
	end

	math.randomseed(tonumber(tostring(os.time() + arg_7_0.timeSeed_):reverse():sub(1, 6)))

	local var_7_4 = math.random(tonumber(os.time()))

	arg_7_0.timeSeed_ = var_7_4

	math.randomseed(var_7_4)

	return (math.random(1, 6))
end

function var_0_3.purpleJudge(arg_8_0, arg_8_1)
	if #arg_8_0.purpleNums_ >= 3 then
		table.remove(arg_8_0.purpleNums_, 1)
		table.insert(arg_8_0.purpleNums_, arg_8_1)
		arg_8_0:purpleAction(arg_8_1, true)
	else
		table.insert(arg_8_0.purpleNums_, arg_8_1)
		arg_8_0:purpleAction(arg_8_1, false)
	end

	local var_8_0, var_8_1 = arg_8_0:purpleNumCheck()

	if var_8_0 ~= 0 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			if var_8_0 == 3 then
				arg_8_0.isThreeSame_ = true
			end

			local var_8_2 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_8_3 = var_0_6:sound(var_8_2)

			var_0_1.ctx.battle.pushSoundQueue(var_8_3)

			local var_8_4 = var_0_6:attackIndex(var_8_2)

			arg_8_0:playAttack(var_8_4)

			arg_8_0.unitSkills_ = var_0_5.new({
				fighter = arg_8_0,
				skillID = var_8_2
			})

			arg_8_0:beginAttackEnd(arg_8_0.unitSkills_)
		end

		arg_8_0:updateChip(var_8_0)

		if var_8_1 then
			arg_8_0.isNextBetSilence_ = true
		end
	end
end

function var_0_3.purpleNumCheck(arg_9_0)
	if #arg_9_0.purpleNums_ < 2 then
		return 0, false
	else
		local var_9_0 = {}

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.purpleNums_) do
			if var_9_0[iter_9_1] then
				var_9_0[iter_9_1] = var_9_0[iter_9_1] + 1
			else
				var_9_0[iter_9_1] = 1
			end
		end

		for iter_9_2, iter_9_3 in pairs(var_9_0) do
			if iter_9_3 == 2 then
				return 2, false
			elseif iter_9_3 == 3 then
				local var_9_1 = false

				if iter_9_2 == 7 then
					var_9_1 = true
				end

				return 3, var_9_1
			end
		end

		return 0, false
	end
end

function var_0_3.purpleAction(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_0:getTeamType() ~= var_0_2.TeamType.A or not arg_10_0.bottomWnd or not not tolua.isnull(arg_10_0.bottomWnd) or var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_10_2 and #arg_10_0.purpleNumDice_ >= 3 then
		arg_10_0.purpleNumDice_[1]:removeSelf()
		table.remove(arg_10_0.purpleNumDice_, 1)
		arg_10_0.purpleNumDice_[1]:runAction(cc.MoveBy:create(0.8, cc.p(-40, 0)))
		arg_10_0.purpleNumDice_[2]:runAction(cc.Sequence:create({
			cc.MoveBy:create(0.8, cc.p(-40, 0)),
			cc.CallFunc:create(function()
				local var_11_0 = tonumber(var_0_2.split(arg_10_0.fighterIndex, "|")[2])
				local var_11_1 = arg_10_0.bottomWnd.children_["click_node" .. var_11_0]
				local var_11_2 = var_0_20 .. arg_10_1 .. ".png"
				local var_11_3 = cc.Sprite:create(var_11_2)

				if var_11_3 then
					var_11_3:addTo(var_11_1, 100)
					var_11_3:setPosition(100, -40)
					var_11_3:setScale(1.5)
					var_11_3:setOpacity(0)
					var_11_3:runAction(cc.FadeIn:create(1))
					table.insert(arg_10_0.purpleNumDice_, var_11_3)
				end
			end)
		}))
	else
		local var_10_0 = tonumber(var_0_2.split(arg_10_0.fighterIndex, "|")[2])
		local var_10_1 = arg_10_0.bottomWnd.children_["click_node" .. var_10_0]
		local var_10_2 = var_0_20 .. arg_10_1 .. ".png"
		local var_10_3 = cc.Sprite:create(var_10_2)

		if var_10_3 and var_10_1 then
			var_10_3:addTo(var_10_1, 100)
			var_10_3:setPosition(20 + #arg_10_0.purpleNumDice_ * 40, -40)
			var_10_3:setScale(1.5)
			table.insert(arg_10_0.purpleNumDice_, var_10_3)
		end
	end
end

function var_0_3.updateHp(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_0.isInRebornBet_ then
		return
	else
		var_0_3.super.updateHp(arg_12_0, arg_12_1, arg_12_2)
	end
end

function var_0_3.removeActionNum(arg_13_0)
	if not arg_13_0.purpleNumDice_ then
		arg_13_0.purpleNumDice_ = {}
	else
		for iter_13_0, iter_13_1 in ipairs(arg_13_0.purpleNumDice_) do
			arg_13_0.purpleNumDice_[iter_13_0]:removeSelf()
		end

		arg_13_0.purpleNumDice_ = {}
	end
end

function var_0_3.die(arg_14_0)
	if arg_14_0:canReborn() then
		local var_14_0 = arg_14_0.killer_

		arg_14_0.hasReborn_ = true

		if var_14_0 and not var_14_0:getTeamType() ~= arg_14_0:getTeamType() then
			arg_14_0:updateHp(1)

			arg_14_0.isInRebornBet_ = true
			arg_14_0.rebornCount_ = var_0_15

			arg_14_0:playAttack(3)

			arg_14_0.rebornTarget_ = var_14_0
			arg_14_0.killer_ = nil
		else
			var_0_3.super.die(arg_14_0)
			arg_14_0:removeActionNum()
		end
	else
		var_0_3.super.die(arg_14_0)
		arg_14_0:removeActionNum()
	end
end

function var_0_3.forceDie(arg_15_0)
	arg_15_0.hasReborn_ = true

	var_0_3.super.forceDie(arg_15_0)
end

function var_0_3.rebornBet(arg_16_0)
	local var_16_0 = 0.5
	local var_16_1

	if arg_16_0:isHasBuffByID(var_0_22) then
		var_16_1 = true

		arg_16_0:removeBuffByID(var_0_22)
	else
		var_16_1 = var_0_2.weightedChoise({
			var_16_0,
			1 - var_16_0
		}) == 1
	end

	return var_16_1
end

function var_0_3.canReborn(arg_17_0)
	if arg_17_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) < 1 or arg_17_0.hasReborn_ then
		return false
	end

	return true
end

function var_0_3.greenAction(arg_18_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_18_0:removeBuffByID(var_0_12)
	arg_18_0.greenEnemyTarget_:removeBuffByID(var_0_12)

	local var_18_0 = var_0_20 .. arg_18_0.selfGreenNum_ .. ".png"

	arg_18_0.selfDice_ = cc.Sprite:create(var_18_0)

	if arg_18_0.selfDice_ then
		arg_18_0.selfDice_:addTo(arg_18_0.fighterModel, 100)
		arg_18_0.selfDice_:setPosition(cc.p(arg_18_0.fighterModel:getHeroAnimation().headPoint.x, arg_18_0.fighterModel:getHeroAnimation().headPoint.y))
		arg_18_0.selfDice_:setScale(1.5)

		if arg_18_0.selfGreenNum_ == 7 then
			local var_18_1 = arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
			local var_18_2 = var_0_4.new({
				tableID = var_0_13,
				start = var_0_1.ctx.battle.count,
				level = arg_18_0:getSkillLevelByID(var_18_1),
				skillID = var_18_1,
				fighter = arg_18_0,
				target = arg_18_0
			})

			arg_18_0:addBuffs({
				var_18_2
			})
			arg_18_0.selfDice_:setVisible(false)

			arg_18_0.selfDiceShowCount_ = var_0_19
		end
	end

	local var_18_3 = var_0_20 .. arg_18_0.sideGreenNum_ .. ".png"

	arg_18_0.sideDice_ = cc.Sprite:create(var_18_3)

	if arg_18_0.sideDice_ then
		arg_18_0.sideDice_:setScale(1.5)
		arg_18_0.sideDice_:addTo(arg_18_0.greenEnemyTarget_.fighterModel, 100)
		arg_18_0.sideDice_:setPosition(cc.p(arg_18_0.greenEnemyTarget_.fighterModel:getHeroAnimation().headPoint.x, arg_18_0.greenEnemyTarget_.fighterModel:getHeroAnimation().headPoint.y))
	end

	arg_18_0.diceCount_ = var_0_18
end

function var_0_3.updateUnitDataByFighter(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4, arg_19_5, arg_19_6, arg_19_7)
	arg_19_2, arg_19_3, arg_19_4, arg_19_5, arg_19_6, arg_19_7 = var_0_3.super.updateUnitDataByFighter(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4, arg_19_5, arg_19_6, arg_19_7)

	if arg_19_1.skillID == arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_19_4 = arg_19_4 * var_0_16 * arg_19_0.blueChipNums_
		arg_19_0.blueSkillHarm_ = arg_19_4

		local var_19_0 = arg_19_0:createAttackUnits({
			arg_19_0
		}, var_0_17)

		for iter_19_0, iter_19_1 in ipairs(var_19_0) do
			table.insert(arg_19_0.moveAttackUnits_, iter_19_1)
			table.insert(arg_19_0.records_.special_units, iter_19_1)
		end
	elseif arg_19_1.skillID == var_0_17 then
		arg_19_5 = arg_19_5 + arg_19_0.blueSkillHarm_ * 0.4 * arg_19_0:getDCureRate()
		arg_19_0.blueSkillHarm_ = 0
	elseif arg_19_1.skillID == arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if arg_19_0.isThreeSame_ then
			arg_19_5 = arg_19_5 * 2
			arg_19_0.isThreeSame_ = false
		end
	elseif arg_19_1.skillID == var_0_7 then
		arg_19_4 = arg_19_4 * var_0_9 * arg_19_0.energyNums_
		arg_19_0.energySkillHarm_ = arg_19_4

		local var_19_1 = arg_19_0:createAttackUnits({
			arg_19_0
		}, var_0_8)

		for iter_19_2, iter_19_3 in ipairs(var_19_1) do
			table.insert(arg_19_0.moveAttackUnits_, iter_19_3)
			table.insert(arg_19_0.records_.special_units, iter_19_3)
		end
	elseif arg_19_1.skillID == var_0_8 then
		arg_19_5 = arg_19_5 + arg_19_0.energySkillHarm_ * 0.4 * arg_19_0:getDCureRate()
		arg_19_0.energySkillHarm_ = 0
	end

	return arg_19_2, arg_19_3, arg_19_4, arg_19_5, arg_19_6, arg_19_7
end

function var_0_3.setupReport(arg_20_0, arg_20_1)
	var_0_3.super.setupReport(arg_20_0, arg_20_1)

	arg_20_0.selfGreenReportData_ = arg_20_1.self_green_num
	arg_20_0.sideGreenReportData_ = arg_20_1.side_green_num
end

function var_0_3.writeReport(arg_21_0)
	local var_21_0 = var_0_3.super.writeReport(arg_21_0)

	var_21_0.self_green_num = arg_21_0.records_.self_green_num
	var_21_0.side_green_num = arg_21_0.records_.side_green_num

	return var_21_0
end

function var_0_3.updateChip(arg_22_0, arg_22_1)
	arg_22_1 = math.ceil(arg_22_1)
	arg_22_0.chipNums_ = math.max(arg_22_0.chipNums_ + arg_22_1, 0)

	arg_22_0:updateStateNumber(arg_22_0.chipNums_)
end

function var_0_3.isBreakImmortal(arg_23_0)
	if arg_23_0.isInRebornBet_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_23_0)
	end
end

function var_0_3.checkEnergySkill(arg_24_0)
	if arg_24_0.chipNums_ >= 7 then
		if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
			return false
		end

		if arg_24_0:isDeath() then
			return false
		end

		if arg_24_0:getDelaySkill() > var_0_1.ctx.battle.count then
			return false
		end

		if arg_24_0.walk2Position_ then
			return false
		end

		if arg_24_0:isBattleUnable() then
			return false
		end

		if arg_24_0:isApUnable() then
			return false
		end

		if arg_24_0.isEnergySkill_ and arg_24_0:isCreatingUnits() then
			return false
		end

		if arg_24_0:isAutoFighter() and arg_24_0:isInSkillRoll() then
			return false
		end

		if arg_24_0:isPugongOnly() then
			return false
		end

		if arg_24_0:isInvalidEnergySkill() then
			return false
		end

		if not arg_24_0:getNearestTarget() then
			return false
		end

		local var_24_0 = var_0_6:distance(arg_24_0:getEnergySkillID())

		if var_24_0 > 0 and var_24_0 < math.abs(arg_24_0:getNearestTarget():getX() - arg_24_0:getX()) then
			return false
		end

		if arg_24_0.leftInterval_ > 0 and arg_24_0.arenaEnergyFull_ ~= true and (var_0_2.CampaignType.ARENA == var_0_1.ctx.battle.campaignType or var_0_2.CampaignType.SUPER_ARENA == var_0_1.ctx.battle.campaignType) then
			return false
		end

		return true
	else
		return false
	end
end

function var_0_3.canAttack(arg_25_0)
	if arg_25_0.isInRebornBet_ then
		return false
	else
		return var_0_3.super.canAttack(arg_25_0)
	end
end

function var_0_3.updateEnergyTo(arg_26_0, arg_26_1)
	return
end

function var_0_3.updateEnergyBy(arg_27_0, arg_27_1, arg_27_2)
	return
end

function var_0_3.updateEnergyByHarm(arg_28_0, arg_28_1)
	return
end

function var_0_3.updateEnergyByCount(arg_29_0)
	return
end

return var_0_3
