local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangerbao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("HeroAnimation")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 40010923
local var_0_9 = 10001004
local var_0_10 = 13
local var_0_11 = 10000836
local var_0_12 = 10000849
local var_0_13 = 600
local var_0_14 = 5
local var_0_15 = 10000843
local var_0_16 = 10000845
local var_0_17 = 10000844
local var_0_18 = 10000846
local var_0_19 = 10000847
local var_0_20 = 10000848

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyType_ = false
	arg_1_0.isPurpleType_ = false
	arg_1_0.purpleSkillTarget_ = nil
	arg_1_0.purpleSkillCD_ = 0
	arg_1_0.energyPartnerModel_ = nil
	arg_1_0.isPurpleSecond_ = false
	arg_1_0.pupleSkillLastTime_ = 0
	arg_1_0.energyPartnerShowTime_ = 0
	arg_1_0.greenShowTarget_ = nil
	arg_1_0.greenShowEffect_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isEnergyType_ and not arg_2_0:isHasBuffByID(var_0_8) then
		arg_2_0.isEnergyType_ = false
	end

	if arg_2_0.energyPartnerShowTime_ > 0 then
		arg_2_0.energyPartnerShowTime_ = arg_2_0.energyPartnerShowTime_ - 1

		if arg_2_0.energyPartnerShowTime_ <= 0 and arg_2_0.energyPartnerModel_ then
			arg_2_0.energyPartnerModel_:show()
			arg_2_0.energyPartnerModel_:playAnimation_("buff", false, nil, nil, function()
				arg_2_0.energyPartnerModel_:hide()
			end)
		end
	end

	arg_2_0:checkPurpleSkill()
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		local var_4_0 = var_0_6:scale(var_0_9) * arg_4_0.heroScale

		if arg_4_0.energyPartnerModel_ then
			arg_4_0.energyPartnerModel_:removeSelf()

			arg_4_0.energyPartnerModel_ = nil
		end

		arg_4_0.energyPartnerModel_ = var_0_4.new(var_0_9, var_0_9, var_4_0, nil)

		arg_4_0.energyPartnerModel_:addTo(var_0_1.ctx.battle.playerLayer)

		local var_4_1, var_4_2 = arg_4_0:getPos()
		local var_4_3 = arg_4_0:getFlipX() and 1 or -1

		arg_4_0.energyPartnerModel_:pos(var_4_1 + var_4_3 * 100, var_4_2)
		arg_4_0.energyPartnerModel_:flipX(arg_4_0:getFlipX())
		arg_4_0.energyPartnerModel_:hide()

		arg_4_0.energyPartnerShowTime_ = var_0_10
	elseif var_0_7:father(arg_4_1.rootID_) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_4_0:setImmuneControl(true)

		arg_4_0.isPurpleType_ = true
	end

	if var_0_7:father(arg_4_1.rootID_) ~= arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_0.greenShowEffect_ then
		arg_4_0.greenShowEffect_:removeSelf()

		arg_4_0.greenShowEffect_ = nil
		arg_4_0.greenShowTarget_ = nil
	end
end

function var_0_3.getOrbOfFrontSkill(arg_5_0)
	local var_5_0 = var_0_3.super.getOrbOfFrontSkill(arg_5_0)
	local var_5_1 = var_0_7:buffOrbSkill(var_5_0)

	if var_5_1 ~= 0 and arg_5_0.isEnergyType_ then
		return var_5_1
	end

	return var_5_0
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		arg_6_0.isEnergyType_ = true
	elseif (arg_6_1.skillID == var_0_15 or arg_6_1.skillID == var_0_16) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = var_0_17

		if arg_6_1.skillID == var_0_16 then
			var_6_0 = var_0_18
		end

		local var_6_1 = arg_6_0:createAttackUnits({
			arg_6_0
		}, var_6_0)

		for iter_6_0, iter_6_1 in ipairs(var_6_1) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	elseif arg_6_1.skillID == var_0_19 or arg_6_1.skillID == var_0_20 then
		arg_6_0:endPurpleSkill()
	elseif arg_6_1.skillID == var_0_11 and arg_6_0.greenShowTarget_ and arg_6_0.greenShowTarget_ == arg_6_1.target then
		if arg_6_0.greenShowEffect_ then
			arg_6_0.greenShowEffect_:removeSelf()
		end

		local var_6_2 = {
			x = arg_6_1.target:getX(),
			y = arg_6_1.target:getY()
		}
		local var_6_3 = var_0_1.ctx.battle.getSpine(var_0_12, "area", 1)

		var_6_3:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_6_3:pos(var_6_2.x, var_6_2.y)
		var_6_3:playRepeat()

		arg_6_0.greenShowEffect_ = var_6_3
	end
