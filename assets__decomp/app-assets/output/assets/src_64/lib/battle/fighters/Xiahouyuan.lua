local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahouyuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = var_0_2.tables.dbuff
local var_0_9 = 10000158
local var_0_10 = 20010101
local var_0_11 = 20010102
local var_0_12 = 1000
local var_0_13 = 15000
local var_0_14 = 50
local var_0_15 = 0.03
local var_0_16 = 80010049
local var_0_17 = 81010049
local var_0_18 = 40011099
local var_0_19 = 10000992
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001467
local var_0_22 = 10002232
local var_0_23 = 40012382

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.bullet_ = 1
	arg_1_0.extraACKSpeed = 0
	arg_1_0.specialReportUnits_ = {}

	arg_1_0:updateStateNumber()

	arg_1_0.skinWiseNum_ = 0
	arg_1_0.skinStrengthNum_ = 0
	arg_1_0.skinAgileNum_ = 0
	arg_1_0.skinTimeCount_ = 0
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_2_0 > 0 and var_0_1.ctx.battle.count % 10 == 0 then
		local var_2_1 = var_0_8:init(var_0_10)
		local var_2_2 = var_0_8:step(var_0_10)

		arg_2_0.extraACKSpeed = math.min(arg_2_0.extraACKSpeed + var_2_1 + var_2_2 * var_2_0, var_0_13)
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if not arg_3_1.target:isDeath() then
		arg_3_0:updateBullet(1)
	end

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:selectTargetByTypeD3(var_0_9, arg_3_1.target)
		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_9)

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			if iter_3_1.resource then
				local var_3_2 = arg_3_1.target:getY() + arg_3_1.target:getFighterModel().attackedPoint.y

				iter_3_1.resource:pos(arg_3_1.target:getX(), var_3_2)
				iter_3_1.resource:addTo(var_0_1.ctx.battle.unitLayer)
				iter_3_1.resource:show()

				iter_3_1.records_.init = {
					arg_3_1.target:getX(),
					var_3_2
				}
			end

			iter_3_1.arrived = false

			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		for iter_3_2 = #arg_3_0.specialReportUnits_, 1, -1 do
			local var_3_3 = arg_3_0.specialReportUnits_[iter_3_2]

			if var_3_3.count == var_0_1.ctx.battle.count then
				var_3_3.resource:pos(var_3_3.iniX_, var_3_3.iniY_)
				var_3_3.resource:addTo(var_0_1.ctx.battle.unitLayer)
				var_3_3.resource:playRepeat()
				var_3_3.resource:show()
				table.insert(arg_3_0.moveAttackUnits_, var_3_3)
				table.remove(arg_3_0.specialReportUnits_, iter_3_2)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)
end

function var_0_3.calculateUnitData(arg_4_0, arg_4_1)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.calculateUnitData(arg_4_0, arg_4_1)

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_16 and var_4_2 > 0 and arg_4_1.target then
		local var_4_6 = 0

		var_4_2 = var_4_2 + arg_4_0.level_ * arg_4_0.energy_ * var_0_15
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if var_0_5:father(arg_5_1.skillID) == arg_5_0:getEnergySkillID() then
		arg_5_4 = arg_5_0.bulletNum_ * arg_5_0.bulletNum_ / (var_0_14 * var_0_14) * arg_5_4
	end

	if arg_5_4 > 0 and arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_17 then
		if arg_5_0.skinStrengthNum_ > 0 then
			local var_5_0 = arg_5_1.target:getHpLimit() * 0.02 * arg_5_1.target:getADJianShang() * arg_5_0.skinStrengthNum_

			var_5_0 = var_5_0 > 5000 and 5000 or var_5_0
			arg_5_4 = arg_5_4 + var_5_0
		end

		if arg_5_0.skinWiseNum_ > 0 then
			arg_5_7 = arg_5_7 - 6 * arg_5_0.skinWiseNum_
		end

		if arg_5_0.skinAgileNum_ > 0 then
			local var_5_1 = {}

			for iter_5_0 = 1, arg_5_0.skinAgileNum_ do
				table.insert(var_5_1, var_0_18)
			end

			local var_5_2 = arg_5_0:createNewBuffs(var_5_1, arg_5_1.target, arg_5_0:getEnergySkillID())

			arg_5_1.target:addBuffs(var_5_2)
		end
	end

	if arg_5_4 > 0 and arg_5_0:hasElementEquipByID(var_0_21) and arg_5_3 then
		local var_5_3 = arg_5_1.target
		local var_5_4 = var_0_21
		local var_5_5 = var_0_20:battleAttr(var_5_4, arg_5_0:getElementEquipLevelByID(var_5_4))
		local var_5_6 = arg_5_0.hero_:getElementEquipActiveRate(var_5_4)
		local var_5_7 = arg_5_0:createNewBuffs({
			var_0_23
		}, arg_5_0, var_0_22)

		for iter_5_1, iter_5_2 in ipairs(var_5_7) do
			iter_5_2.manualRevise = var_5_5 * var_5_6
		end

		arg_5_0:addBuffs(var_5_7)
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_6_0 = arg_6_1:getRemoveSkill()
	local var_6_1 = {
		arg_6_1.target
	}
	local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

	for iter_6_0, iter_6_1 in ipairs(var_6_2) do
		table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
		table.insert(arg_6_0.records_.special_units, iter_6_1)
	end
