local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangliang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 300
local var_0_8 = 100
local var_0_9 = -50
local var_0_10 = 600
local var_0_11 = 90
local var_0_12 = 40010894
local var_0_13 = 10000827
local var_0_14 = 3
local var_0_15 = 10000828
local var_0_16 = 10000829
local var_0_17 = 10
local var_0_18 = {
	50,
	115,
	180
}
local var_0_19 = {
	40010899,
	40010900,
	40010901
}
local var_0_20 = {
	40010904,
	40010905
}
local var_0_21 = {
	0.0014,
	0.05
}
local var_0_22 = {
	3,
	500,
	100
}
local var_0_23 = {
	40,
	10000830,
	0.2,
	40010897,
	40010898,
	4
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.chargeNum_ = 0
	arg_2_0.greenUseNum_ = 0
	arg_2_0.blueSkillTargetCD_ = {}
	arg_2_0.records_.blue_lv3_buff = {}
	arg_2_0.isPurpleSummon_ = false
	arg_2_0.purpleMonster_ = nil
	arg_2_0.energyChildSkillCount_ = 0
	arg_2_0.greenHarmInfo_ = {}
	arg_2_0.energyCDCount_ = 0
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_3_0.PugongID = 10002487
	else
		arg_3_0.PugongID = 10010164
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0:updateChargeNum(var_0_9)

		arg_4_0.energyCDCount_ = var_0_10
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() or var_0_1.ctx.battle.walk2NextBattle_ then
		if arg_5_0.purpleMonster_ and not arg_5_0.purpleMonster_:isDeath() then
			arg_5_0.purpleMonster_:updateHp(1)
			arg_5_0.purpleMonster_:die()
		end

		if arg_5_0.chargeNum_ > 0 then
			arg_5_0.chargeNum_ = 0

			arg_5_0:updateStateNumber()
		end

		return
	end

	local var_5_0 = {}
	local var_5_1 = 0

	for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("harm_info")) do
		local var_5_2 = iter_5_1.harm
		local var_5_3 = iter_5_1.fighter
		local var_5_4 = iter_5_1.target

		if var_5_2 > 0 and iter_5_1.type == var_0_2.AttackType.AD and var_5_3:getTeamType() == arg_5_0:getTeamType() then
			var_5_1 = var_5_1 + 1
		end

		if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_5_2 > 0 and iter_5_1.type == var_0_2.AttackType.AD and var_5_3:getTeamType() == arg_5_0:getTeamType() and var_5_3:getSummonType() == var_0_2.summonMonsterType.None then
			if not arg_5_0.greenHarmInfo_[var_5_3] then
				arg_5_0.greenHarmInfo_[var_5_3] = var_5_2
			else
				arg_5_0.greenHarmInfo_[var_5_3] = arg_5_0.greenHarmInfo_[var_5_3] + var_5_2
			end
		end

		arg_5_0:checkBlueLv3Skill(var_5_0, var_5_3, var_5_4)
	end

	arg_5_0:updateChargeNum(var_5_1)

	if not arg_5_0.isPurpleSummon_ and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_5_0.isPurpleSummon_ = true

		arg_5_0:summonPurpleMonster()
	end

	if arg_5_0.energyChildSkillCount_ > 0 and arg_5_0:isHasBuffByID(var_0_12) then
		arg_5_0.energyChildSkillCount_ = arg_5_0.energyChildSkillCount_ - 1

		if arg_5_0.energyChildSkillCount_ <= 0 then
			arg_5_0:useEnergyChildSkill()
		end
	end

	if arg_5_0.energyCDCount_ > 0 then
		arg_5_0.energyCDCount_ = arg_5_0.energyCDCount_ - 1
	end
end