end

function var_0_3.checkPurpleSkill(arg_7_0)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 then
		return
	elseif not arg_7_0.isPurpleType_ and arg_7_0.purpleSkillCD_ > 0 and var_0_1.ctx.battle.count - arg_7_0.purpleSkillCD_ < var_0_13 then
		return
	end

	local var_7_0 = arg_7_0:checkInCircle()

	if arg_7_0.isPurpleType_ and not var_7_0 then
		arg_7_0:endPurpleSkill(true)

		return
	elseif not arg_7_0.isPurpleType_ and var_7_0 then
		local var_7_1 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_7_2 = var_0_7:buffOrbSkill(var_7_1)

		if arg_7_0.isEnergyType_ and var_7_2 ~= 0 then
			var_7_1 = var_7_2
		end

		arg_7_0:usePurpleSkill(var_7_1)

		return
	end
end

function var_0_3.createAttacks(arg_8_0)
	local var_8_0 = arg_8_0.unitSkills_

	if not var_8_0 then
		return
	end

	if var_8_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_8_0.reportSkills_, 1)
		end

		arg_8_0.unitSkills_ = nil

		return
	end

	local var_8_1, var_8_2 = var_8_0:getFront()

	while var_8_1 and var_8_1 < 1 do
		if var_0_1.ctx.battle.infoListener.createAttack_info then
			table.insert(var_0_1.ctx.battle.infoListener.createAttack_info, arg_8_0)
		end

		arg_8_0:createUnits(var_8_0)
		var_8_0:popQueue()

		local var_8_3

		var_8_1, var_8_3 = var_8_0:getFront()

		if var_8_3 == var_0_19 or var_8_3 == var_0_20 then
			local var_8_4 = var_0_7:sound(var_8_3)

			var_0_1.ctx.battle.pushSoundQueue(var_8_4)

			local var_8_5 = var_0_7:attackIndex(var_8_3)

			arg_8_0:playAttack(var_8_5)
		end

		if not arg_8_0:isCreatingUnits() then
			arg_8_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_8_0.reportSkills_, 1)
			end

			arg_8_0:updateEnergyBy(var_8_0:getRemp() * arg_8_0:getAttrByType(var_0_2.AttributeType.ENERGY_RATE))
			arg_8_0:popFrontSkill()
		end
	end
end

function var_0_3.endPurpleSkill(arg_9_0, arg_9_1)
	arg_9_0.isPurpleType_ = false
	arg_9_0.isPurpleSecond_ = false
	arg_9_0.purpleSkillTarget_ = nil
	arg_9_0.purpleSkillCD_ = var_0_1.ctx.battle.count

	arg_9_0:setImmuneControl(false)

	if arg_9_1 then
		arg_9_0:skillIsBreak()
	end
end

function var_0_3.usePurpleSkill(arg_10_0, arg_10_1)
	if arg_10_0.walk2Position_ or not arg_10_0:acttionInBlack() or arg_10_0:isBattleUnable() or arg_10_0:isCreatingUnits() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_10_0 = var_0_7:sound(arg_10_1)

	var_0_1.ctx.battle.pushSoundQueue(var_10_0)

	local var_10_1 = var_0_7:attackIndex(arg_10_1)

	arg_10_0:playAttack(var_10_1)

	arg_10_0.unitSkills_ = var_0_5.new({
		fighter = arg_10_0,
		skillID = arg_10_1
	})

	arg_10_0:beginAttackEnd(arg_10_0.unitSkills_)

	if arg_10_0.purpleSkillTarget_ then
		if arg_10_0.purpleSkillTarget_:getX() < arg_10_0:getX() then
			arg_10_0:flipX(true)
		else
			arg_10_0:flipX(false)
		end
	end
end

