local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiaoqiao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 30
local var_0_8 = 0.01
local var_0_9 = 30010022
local var_0_10 = 240
local var_0_11 = {
	30010023,
	30010024
}
local var_0_12 = 80020055
local var_0_13 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.heroWithBuff = {}
	arg_1_0.hocusTime = var_0_10
	arg_1_0.hocusTarget = nil
	arg_1_0.collectHp = 0
	arg_1_0.hocusHurt = 0
	arg_1_0.hocusCure = 0
	arg_1_0.startHocus = false
	arg_1_0.lastAllHurtHp = 0
	arg_1_0.count = false
	arg_1_0.balanceTime = var_0_7
	arg_1_0.selectTarget = nil
	arg_1_0.extraSelectTarget = nil
	arg_1_0.maxHp = 0
	arg_1_0.cdTime_ = 0
	var_0_1.ctx.battle.isCountHurtNum = true
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.energyBuffID = 40012711
		arg_2_0.purpleBuffID = 40012712
	else
		arg_2_0.energyBuffID = 30010028
		arg_2_0.purpleBuffID = 30010029
	end
end

function var_0_3.singleLoop(arg_3_0)
	arg_3_0.cdTime_ = arg_3_0.cdTime_ > 0 and arg_3_0.cdTime_ - 1 or 0

	local function var_3_0(arg_4_0, arg_4_1, arg_4_2)
		local var_4_0 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0) do
			local var_4_1 = var_0_5.new({
				tableID = iter_4_1,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByID(arg_4_1),
				skillID = arg_4_1,
				fighter = arg_3_0,
				target = arg_4_2
			})

			var_4_1:setYongJiu()
			table.insert(var_4_0, var_4_1)
		end

		return var_4_0
	end

	if not arg_3_0.count then
		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
			local var_3_1 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)

			arg_3_0.greenRatio = 1 + var_0_8 * arg_3_0:getSkillLevelByID(var_3_1)
		end

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) == 0 then
			arg_3_0.isBlueSkillExist = false
		else
			arg_3_0.isBlueSkillExist = true

			local var_3_2 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

			arg_3_0.blueRatio = var_0_4:ap(var_3_2) / 10000 + var_0_4:apStep(var_3_2) / 10000 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
			arg_3_0.maxHp = var_0_4:init(var_3_2) + var_0_4:step(var_3_2) * arg_3_0:getSkillLevelByID(var_3_2)
		end

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) == 0 then
			arg_3_0.isPurpleSkillExist = false
		else
			arg_3_0.isPurpleSkillExist = true

			local var_3_3 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

			arg_3_0.purpleRatio = var_0_4:ap(var_3_3) / 10000 + var_0_4:apStep(var_3_3) / 10000 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		end

		arg_3_0.count = true
	end

	if arg_3_0.isPurpleSkillExist and not arg_3_0:isDeath() then
		local var_3_4 = arg_3_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
		local var_3_5 = 1

		if arg_3_0.selectTarget then
			if arg_3_0.selectTarget:isDeath() then
				arg_3_0.selectTarget = nil
			else
				var_3_5 = arg_3_0.selectTarget:getHp() / arg_3_0.selectTarget:getHpLimit()
			end
		end

		for iter_3_0, iter_3_1 in ipairs(var_3_4) do
			if (not arg_3_0.selectTarget or iter_3_1:getTableID() ~= arg_3_0.selectTarget:getTableID()) and not iter_3_1:isDeath() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_3_6 = iter_3_1:getHp() / iter_3_1:getHpLimit()

				if var_3_6 < var_3_5 then
					if arg_3_0.selectTarget then
						arg_3_0.selectTarget:removeBuffByID(arg_3_0.purpleBuffID)
					end

					arg_3_0.selectTarget = iter_3_1
					var_3_5 = var_3_6
				elseif var_3_6 == var_3_5 then
					if arg_3_0.selectTarget then
						if iter_3_1:getHp() < arg_3_0.selectTarget:getHp() then
							arg_3_0.selectTarget:removeBuffByID(arg_3_0.purpleBuffID)

							arg_3_0.selectTarget = iter_3_1
						end
					else
						arg_3_0.selectTarget = iter_3_1
					end
				end
			end
		end

		local var_3_7 = 1

		if arg_3_0.extraSelectTarget then
			if arg_3_0.extraSelectTarget:isDeath() or arg_3_0.extraSelectTarget == arg_3_0.selectTarget then
				arg_3_0.extraSelectTarget = nil
			else
				var_3_7 = arg_3_0.extraSelectTarget:getHp() / arg_3_0.extraSelectTarget:getHpLimit()
			end
		end

		if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_12 and arg_3_0.selectTarget then
			for iter_3_2, iter_3_3 in ipairs(var_3_4) do
				if (not arg_3_0.extraSelectTarget or iter_3_3:getTableID() ~= arg_3_0.extraSelectTarget:getTableID()) and iter_3_3 ~= arg_3_0.selectTarget and not iter_3_3:isDeath() and iter_3_3:getSummonType() == var_0_2.summonMonsterType.None then
					local var_3_8 = iter_3_3:getHp() / iter_3_3:getHpLimit()

					if var_3_8 < var_3_7 then
						if arg_3_0.extraSelectTarget then
							arg_3_0.extraSelectTarget:removeBuffByID(arg_3_0.purpleBuffID)
						end

						arg_3_0.extraSelectTarget = iter_3_3
						var_3_7 = var_3_8
					elseif var_3_8 == var_3_7 then
						if arg_3_0.extraSelectTarget then
							if iter_3_3:getHp() < arg_3_0.extraSelectTarget:getHp() then
								arg_3_0.extraSelectTarget:removeBuffByID(arg_3_0.purpleBuffID)

								arg_3_0.extraSelectTarget = iter_3_3
							end
						else
							arg_3_0.extraSelectTarget = iter_3_3
						end
					end
				end
			end
		end

		if arg_3_0.selectTarget and not arg_3_0.selectTarget:isHasBuffByID(arg_3_0.purpleBuffID) then
			local var_3_9 = var_3_0({
				arg_3_0.purpleBuffID
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_3_0.selectTarget)

			arg_3_0.selectTarget:addBuffs(var_3_9)
		end

		if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_12 and arg_3_0.extraSelectTarget and not arg_3_0.extraSelectTarget:isHasBuffByID(arg_3_0.purpleBuffID) then
			local var_3_10 = var_3_0({
				arg_3_0.purpleBuffID
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_3_0.extraSelectTarget)

			arg_3_0.extraSelectTarget:addBuffs(var_3_10)
		end

		for iter_3_4, iter_3_5 in ipairs(var_3_4) do
			local var_3_11 = iter_3_5:getCureHp()

			if var_3_11 ~= 0 then
				if arg_3_0.selectTarget then
					arg_3_0.selectTarget:updateHp(arg_3_0.selectTarget:getHp() + var_3_11 * arg_3_0.purpleRatio * arg_3_0.selectTarget:getDCureRate())
				end

				if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_12 and arg_3_0.extraSelectTarget then
					arg_3_0.extraSelectTarget:updateHp(arg_3_0.extraSelectTarget:getHp() + var_3_11 * arg_3_0.purpleRatio * arg_3_0.extraSelectTarget:getDCureRate())
				end
			end

			if not iter_3_5:getParalysis() then
				iter_3_5:setCureHp(0)
			end
		end
	end

	if arg_3_0.hocusTarget then
		arg_3_0.hocusHurt = arg_3_0.hocusTarget:getHurtHp() + arg_3_0.hocusHurt

		arg_3_0.hocusTarget:setHurtHp(0)

		arg_3_0.hocusCure = arg_3_0.hocusTarget:getCureHp() + arg_3_0.hocusCure

		arg_3_0.hocusTarget:setCureHp(0)
	end

	if arg_3_0.isBlueSkillExist and not arg_3_0:isDeath() then
		arg_3_0.collectHp = (var_0_1.ctx.battle.allFighterHurt - arg_3_0.lastAllHurtHp) * arg_3_0.blueRatio + arg_3_0.collectHp

		if arg_3_0.collectHp >= arg_3_0.maxHp and arg_3_0.cdTime_ < 1 then
			arg_3_0:curePartner()

			arg_3_0.collectHp = 0
			arg_3_0.cdTime_ = var_0_13
		end

		arg_3_0.lastAllHurtHp = var_0_1.ctx.battle.allFighterHurt
	end

	var_0_3.super.singleLoop(arg_3_0)

	if arg_3_0:acttionInBlack() and not arg_3_0:isDeath() and arg_3_0:isHasBuffByID(arg_3_0.energyBuffID) then
		arg_3_0.balanceTime = arg_3_0.balanceTime - 1

		if arg_3_0.balanceTime == 0 then
			arg_3_0:balanceHeroHp()

			arg_3_0.balanceTime = var_0_0.clone(var_0_7)
		end

		local var_3_12 = {}
		local var_3_13 = arg_3_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

		for iter_3_6 = #arg_3_0.heroWithBuff, 1, -1 do
			local var_3_14 = arg_3_0.heroWithBuff[iter_3_6]

			if not arg_3_0:isInCircle(var_3_14) then
				for iter_3_7, iter_3_8 in ipairs(var_0_11) do
					var_3_14:removeBuffByID(iter_3_8)
				end

				table.remove(arg_3_0.heroWithBuff, iter_3_6)
			end
		end

		for iter_3_9, iter_3_10 in ipairs(var_3_13) do
			if iter_3_10:getSummonType() ~= var_0_2.summonMonsterType.Copy and not iter_3_10:isDeath() and not iter_3_10:isAffected() and not var_0_0.table.indexof(arg_3_0.heroWithBuff, iter_3_10) and arg_3_0:isInCircle(iter_3_10) then
				local var_3_15 = var_3_0(var_0_11, arg_3_0:getEnergySkillID(), iter_3_10)

				iter_3_10:addBuffs(var_3_15)
				table.insert(arg_3_0.heroWithBuff, iter_3_10)
			end
		end
	end

	if arg_3_0.startHocus then
		arg_3_0.hocusTime = arg_3_0.hocusTime - 1

		if arg_3_0.hocusTime == 0 then
			arg_3_0:hocusSettle()
		end
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_5_0.startHocus and arg_5_0.hocusTarget then
		arg_5_0:hocusSettle()
	end
end

function var_0_3.hocusSettle(arg_6_0)
	local var_6_0 = arg_6_0.hocusTarget:getHp() + arg_6_0.hocusCure * arg_6_0.greenRatio - arg_6_0.hocusHurt

	arg_6_0.hocusTarget:setParalysis(false)

	if var_6_0 <= 0 then
		arg_6_0.hocusTarget:updateHp(0)

		if arg_6_0.hocusTarget:isDeath() then
			arg_6_0.hocusTarget:die()
		end
	elseif var_6_0 >= arg_6_0.hocusTarget:getHpLimit() then
		arg_6_0.hocusTarget:updateHp(arg_6_0.hocusTarget:getHpLimit())
	else
		arg_6_0.hocusTarget:updateHp(var_6_0)
	end

	if arg_6_0.hocusTarget:isHasBuffByID(var_0_9) then
		arg_6_0.hocusTarget:removeBuffByID(var_0_9)
	end

	arg_6_0.hocusTarget = nil
	arg_6_0.startHocus = false
	arg_6_0.hocusHurt = 0
	arg_6_0.hocusCure = 0
	arg_6_0.hocusTime = var_0_0.clone(var_0_10)
end

function var_0_3.removeBuffs(arg_7_0, arg_7_1)
	var_0_3.super.removeBuffs(arg_7_0, arg_7_1)

	if arg_7_1.tableID_ == arg_7_0.energyBuffID then
		for iter_7_0, iter_7_1 in ipairs(arg_7_0.heroWithBuff) do
			if not iter_7_1:isDeath() then
				for iter_7_2, iter_7_3 in ipairs(var_0_11) do
					iter_7_1:removeBuffByID(iter_7_3)
				end
			end
		end

		arg_7_0.heroWithBuff = {}
	end
end

function var_0_3.clearResource(arg_8_0)
	var_0_3.super.clearResource(arg_8_0)

	if arg_8_0.startHocus and arg_8_0.hocusTarget then
		arg_8_0:hocusSettle()
	end
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_9_0.hocusTarget = arg_9_1.target

		arg_9_0.hocusTarget:setParalysis(true)
		arg_9_0.hocusTarget:setHurtHp(0)
		arg_9_0.hocusTarget:setCureHp(0)

		arg_9_0.hocusHurt = 0
		arg_9_0.hocusCure = 0
		arg_9_0.startHocus = true
	end
end

function var_0_3.die(arg_10_0)
	var_0_3.super.die(arg_10_0)

	if next(arg_10_0.heroWithBuff) ~= nil then
		for iter_10_0, iter_10_1 in ipairs(arg_10_0.heroWithBuff) do
			for iter_10_2, iter_10_3 in ipairs(var_0_11) do
				iter_10_1:removeBuffByID(iter_10_3)
			end
		end

		arg_10_0.heroWithBuff = {}
	end

	if arg_10_0.selectTarget and not arg_10_0.selectTarget:isDeath() then
		arg_10_0.selectTarget:removeBuffByID(arg_10_0.purpleBuffID)

		arg_10_0.selectTarget = nil
	end

	if arg_10_0.extraSelectTarget and not arg_10_0.extraSelectTarget:isDeath() then
		arg_10_0.extraSelectTarget:removeBuffByID(arg_10_0.purpleBuffID)

		arg_10_0.extraSelectTarget = nil
	end
end

function var_0_3.isInCircle(arg_11_0, arg_11_1)
	if arg_11_1:isDeath() then
		return false
	end

	if math.abs(arg_11_0:getX() - arg_11_1:getX()) <= var_0_4:scope(arg_11_0:getEnergySkillID()) / 2 then
		return true
	end

	return false
end

function var_0_3.balanceHeroHp(arg_12_0)
	local var_12_0 = 0
	local var_12_1 = 0

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.heroWithBuff) do
		if not iter_12_1:isDeath() then
			var_12_1 = var_12_1 + 1
			var_12_0 = var_12_0 + iter_12_1:getHp() / iter_12_1:getHpLimit()
		end
	end

	if var_12_1 > 0 then
		var_12_0 = var_12_0 / var_12_1
	end

	for iter_12_2, iter_12_3 in ipairs(arg_12_0.heroWithBuff) do
		if not iter_12_3:isDeath() then
			iter_12_3:updateHp(iter_12_3:getHpLimit() * var_12_0)
		end
	end
end

function var_0_3.curePartner(arg_13_0)
	local var_13_0
	local var_13_1
	local var_13_2 = var_0_6.A4(arg_13_0, arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))[1]

	if var_13_2 then
		local var_13_3 = arg_13_0.maxHp + var_13_2:getHp()

		var_13_2:setCureHp(var_13_2:getCureHp() + arg_13_0.maxHp)

		if var_13_3 > var_13_2:getHpLimit() then
			var_13_2:updateHp(var_13_2:getHpLimit())
		else
			var_13_2:updateHp(var_13_3)
		end
	end
end

function var_0_3.checkRebirthTimes(arg_14_0)
	if not arg_14_0.rebirthTimes then
		arg_14_0.rebirthTimes = 0
	end

	if arg_14_0.rebirthTimes < rebornTimes then
		return true
	else
		return false
	end
end

return var_0_3