function var_0_3.checkBlueLv3Skill(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) <= 0 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_6_2:isHasBuffByID(var_0_19[3]) and arg_6_3:getTeamType() ~= arg_6_0:getTeamType() and (arg_6_1[arg_6_2] or not arg_6_0.blueSkillTargetCD_[arg_6_2] or var_0_1.ctx.battle.count - arg_6_0.blueSkillTargetCD_[arg_6_2] > var_0_23[1]) then
		arg_6_1[arg_6_2] = true
		arg_6_0.blueSkillTargetCD_[arg_6_2] = var_0_1.ctx.battle.count

		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_3
		}, var_0_23[2])

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	if not arg_7_0.greenHarmInfo_ or not next(arg_7_0.greenHarmInfo_) then
		return {}
	end

	local var_7_0 = 0
	local var_7_1

	for iter_7_0, iter_7_1 in pairs(arg_7_0.greenHarmInfo_) do
		if not iter_7_0:isDeath() and not iter_7_0:isAffected() and var_7_0 < iter_7_1 then
			var_7_1 = iter_7_0
			var_7_0 = iter_7_1
		end
	end

	return {
		var_7_1
	}
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_8_0:updateChargeNum(var_0_17)

		arg_8_0.greenUseNum_ = arg_8_0.greenUseNum_ + 1

		arg_8_0:checkUseGreenSkill()
	elseif arg_8_1.skillID == var_0_23[2] then
		arg_8_0:checkAddBlueLv3Buff(arg_8_1.target)
	elseif arg_8_1.skillID == arg_8_0:getEnergySkillID() then
		arg_8_0:useEnergyChildSkill(true)
	end
end