function var_0_3.unitAfterCreate(arg_11_0, arg_11_1, arg_11_2)
	var_0_3.super.unitAfterCreate(arg_11_0, arg_11_1, arg_11_2)

	if not arg_11_0.isPurpleSecond_ and arg_11_2 and next(arg_11_2) then
		for iter_11_0, iter_11_1 in ipairs(arg_11_2) do
			if iter_11_1.skillID == var_0_15 or iter_11_1.skillID == var_0_16 then
				arg_11_0:playAttack(var_0_14)

				break
			end
		end
	end
end

function var_0_3.checkInCircle(arg_12_0)
	local var_12_0 = arg_12_0:getX()
	local var_12_1
	local var_12_2
	local var_12_3 = var_0_7:scope(arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	if arg_12_0.purpleSkillTarget_ then
		if arg_12_0.purpleSkillTarget_:isDeath() then
			return false
		end

		if var_12_3 >= math.abs(arg_12_0.purpleSkillTarget_:getX() - var_12_0) then
			return true
		end

		return false
	end

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None and var_12_3 >= math.abs(var_12_0 - iter_12_1:getX()) then
			local var_12_4 = math.abs(var_12_0 - iter_12_1:getX())

			if not var_12_1 or var_12_4 < var_12_1 then
				var_12_2 = iter_12_1
				var_12_1 = var_12_4
			end
		end
	end

	if var_12_2 then
		arg_12_0.purpleSkillTarget_ = var_12_2

		return true
	end

	return false
end

function var_0_3.playAttack(arg_13_0, arg_13_1, arg_13_2)
	if not arg_13_1 then
		return
	end

	arg_13_0.skillRoll_ = var_0_6:duration(arg_13_0:getModelID(), arg_13_1)

	if arg_13_1 == var_0_14 then
		arg_13_0.isPurpleSecond_ = true

		arg_13_0:getFighterModel():attack(arg_13_1, nil, nil, nil, nil, true)
	else
		arg_13_0.isPurpleSecond_ = false

		arg_13_0:getFighterModel():attack(arg_13_1, nil, nil, function()
			if arg_13_2 then
				arg_13_2()
			end

			if arg_13_0.fighterModel:getScale() ~= 1 then
				arg_13_0.fighterModel:scale(1)
			end

			if arg_13_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_13_1) then
				arg_13_0:resumeIdle()
			end
		end)
	end
end

function var_0_3.isMoveUnable(arg_15_0)
	if arg_15_0.isPurpleType_ then
		return true
	end

	return var_0_3.super.isMoveUnable(arg_15_0)
end

function var_0_3.selectTargetByTypeD1(arg_16_0)
	return {
		arg_16_0.purpleSkillTarget_
	}
end

function var_0_3.selectTargetByTypeD2(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = {}
	local var_17_1 = var_0_7:scope(arg_17_1)

	if arg_17_0.greenShowEffect_ then
		local var_17_2 = arg_17_0.greenShowEffect_:getX()

		for iter_17_0, iter_17_1 in ipairs(arg_17_0.sideTeam_) do
			if not iter_17_1:isDeath() and not iter_17_1:isAffected() and var_17_1 > math.abs(iter_17_1:getX() - var_17_2) then
				table.insert(var_17_0, iter_17_1)
			end
		end

		return var_17_0
	end

	local function var_17_3(arg_18_0, arg_18_1)
		local var_18_0 = {}

		table.insert(var_18_0, arg_18_0)

		for iter_18_0, iter_18_1 in ipairs(arg_17_0.sideTeam_) do
			if not iter_18_1:isDeath() and not iter_18_1:isAffected() and iter_18_1 ~= arg_18_0 and arg_18_1 >= math.abs(iter_18_1:getX() - arg_18_0:getX()) then
				table.insert(var_18_0, iter_18_1)
			end
		end

		return var_18_0
	end

	local var_17_4
	local var_17_5 = 0

	for iter_17_2, iter_17_3 in ipairs(arg_17_0.sideTeam_) do
		if not iter_17_3:isDeath() and not iter_17_3:isAffected() then
			local var_17_6 = var_17_3(iter_17_3, var_17_1)

			if var_17_5 < #var_17_6 then
				var_17_4 = iter_17_3
				var_17_0 = var_17_6
				var_17_5 = #var_17_6
			end
		end
	end

	arg_17_0.greenShowTarget_ = var_17_4

	return var_17_0
end

return var_0_3