end

function var_0_3.selectTargetByTypeD3(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1
	local var_7_2
	local var_7_3 = arg_7_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_7_4 = arg_7_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_7_5 = arg_7_0:isAttackFriend() and var_7_3 or var_7_4
	local var_7_6 = {}

	if arg_7_0:getX() < arg_7_2:getX() then
		for iter_7_0, iter_7_1 in ipairs(var_7_5) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:getX() > arg_7_2:getX() + 50 and iter_7_1:getX() < arg_7_2:getX() + 290 then
				table.insert(var_7_6, iter_7_1)
			end
		end
	elseif arg_7_0:getX() > arg_7_2:getX() then
		for iter_7_2, iter_7_3 in ipairs(var_7_5) do
			if not iter_7_3:isDeath() and not iter_7_3:isAffected() and iter_7_3:getX() < arg_7_2:getX() - 50 and iter_7_3:getX() > arg_7_2:getX() - 290 then
				table.insert(var_7_6, iter_7_3)
			end
		end
	end

	return var_7_6
end

function var_0_3.getCurrentAckSpeed(arg_8_0)
	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return var_0_3.super.getCurrentAckSpeed(arg_8_0)
	end

	local var_8_0 = arg_8_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED) + arg_8_0.extraACKSpeed
	local var_8_1 = math.min(var_8_0 / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

	return (math.max(var_8_1, var_0_2.MIN_ATTACK_SPEED))
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == arg_9_0:getEnergySkillID() then
		arg_9_0.bulletNum_ = var_0_0.clone(arg_9_0.bullet_)

		local var_9_0
		local var_9_1 = math.floor(arg_9_0.bullet_ / 2)

		arg_9_0:updateBullet(var_9_1 - arg_9_0.bullet_)
	end
end

function var_0_3.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	if arg_10_2 > 0 and arg_10_0.extraACKSpeed > 0 and arg_10_0.extraACKSpeed > var_0_12 then
		arg_10_0.extraACKSpeed = arg_10_0.extraACKSpeed / 2
	end

	return var_0_3.super.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
end

function var_0_3.getAD(arg_11_0)
	local var_11_0 = var_0_8:init(var_0_11)
	local var_11_1 = var_0_8:step(var_0_11)

	return var_0_3.super.getAD(arg_11_0) + var_11_0 + var_11_1 * arg_11_0.bullet_
end

function var_0_3.getReportSpecialUnits(arg_12_0, arg_12_1)
	arg_12_0.reportUnits_ = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
		local var_12_0 = {
			skillID = tonumber(iter_12_1.skillID),
			fighter = arg_12_0,
			target = var_0_1.ctx.battle.getFighter(iter_12_1.initTarget),
			count = tonumber(iter_12_1.start),
			reportdata = iter_12_1
		}
		local var_12_1 = var_0_4.new(var_12_0)

		if var_12_1.resource then
			table.insert(arg_12_0.specialReportUnits_, var_12_1)
		else
			table.insert(arg_12_0.applyUnits_, var_12_1)
		end

		table.insert(arg_12_0.reportUnits_, var_12_1)
	end
end

function var_0_3.toDoPerFrames(arg_13_0)
	if arg_13_0:isDeath() then
		return
	end

	if arg_13_0.isSkinSkillOn_ and arg_13_0.skinSkillID_ == var_0_17 then
		arg_13_0.skinTimeCount_ = arg_13_0.skinTimeCount_ - 1

		if arg_13_0.skinTimeCount_ <= 0 then
			arg_13_0:checkHeroNum()

			arg_13_0.skinTimeCount_ = 150
		end
	end
end

function var_0_3.checkHeroNum(arg_14_0)
	local var_14_0 = 0
	local var_14_1 = 0
	local var_14_2 = 0

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_14_3 = iter_14_1.hero_:getHeroType()

			if var_14_3 == var_0_2.HeroType.STRENGTH then
				var_14_0 = var_14_0 + 1
			elseif var_14_3 == var_0_2.HeroType.WISE then
				var_14_1 = var_14_1 + 1
			elseif var_14_3 == var_0_2.HeroType.AGILE then
				var_14_2 = var_14_2 + 1
			end
		end
	end

	arg_14_0.skinStrengthNum_ = var_14_0
	arg_14_0.skinWiseNum_ = var_14_1
	arg_14_0.skinAgileNum_ = var_14_2
end

function var_0_3.updateBullet(arg_15_0, arg_15_1)
	arg_15_0.bullet_ = math.min(arg_15_0.bullet_ + arg_15_1, var_0_14)
	arg_15_0.bullet_ = math.max(arg_15_0.bullet_, 1)

	arg_15_0:updateStateNumber(arg_15_0.bullet_)
end

return var_0_3