function var_0_3.checkAddBlueLv3Buff(arg_9_0, arg_9_1)
	if #arg_9_1:getBuffsByID(var_0_23[4]) >= var_0_23[6] or arg_9_1:isDeath() then
		return
	end

	local var_9_0 = false

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_9_0.blueAddLv3Buff and arg_9_0.blueAddLv3Buff[tostring(var_0_1.ctx.battle.count)] then
			var_9_0 = true
		end
	else
		var_9_0 = var_0_2.weightedChoise({
			var_0_23[2],
			1 - var_0_23[2]
		}) == 1

		if var_9_0 then
			arg_9_0.records_.blue_lv3_buff[tostring(var_0_1.ctx.battle.count)] = 1
		end
	end

	if var_9_0 then
		local var_9_1 = arg_9_0:newBuff({
			var_0_23[4],
			var_0_23[5]
		}, arg_9_1, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_9_1:addBuffs(var_9_1)
	end
end

function var_0_3.checkUseGreenSkill(arg_10_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_10_0.greenUseNum_ >= var_0_14 then
		local var_10_0 = arg_10_0:getTargets(var_0_15)
		local var_10_1 = arg_10_0:createAttackUnits(var_10_0, var_0_15)

		for iter_10_0, iter_10_1 in ipairs(var_10_1) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end

		local var_10_2 = arg_10_0:createAttackUnits({
			arg_10_0
		}, var_0_16)

		for iter_10_2, iter_10_3 in ipairs(var_10_2) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
			table.insert(arg_10_0.records_.special_units, iter_10_3)
		end

		arg_10_0.greenUseNum_ = 0
	end
end

function var_0_3.updateChargeNum(arg_11_0, arg_11_1)
	if not arg_11_1 or arg_11_1 == 0 then
		return
	end

	arg_11_0.chargeNum_ = arg_11_0.chargeNum_ + arg_11_1

	if arg_11_0.chargeNum_ > var_0_7 then
		arg_11_0.chargeNum_ = var_0_7
	end

	arg_11_0:updateStateNumber(arg_11_0.chargeNum_, 0.7)
	arg_11_0:checkBlueSkill()
end

function var_0_3.checkBlueSkill(arg_12_0)
	if arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) <= 0 then
		return
	end

	local function var_12_0(arg_13_0, arg_13_1)
		for iter_13_0, iter_13_1 in ipairs(arg_12_0.selfTeam_) do
			if not iter_13_1:isDeath() and iter_13_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
				if arg_13_1 then
					local var_13_0 = arg_12_0:newBuff(arg_13_0, iter_13_1, arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

					iter_13_1:addBuffs(var_13_0)
				else
					for iter_13_2 = 1, #arg_13_0 do
						iter_13_1:removeBuffByID(arg_13_0[iter_13_2])
					end
				end
			end
		end
	end

	if arg_12_0.chargeNum_ < var_0_18[1] then
		var_12_0({
			var_0_20[1],
			var_0_19[1]
		}, false)
	else
		var_12_0({
			var_0_20[1],
			var_0_19[1]
		}, true)
	end

	if arg_12_0.chargeNum_ < var_0_18[2] then
		var_12_0({
			var_0_20[2],
			var_0_19[2]
		}, false)
	else
		var_12_0({
			var_0_19[1]
		}, false)
		var_12_0({
			var_0_20[2],
			var_0_19[2]
		}, true)
	end

	if arg_12_0.chargeNum_ < var_0_18[3] then
		var_12_0({
			var_0_19[3]
		}, false)
	else
		var_12_0({
			var_0_19[2]
		}, false)
		var_12_0({
			var_0_19[3]
		}, true)
	end
end

function var_0_3.newBuff(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		local var_14_1 = var_0_4.new({
			tableID = iter_14_1,
			start = var_0_1.ctx.battle.count,
			level = arg_14_0:getSkillLevelByID(arg_14_3),
			skillID = arg_14_3,
			fighter = arg_14_0,
			target = arg_14_2
		})

		var_14_1:setIsHit(true)
		var_14_1:setDirection(arg_14_0:getFighterModel():getFlipX())
		table.insert(var_14_0, var_14_1)
	end

	return var_14_0
end

function var_0_3.buffAddAction(arg_15_0, arg_15_1)
	var_0_3.super.buffAddAction(arg_15_0, arg_15_1)

	if arg_15_1:getTableID() == var_0_20[1] then
		arg_15_1.manualRevise = (arg_15_0.chargeNum_ - var_0_18[1]) * var_0_21[1] + var_0_21[2]
	elseif arg_15_1:getTableID() == var_0_20[2] then
		local var_15_0 = arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		arg_15_1.manualRevise = ((arg_15_0.chargeNum_ - var_0_18[2]) * var_0_22[1] + var_0_22[2]) / var_0_22[3] * var_15_0
	end
end

function var_0_3.setupReport(arg_16_0, arg_16_1)
	var_0_3.super.setupReport(arg_16_0, arg_16_1)

	arg_16_0.blueAddLv3Buff = arg_16_1.blue_lv3_buff
end

function var_0_3.writeReport(arg_17_0)
	local var_17_0 = var_0_3.super.writeReport(arg_17_0)

	var_17_0.blue_lv3_buff = arg_17_0.records_.blue_lv3_buff

	return var_17_0
end

function var_0_3.summonPurpleMonster(arg_18_0)
	local var_18_0 = arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_18_1 = var_0_6:summonMonster(var_18_0)

	if next(var_18_1) == nil then
		return
	end

	local var_18_2 = var_18_1[1]
	local var_18_3 = arg_18_0:getSkillLevelByID(var_18_0)
	local var_18_4 = arg_18_0.hero_:getColor()
	local var_18_5 = 100

	if arg_18_0:getFlipX() then
		var_18_5 = var_0_2.STAGE_WIDTH - 100
	end

	local var_18_6 = var_0_1.ctx.battle.adjustX(var_18_5, arg_18_0)
	local var_18_7 = {
		y = 230,
		x = var_18_6
	}

	arg_18_0.purpleMonster_ = arg_18_0:setSummonMonsters(var_18_2, var_18_3, var_18_4, var_18_7)
end

function var_0_3.setSummonMonsters(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4)
	local var_19_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_19_0 = arg_19_0:getSummonMonster()
	else
		local var_19_1 = var_0_5.new()

		var_19_1:populateWithTableID(arg_19_1)

		var_19_1.level_ = arg_19_2 or var_19_1.level_
		var_19_1.color_ = arg_19_3 or var_19_1.color_

		for iter_19_0, iter_19_1 in ipairs(var_19_1.skillLev_) do
			local var_19_2 = arg_19_0.hero_:getSkillLevel(iter_19_0)

			if var_19_2 and var_19_2 > 0 then
				var_19_1.skillLev_[iter_19_0] = var_0_0.clone(var_19_2)
			end
		end

		local var_19_3 = var_19_1:className()

		var_19_0 = var_0_1.ctx.battle.requireFighter(var_19_3).new({
			is_arena = arg_19_0.isInArena_
		})

		var_19_0:populateWithHero(var_19_1)
		var_19_0:initModels()
		var_19_0.fighterModel:initHeaderView(arg_19_0:getTeamType() - 1)

		var_19_0.fighterIndex = arg_19_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_19_0:setFormationDelay(0, 100)
	end

	var_19_0:setTeamType(arg_19_0:getTeamType())

	var_19_0.summoner = arg_19_0

	var_19_0.fighterModel:pos(arg_19_4.x, arg_19_4.y)
	var_19_0:getFighterModel():flipX(arg_19_0:getTeamType() == var_0_2.TeamType.B)
	var_19_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_19_0:born()
	var_19_0:setGlobalBuffs()
	var_19_0:updateHp(var_19_0:getHpLimit())

	local var_19_4 = var_19_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_19_4, var_19_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_19_0)
	var_0_1.ctx.battle.updateZorder()

	return var_19_0
end

function var_0_3.updateEnergyTo(arg_20_0, arg_20_1)
	return
end

function var_0_3.updateEnergyBy(arg_21_0, arg_21_1, arg_21_2)
	return
end

function var_0_3.updateEnergyByHarm(arg_22_0, arg_22_1)
	return
end

function var_0_3.checkEnergySkill(arg_23_0)
	if arg_23_0.energyCDCount_ > 0 then
		return false
	elseif arg_23_0.isEnergyType_ then
		return false
	elseif arg_23_0.chargeNum_ >= var_0_8 then
		return true
	end

	return false
end

function var_0_3.useEnergyChildSkill(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_1

	if not arg_24_0:isHasBuffByID(var_0_12) or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_24_1 = {}

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.sideTeam_) do
		if not iter_24_1:isDeath() and not iter_24_1:isAffected() and iter_24_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
			table.insert(var_24_1, iter_24_1)
		end
	end

	if arg_24_0.purpleMonster_ and not arg_24_0.purpleMonster_:isDeath() then
		var_24_0 = true
	end

	if not var_24_0 then
		for iter_24_2, iter_24_3 in ipairs(arg_24_0.selfTeam_) do
			if not iter_24_3:isDeath() and not iter_24_3:isAffected() and iter_24_3:getSummonType() ~= var_0_2.summonMonsterType.Pet then
				table.insert(var_24_1, iter_24_3)
			end
		end
	end

	local var_24_2

	if #var_24_1 > 0 then
		var_24_2 = var_24_1[math.random(1, #var_24_1)]
	end

	if var_24_2 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_24_3 = arg_24_0:createAttackUnits({
			var_24_2
		}, var_0_13)

		for iter_24_4, iter_24_5 in ipairs(var_24_3) do
			table.insert(arg_24_0.moveAttackUnits_, iter_24_5)
			table.insert(arg_24_0.records_.special_units, iter_24_5)
		end
	end

	arg_24_0.energyChildSkillCount_ = var_0_11
end

function var_0_3.buffRemoveAction(arg_25_0, arg_25_1)
	if arg_25_1:getTableID() == var_0_12 then
		arg_25_0.energyChildSkillCount_ = 0
	end
end

function var_0_3.getOrbOfFrontSkill(arg_26_0)
	local var_26_0 = var_0_3.super.getOrbOfFrontSkill(arg_26_0)

	if var_26_0 == arg_26_0:getPugongID() then
		var_26_0 = arg_26_0.PugongID
	end

	return var_26_0
end

return var_0_3
